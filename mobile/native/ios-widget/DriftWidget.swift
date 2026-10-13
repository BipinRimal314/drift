import SwiftUI
import WidgetKit

struct DriftEntry: TimelineEntry {
    let date: Date
    var clock: DriftClock { DriftClock(date: date) }
}

struct DriftProvider: TimelineProvider {
    func placeholder(in context: Context) -> DriftEntry { DriftEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DriftEntry) -> Void) {
        completion(DriftEntry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DriftEntry>) -> Void) {
        let now = Date()
        // shortcut: iOS controls delivery of percentage entries; use the app for a continuously updated clock.
        let entries = DriftClock(date: now).timelineDates().map { DriftEntry(date: $0) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }
}

struct DriftWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DriftEntry
    private var color: Color {
        let hex = entry.clock.color
        return Color(red: Double((hex >> 16) & 255) / 255,
                     green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 4)
                Circle().trim(from: 0, to: entry.clock.progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(entry.clock.percentage)%")
                        .font(.system(size: 34, weight: .medium, design: .rounded)).minimumScaleFactor(0.6)
                    Text(entry.clock.phase).font(.system(size: 12)).foregroundStyle(color)
                }.padding(12)
            }.aspectRatio(1, contentMode: .fit)
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 8) {
                    Text("drift.").font(.system(size: 22, weight: .medium))
                    Text("\(entry.clock.minutesLeft) minutes left").font(.system(size: 15))
                    Text("in this local hour").font(.system(size: 12)).foregroundStyle(.secondary)
                    Text(entry.clock.time).font(.system(size: 14, design: .monospaced)).foregroundStyle(.secondary)
                }.fixedSize(horizontal: true, vertical: false)
            }
        }
        .foregroundStyle(.white)
        .containerBackground(Color(red: 10 / 255, green: 10 / 255, blue: 11 / 255), for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.clock.percentage) percent of this local hour complete. \(entry.clock.phase). \(entry.clock.minutesLeft) minutes left. \(entry.clock.time).")
    }
}

@main
struct DriftWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DriftWidget", provider: DriftProvider()) { entry in
            DriftWidgetView(entry: entry)
        }
        .configurationDisplayName("Drift percentage clock")
        .description("See the percentage and color phase of your local hour.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
