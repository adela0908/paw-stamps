import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    let onClose: () -> Void

    struct EditableReward: Identifiable {
        let id: String
        var icon: String
        var name: String
        var costText: String
    }

    @State private var name = ""
    @State private var newPin = ""
    @State private var rewards: [EditableReward] = []
    @State private var adjustText = ""
    @State private var confirmReset = false
    @State private var loaded = false

    var body: some View {
        ModalScaffold(maxWidth: 460, onClose: onClose) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    Text("Settings ⚙️").font(.chunky(22)).foregroundColor(Palette.ink)
                    Text("Parents' corner").font(.chunky(14, .bold)).foregroundColor(Palette.tan)

                    labeled("Kid's name") {
                        styledField("Name", text: $name)
                    }

                    row("Sound effects") {
                        Button {
                            store.state.soundOn.toggle()
                            SoundPlayer.shared.play("tap", enabled: store.state.soundOn)
                        } label: {
                            Text(store.state.soundOn ? "On 🔊" : "Off 🔇")
                                .font(.chunky(13))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, textColor: Palette.ink,
                                                       corner: 12, drop: 3))
                    }

                    row("Secret code (PIN)") {
                        HStack(spacing: 8) {
                            TextField("New 4 digits", text: $newPin)
                                .font(.chunky(15, .bold))
                                .keyboardType(.numberPad)
                                .frame(width: 110)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
                            Button {
                                if newPin.count == 4, newPin.allSatisfy(\.isNumber) {
                                    store.state.pin = newPin
                                    newPin = ""
                                    SoundPlayer.shared.play("pop", enabled: store.state.soundOn)
                                } else {
                                    SoundPlayer.shared.play("no", enabled: store.state.soundOn)
                                }
                            } label: {
                                Text("Set")
                                    .font(.chunky(13))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, textColor: Palette.ink,
                                                           corner: 12, drop: 3))
                        }
                    }

                    row("Fix balance (now \(store.state.balance))") {
                        HStack(spacing: 8) {
                            adjustButton("−1", delta: -1)
                            adjustButton("+1", delta: 1)
                            adjustButton("+5", delta: 5)
                        }
                    }

                    labeled("Rewards (emoji · name · stamps needed)") {
                        VStack(spacing: 10) {
                            ForEach($rewards) { $reward in
                                HStack(spacing: 8) {
                                    styledField("⭐", text: $reward.icon)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.center)
                                    styledField("Reward name", text: $reward.name)
                                    styledField("Cost", text: $reward.costText, numeric: true)
                                        .frame(width: 72)
                                        .multilineTextAlignment(.center)
                                    Button {
                                        rewards.removeAll { $0.id == reward.id }
                                    } label: {
                                        Text("🗑")
                                            .font(.system(size: 16))
                                            .frame(width: 40, height: 40)
                                    }
                                    .buttonStyle(ChunkyButtonStyle(fill: .white, textColor: Palette.ink,
                                                                   corner: 12, drop: 3))
                                }
                            }
                            Button {
                                rewards.append(EditableReward(id: newID(), icon: "⭐",
                                                              name: "New reward", costText: "15"))
                            } label: {
                                Text("＋ Add a reward")
                                    .font(.chunky(13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                            }
                            .buttonStyle(ChunkyButtonStyle(fill: Palette.yellow, textColor: Palette.ink,
                                                           corner: 12, drop: 3))
                        }
                    }

                    Button {
                        saveAndClose()
                    } label: {
                        Text("Save ✅")
                            .font(.chunky(20))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: Palette.green, corner: 22, drop: 6))
                    .padding(.top, 6)

                    Button {
                        confirmReset = true
                    } label: {
                        Text("Reset everything…")
                            .font(.chunky(15))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: Palette.disabled, textColor: Palette.tan,
                                                   corner: 22, drop: 5))
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 560)
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            name = store.state.kidName
            rewards = store.state.rewards.map {
                EditableReward(id: $0.id, icon: $0.icon, name: $0.name, costText: String($0.cost))
            }
        }
        .alert("Reset EVERYTHING?", isPresented: $confirmReset) {
            Button("Reset it all", role: .destructive) {
                store.resetAll()
                onClose()
            }
            Button("Keep my stamps", role: .cancel) {}
        } message: {
            Text("All stamps, history and settings will be gone. This cannot be undone.")
        }
    }

    // MARK: - Helpers

    private func saveAndClose() {
        var s = store.state
        s.kidName = name.trimmingCharacters(in: .whitespaces)
        s.rewards = rewards.map {
            Reward(id: $0.id,
                   icon: $0.icon.trimmingCharacters(in: .whitespaces).isEmpty ? "⭐" : $0.icon,
                   name: $0.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Reward" : $0.name,
                   cost: max(1, Int($0.costText) ?? 5))
        }
        store.state = s
        SoundPlayer.shared.play("pop", enabled: s.soundOn)
        onClose()
    }

    private func adjustButton(_ label: String, delta: Int) -> some View {
        Button {
            store.adjustBalance(by: delta, note: "Parent adjustment")
            SoundPlayer.shared.play("tap", enabled: store.state.soundOn)
        } label: {
            Text(label)
                .font(.chunky(13))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .buttonStyle(ChunkyButtonStyle(fill: .white, textColor: Palette.ink, corner: 12, drop: 3))
    }

    private func labeled<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.chunky(14)).foregroundColor(Palette.tan)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row<C: View>(_ label: String, @ViewBuilder trailing: () -> C) -> some View {
        HStack {
            Text(label)
                .font(.chunky(15))
                .foregroundColor(Palette.ink)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .stickerCard(corner: 16, border: 3, drop: 4)
    }

    private func styledField(_ placeholder: String, text: Binding<String>,
                             numeric: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .font(.chunky(15, .bold))
            .keyboardType(numeric ? .numberPad : .default)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
    }
}
