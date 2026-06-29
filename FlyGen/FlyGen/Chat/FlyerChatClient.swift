import Foundation

enum ChatClientError: LocalizedError {
    case badStatus(Int)
    var errorDescription: String? {
        switch self {
        case .badStatus(let c): return "Engine returned HTTP \(c). Is it running on :8000?"
        }
    }
}

struct FlyerChatClient {
    /// The Simulator reaches the host Mac's localhost directly.
    /// Start the engine with `scripts/run-engine.sh`.
    static let baseURL = URL(string: "http://localhost:8000")!

    private let session: URLSession
    init() {
        let cfg = URLSessionConfiguration.default
        // The first GLM extract and image generation can idle for minutes with no
        // intermediate bytes, so allow long gaps before timing out.
        cfg.timeoutIntervalForRequest = 300
        cfg.timeoutIntervalForResource = 600
        session = URLSession(configuration: cfg)
    }

    func stream(_ body: ChatRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = URLRequest(url: Self.baseURL.appendingPathComponent("chat"))
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    req.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        continuation.finish(throwing: ChatClientError.badStatus(http.statusCode)); return
                    }

                    var eventName = "message"
                    var dataLines: [String] = []
                    func flush() {
                        guard !dataLines.isEmpty else { return }
                        if let data = dataLines.joined(separator: "\n").data(using: .utf8) {
                            continuation.yield(SSEEvent.decode(event: eventName, data: data))
                        }
                        eventName = "message"; dataLines = []
                    }

                    for try await line in bytes.lines {
                        // URLSession's AsyncBytes.lines does NOT surface blank lines, so the
                        // SSE blank-line frame delimiter is invisible here. Use start-of-frame
                        // (the next `event:`) as the reliable boundary and flush the previous
                        // frame then; also flush on any blank line we do see, and at stream end.
                        if line.isEmpty {
                            flush()
                        } else if line.hasPrefix("event:") {
                            flush()
                            eventName = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            dataLines.append(String(line.dropFirst(5).drop(while: { $0 == " " })))
                        }
                    }
                    flush()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
