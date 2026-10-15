import SwiftUI
import UIKit
import Combine
import AVFoundation
import StreamDeckKit

@MainActor
final class DeckTest: ObservableObject {
    @Published var status = "Starting…"
    @Published var deviceStatus = "No deck detected"
    @Published var selected = 0
    @Published var message = "Press a ticket button."
    @Published var log: [String] = []
    @Published var remaining: [Int: Int] = [:]
    @Published var overview = false
    @Published var paused = false
    @Published var speech = false
    private var decks: [StreamDeck] = []
    private var down: [Int: TimeInterval] = [:]
    private var taps: [Int: TimeInterval] = [:]
    private var deadlines: [Int: TimeInterval] = [:]
    private var cancelledRelease = Set<Int>()
    private var subscriptions = Set<AnyCancellable>()
    private let speaker = AVSpeechSynthesizer()
    private var started = false
    private var owner: ObjectIdentifier?

    func note(_ text: String) {
        message = text
        log.insert("\(Date().formatted(date: .omitted, time: .standard))  \(text)", at: 0)
        if log.count > 80 { log.removeLast() }
    }
    func start() {
        guard !started else { return }
        started = true
        UIApplication.shared.isIdleTimerDisabled = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        StreamDeckSession.instance.$devices.receive(on: DispatchQueue.main).sink { [weak self] devices in
            guard let self else { return }
            self.decks = devices
            self.deviceStatus = devices.isEmpty ? "No deck detected" : devices.map { "\($0.info.productName): \($0.capabilities.keyCount) keys" }.joined(separator: ", ")
            self.clear()
            self.draw()
        }.store(in: &subscriptions)
        StreamDeckSession.setUp(stateHandler: { [weak self] state in
            self?.status = String(describing: state)
        }, newDeviceHandler: { [weak self] deck in
            guard let self else { return }
            deck.setBrightness(60)
            deck.inputEventHandler = { [weak self, weak deck] event in
                guard let self, let deck else { return }
                if case let .keyPress(index, pressed) = event {
                    let source = ObjectIdentifier(deck)
                    if self.owner != source { self.clear(); self.owner = source }
                    self.input(index, pressed)
                }
            }
            self.paint(deck)
        })
        Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.tick() }.store(in: &subscriptions)
    }
    func clear() {
        down.removeAll(); taps.removeAll(); deadlines.removeAll()
        remaining.removeAll(); cancelledRelease.removeAll()
    }
    func suspend() {
        clear()
        speaker.stopSpeaking(at: .immediate)
        note("App inactive: pending announcements cancelled.")
        draw()
    }
    func input(_ key: Int, _ pressed: Bool) {
        let now = ProcessInfo.processInfo.systemUptime
        if pressed {
            guard down[key] == nil else { return }
            down[key] = now
            note("Key \(key + 1) down")
            if deadlines[key] != nil {
                deadlines[key] = nil; remaining[key] = nil; taps[key] = nil
                cancelledRelease.insert(key)
                note("Cancelled #\(150 + key)"); draw()
            }
            return
        }
        guard let began = down.removeValue(forKey: key) else { return }
        if cancelledRelease.remove(key) != nil { return }
        let held = now - began
        if key >= 10 {
            if key == 14 && held >= 1 {
                paused.toggle()
                note(paused ? "TEST: kiosk paused (no real kiosk connected)" : "TEST: kiosk resumed")
            } else if key == 13 {
                overview.toggle(); note("Batch overview toggled")
            } else {
                note("Utility key \(key + 1): reserved in this hardware test")
            }
            draw(); return
        }
        selected = key; overview = false
        if held >= 1 {
            taps[key] = nil
            note("TEST REPRINT #\(150 + key) — no printer connected")
        } else if let last = taps[key], now - last <= 0.45 {
            taps[key] = nil
            deadlines[key] = now + 5; remaining[key] = 5
            note("Notifying #\(150 + key) in 5 seconds. Press its button to cancel.")
        } else {
            taps.removeAll(); taps[key] = now
            note("Viewing sample ticket #\(150 + key)")
        }
        draw()
    }
    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        var changed = false
        for (key, deadline) in Array(deadlines) {
            let seconds = max(0, Int(ceil(deadline - now)))
            if seconds == 0 {
                deadlines[key] = nil; remaining[key] = nil
                note("TEST announcement #\(150 + key) completed. No SMS sent.")
                if speech {
                    speaker.speak(AVSpeechUtterance(string: "Test announcement. Order \(150 + key) is ready. Please collect at the window."))
                }
                changed = true
            } else if remaining[key] != seconds {
                remaining[key] = seconds; changed = true
            }
        }
        if changed { draw() }
    }
    func draw() { for deck in decks { paint(deck) } }
    private func paint(_ deck: StreamDeck) {
        for key in 0..<deck.capabilities.keyCount {
            let labels = ["PREV", "NEXT", "RECENT", "BATCH", paused ? "PAUSED" : "PAUSE"]
            let title = key < 10 ? "#\(150 + key)" : (key < 15 ? labels[key - 10] : "KEY \(key + 1)")
            let detail = key < 10 ? (remaining[key].map { "CANCEL \($0)s" } ?? "TICKET") : (key == 14 ? "HOLD 1s" : "TEST")
            let color: UIColor = remaining[key] != nil ? .systemOrange : (key == 14 && paused ? .systemRed : (key == selected ? .systemTeal : .systemBlue))
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 144, height: 144), format: format).image { ctx in
                color.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 144, height: 144))
                let style = NSMutableParagraphStyle(); style.alignment = .center
                var attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 30), .foregroundColor: UIColor.white, .paragraphStyle: style]
                (title as NSString).draw(in: CGRect(x: 2, y: 34, width: 140, height: 44), withAttributes: attributes)
                attributes[.font] = UIFont.boldSystemFont(ofSize: 18)
                (detail as NSString).draw(in: CGRect(x: 2, y: 90, width: 140, height: 30), withAttributes: attributes)
            }
            deck.setKeyImage(image, at: key)
        }
    }
}

