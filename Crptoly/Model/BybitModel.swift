//
//  BybitModel.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation
import CryptoSwift

private let endpoint = "https://api.bybit.com"
private let api_key = ApiKey().getStringValue("BybitApiKey")
private let apiSecret = ApiKey().getStringValue("BybitApiSecret")

//class BybitAmount: Amount {
//    var USDJPY = 0.0 // 米ドル円レート: 買気配(Bid)
//    var spot = Amount() // 現物資産
//    var derivatives = Amount() // デリバティブ資産
//    var staking = Amount() // ステーキング資産
//
//    override init() {
//        super.init()
//    }
//
//    init(USDJPY: Double, spot: Amount, derivatives: Amount, staking: Amount) {
//        self.USDJPY = USDJPY
//        self.spot = spot
//        self.derivatives = derivatives
//        self.staking = staking
//
//        super.init()
//        self.last = (spot.last + derivatives.last + staking.last) * USDJPY
//        self.open = (spot.open + derivatives.open + staking.open) * USDJPY
//    }
//
//    var allAmountUSD: Double {
//        return spot.last + derivatives.last + staking.last
//    }
//}

class BybitModel {
    func fetch(completion: @escaping (AccountAsset, Double) -> ()) {
        self.fetchData(completion: { exchangeRate, spotWallet, spotTickers, derivativesWallet in
            var rateUSDJPY = 0.0
            var spot = Asset()
            var derivatives = Asset()
            var staking = Asset()

            print("--- USDJPY ----------")
            let rates = exchangeRate.quotes
            for rate in rates {
                if rate.currencyPairCode == "USDJPY" {
                    rateUSDJPY = Double(rate.bid) ?? 0.0
                    print("USDJPY: \(rateUSDJPY)")
                    break
                }
            }

            print("--- spot ----------")
            if let balances = spotWallet.result?.balances, let tickers = spotTickers.result {
                for balance in balances {
                    let coinName = balance.coin
                    let symbol = coinName + "USDT"
                    for ticker in tickers {
                        if symbol == ticker.symbol {
                            let pair = "USDT" // TODO: ハードコード
                            let lastPrice = Double(ticker.lastPrice) ?? 0.0
                            let openPrice = Double(ticker.openPrice) ?? 0.0
                            let ticker = Ticker(symbol: coinName, pair: pair, lastPrice: lastPrice, openPrice: openPrice)

                            let balance = Double(balance.total) ?? 0.0
                            let coin = Coin(ticker: ticker, balance: balance, dollarBasis: true)
                            spot.coins.append(coin)
                            break
                        }
                    }
                }
            }
            print("spot.lastAmount: \(spot.lastAmount), spot.openAmount: \(spot.openAmount)")

            print("--- delivatives ----------")
            if let coins = derivativesWallet.result {
                for coin in coins {
                    var coinSize = 0.0
                    for value in coin.value {
                        //print("[delivatives] key: \(value.key), value: \(value.value)")
                        if value.key == "equity" {
                            coinSize = value.value
                            break
                        }
                    }
                    let coinName = coin.key
                    derivatives.coins.append(Coin(coinName: coinName, coinSize: coinSize, dollarBasis: true))
                }
            }
            print("derivatives.lastAmount: \(derivatives.lastAmount)")


            print("--- staking ----------")
            // TODO: ハードコード
            // APYは無視して評価額ベースで簡易的に算出
            let coins: Dictionary = ["AVAX": 3.420576]
            for coin in coins {
                let coinName = coin.key
                let symbol = coinName + "USDT"
                let balance = coin.value
                if let tickers = spotTickers.result {
                    for ticker in tickers {
                        if symbol == ticker.symbol {
                            let pair = "USDT" // TODO: ハードコード
                            let lastPrice = Double(ticker.lastPrice) ?? 0.0
                            let openPrice = Double(ticker.openPrice) ?? 0.0
                            let ticker = Ticker(symbol: coinName, pair: pair, lastPrice: lastPrice, openPrice: openPrice)
                            staking.coins.append(Coin(ticker: ticker, balance: balance, dollarBasis: true))
                            break
                        }
                    }
                }
            }
            print("staking.lastAmount: \(staking.lastAmount), staking.openAmount: \(staking.openAmount)")

            print("--- total ----------")
            let account = AccountAsset(accountName: "ByBit", spot: spot, derivatives: derivatives, staking: staking)
            completion(account, rateUSDJPY)
        })
    }

