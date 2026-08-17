import SwiftUI
import AVFoundation
import Speech

/// Live voice dictation for the chat composer: taps the microphone and streams partial
/// transcripts into the composer text as the user speaks, then leaves the final text there to
/// review, edit, and send. Nothing is ever auto-sent — every text send is a paid engine turn,
/// so a mis-heard word must be fixable before money moves.
///
/// Recognition uses Apple's Speech framework in the device's locale (the same voice the
/// keyboard's dictation key would hear), on-device where the locale supports it. Free, no
/// engine/backend involvement, works offline for major languages.
@MainActor
final class SpeechDictationService: ObservableObject {

    @Published private(set) var isRecording = false
    /// Mic or speech permission was denied — the view offers the Settings deep-link.
    @Published var permissionDenied = false
    /// Recognition genuinely can't run right now (no recognizer for the locale, no audio input).
    @Published var unavailable = false

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// Composer text present when dictation started; the transcript appends after it, so
    /// dictating never clobbers what was already typed.
    private var baseText = ""
    private var onUpdate: ((String) -> Void)?

    /// Mic button handler: starts listening, or gracefully stops (keeping the transcript).
    func toggle(existingText: String, onUpdate: @escaping (String) -> Void) {
        if isRecording { stop() } else { begin(existingText: existingText, onUpdate: onUpdate) }
    }

    /// Graceful stop: stop capturing but let the recognizer deliver its final (best) transcript,
    /// which lands in the composer via the same update path a partial would.
    func stop() {
        guard isRecording else { return }
        isRecording = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()          // recognizer finishes up and calls back with isFinal
    }

    /// Hard stop: freeze the composer exactly as it reads right now and drop any late results.
    /// Used when the text is about to be consumed (send) or the chat is going away — a final
    /// result arriving after `send()` cleared the composer would resurrect ghost text.
    func cancel() {
        onUpdate = nil
        isRecording = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        task?.cancel()
        cleanup()
    }

    // MARK: - Internals

    private func begin(existingText: String, onUpdate: @escaping (String) -> Void) {
        requestPermissions { [weak self] granted in
            guard let self else { return }
            if granted {
                self.startRecognition(existingText: existingText, onUpdate: onUpdate)
            } else {
                self.permissionDenied = true
            }
        }
    }

    /// Speech-recognition authorization first, then microphone; both must be granted.
    private func requestPermissions(_ completion: @escaping @MainActor (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                guard status == .authorized else { completion(false); return }
                let micGranted = await AVAudioApplication.requestRecordPermission()
                completion(micGranted)
            }
        }
    }

    private func startRecognition(existingText: String, onUpdate: @escaping (String) -> Void) {
        // Device locale, like the keyboard's dictation key; en-US as the last-resort fallback.
        guard let recognizer = SFSpeechRecognizer(locale: .current)
                            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            unavailable = true
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            unavailable = true
            return
        }

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        // A dead input (0 Hz) crashes installTap — e.g. an environment with no microphone.
        guard format.sampleRate > 0 else {
            unavailable = true
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = true

        // Seed state before any callback can fire.
        baseText = existingText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onUpdate = onUpdate
        self.request = request
        self.audioEngine = engine

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            cleanup()
            unavailable = true
            return
        }

        isRecording = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // A graceful stop lets the old task run on briefly to deliver its final result.
                // If the user has already started a NEW dictation by then, this callback is
                // stale — it must not write into (or tear down) the new session's state.
                guard self.request === request else { return }
                if let result {
                    self.onUpdate?(self.joined(with: result.bestTranscription.formattedString))
                    if result.isFinal { self.cleanup() }
                }
                // Errors include the ~1-minute cap on server-side recognition; whatever was
                // transcribed so far is already in the composer, so just wind down quietly.
                if error != nil {
                    self.isRecording = false
                    self.audioEngine?.stop()
                    self.audioEngine?.inputNode.removeTap(onBus: 0)
                    self.cleanup()
                }
            }
        }
    }

    /// The dictated text goes after whatever was already typed, one space apart.
    private func joined(with transcript: String) -> String {
        baseText.isEmpty ? transcript : baseText + " " + transcript
    }

    private func cleanup() {
        request = nil
        task = nil
        audioEngine = nil
        onUpdate = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