struct ContentView: View {
    @StateObject private var model = DeckTest()
    @Environment(\.scenePhase) private var scenePhase
    @State private var battery = "Checking…"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Food Truck • Stream Deck Test").font(.largeTitle.bold())
                Text("SAMPLE DATA — no actual texts, printing, or kiosk control").foregroundStyle(.orange)
                Text("Driver: \(model.status)")
                Text(model.deviceStatus).font(.headline)
                Text("Battery: \(battery)")
                Text(model.message).font(.title2.bold()).padding().background(.blue.opacity(0.15)).cornerRadius(12)
                HStack(alignment: .top, spacing: 30) {
                    if !model.overview {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ORDER #\(150 + model.selected)").font(.largeTitle.bold())
                            Text("2 cheeseburgers\n1 NO ONION\n1 fries\n1 pop").font(.title)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SAMPLE BATCH TOTALS").font(.title2.bold())
                        Text("Cumulative: next 3 / next 10 / all")
                        Text("Burgers  4 / 12 / 21\nChicken  1 / 3 / 6\nFries    3 / 8 / 14").font(.title.monospaced())
                        Text("Fixed demonstration counts").foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding()
                Toggle("Speak test announcements", isOn: $model.speech)
                Text("Single: view • Double: countdown • Press during countdown: cancel • Hold ≥1s then release: test reprint")
                Button("Toggle batch overview") { model.overview.toggle() }.buttonStyle(.bordered)
                Text("Event log").font(.headline)
                ForEach(Array(model.log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.system(.caption, design: .monospaced))
                }
            }.padding(24)
        }
        .task { model.start(); refreshBattery() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in refreshBattery() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in refreshBattery() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.suspend() } }
    }
    private func refreshBattery() {
        let device = UIDevice.current
        let percent = device.batteryLevel < 0 ? "unknown" : "\(Int(device.batteryLevel * 100))%"
        let powered = device.batteryState == .charging || device.batteryState == .full
        battery = "\(percent) — \(powered ? "external power/full" : "not charging or unavailable")"
    }
}
