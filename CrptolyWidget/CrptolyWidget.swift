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
    var wallet: WalletAmount
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let loadingData = Entry(date: Date(), wallet: WalletAmount())
        completion(loadingData)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let model = WalletModel()
        model.fetch(completion: { wallet in
            let date = Date()
            let entry = Entry(date: date, wallet: wallet)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: date)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate!))
            completion(timeline)
        })
    }

    func placeholder(in context: Context) -> Entry {
        let loadingData = Entry(date: Date(), wallet: WalletAmount())
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
        case .systemExtraLarge:
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
                .font(.caption2)

            HStack(spacing: 0) {
                Text((entry.wallet.equityRatio * 100).toDecimalString)
                    .font(.title2)
                    .frame(alignment: .leading)
                VStack {
                    Spacer()
                    Text("%")
                        .font(.caption2)
                        .frame(alignment: .leading)
                }
                VStack(spacing: 0) {
                    Text(entry.wallet.last.toIntegerString)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(entry.wallet.equity.toIntegerString)
                        .font(.caption2)
                        .foregroundColor(entry.wallet.equity.toColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            Divider()
            Spacer()

            WalletItemView(amount: entry.wallet.bitbank, image: "bitbank")
            Divider()
            Spacer()
            WalletItemView(amount: entry.wallet.bybit, image: "bybit")

            Spacer()
        }
        .padding(8)
    }

    private struct WalletItemView: View {
        let amount: Amount
        let image: String
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.15, alignment: .trailing)
                            .cornerRadius(4)
                        Spacer()
                    }

                    VStack(spacing: 0) {
                        Text(amount.lastDelta.toIntegerString)
                            .font(.caption2)
                            .foregroundColor(amount.lastDelta.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(amount.lastRatio.toPercentString)
                            .font(.caption2)
                            .foregroundColor(amount.lastRatio.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                    }

                    VStack(spacing: 0) {
                        Text(amount.last.toIntegerString)
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(amount.equityRatio.toPercentString)
                            .font(.caption2)
                            .foregroundColor(amount.equityRatio.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                    }
                }
            }
        }
    }
}

@main
struct CrptolyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Kind", provider: Provider(), content: { entry in
            WidgetContentView(entry: entry)
        }).description(Text("保有コイン数から現在の評価額を表示します"))
            .configurationDisplayName(Text("運用資産の概算"))
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct CrptolyWidget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
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
