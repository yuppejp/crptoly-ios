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

struct BybitWalletBalance {
    var USDJPY = 0.0 // 米ドル円レート: 買気配(Bid)
    var spot = Amount() // 現物資産
    var derivatives = Amount() // デリバティブ資産
    var staking = Amount() // ステーキング資産
    var total = Amount() // 合計資産

    struct Amount {
        var lastAmount = 0.0  // 最新の評価額(USD換算)
        var openAmount = 0.0   // 14h前の評価額(USD換算)
    }
}

struct BybitModel {
    
    func fetch(completion: @escaping (BybitWalletBalance) -> ()) {
        self.fetchData(completion: { exchangeRate, spotWallet, spotTickers, derivativesWallet in
            var wallet = BybitWalletBalance()
            
            print("--- USDJPY ----------")
            let rates = exchangeRate.quotes
            for rate in rates {
                if rate.currencyPairCode == "USDJPY" {
                    wallet.USDJPY = Double(rate.bid) ?? 0.0
                    print("USDJPY: \(wallet.USDJPY)")
                    break
                }
            }

            print("--- spot ----------")
            if let balances = spotWallet.result?.balances, let tickers = spotTickers.result {
                for balance in balances {
                    let symbol = balance.coin + "USDT"
                    for ticker in tickers {
                        if symbol == ticker.symbol {
                            if let total = Double(balance.total), let lastPrice = Double(ticker.lastPrice), let openPrice = Double(ticker.openPrice) {
                                let lastAmount = total * lastPrice
                                let openAmount = total * openPrice
                                print("coin: \(balance.coin), total: \(balance.total), lastAmount: \(lastAmount), openAmount: \(openAmount)")
                                wallet.spot.lastAmount += lastAmount
                                wallet.spot.openAmount += openAmount
                            }
                            break
                        }
                    }
                }
            }
            print("spot.lastAmount: \(wallet.spot.lastAmount), spot.openAmount: \(wallet.spot.openAmount)")

            print("--- delivatives ----------")
            if let coins = derivativesWallet.result {
                for coin in coins {
                    for value in coin.value {
                        if value.key == "equity" {
                            let equity: Double = value.value
                            print("\(coin.key): \(equity)")
                            wallet.derivatives.lastAmount += equity
                            // デリバティブはopne値が無いので、とりあえず同じ値を入れておく
                            wallet.derivatives.openAmount = wallet.derivatives.lastAmount
                            break
                        }
                    }
                }
            }
            print("derivatives.lastAmount: \(wallet.derivatives.lastAmount)")


            print("--- staking ----------")
            // APYは無視して評価額ベースで簡易的に算出
            let coins: Dictionary = ["AVAX": 3.420576]
            for coin in coins {
                let symbol = coin.key + "USDT"
                let total = coin.value
                if let tickers = spotTickers.result {
                    for ticker in tickers {
                        if symbol == ticker.symbol {
                            if let lastPrice = Double(ticker.lastPrice), let openPrice = Double(ticker.openPrice) {
                                let lastAmount = total * lastPrice
                                let openAmount = total * openPrice
                                print("coin: \(coin), total: \(total), lastAmount: \(lastAmount), openAmount: \(openAmount)")
                                wallet.staking.lastAmount += lastAmount
                                wallet.staking.openAmount += openAmount
                            }
                            break
                        }
                    }
                }
            }
            print("staking.lastAmount: \(wallet.staking.lastAmount), staking.openAmount: \(wallet.staking.openAmount)")

            print("--- total ----------")
            wallet.total.lastAmount = wallet.spot.lastAmount + wallet.derivatives.lastAmount + wallet.staking.lastAmount
            wallet.total.openAmount = wallet.spot.openAmount + wallet.derivatives.openAmount + wallet.staking.openAmount
            print("total.lastAmount: \(wallet.total.lastAmount), total.openAmount: \(wallet.total.openAmount)")
            
            completion(wallet)
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
