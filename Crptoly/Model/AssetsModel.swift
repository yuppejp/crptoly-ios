//
//  AssetsModel.swift
//  Crptoly
//  
//  Created on 2022/08/18
//  
//

import Foundation

struct Ticker {
    var symbol: String // 銘柄名
    var pair : String // ペアとなる通貨: USDT or JPY
    var lastPrice: Double // 最新価格
    var openPrice: Double // 24時間前価格
}

struct Coin {
    var dollarBasis: Bool // ドル建てコイン
    
    var ticker: Ticker! // 保有銘柄
    var tickerSize: Double! // 保有数
    
    var coinName: String! // コイン名
    var coinSize: Double! // コイン保有数
    
    // ティッカーの場合
    init(ticker: Ticker, balance: Double, dollarBasis: Bool = false) {
        self.ticker = ticker
        self.tickerSize = balance
        self.dollarBasis = dollarBasis
    }

    // コインの場合
    init(coinName: String, coinSize: Double, dollarBasis: Bool = false) {
        self.coinName = coinName
        self.coinSize = coinSize
        self.dollarBasis = dollarBasis
    }

    // 評価額
    var lastAmount: Double {
        var amount = 0.0
        if let quantity = tickerSize {
            amount = quantity * ticker.lastPrice
        }
        else if let equity = coinSize {
            amount = equity
        }
        if dollarBasis {
            amount = CurrencyExchange.share.USD2JPY(amount)
        }
        return amount
    }

    // 24時間前の評価額
    var openAmount: Double {
        var amount = 0.0
        if let quantity = tickerSize {
            amount = quantity * ticker.openPrice
        }
        else if let equity = coinSize {
            amount = equity
        }
        if dollarBasis {
            amount = CurrencyExchange.share.USD2JPY(amount)
        }
        return amount
    }
}

struct Asset {
    // 保有コイン
    var coins: [Coin] = []
    
    // 投資額(口座入金額)
    var investmentAmount = 0.0

    // 評価額
    var lastAmount: Double {
        var lastAmount = 0.0
        for coin in coins {
            lastAmount += coin.lastAmount
        }
        return lastAmount
    }

    // 24時間前評価額
    var openAmount: Double {
        var openAmount = 0.0
        for coin in coins {
            openAmount += coin.openAmount
        }
        return openAmount
    }
    
    // 損益
    var equity: Double {
        return lastAmount - investmentAmount
    }

    // 損益率
    var equityRatio: Double {
        if investmentAmount == 0.0 {
            return 0.0
        } else {
            return equity / investmentAmount
        }
    }

    // 24時間比の増減額
    var lastAmountDelta: Double {
        let delta = lastAmount - openAmount
        return delta
    }
    
    // 24時間比の増減率
    var lastAmountRatio: Double {
        if openAmount == 0.0 {
            return 0.0
        } else {
            return lastAmountDelta / openAmount
        }
    }
}

struct AccountAsset {
    var accountName: String // 口座名: "bitbank", "bybit"
    var spot = Asset() // 現物資産
    var derivatives = Asset() // デリバティブ資産
    var staking = Asset() // ステーキング資産

    // 投資額
    var investmentAmount: Double {
        let total = spot.investmentAmount + derivatives.investmentAmount + staking.investmentAmount
        return total
    }

    // 評価額
    var lastAmount: Double {
        let total = spot.lastAmount + derivatives.lastAmount + staking.lastAmount
        return total
    }

    // 24時間前評価額
    var openAmount: Double {
        let total = spot.openAmount + derivatives.openAmount + staking.openAmount
        return total
    }
    
    // 損益
    var equity: Double {
        let total = spot.equity + derivatives.equity + staking.equity
        return total
    }

    // 損益率
    var equityRatio: Double {
        if investmentAmount == 0.0 {
            return 0.0
        } else {
            return equity / investmentAmount
        }
    }

    // 24時間比の増減額
    var lastAmountDelta: Double {
        let delta = lastAmount - openAmount
        return delta
    }
    
    // 24時間比の増減率
    var lastAmountRatio: Double {
        if openAmount == 0.0 {
            return 0.0
        } else {
            return lastAmountDelta / openAmount
        }
    }

}

struct TotalAssets {
    var accounts: [AccountAsset] = [] // 口座資産
    
    // 投資額
    var investmentAmount: Double {
        // TODO: 設定画面をつくる
        // 投資額を補正
        return 1869925.0 // bitbank入金額
    }

    // 評価額
    var lastAmount: Double {
        var total = 0.0
        for account in accounts {
            total += account.lastAmount
        }
        return total
    }

    // 24時間前評価額
    var openAmount: Double {
        var total = 0.0
        for account in accounts {
            total += account.openAmount
        }
        return total
    }
    
    // 損益
    var equity: Double {
        return lastAmount - investmentAmount
    }

    // 損益率
    var equityRatio: Double {
        if investmentAmount == 0.0 {
            return 0.0
        } else {
            return equity / investmentAmount
        }
    }

    // 24時間比の増減額
    var lastAmountDelta: Double {
        let delta = lastAmount - openAmount
        return delta
    }
    
    // 24時間比の増減率
    var lastAmountRatio: Double {
        if openAmount == 0.0 {
            return 0.0
        } else {
            return lastAmountDelta / openAmount
        }
    }
}

struct CurrencyExchange {
    static var share = CurrencyExchange()
    var USDJPY = 0.0
    
    private init() {
    }
    
    func USD2JPY(_ usd: Double) -> Double {
        return usd * USDJPY
    }

    func JPY2USD(_ jpy: Double) -> Double {
        return jpy / USDJPY
    }
}

struct AssetsModel {
    func fetch(completion: @escaping (TotalAssets) -> ()) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        var bitbank = AccountAsset(accountName: "bitbank")
        var bybit = AccountAsset(accountName: "ByBit")

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[WalletBalanceModel#fetch] 1: enter")
            BitbankModel().fetch(completion: { result in
                bitbank = result
                dispatchGroup.leave()
                print("[WalletBalanceModel#fetch] 1: leave")
            })
        }

// TODO: debug
//        dispatchGroup.enter()
//        dispatchQueue.async {
//            print("[WalletBalanceModel#fetch] 2: enter")
//            BybitModel().fetch(completion: { result, rate in
//                bybit = result
//                CurrencyExchange.share.USDJPY = rate
//                dispatchGroup.leave()
//                print("[WalletBalanceModel#fetch]: leave")
//            })
//        }
        
        dispatchGroup.notify(queue: .main) {
            print("[WalletBalanceModel#fetch] completion")
            let accounts = [bitbank, bybit]
            let total = TotalAssets(accounts: accounts)
            completion(total)
        }
    }
}
