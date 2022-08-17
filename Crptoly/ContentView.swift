//
//  ContentView.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import SwiftUI
import CoreData

class ContentViewModel: ObservableObject {
    private let model = BybitModel()
    @Published var wallet = BybitWalletBalance()
    
    func update() {
        model.fetch(completion: { (wallet) in
            self.wallet = wallet
        })
    }
}

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    RefreshControl(coordinateSpaceName: "RefreshControl", onRefresh: {
                        print("doRefresh()")
                        viewModel.update()
                    })
                    
                    HStack(spacing: 0) {
                        Image("bybit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, alignment: .leading)
                            .padding(.trailing, 8)
                        Text("Wallet Balance")
                            .font(.title)
                    }
                    
                    WalletBalanceView(wallet: viewModel.wallet)
                        .frame(minHeight: geometry.size.height * 0.9)
                }
            }
            .coordinateSpace(name: "RefreshControl")
        }.onAppear {
            viewModel.update()
        }
    }
}

struct WalletBalanceView: View {
    var wallet: BybitWalletBalance
    
    var body: some View {
        List() {
            Section(header: Text("資産合計 USD")) {
                ListItemView(name: "BTC換算", value: wallet.total.lastAmount.toDecimalString + " USD")
                //ListItemView(name: "24時間前", value: wallet.total.openAmount.toDecimalString + " USD")
            }
            Section(header: Text("資産合計 JPY")) {
                ListItemView(name: "円換算", value: exchage(wallet.total.lastAmount).toIntegerString + " 円")
                ListItemView(name: "24時間前", value: exchage(wallet.total.openAmount).toIntegerString + " 円")
                ListItemView(name: "増減額", value: delta(exchage(wallet.total.openAmount), exchage(wallet.total.lastAmount)).toIntegerString + " 円")
                ListItemView(name: "増減比", value: deltaRatio(exchage(wallet.total.openAmount), exchage(wallet.total.lastAmount)).toPercentString)
                ListItemView(name: "米ドル円レート", value: wallet.USDJPY.toDecimalString + " 円")
            }
            Section(header: Text("資産内訳")) {
                ListItemView(name: "現物", value: exchage(wallet.spot.lastAmount).toIntegerString + " 円")
                ListItemView(name: "デリバティブ", value: exchage(wallet.derivatives.lastAmount).toIntegerString + " 円")
                ListItemView(name: "ステーキング", value: exchage(wallet.staking.lastAmount).toIntegerString + " 円")
            }
        }
    }
    
    private func exchage(_ usd: Double) -> Double {
        return usd * wallet.USDJPY
    }

    private func delta(_ from: Double, _ to: Double) -> Double {
        return to - from
    }

    private func deltaRatio(_ from: Double, _ to: Double) -> Double {
        print("from:", from)
        print("from:", to)
        print("delta:", delta(from, to))
        return delta(from, to) / from
    }

}

struct ListItemView: View {
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

struct RefreshControl: View {
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
                    Text("↓")
                        .font(.system(size: 28))
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
//struct AssetItem: Identifiable {
//    var id = UUID()
//    var asset: UserAsset
//}
//
//class MainViewModel: ObservableObject {
//    @Published var updateCounter = 0
//    var assets: [AssetItem] = []
//    var info = UserAssetsInfo()
//
//    func update() {
//        BitbankModel.shared.fetch(completion: { info in
//            self.info = info
//            self.assets.removeAll()
//            for asset in info.assets {
//                let item = AssetItem(asset: asset)
//                self.assets.append(item)
//            }
//            DispatchQueue.main.async {
//                self.updateCounter += 1
//            }
//        })
//    }
//}
//
//struct ContentView: View {
//    @StateObject var viewModel = MainViewModel()
//
//    var body: some View {
//        VStack(spacing: 0) {
//
//            VStack {
//                Text(viewModel.info.updateDate, style: .time)
//                    .font(.headline)
//
//                Text(viewModel.info.getTotalLastAmount().toCurrency)
//                    .font(.largeTitle)
//
//                HStack {
//                    Text("total:")
//                        .font(.body)
//                    Text(viewModel.info.getTotalDelta().toCommaWithSign + " (" +
//                         viewModel.info.getTotalRate().toPercent + ")")
//                        .font(.title)
//                }
//
//                HStack {
//                    Text("24h:")
//                        .font(.body)
//                    Text(viewModel.info.getTotalLastAmountDelta().toCommaWithSign + " (" +
//                         viewModel.info.getTotalLastAmountRate().toPercent + ")")
//                        .font(.title)
//                }
//            }
//            //.background(Color.gray)
//
//            Spacer()
//
//            if viewModel.updateCounter > 0 {
//                Spacer()
//                AssetListView(assets: viewModel.assets)
//            } else {
//                Text("Loading...")
//            }
//
//            Button(action: {
//                viewModel.update()
//            }, label: { Text("更新") })
//        }
//        .onAppear {
//            viewModel.update()
//        }
//    }
//}
//
//struct AssetListView: View {
//    var assets: [AssetItem]
//
//    var body: some View {
//        List {
//            if assets.count > 0 {
//                ForEach(assets) { asset in
//                    AssetItemView(item: asset)
//                }
//            }
//        }
//        .listStyle(PlainListStyle())
//    }
//}
//
//struct AssetItemView: View {
//    var item: AssetItem
//
//    var body: some View {
//        GeometryReader { geo in
//            HStack(spacing: 0) {
//                Text(item.asset.asset.asset)
//                    .frame(maxWidth: geo.size.width * 0.2, alignment: .leading)
//                Text(item.asset.getLastAmount().toCurrency)
//                    .frame(maxWidth: geo.size.width * 0.35, alignment: .trailing)
//                Text(item.asset.getLastDelta().toCommaWithSign)
//                    .frame(maxWidth: geo.size.width * 0.25, alignment: .trailing)
//                Text(item.asset.getLastRate().toPercent)
//                    .frame(maxWidth: geo.size.width * 0.2, alignment: .trailing)
//            }
//            //.frame(maxWidth: .infinity, alignment: .trailing)
//        }
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}


//struct ContentView: View {
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
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
