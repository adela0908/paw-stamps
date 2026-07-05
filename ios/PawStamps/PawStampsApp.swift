import SwiftUI

@main
struct PawStampsApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

enum AppTab: String, CaseIterable {
    case wallet, rewards, book

    var title: String {
        switch self {
        case .wallet: return "Stamps"
        case .rewards: return "Rewards"
        case .book: return "Book"
        }
    }

    var emoji: String {
        switch self {
        case .wallet: return "🐾"
        case .rewards: return "🎁"
        case .book: return "📖"
        }
    }
}

struct GateRequest: Identifiable {
    let id = UUID()
    let onSuccess: () -> Void
}

struct Celebration: Identifiable {
    let id = UUID()
    let emoji: String
    let line: String
    let line2: String
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var tab: AppTab = .wallet
    @State private var gate: GateRequest?
    @State private var showGive = false
    @State private var showSettings = false
    @State private var redeemTarget: Reward?
    @State private var celebration: Celebration?
    @State private var slamming = false
    @State private var confettiBurst = 0
    @State private var freshSlot: Int?

    private var sound: Bool { store.state.soundOn }

    var body: some View {
        ZStack {
            Palette.paper.ignoresSafeArea()
            PawPattern()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    Group {
                        switch tab {
                        case .wallet:
                            WalletView(freshSlot: $freshSlot)
                        case .rewards:
                            RewardsView(
                                onRedeem: { reward in openGate { redeemTarget = reward } },
                                onEditRewards: { openGate { showSettings = true } }
                            )
                        case .book:
                            HistoryView()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .padding(.bottom, 150)
                }
            }

            VStack {
                Spacer()
                tabBar
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fab
                        .padding(.trailing, 18)
                        .padding(.bottom, 96)
                }
            }

            // ------- overlays (topmost last) -------
            if slamming {
                BigStampSlam()
            }
            ConfettiView(burst: confettiBurst)

            if !store.state.onboarded {
                OnboardingView(onDone: { confettiBurst += 1 })
            }
            if let request = gate {
                PinGateView(
                    correctPin: store.state.pin,
                    soundOn: sound,
                    onSuccess: {
                        let action = request.onSuccess
                        gate = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { action() }
                    },
                    onCancel: { gate = nil }
                )
            }
            if showGive {
                GiveStampView(
                    soundOn: sound,
                    onSubmit: { count, reason in
                        showGive = false
                        performSlam(count: count, reason: reason)
                    },
                    onCancel: { showGive = false }
                )
            }
            if let reward = redeemTarget {
                RedeemConfirmView(
                    reward: reward,
                    balance: store.state.balance,
                    onConfirm: {
                        redeemTarget = nil
                        if store.redeem(reward) {
                            SoundPlayer.shared.play("fanfare", enabled: sound)
                            confettiBurst += 1
                            celebration = Celebration(emoji: reward.icon,
                                                      line: "ENJOY YOUR PRIZE!",
                                                      line2: "\(reward.name) — you earned it! 🐾")
                        }
                    },
                    onCancel: { redeemTarget = nil }
                )
            }
            if showSettings {
                SettingsView(onClose: { showSettings = false })
            }
            if let c = celebration {
                CelebrationView(celebration: c, soundOn: sound, onDismiss: { celebration = nil })
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(spacing: 14) {
            MascotView()
                .frame(width: 86, height: 78)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.state.kidName.isEmpty ? "Paw Stamps" : "Hi, \(store.state.kidName)! 👋")
                    .font(.chunky(24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Collect stamps, get treats!")
                    .font(.chunky(14, .bold))
                    .foregroundColor(Palette.tan)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                PawPrint(opacity: 1)
                    .frame(width: 30, height: 30)
                VStack(spacing: 0) {
                    Text("\(store.state.balance)")
                        .font(.chunky(30))
                        .foregroundColor(Palette.red)
                    Text("STAMPS")
                        .font(.chunky(11, .bold))
                        .foregroundColor(Palette.tan)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .stickerCard(corner: 22)
            .rotationEffect(.degrees(2))

            Button {
                SoundPlayer.shared.play("tap", enabled: sound)
                openGate { showSettings = true }
            } label: {
                Text("⚙️")
                    .font(.system(size: 26))
                    .opacity(0.45)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .foregroundColor(Palette.ink)
    }

    private var tabBar: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases, id: \.self) { t in
                Button {
                    SoundPlayer.shared.play("tap", enabled: sound)
                    tab = t
                } label: {
                    VStack(spacing: 2) {
                        Text(t.emoji).font(.system(size: 22))
                        Text(t.title).font(.chunky(14))
                    }
                    .foregroundColor(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(ChunkyButtonStyle(fill: tab == t ? Palette.yellow : .white,
                                               textColor: Palette.ink, corner: 16, drop: 4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Palette.paper
                .overlay(Rectangle().fill(Palette.ink).frame(height: 3.5), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var fab: some View {
        Button {
            SoundPlayer.shared.play("tap", enabled: sound)
            openGate { showGive = true }
        } label: {
            VStack(spacing: 1) {
                Text("🐾").font(.system(size: 28))
                Text("GIVE\nSTAMP")
                    .font(.chunky(12))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.white)
            .frame(width: 84, height: 84)
            .background(
                ZStack {
                    Circle().fill(Palette.ink).offset(y: 5)
                    Circle().fill(Palette.red)
                    Circle().strokeBorder(Palette.ink, lineWidth: 4)
                }
            )
        }
    }

    // MARK: - Actions

    private func openGate(_ action: @escaping () -> Void) {
        gate = GateRequest(onSuccess: action)
    }

    private func performSlam(count: Int, reason: String) {
        slamming = true
        SoundPlayer.shared.play("pop", enabled: sound)
        confettiBurst += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            slamming = false
            let completedCard = store.giveStamps(count: count, reason: reason)
            let cur = store.state.balance % 10
            freshSlot = cur == 0 ? 9 : cur - 1
            if completedCard {
                SoundPlayer.shared.play("fanfare", enabled: sound)
                celebration = Celebration(emoji: "🏆", line: "CARD COMPLETE!",
                                          line2: "You filled a whole card — amazing!")
            }
        }
    }
}

/// Faint scattered paw prints behind everything.
struct PawPattern: View {
    private let spots: [(x: CGFloat, y: CGFloat, r: Double, s: CGFloat)] = [
        (0.12, 0.16, -18, 44), (0.85, 0.10, 22, 38), (0.30, 0.42, 10, 40),
        (0.90, 0.48, -12, 46), (0.08, 0.70, 15, 38), (0.55, 0.85, -20, 44),
        (0.78, 0.78, 8, 36), (0.45, 0.12, -8, 34),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<spots.count, id: \.self) { i in
                let s = spots[i]
                PawPrint(color: Palette.ink, rotation: s.r, opacity: 0.045)
                    .frame(width: s.s, height: s.s)
                    .position(x: geo.size.width * s.x, y: geo.size.height * s.y)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
