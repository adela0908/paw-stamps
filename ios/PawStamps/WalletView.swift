import SwiftUI

struct WalletView: View {
    @EnvironmentObject var store: Store
    @Binding var freshSlot: Int?

    private var fullCards: Int { store.state.balance / 10 }
    private var currentStamps: Int { store.state.balance % 10 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if fullCards > 0 {
                sectionTitle("🏆 Saved full cards: \(fullCards) (\(fullCards * 10) stamps banked!)")
                fullCardChips
            }

            currentCard
                .padding(.top, 14)

            if let goal = store.nextGoal {
                let need = goal.cost - store.state.balance
                sectionTitle(need > 0
                    ? "🎯 Next goal: \(goal.icon) \(goal.name) — \(need) stamps to go!"
                    : "🎯 Next goal: \(goal.icon) \(goal.name) — READY! Go redeem it! 🎉")
                    .padding(.top, 8)
            }
        }
        .padding(.top, 8)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.chunky(17))
            .foregroundColor(Palette.tan)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var fullCardChips: some View {
        let shown = min(fullCards, 12)
        return FlowChips(count: shown, extra: fullCards - shown)
    }

    private var currentCard: some View {
        VStack(spacing: 14) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<10, id: \.self) { i in
                    SlotView(index: i,
                             filled: i < currentStamps,
                             isFresh: freshSlot == i && i == currentStamps - 1)
                }
            }
            Text(currentStamps == 0 && store.state.balance > 0
                 ? "New card — go go go! 🚀"
                 : "\(10 - currentStamps) more to finish this card!")
                .font(.chunky(15))
                .foregroundColor(Palette.tan)
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .stickerCard(corner: 26, border: 4, drop: 7)
        .overlay(ribbon, alignment: .topLeading)
    }

    private var ribbon: some View {
        Text(fullCards > 0 ? "Card #\(fullCards + 1)" : "My stamp card")
            .font(.chunky(14))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 3)
            .stickerCard(fill: Palette.red, corner: 12, border: 3, drop: 3)
            .rotationEffect(.degrees(-3))
            .offset(x: 22, y: -14)
    }
}

struct SlotView: View {
    let index: Int
    let filled: Bool
    let isFresh: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.faint, style: StrokeStyle(lineWidth: 3, dash: [7, 6]))
            if filled {
                PawPrint(rotation: Double((index * 47) % 15 - 7))
                    .padding(-3)
                    .scaleEffect(isFresh && !appeared ? 3 : 1)
                    .rotationEffect(.degrees(isFresh && !appeared ? -30 : 0))
                    .opacity(isFresh && !appeared ? 0 : 1)
            } else {
                Text("\(index + 1)")
                    .font(.chunky(13))
                    .foregroundColor(Palette.faint)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 76)
        .onAppear {
            guard isFresh else { appeared = true; return }
            withAnimation(.interpolatingSpring(stiffness: 260, damping: 14).delay(0.05)) {
                appeared = true
            }
        }
    }
}

/// Wrapping row of "×10" chips for completed cards.
struct FlowChips: View {
    let count: Int
    let extra: Int

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 8, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Text("🐾 ×10")
                    .font(.chunky(15))
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .stickerCard(fill: i % 2 == 0 ? Palette.yellow : Palette.pink,
                                 corner: 12, border: 3, drop: 3)
                    .rotationEffect(.degrees(i % 2 == 0 ? -2 : 2))
            }
            if extra > 0 {
                Text("＋\(extra) more!")
                    .font(.chunky(15))
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .stickerCard(fill: Palette.blue, corner: 12, border: 3, drop: 3)
            }
        }
    }
}
