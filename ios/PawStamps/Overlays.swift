import SwiftUI

/// Dimmed backdrop + chunky modal card, used by every overlay.
struct ModalScaffold<Content: View>: View {
    var maxWidth: CGFloat = 440
    var onClose: (() -> Void)?
    @ViewBuilder let content: Content
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { /* block taps behind */ }

            content
                .padding(22)
                .frame(maxWidth: maxWidth)
                .stickerCard(fill: Palette.paper, corner: 28, border: 4, drop: 8)
                .overlay(alignment: .topTrailing) {
                    if let onClose = onClose {
                        Button(action: onClose) {
                            Text("✕")
                                .font(.chunky(17))
                                .foregroundColor(Palette.ink)
                                .frame(width: 38, height: 38)
                                .background(
                                    ZStack {
                                        Circle().fill(Palette.ink).offset(y: 3)
                                        Circle().fill(Color.white)
                                        Circle().strokeBorder(Palette.ink, lineWidth: 3)
                                    }
                                )
                        }
                        .offset(x: -10, y: 10)
                    }
                }
                .padding(24)
                .scaleEffect(shown ? 1 : 0.7)
                .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) { shown = true }
        }
    }
}

// MARK: - PIN gate

struct PinGateView: View {
    let correctPin: String
    let soundOn: Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var buffer = ""
    @State private var shakes = 0

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]

    var body: some View {
        ModalScaffold(maxWidth: 360, onClose: onCancel) {
            VStack(spacing: 10) {
                Text("Parents Only! 🙀").font(.chunky(22)).foregroundColor(Palette.ink)
                Text("Enter the secret code").font(.chunky(14, .bold)).foregroundColor(Palette.tan)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < buffer.count ? Palette.red : Color.white)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 3))
                    }
                }
                .padding(.vertical, 10)
                .modifier(ShakeEffect(shakes: CGFloat(shakes)))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                          spacing: 12) {
                    ForEach(0..<keys.count, id: \.self) { i in
                        if keys[i].isEmpty {
                            Color.clear.frame(height: 54)
                        } else {
                            Button {
                                tap(keys[i])
                            } label: {
                                Text(keys[i])
                                    .font(.chunky(24))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            }
                            .buttonStyle(ChunkyButtonStyle(fill: .white, textColor: Palette.ink,
                                                           corner: 18, drop: 4))
                        }
                    }
                }
                .frame(maxWidth: 280)

                if correctPin == "1234" {
                    Text("(Default code is 1234 — change it in Settings)")
                        .font(.chunky(12, .bold))
                        .foregroundColor(Palette.faint)
                        .padding(.top, 8)
                }
            }
        }
    }

    private func tap(_ key: String) {
        SoundPlayer.shared.play("tap", enabled: soundOn)
        if key == "⌫" {
            if !buffer.isEmpty { buffer.removeLast() }
        } else if buffer.count < 4 {
            buffer += key
        }
        guard buffer.count == 4 else { return }
        if buffer == correctPin {
            onSuccess()
        } else {
            SoundPlayer.shared.play("no", enabled: soundOn)
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { buffer = "" }
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: -9 * sin(shakes * .pi * 4), y: 0))
    }
}

// MARK: - Give stamp

struct GiveStampView: View {
    let soundOn: Bool
    let onSubmit: (Int, String) -> Void
    let onCancel: () -> Void

    @State private var reason = stampReasons[0]
    @State private var isCustom = false
    @State private var customText = ""
    @State private var count = 1

    private let counts = [1, 2, 3, 5, 10]

