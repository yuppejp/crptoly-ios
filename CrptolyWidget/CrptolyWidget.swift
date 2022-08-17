//
//  CrptolyWidget.swift
//  CrptolyWidgetExtension
//  
//  Created on 2022/08/17
//  
//

import WidgetKit
import SwiftUI
import Intents

struct Entry: TimelineEntry {
    var date: Date
    var info: UserAssetsInfo
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let loadingData = Entry(date: Date(), info: UserAssetsInfo())
        completion(loadingData)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        BitbankModel.shared.fetch(completion: { info in
            let date = Date()
            let entry = Entry(date: date, info: info)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: date)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate!))
            completion(timeline)
        })
    }

    func placeholder(in context: Context) -> Entry {
        let loadingData = Entry(date: Date(), info: UserAssetsInfo())
        return loadingData
    }
}

struct WidgetContentView: View {
    var entry: Entry
    @Environment(\.widgetFamily) var WidgetFamily
    
    var body: some View {
        switch WidgetFamily {
        case .systemSmall:
            WidgetView(entry: entry)
        case .systemMedium:
            WidgetView(entry: entry)
        case .systemLarge:
            WidgetView(entry: entry)
        default:
            Text("Default")
        }
    }
}

struct WidgetView: View {
    var entry: Entry
    var body: some View {
        VStack(spacing: 0) {
            Text(entry.date, style: .time)
                .font(.caption)
                .padding(.top, 8)

            Spacer()

            Text(entry.info.getTotalLastAmount().toComma)
                .font(.title)
            
            Spacer()
                .frame(height: .infinity) // 余白対策

            NumberRateView(
                number: entry.info.getTotalDelta(),
                rate: entry.info.getTotalRate())
            NumberRateView(
                number: entry.info.getTotalLastAmountDelta(),
                rate: entry.info.getTotalLastAmountRate())

            Spacer()
                .frame(height: .infinity) // 余白対策
        }
    }
}

struct NumberRateView: View {
    let number: Double
    let rate: Double

    var body: some View {
        GeometryReader { view in
            HStack(spacing: 0) {
                Text(number.toCommaWithSign)
                    .font(.caption)
                    .frame(maxWidth: view.size.width * 0.65, alignment: .trailing)
                    .padding(.leading, 8)

                Spacer()

                Text(rate.toPercent)
                    .padding(.horizontal, 4)
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: view.size.width * 0.35, alignment: .trailing)
                    .background(getColor(rate))
                    .cornerRadius(4)
                    .padding(.trailing, 8)
            }
        }
        //.frame(height: 20) // 余白対策
    }
    
    func getColor(_ number: Double) -> Color {
        if number >= 0 {
            return Color.green
        } else {
            return Color.red
        }
    }
    
}

@main
struct CrptolyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Kind", provider: Provider(), content: { entry in
            WidgetContentView(entry: entry)
        }).description(Text("Description")).configurationDisplayName(Text("configurationDisplayName"))
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CrptolyWidget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetContentView(entry: Entry(date: Date(), info: UserAssetsInfo()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
//struct Provider: IntentTimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
//    }
//
//    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        let entry = SimpleEntry(date: Date(), configuration: configuration)
//        completion(entry)
//    }
//
//    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []
//
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
//
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let configuration: ConfigurationIntent
//}
//
//struct CrptolyWidgetEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        Text(entry.date, style: .time)
//    }
//}
//
//@main
//struct CrptolyWidget: Widget {
//    let kind: String = "CrptolyWidget"
//
//    var body: some WidgetConfiguration {
//        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
//            CrptolyWidgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("My Widget")
//        .description("This is an example widget.")
//    }
//}
//
//struct CrptolyWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        CrptolyWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