    private func fetchData(completion: @escaping (ExchangeRateResponse, SpotWalletBalanceResponse, SpotTickersResponse, DerivativesWalletBalanceResponse) -> ()) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        var result1: ExchangeRateResponse!
        var result2: SpotWalletBalanceResponse!
        var result3: SpotTickersResponse!
        var result4: DerivativesWalletBalanceResponse!
        //var result5: DerivativesTickersResponse!

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] 1: enter")
            self.fetchExchangeRate(completion: { result in
                result1 = result
                dispatchGroup.leave()
                print("[fetchData] 1: leave")
            })
        }

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] 2: enter")
            self.fetchSpotWalletBalance(completion: { result in
                result2 = result
                dispatchGroup.leave()
                print("[fetchData] 2: leave")
            })
        }
        
        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] 3: enter")
            self.fetchSpotTickers(completion: { result in
                result3 = result
                dispatchGroup.leave()
                print("[fetchData] 3: leave")
            })
        }
        
        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] 4: enter")
            self.fetchDerivativesWalletBalance(completion: { result in
                result4 = result
                dispatchGroup.leave()
                print("[fetchData] 4: leave")
            })
        }
        
//        dispatchGroup.enter()
//        dispatchQueue.async {
//            print("[fetchData] 5: enter")
//            self.fetchDerivativesTickers(completion: { result in
//                result4 = result
//                dispatchGroup.leave()
//                print("[fetchData] 5: leave")
//            })
//        }

        dispatchGroup.notify(queue: .main) {
            print("[fetchData] completion")
            completion(result1, result2, result3, result4)
        }
    }

    private func fetchSpotWalletBalance(completion: @escaping (SpotWalletBalanceResponse) -> ()) {
        let path = "/spot/v1/account"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryParam = "api_key=\(api_key)&timestamp=\(timestamp)"
        let sign = makeSign(secret: apiSecret, queryParam: queryParam)
        let urlString = "\(endpoint)\(path)?\(queryParam)&sign=\(sign)"
        
        getRequest(string: urlString, completion: { (data) in
            do {
                let result = try JSONDecoder().decode(SpotWalletBalanceResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        })
    }

    private func fetchSpotTickers(completion: @escaping (SpotTickersResponse) -> ()) {
        let path = "/spot/quote/v1/ticker/24hr"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryParam = "api_key=\(api_key)&timestamp=\(timestamp)"
        let sign = makeSign(secret: apiSecret, queryParam: queryParam)
        let urlString = "\(endpoint)\(path)?\(queryParam)&sign=\(sign)"
        
        getRequest(string: urlString, completion: { (data) in
            do {
                let result = try JSONDecoder().decode(SpotTickersResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        })
    }

    private func fetchDerivativesWalletBalance(completion: @escaping (DerivativesWalletBalanceResponse) -> ()) {
        let path = "/v2/private/wallet/balance"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryParam = "api_key=\(api_key)&timestamp=\(timestamp)"
        let sign = makeSign(secret: apiSecret, queryParam: queryParam)
        let urlString = "\(endpoint)\(path)?\(queryParam)&sign=\(sign)"
        
        getRequest(string: urlString, completion: { (data) in
            do {
                let result = try JSONDecoder().decode(DerivativesWalletBalanceResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        })
    }

    private func fetchDerivativesTickers(completion: @escaping (DerivativesTickersResponse) -> ()) {
        let path = "/v2/public/tickers"
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryParam = "api_key=\(api_key)&timestamp=\(timestamp)"
        let sign = makeSign(secret: apiSecret, queryParam: queryParam)
        let urlString = "\(endpoint)\(path)?\(queryParam)&sign=\(sign)"
        
        getRequest(string: urlString, completion: { (data) in
            do {
                let result = try JSONDecoder().decode(DerivativesTickersResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        })
    }

    private func fetchExchangeRate(completion: @escaping (ExchangeRateResponse) -> ()) {
        let urlString = "https://www.gaitameonline.com/rateaj/getrate"
        
        getRequest(string: urlString, completion: { (data) in
            do {
                let result = try JSONDecoder().decode(ExchangeRateResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        })
    }

    private func getRequest(string: String, completion: @escaping (Data?) -> ()) {
        let url = URL(string: string)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                completion(nil)
            }

            // debug print
            //do {
            //    let object = try JSONSerialization.jsonObject(with: data!, options: [])
            //    print(object)
            //} catch {
            //    print(error.localizedDescription)
            //}

            completion(data!)
        }
        task.resume()
    }

    private func makeSign(secret: String, queryParam: String) -> String {
        let bytes = queryParam.bytes
        do {
            let hmac = try HMAC(key: secret, variant: .sha2(.sha256)).authenticate(bytes)
            let signature = hmac.toHexString()
            return signature
        }
        catch {
            print(error.localizedDescription)
            return ""
        }
    }
}