    var body: some View {
        ModalScaffold(onClose: onCancel) {
            VStack(spacing: 12) {
                Text("Give a Stamp! 🎉").font(.chunky(22)).foregroundColor(Palette.ink)
                Text("What good thing happened?").font(.chunky(14, .bold)).foregroundColor(Palette.tan)

                let cols = [GridItem(.adaptive(minimum: 150), spacing: 10)]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(stampReasons, id: \.self) { r in
                        chip(r, selected: !isCustom && reason == r) {
                            isCustom = false
                            reason = r
                        }
                    }
                    chip("✏️ My own…", selected: isCustom) { isCustom = true }
                }

                if isCustom {
                    TextField("Type your own…", text: $customText)
                        .font(.chunky(17, .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.ink, lineWidth: 3))
                }

                Text("How many stamps?").font(.chunky(14, .bold)).foregroundColor(Palette.tan)
                    .padding(.top, 4)
                HStack(spacing: 12) {
                    ForEach(counts, id: \.self) { n in
                        Button {
                            SoundPlayer.shared.play("tap", enabled: soundOn)
                            count = n
                        } label: {
                            Text("\(n)")
                                .font(.chunky(20))
                                .frame(width: 54, height: 54)
                        }
                        .buttonStyle(ChunkyButtonStyle(fill: count == n ? Palette.yellow : .white,
                                                       textColor: Palette.ink, corner: 27, drop: 4))
                    }
                }

                Button {
                    let final = isCustom
                        ? (customText.trimmingCharacters(in: .whitespaces).isEmpty
                           ? "Being awesome!" : customText.trimmingCharacters(in: .whitespaces))
                        : reason
                    onSubmit(count, final)
                } label: {
                    Text("STAMP IT! 🐾")
                        .font(.chunky(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.red, corner: 22, drop: 6))
                .padding(.top, 8)
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            SoundPlayer.shared.play("tap", enabled: soundOn)
            action()
        } label: {
            Text(label)
                .font(.chunky(15))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(fill: selected ? Palette.blue : .white,
                                       textColor: selected ? .white : Palette.ink,
                                       corner: 22, drop: 3))
    }
}

// MARK: - Redeem confirm

struct RedeemConfirmView: View {
    let reward: Reward
    let balance: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ModalScaffold(maxWidth: 380, onClose: onCancel) {
            VStack(spacing: 10) {
                Text("Trade \(reward.cost) stamps?").font(.chunky(22)).foregroundColor(Palette.ink)
                Text(reward.icon).font(.system(size: 64))
                Text("\(reward.name) — you have \(balance) stamps")
                    .font(.chunky(14, .bold))
                    .foregroundColor(Palette.tan)
                    .multilineTextAlignment(.center)
                Button(action: onConfirm) {
                    Text("YES! Trade stamps 🎉")
                        .font(.chunky(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.green, corner: 22, drop: 6))
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Celebration

struct CelebrationView: View {
    let celebration: Celebration
    let soundOn: Bool
    let onDismiss: () -> Void
    @State private var wobble = false

    var body: some View {
        ModalScaffold(maxWidth: 380) {
            VStack(spacing: 8) {
                Text(celebration.emoji)
                    .font(.system(size: 74))
                    .rotationEffect(.degrees(wobble ? 6 : -6))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            wobble = true
                        }
                    }
                Text(celebration.line)
                    .font(.chunky(26))
                    .foregroundColor(Palette.red)
                    .multilineTextAlignment(.center)
                Text(celebration.line2)
                    .font(.chunky(16, .bold))
                    .foregroundColor(Palette.tan)
                    .multilineTextAlignment(.center)
                Button {
                    SoundPlayer.shared.play("tap", enabled: soundOn)
                    onDismiss()
                } label: {
                    Text("YAY! 🐱")
                        .font(.chunky(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.red, corner: 22, drop: 6))
                .padding(.top, 10)
            }
        }
    }
}

// MARK: - Big stamp slam

struct BigStampSlam: View {
    @State private var landed = false

    var body: some View {
        GeometryReader { geo in
            BigStamp()
                .frame(width: min(geo.size.width, geo.size.height) * 0.46)
                .rotationEffect(.degrees(-8))
                .scaleEffect(landed ? 1 : 4)
                .opacity(landed ? 1 : 0)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .onAppear {
                    withAnimation(.interpolatingSpring(stiffness: 240, damping: 13)) {
                        landed = true
                    }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    let burst: Int
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, height: geo.size.height)
                }
            }
            .onChange(of: burst) { _ in
                guard burst > 0 else { return }
                let fresh = (0..<28).map { _ in ConfettiPiece(width: geo.size.width) }
                pieces.append(contentsOf: fresh)
                let ids = Set(fresh.map(\.id))
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    pieces.removeAll { ids.contains($0.id) }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let delay: Double
    let duration: Double
    let color: Color
    let isRound: Bool
    let spin: Double

    init(width: CGFloat) {
        x = CGFloat.random(in: 0.05...0.95) * width
        delay = Double.random(in: 0...0.4)
        duration = Double.random(in: 1.2...2.1)
        color = [Palette.red, Palette.yellow, Palette.blue, Palette.pink, Palette.green]
            .randomElement()!
        isRound = Bool.random()
        spin = Double.random(in: 360...900)
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let height: CGFloat
    @State private var fall = false

    var body: some View {
        RoundedRectangle(cornerRadius: piece.isRound ? 6 : 2)
            .fill(piece.color)
            .frame(width: 12, height: 12)
            .rotationEffect(.degrees(fall ? piece.spin : 0))
            .position(x: piece.x, y: fall ? height + 30 : -30)
            .opacity(fall ? 0.75 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    fall = true
                }
            }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    let onDone: () -> Void
    @State private var name = ""
    @State private var pin = ""

    var body: some View {
        ModalScaffold(maxWidth: 400) {
            VStack(spacing: 10) {
                MascotView()
                    .frame(width: 130, height: 118)
                Text("Welcome to Paw Stamps!").font(.chunky(22)).foregroundColor(Palette.ink)
                Text("A stamp wallet for good deeds 🐾")
                    .font(.chunky(14, .bold)).foregroundColor(Palette.tan)

                field(label: "What's the kid's name?", text: $name, placeholder: "e.g. Leo")
                field(label: "Parent secret code (4 digits)", text: $pin, placeholder: "1234", numeric: true)

                Button {
                    var s = store.state
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { s.kidName = trimmed }
                    if pin.count == 4, pin.allSatisfy(\.isNumber) { s.pin = pin }
                    s.onboarded = true
                    store.state = s
                    SoundPlayer.shared.play("fanfare", enabled: s.soundOn)
                    onDone()
                } label: {
                    Text("Let's go! 🚀")
                        .font(.chunky(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(ChunkyButtonStyle(fill: Palette.red, corner: 22, drop: 6))
                .padding(.top, 8)
            }
        }
    }

    private func field(label: String, text: Binding<String>,
                       placeholder: String, numeric: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.chunky(14)).foregroundColor(Palette.tan)
            TextField(placeholder, text: text)
                .font(.chunky(17, .bold))
                .keyboardType(numeric ? .numberPad : .default)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.ink, lineWidth: 3))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
