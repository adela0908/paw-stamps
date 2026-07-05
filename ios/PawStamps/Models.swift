import Foundation
import SwiftUI

struct Reward: Identifiable, Codable, Equatable {
    var id: String
    var icon: String
    var name: String
    var cost: Int
}

struct HistoryEntry: Identifiable, Codable, Equatable {
    enum Kind: String, Codable { case stamp, redeem }
    var id: String
    var date: Date
    var kind: Kind
    var count: Int
    var note: String
}

struct AppState: Codable, Equatable {
    var onboarded: Bool = false
    var kidName: String = ""
    var pin: String = "1234"
    var soundOn: Bool = true
    var balance: Int = 0
    var lifetime: Int = 0
    var history: [HistoryEntry] = []
    var rewards: [Reward] = AppState.defaultRewards

    static let defaultRewards: [Reward] = [
        Reward(id: "r1", icon: "🍦", name: "Ice cream treat", cost: 5),
        Reward(id: "r2", icon: "🧸", name: "Small toy", cost: 10),
        Reward(id: "r3", icon: "🎬", name: "Movie night pick", cost: 20),
        Reward(id: "r4", icon: "🎢", name: "Fun park trip", cost: 50),
        Reward(id: "r5", icon: "🎁", name: "BIG surprise gift", cost: 100),
    ]
}

let stampReasons = ["Helped out 🤝", "Super kind 💖", "Homework done 📚",
                    "Tidied up 🧹", "Brave moment 💪", "Great manners 🙏"]

func newID() -> String {
    String(Date().timeIntervalSince1970) + "-" + String(Int.random(in: 0..<100000))
}

final class Store: ObservableObject {
    static let storageKey = "pawstamps.state.v1"

    @Published var state: AppState {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Store.storageKey),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            state = decoded
        } else {
            state = AppState()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Store.storageKey)
        }
    }

    // MARK: - Actions

    /// Returns true if a card of 10 was completed by this grant.
    @discardableResult
    func giveStamps(count: Int, reason: String) -> Bool {
        let before = state.balance
        state.balance += count
        state.lifetime += count
        state.history.append(HistoryEntry(id: newID(), date: Date(), kind: .stamp, count: count, note: reason))
        trimHistory()
        return state.balance / 10 > before / 10
    }

    /// Returns false if balance is insufficient.
    @discardableResult
    func redeem(_ reward: Reward) -> Bool {
        guard state.balance >= reward.cost else { return false }
        state.balance -= reward.cost
        state.history.append(HistoryEntry(id: newID(), date: Date(), kind: .redeem, count: reward.cost,
                                          note: "\(reward.icon) \(reward.name)"))
        trimHistory()
        return true
    }

    func adjustBalance(by delta: Int, note: String) {
        let applied = max(delta, -state.balance)
        guard applied != 0 else { return }
        state.balance += applied
        if applied > 0 { state.lifetime += applied }
        state.history.append(HistoryEntry(id: newID(), date: Date(),
                                          kind: applied > 0 ? .stamp : .redeem,
                                          count: abs(applied), note: note))
        trimHistory()
    }

    func resetAll() {
        state = AppState()
    }

    private func trimHistory() {
        if state.history.count > 500 {
            state.history.removeFirst(state.history.count - 500)
        }
    }

    var nextGoal: Reward? {
        let unearned = state.rewards.filter { $0.cost > state.balance }.min { $0.cost < $1.cost }
        return unearned ?? state.rewards.min { $0.cost < $1.cost }
    }
}
