import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: Store

    private var grouped: [(day: String, entries: [HistoryEntry])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d EEE"
        var out: [(String, [HistoryEntry])] = []
        for entry in store.state.history.reversed() {
            let label: String
            if cal.isDateInToday(entry.date) { label = "Today" }
            else if cal.isDateInYesterday(entry.date) { label = "Yesterday" }
            else { label = fmt.string(from: entry.date) }
            if let last = out.indices.last, out[last].0 == label {
                out[last].1.append(entry)
            } else {
                out.append((label, [entry]))
            }
        }
        return out.map { (day: $0.0, entries: $0.1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("⭐ All-time stamps earned: \(store.state.lifetime)")
                .font(.chunky(15))
                .foregroundColor(Palette.tan)
                .frame(maxWidth: .infinity)

            if store.state.history.isEmpty {
                Text("Nothing here yet…\nDo something great to earn your first stamp! 🐾")
                    .font(.chunky(16, .bold))
                    .foregroundColor(Palette.faint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }

            ForEach(grouped, id: \.day) { group in
                Text(group.day)
                    .font(.chunky(13))
                    .foregroundColor(Palette.tan)
                    .padding(.top, 8)
                ForEach(group.entries) { entry in
                    HistoryRow(entry: entry)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.kind == .stamp ? "+\(entry.count)" : "−\(entry.count)")
                .font(.chunky(18))
                .foregroundColor(.white)
                .frame(width: 56)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.kind == .stamp ? Palette.green : Palette.red)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.ink, lineWidth: 2.5))
            Text(entry.note)
                .font(.chunky(15, .bold))
                .foregroundColor(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Self.timeFmt.string(from: entry.date))
                .font(.chunky(12, .bold))
                .foregroundColor(Palette.tan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .stickerCard(corner: 16, border: 3, drop: 4)
    }
}
