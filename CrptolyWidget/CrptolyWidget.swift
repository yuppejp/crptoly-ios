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
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            Text("Default")
        }
    }
}

struct SmallWidgetView: View {
    var entry: Entry
    
    var body: some View {
        VStack(spacing: 0) {
            Text(entry.date, style: .time)
                .font(.caption2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.wallet.equityRatio.toPercentString)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.wallet.last.toIntegerString)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Divider()
            Spacer()
            WalletItemView(amount: entry.wallet.bitbank, image: "bitbank")
            Spacer()
            WalletItemView(amount: entry.wallet.bybit, image: "bybit")
        }
        .padding(14)
    }

    private struct WalletItemView: View {
        let amount: Amount
        let image: String
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: geometry.size.width * 0.15, alignment: .leading)
                        .cornerRadius(4)
                    Spacer()
                    Text(amount.lastDelta.toIntegerString)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Spacer()
                    Text(amount.lastRatio.toPercentString)
                        .font(.caption2)
                        .foregroundColor(Color.white)
                        .padding(.trailing, 2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .background(amount.lastRatio.toColor)
                        .cornerRadius(4)
                }
            }
        }
    }
}

struct MediumWidgetView: View {
    var entry: Entry
    
    var body: some View {
        VStack(spacing: 0) {
            Text(entry.date, style: .time)
                .font(.caption2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                Text(entry.wallet.equityRatio.toPercentString)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 0) {
                    Text(entry.wallet.last.toIntegerString)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(entry.wallet.equity.toIntegerString)
                        .font(.caption)
                        .foregroundColor(entry.wallet.equity.toColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            Spacer()
            Divider()
            WalletItemView(amount: entry.wallet.bitbank, image: "bitbank")
            Spacer()
            Divider()
            WalletItemView(amount: entry.wallet.bybit, image: "bybit")
        }
        .padding(14)
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
                            .frame(maxWidth: geometry.size.width * 0.15, alignment: .leading)
                            .cornerRadius(4)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Text(amount.lastDelta.toIntegerString)
                            .font(.caption)
                            .foregroundColor(amount.lastDelta.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(amount.lastRatio.toPercentString)
                            .font(.caption)
                            .foregroundColor(amount.lastRatio.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Text(amount.last.toIntegerString)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(amount.equityRatio.toPercentString)
                            .font(.caption)
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
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CrptolyWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetContentView(entry: Entry(date: Date(), wallet: WalletAmount()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
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
