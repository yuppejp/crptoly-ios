//
//  AssetView.swift
//  Crptoly
//  
//  Created on 2022/08/22
//  
//

import SwiftUI

struct AssetView: View {
    var assetName: String
    var asset: Asset
    private var coins: [IdentifiableCoin] = []
    
    init(assetName: String, asset: Asset) {
        self.assetName = assetName
        self.asset = asset
        for coin in asset.coins {
            coins.append(IdentifiableCoin(coin: coin))
        }
        coins.sort(by: { (coin1:IdentifiableCoin , coin2: IdentifiableCoin) -> Bool in
            if coin1.coin.lastAmount >= coin2.coin.lastAmount {
                return true
            } else {
                return false
            }
        })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            List() {
                Section(header: Text(assetName)) {
                    ForEach(coins) { coin in
                        if coin.coin.lastAmount != 0 {
                            CoinView(coin: coin.coin)
                        }
                    }
                }
            }
        }
    }
    
    private struct CoinView: View {
        let coin: Coin
        private var name: String = ""
        private var balance: Double = 0.0
        private var amount: Double = 0.0
        
        init(coin: Coin) {
            self.coin = coin
            
            if coin.coinName != nil {
                name = coin.coinName
                balance = coin.coinSize
            } else if coin.ticker != nil {
                name = coin.ticker.symbol
                balance = coin.tickerSize
            }

            amount = coin.lastAmount
        }
        
        var body: some View {
            ListItemView(name: name,
                         value1: "\(balance.toDecimalP8String) 枚",
                         value2: "\(amount.toIntegerString) 円")
        }

        private struct ListItemView: View {
            var name: String
            var value1: String
            var value2: String

            var body: some View {
                HStack(spacing: 0) {
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 0) {
                        Text(value1)
                            .font(.caption)
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text(value2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }
    
    private struct IdentifiableCoin: Identifiable {
        var id = UUID()
        var coin: Coin
    }
}

struct AssetView_Previews: PreviewProvider {
    static var previews: some View {
        let coin1 = Coin(coinName: "COIN1", coinSize: 100)
        let coin2 = Coin(coinName: "COIN2", coinSize: 200)
        let coins: [Coin] = [coin1, coin2]
        AssetView(assetName: "spot", asset: Asset(coins: coins))
    }
}
