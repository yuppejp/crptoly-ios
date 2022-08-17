//
//  CrptolyApp.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import SwiftUI

@main
struct CrptolyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
