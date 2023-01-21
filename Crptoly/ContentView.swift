//
//  ContentView.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import SwiftUI
import CoreData
import WidgetKit

class ContentViewModel: ObservableObject {
    private let model = AssetsModel()
    @Published var assets = TotalAssets()
    
    func update() {
        model.fetch(completion: { (assets) in
            self.assets = assets
        })
    }
}

let coloredNavAppearance = UINavigationBarAppearance()
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel = ContentViewModel()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        RefreshControl(coordinateSpaceName: "RefreshControl", onRefresh: {
                            print("doRefresh()")
                            viewModel.update()
                        })
                        VStack() {
                            Text(Date(), style: .time)
                                .font(.caption)
                            TotalAssetsView(assets: viewModel.assets)
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
                .coordinateSpace(name: "RefreshControl")
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Wallet Balance")
            }
        }.onAppear {
            viewModel.update()
        }
        .onChange(of: scenePhase) { phase in
            // nofification to widget
            WidgetCenter.shared.reloadTimelines(ofKind: "jp.yuppe.crptoly.widget")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private struct TotalAssetsView: View {
        var assets: TotalAssets
        private var accounts: [IdentifiableAccountAsset] = []

        init(assets: TotalAssets) {
            self.assets = assets
            for account in assets.accounts {
                self.accounts.append(IdentifiableAccountAsset(account: account))
            }
        }
        
        var body: some View {
            List() {
                Section(header: Text("資産合計")) {
                    ListItemView(name: "評価額", value: assets.lastAmount.toIntegerString + " 円")
                    ListItemView(name: "投資額", value: assets.investmentAmount.toIntegerString + " 円")
                    ListItemView(name: "損益", value: assets.equity.toIntegerString + " 円")
                    ListItemView(name: "損益率", value: assets.equityRatio.toPercentString)
                    ListItemView(name: "24時間増減額", value: assets.lastAmountDelta.toIntegerString + " 円")
                    ListItemView(name: "増減比", value: assets.lastAmountRatio.toPercentString)
                }
                ForEach(accounts) { account in
                    Section(header: Text(account.account.accountName)) {
                        ListItemView(name: "評価額", value: account.account.lastAmount.toIntegerString + " 円")
                        ListItemView(name: "24時間増減額", value: account.account.lastAmountDelta.toIntegerString + " 円")
                        ListItemView(name: "増減率", value: account.account.lastAmountRatio.toPercentString)
                        AssetsView(spot: account.account.spot, derivatives: account.account.derivatives, staking: account.account.staking)
                    }
                }
                Section(header: Text("為替レート")) {
                    ListItemView(name: "USD/JPY", value: CurrencyExchange.share.USDJPY.toDecimalString + " 円")
                }
            }
        }
        
        private struct ListItemView: View {
            var name: String
            var value: String
            
            var body: some View {
                HStack(spacing: 0) {
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(value)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        
        private struct AssetsView: View {
            private var assets: [IdentifiableAsset] = []
            
            init(spot: Asset, derivatives: Asset, staking: Asset) {
                if spot.lastAmount > 0 {
                    assets.append(IdentifiableAsset(assetName: "現物", asset: spot))
                }
                if derivatives.lastAmount > 0 {
                    assets.append(IdentifiableAsset(assetName: "デリバティブ", asset: derivatives))
                }
                if staking.lastAmount > 0 {
                    assets.append(IdentifiableAsset(assetName: "ステーキング", asset: staking))
                }
            }

            var body: some View {
                ForEach(assets) { asset in
                    AssetsNavigationLink(assetName: asset.assetName, asset: asset.asset)
                }
            }
            
            private struct IdentifiableAsset: Identifiable {
                var id = UUID()
                var assetName: String
                var asset: Asset
            }
        }
        
        private struct AssetsNavigationLink: View {
            var assetName: String
            var asset: Asset
        
            var body: some View {
                NavigationLink {
                    ZStack {
                        AssetView(assetName: assetName, asset: asset)
                    }
                    //.navigationBarTitleDisplayMode(.inline)
                } label: {
                    ListItemView(name: assetName, value: asset.lastAmount.toIntegerString + " 円")
                }
            }
        }
        
        private struct IdentifiableAccountAsset: Identifiable {
            var id = UUID()
            var account: AccountAsset
        }
        
        private struct IdentifiableAsset: Identifiable {
            var id = UUID()
            var asset: Asset
        }
    }
    
    private struct RefreshControl: View {
        @State private var isRefreshing = false
        var coordinateSpaceName: String
        var onRefresh: () -> Void
        let haptics = UINotificationFeedbackGenerator()
        
        var body: some View {
            GeometryReader { geometry in
                if geometry.frame(in: .named(coordinateSpaceName)).midY > 30 {
                    Spacer()
                        .onAppear() {
                            haptics.notificationOccurred(.success) // 触覚フィードバック
                            isRefreshing = true
                        }
                } else if geometry.frame(in: .named(coordinateSpaceName)).maxY < 10 {
                    Spacer()
                        .onAppear() {
                            if isRefreshing {
                                isRefreshing = false
                                onRefresh()
                            }
                        }
                }
                HStack {
                    Spacer()
                    if isRefreshing {
                        ProgressView()
                    } else {
                        //Text("↓")
                        //    .font(.system(size: 28))
                    }
                    Spacer()
                }
            }.padding(.top, -50)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// MARK: スケルトンコード
//struct ContentView0: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
//                    } label: {
//                        Text(item.timestamp!, formatter: itemFormatter)
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(context: viewContext)
//            newItem.timestamp = Date()
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            offsets.map { items[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//}
//
//private let itemFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .medium
//    return formatter
//}()
//
//struct ContentView0_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView0().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
