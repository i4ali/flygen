import Foundation

enum ChatClientError: LocalizedError {
    case badStatus(Int)
    var errorDescription: String? {
        switch self {
        case .badStatus(let c): return "The flyer engine returned an error (HTTP \(c)). Please try again."
        }
    }
}

struct FlyerChatClient {
    /// Debug builds talk to a local engine (`scripts/run-engine.sh` on :8000) so the
    /// engine can be iterated on from the Simulator via NSAllowsLocalNetworking.
    /// Release / TestFlight / App Store builds talk to the deployed engine on Cloud Run.
    /// Shipping a localhost URL is what got build 44 rejected, so production must never
    /// fall back to localhost - the two are split at compile time.
    #if DEBUG
    static let baseURL = URL(string: "http://localhost:8000")!
    #else
    static let baseURL = URL(string: "https://flygen-engine-139288370007.us-central1.run.app")!
    #endif

    /// Shared secret the deployed engine checks (ENGINE_SHARED_SECRET on Cloud Run).
    /// Sent on every request; the local dev engine ignores it when its env var is unset.
    /// This is obfuscation-grade (it ships in the binary), not user auth - it just keeps
    /// the endpoint from being trivially callable by anyone who finds the URL.
    private static let engineKey = "1b9adbd0818b85d8f511aff79d9d340df1bd400524a1c144"

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
                var eventName = "message"
                var dataLines: [String] = []
                func flush() {
                    guard !dataLines.isEmpty else { return }
                    if let data = dataLines.joined(separator: "\n").data(using: .utf8) {
                        continuation.yield(SSEEvent.decode(event: eventName, data: data))
                    }
                    eventName = "message"; dataLines = []
                }
                do {
                    var req = URLRequest(url: Self.baseURL.appendingPathComponent("chat"))
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    req.setValue(Self.engineKey, forHTTPHeaderField: "x-engine-key")
                    req.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: req)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        continuation.finish(throwing: ChatClientError.badStatus(http.statusCode)); return
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
                    // The final frame only flushes after the loop, so a tail-side socket fault
                    // used to discard a fully-buffered event - on an approve turn, the ONLY
                    // event, i.e. three paid concepts. Deliver whatever is complete, then fail.
                    flush()
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
