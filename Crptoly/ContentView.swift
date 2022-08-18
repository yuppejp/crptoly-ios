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
    private let model = WalletModel()
    @Published var wallet = WalletAmount()
    
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
                VStack(spacing: 0) {
                    RefreshControl(coordinateSpaceName: "RefreshControl", onRefresh: {
                        print("doRefresh()")
                        viewModel.update()
                    })
                    
                    Text("Wallet Balance")
                        .font(.title)
                    
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
    var wallet: WalletAmount
    
    var body: some View {
        List() {
            Section(header: Text("資産合計")) {
                ListItemView(name: "BTC換算", value: wallet.last.toIntegerString + " 円")
                ListItemView(name: "24時間増減額", value: wallet.lastDelta.toIntegerString + " 円")
                ListItemView(name: "増減比", value: wallet.lastRatio.toPercentString)
            }
            Section(header: Text("bitbank")) {
                ListItemView(name: "評価額", value: wallet.bitbank.last.toIntegerString + " 円")
                ListItemView(name: "24時間増減額", value: wallet.bitbank.lastDelta.toIntegerString + " 円")
                ListItemView(name: "増減比", value: wallet.bitbank.lastRatio.toPercentString)
            }
            Section(header: Text("Bybit")) {
                ListItemView(name: "評価額", value: wallet.bybit.last.toIntegerString + " 円")
                ListItemView(name: "24時間増減額", value: wallet.bybit.lastDelta.toIntegerString + " 円")
                ListItemView(name: "増減比", value: wallet.bybit.lastRatio.toPercentString)
                ListItemView(name: "米ドル円レート", value: wallet.bybit.USDJPY.toDecimalString + " 円")
            }
        }
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


// MARK: スケルトンコード
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
