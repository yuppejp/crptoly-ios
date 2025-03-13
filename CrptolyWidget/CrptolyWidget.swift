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
    var assets: TotalAssets
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let loadingData = Entry(date: Date(), assets: TotalAssets())
        completion(loadingData)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let model = AssetsModel()
        model.fetch(completion: { assets in
            let date = Date()
            let entry = Entry(date: date, assets: assets)

            //let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: date)
            //let timeline = Timeline(entries: [entry], policy: .after(nextUpdate!))

            let timeline = Timeline(entries: [entry], policy: .atEnd)

            completion(timeline)
        })
    }

    func placeholder(in context: Context) -> Entry {
        let loadingData = Entry(date: Date(), assets: TotalAssets())
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
    var accounts: [IdentifiableAccountAsset] = []
    
    init(entry: Entry) {
        self.entry = entry
        for account in entry.assets.accounts {
            self.accounts.append(IdentifiableAccountAsset(account: account))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(entry.date, style: .time)
                    .font(.caption2)
                Text(entry.date, style: .offset)
                    .font(.caption2)
            }
            Text(entry.assets.lastAmount.toIntegerString)
                .font(.title2)
                //.foregroundColor(entry.assets.equity.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Text((entry.assets.equity >= 0 ? "+" : "-") + entry.assets.equity.toIntegerString)
                    .font(.caption)
                    .foregroundColor(entry.assets.equity.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(entry.assets.equityRatio.toPercentString)
                    .font(.caption)
                    .foregroundColor(entry.assets.equityRatio.toColor)
            }
            Spacer()
            Divider()
            ForEach(accounts) { account in
                Spacer()
                ItemView(item: account)
            }
        }
        .widgetBackground(backgroundView: Color.clear) // add for iOS 17
        .padding(14)
    }

    private struct ItemView: View {
        let item: IdentifiableAccountAsset
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    let _ = print("*** accountName: " + item.account.accountName)
                    Image(item.account.accountName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: geometry.size.width * 0.15, alignment: .leading)
                        .cornerRadius(4)
                    //Spacer()
                    Text(item.account.lastAmountDelta.toIntegerString)
                        .font(.caption2)
                        .foregroundColor(item.account.lastAmountDelta.toColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Spacer()
                    Text(item.account.lastAmountRatio.toPercentString)
                        .font(.caption2)
                        .foregroundColor(item.account.lastAmountRatio.toColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        //.font(.system(size: 11))
                        //.foregroundColor(Color.white)
                        //.padding(.trailing, 2)
                        //.frame(maxWidth: geometry.size.width * 0.32, alignment: .trailing)
                        //.background(item.account.lastAmountRatio.toColor)
                        //.cornerRadius(4)
                }
            }
        }
    }
}

struct MediumWidgetView: View {
    var entry: Entry
    var accounts: [IdentifiableAccountAsset] = []

    init(entry: Entry) {
        self.entry = entry
        for account in entry.assets.accounts {
            self.accounts.append(IdentifiableAccountAsset(account: account))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(entry.date, style: .time)
                    .font(.caption2)
                Text(entry.date, style: .offset)
                    .font(.caption2)
            }
            HStack(spacing: 0) {
                Text(entry.assets.equityRatio.toPercentString)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 0) {
                    Text(entry.assets.lastAmount.toIntegerString)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(entry.assets.equity.toIntegerString)
                        .font(.caption)
                        .foregroundColor(entry.assets.equity.toColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            ForEach(accounts) { account in
                Spacer()
                Divider()
                ItemView(item: account)
            }
        }
        .padding(14)
    }

    private struct ItemView: View {
        let item: IdentifiableAccountAsset
        
        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Image(item.account.accountName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.15, alignment: .leading)
                            .cornerRadius(4)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Text(item.account.lastAmountDelta.toIntegerString)
                            .font(.caption)
                            .foregroundColor(item.account.lastAmountDelta.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(item.account.lastAmountRatio.toPercentString)
                            .font(.caption)
                            .foregroundColor(item.account.lastAmountRatio.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Text(item.account.lastAmount.toIntegerString)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(item.account.equityRatio.toPercentString)
                            .font(.caption)
                            .foregroundColor(item.account.equityRatio.toColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct IdentifiableAccountAsset: Identifiable {
    var id = UUID()
    var account: AccountAsset
}

@main
struct CrptolyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jp.yuppe.crptoly.widget", provider: Provider(), content: { entry in
            WidgetContentView(entry: entry)
        }).description(Text("保有コイン数から現在の評価額を表示します"))
            .configurationDisplayName(Text("運用資産の概算"))
            .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled() // Xcode15ビルドの余白を無視する
    }
}

struct CrptolyWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetContentView(entry: Entry(date: Date(), assets: TotalAssets()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetContentView(entry: Entry(date: Date(), assets: TotalAssets()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

// add for iOS 17
// https://nemecek.be/blog/192/hotfixing-widgets-for-ios-17-containerbackground-padding
// https://www.reddit.com/r/SwiftUI/comments/15iahj8/please_adopt_containerbackground_api/?rdt=54594
extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
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
