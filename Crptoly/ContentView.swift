//
//  ContentView.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import SwiftUI
import CoreData

struct AssetItem: Identifiable {
    var id = UUID()
    var asset: UserAsset
}

class MainViewModel: ObservableObject {
    @Published var updateCounter = 0
    var assets: [AssetItem] = []
    var info = UserAssetsInfo()
    
    func update() {
        BitbankModel.shared.fetch(completion: { info in
            self.info = info
            self.assets.removeAll()
            for asset in info.assets {
                let item = AssetItem(asset: asset)
                self.assets.append(item)
            }
            DispatchQueue.main.async {
                self.updateCounter += 1
            }
        })
    }
}

struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack {
                Text(viewModel.info.updateDate, style: .time)
                    .font(.headline)

                Text(viewModel.info.getTotalLastAmount().toCurrency)
                    .font(.largeTitle)

                HStack {
                    Text("total:")
                        .font(.body)
                    Text(viewModel.info.getTotalDelta().toCommaWithSign + " (" +
                         viewModel.info.getTotalRate().toPercent + ")")
                        .font(.title)
                }

                HStack {
                    Text("24h:")
                        .font(.body)
                    Text(viewModel.info.getTotalLastAmountDelta().toCommaWithSign + " (" +
                         viewModel.info.getTotalLastAmountRate().toPercent + ")")
                        .font(.title)
                }
            }
            //.background(Color.gray)
            
            Spacer()

            if viewModel.updateCounter > 0 {
                Spacer()
                AssetListView(assets: viewModel.assets)
            } else {
                Text("Loading...")
            }

            Button(action: {
                viewModel.update()
            }, label: { Text("更新") })
        }
        .onAppear {
            viewModel.update()
        }
    }
}

struct AssetListView: View {
    var assets: [AssetItem]
    
    var body: some View {
        List {
            if assets.count > 0 {
                ForEach(assets) { asset in
                    AssetItemView(item: asset)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct AssetItemView: View {
    var item: AssetItem
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Text(item.asset.asset.asset)
                    .frame(maxWidth: geo.size.width * 0.2, alignment: .leading)
                Text(item.asset.getLastAmount().toCurrency)
                    .frame(maxWidth: geo.size.width * 0.35, alignment: .trailing)
                Text(item.asset.getLastDelta().toCommaWithSign)
                    .frame(maxWidth: geo.size.width * 0.25, alignment: .trailing)
                Text(item.asset.getLastRate().toPercent)
                    .frame(maxWidth: geo.size.width * 0.2, alignment: .trailing)
            }
            //.frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


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
