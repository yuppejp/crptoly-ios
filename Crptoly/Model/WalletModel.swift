//
//  WalletModel.swift
//  Crptoly
//  
//  Created on 2022/08/18
//  
//

import Foundation

class Amount {
    // 投資額(口座入金額)
    var investment = 0.0

    // 評価額
    var last = 0.0

    // 24時間前評価額
    var open = 0.0

    // 損益
    var equity: Double {
        return last - investment
    }

    // 損益率
    var equityRatio: Double {
        if investment == 0.0 {
            return 0.0
        } else {
            return equity / investment
        }
    }

    // 24時間比の増減額
    var lastDelta: Double {
        let delta = last - open
        return delta
    }
    
    // 24時間比の増減率
    var lastRatio: Double {
        if open == 0.0 {
            return 0.0
        } else {
            return lastDelta / open
        }
    }
}

class WalletAmount: Amount {
    var bitbank =  Amount()
    var bybit =  BybitAmount()

    override init() {
        super.init()
    }
    
    init(bitbank: Amount, bybit: BybitAmount) {
        super.init()
        
        self.bitbank = bitbank
        self.bybit = bybit
        self.last = bitbank.last + bybit.last
        self.open = bitbank.open + bybit.open
        
        // TODO: 設定画面をつくる
        // 投資額を補正
        self.investment = 1869925.0 // bitbank入金額
        self.bitbank.investment = self.investment - self.bybit.last
        self.bybit.investment = self.bybit.last
    }
}

struct WalletModel {
    func fetch(completion: @escaping (WalletAmount) -> ()) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        var result1: Amount!
        var result2: BybitAmount!

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[WalletBalanceModel#fetch] 1: enter")
            BitbankModel().fetch(completion: { result in
                result1 = result
                dispatchGroup.leave()
                print("[WalletBalanceModel#fetch] 1: leave")
            })
        }

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[WalletBalanceModel#fetch] 2: enter")
            BybitModel().fetch(completion: { result in
                result2 = result
                dispatchGroup.leave()
                print("[WalletBalanceModel#fetch]: leave")
            })
        }
        
        dispatchGroup.notify(queue: .main) {
            print("[WalletBalanceModel#fetch] completion")
            let wallet = WalletAmount(bitbank: result1, bybit: result2)
            completion(wallet)
        }
    }
}
