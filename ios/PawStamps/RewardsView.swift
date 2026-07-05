import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var store: Store
    let onRedeem: (Reward) -> Void
    let onEditRewards: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎁 Trade your stamps for…")
                .font(.chunky(17))
                .foregroundColor(Palette.tan)

            if store.state.rewards.isEmpty {
                Text("No rewards yet — parents can add some below!")
                    .font(.chunky(16, .bold))
                    .foregroundColor(Palette.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }

            ForEach(store.state.rewards.sorted { $0.cost < $1.cost }) { reward in
                RewardRow(reward: reward,
                          balance: store.state.balance,
                          soundOn: store.state.soundOn,
                          onRedeem: onRedeem)
            }

            Button {
                SoundPlayer.shared.play("tap", enabled: store.state.soundOn)
                onEditRewards()
            } label: {
                Text("✏️ Parents: edit rewards")
                    .font(.chunky(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(ChunkyButtonStyle(fill: Palette.disabled, textColor: Palette.tan,
                                           corner: 22, drop: 5))
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }
}

struct RewardRow: View {
    let reward: Reward
    let balance: Int
    let soundOn: Bool
    let onRedeem: (Reward) -> Void
    @State private var wobble = false

    private var affordable: Bool { balance >= reward.cost }
    private var progress: CGFloat { min(1, CGFloat(balance) / CGFloat(max(reward.cost, 1))) }

    var body: some View {
        HStack(spacing: 14) {
            Text(reward.icon)
                .font(.system(size: 38))
                .frame(width: 64, height: 64)
                .stickerCard(fill: affordable ? Palette.yellow : Palette.paper2,
                             corner: 18, border: 3, drop: 3)
                .rotationEffect(.degrees(affordable && wobble ? 4 : (affordable ? -4 : 0)))
                .onAppear {
                    guard affordable else { return }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        wobble = true
                    }
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(reward.name)
                    .font(.chunky(18))
                    .foregroundColor(Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text("\(reward.cost) stamps · you have \(min(balance, reward.cost))/\(reward.cost)")
                    .font(.chunky(13, .bold))
                    .foregroundColor(Palette.tan)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Palette.paper2)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(affordable ? Palette.yellow : Palette.green)
                            .frame(width: max(6, geo.size.width * progress))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Palette.ink, lineWidth: 2.5)
                    }
                }
                .frame(height: 16)
            }

            Button {
                if affordable {
                    onRedeem(reward)
                } else {
                    SoundPlayer.shared.play("no", enabled: soundOn)
                }
            } label: {
                Text(affordable ? "GET IT!" : "Not yet")
                    .font(.chunky(15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .buttonStyle(ChunkyButtonStyle(fill: affordable ? Palette.red : Palette.disabled,
                                           textColor: affordable ? .white : Palette.tan,
                                           corner: 16, drop: 4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .stickerCard(corner: 22, border: 4, drop: 6)
    }
}
