//
//  BitbankModel.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation


import CryptoSwift

private let publicEndpoint = "https://public.bitbank.cc"
private let privateEndpoint = "https://api.bitbank.cc"
private let apiKey = ApiKey().getStringValue("BitbankApiKey") // bitbankのポータルサイトで取得したAPIキー
private let apiSecret = ApiKey().getStringValue("BitbankApiSecret") // bitbankのポータルサイトで取得したシークレット


class UserAsset {
    var asset: BitbankAsset
    var ticker: BitbankTicker
    
    init(asset: BitbankAsset, ticker: BitbankTicker) {
        self.asset = asset
        self.ticker = ticker
    }
    
    func getAsseetName() -> String {
        return asset.asset
    }
    
    // 現在の評価額
    func getLastAmount() -> Double {
        var amount = 0.0
        if let last = Double(ticker.last), let onhandAmount = Double(asset.onhandAmount) {
            if asset.asset == "jpy" {
                amount = onhandAmount
            } else {
                amount = last * onhandAmount
            }
            //print("[UserAsset#getLastAmount] last: \(last), onhandAmount: \(onhandAmount), amount: \(amount)")
        }
        return amount
    }

    // 24時間前の評価額
    func getOpenAmount() -> Double {
        var amount = 0.0
        if let open = Double(ticker.datumOpen), let onhandAmount = Double(asset.onhandAmount) {
            if asset.asset == "jpy" {
                amount = onhandAmount
            } else {
                amount = open * onhandAmount
            }
        }
        return amount
    }
    
    // 24時間前比の損益
    func getLastDelta() -> Double {
        let delta = getLastAmount() - getOpenAmount()
        //print("[UserAsset#getLastDelta] delta: \(delta)")
        return delta
    }
    
    // 24時間前比の損益率
    func getLastRate() -> Double {
        var rate = 0.0
        let last = getLastAmount()
        let open = getOpenAmount()
        if open != 0.0 {
            let delta = last - open
            rate = delta / open
        }
        return rate
    }
}

class UserAssetsInfo {
    var assets: [UserAsset] = []
    var updateDate: Date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
                                                                 
    // 現在の合計評価
    func getTotalLastAmount() -> Double {
        var total = 0.0
        for asset in assets {
            total += asset.getLastAmount()
        }
        return total
    }
    
    // 24時間前の合計評価額
    func getTotalOpenAmount() -> Double {
        var total = 0.0
        for asset in assets {
            total += asset.getOpenAmount()
        }
        return total
    }
    
    // 24時間前比の合計損益額
    func getTotalLastAmountDelta() -> Double {
        return getTotalLastAmount() - getTotalOpenAmount()
    }
    
    // 24時間前比の合計損益比
    func getTotalLastAmountRate() -> Double {
        var rate = 0.0
        let last = getTotalLastAmount()
        let open = getTotalOpenAmount()
        let delta = last - open
        if open != 0.0 {
            rate = delta / open
       }
        return rate
    }
    
    // 合計損益
    func getTotalInvestment() -> Double {
        let bybitUSD = 640.63 // ByBit資産(USD換算)
        let USDYEN = 133.289 // 米ドル円 2022/8/3
        let bybitAmout = bybitUSD * USDYEN
        let bitbankInit = 1869925.0 // bitbank投資額
        let investment = bitbankInit - bybitAmout
        return investment
    }

    // 合計損益
    func getTotalDelta() -> Double {
        return getTotalLastAmount() - getTotalInvestment()
    }
    
    // 合計損益率
    func getTotalRate() -> Double {
        var rate = 0.0
        let last = getTotalLastAmount()
        let investment  = getTotalInvestment()
        let delta = last - investment
        if investment != 0.0 {
            rate = delta / investment
       }
        return rate
    }
    
//    // 更新時刻
//    func formatUpdateDate() -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
//
//        formatter.locale = Locale(identifier: "ja_JP")
//        return formatter.string(from: updateDate)
//    }}

}

class BitbankModel/*: NSObject*/ { // todo: NSObject継承必要？
    static let shared = BitbankModel()
    
    private init() {
    }

    func fetch(completion: @escaping (UserAssetsInfo) -> ()) {
        BitbankModel.shared.fetchData(completion: { result1, result2 in
            let bitbankAssets = result1.data.assets
            let bitbankTickers = result2.data
            let info = UserAssetsInfo()
            info.updateDate = Date()

            for asset in bitbankAssets {
                for ticker in bitbankTickers {
                    let pair = asset.asset + "_jpy"
                    if (ticker.pair == pair) {
                        let asset = UserAsset(asset: asset, ticker: ticker)
                        info.assets.append(asset)
                        break
                    }
                }
            }
            completion(info)
        })
    }
    
    private func fetchData(completion: @escaping (BitbankUserAssetsResponse, BitbankTickersResponse) -> ()) {
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        var result1: BitbankUserAssetsResponse!
        var result2: BitbankTickersResponse!

        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] getUserAssets: enter")
            BitbankModel.shared.getUserAssets(completion: { result in
                result1 = result
                dispatchGroup.leave()
                print("[fetchData] getUserAssets: leave")
            })
        }
        
        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] getTickers: enter")
            BitbankModel.shared.getTickers(completion:  { result in
                result2 = result
                dispatchGroup.leave()
                print("[fetchData] getTickers: leave")
            })
        }

        dispatchGroup.notify(queue: .main) {
            print("[fetchData] completion")
            completion(result1, result2)
        }
    }
//    private func fetchData(completion: @escaping (BitbankUserAssetsResponse, BitbankTickersResponse) -> ()) {
//        BitbankModel.shared.getUserAssets(completion: { result1 in
//            BitbankModel.shared.getTickers(completion:  { result2 in
//                completion(result1, result2)
//            })
//        })
//    }
    
    private func getUserAssets(completion: @escaping (BitbankUserAssetsResponse) -> ()) {
        let path = "/v1/user/assets"
        let queryParam = ""
        
        let urlString = privateEndpoint + path + queryParam
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        let date: Date = Date()
        let nonce = String(Int(date.timeIntervalSince1970 * 10000))
        
        let signature = makeSignature(secret: apiSecret, nonce: nonce, path: path, queryParam: queryParam)
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["ACCESS-KEY": apiKey]
        request.allHTTPHeaderFields = ["ACCESS-NONCE": nonce]
        request.allHTTPHeaderFields = ["ACCESS-SIGNATURE": signature]
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
            if err != nil {
                print(err!.localizedDescription)
                return
            }
            do {
                // debug print
                //let object = try JSONSerialization.jsonObject(with: data!, options: [])
                //print(object)

                let result = try JSONDecoder().decode(BitbankUserAssetsResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }

    private func getTickers(completion: @escaping (BitbankTickersResponse) -> ()) {
        let path = "/tickers"
        
        let urlString = publicEndpoint + path
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
            if err != nil {
                print(err!.localizedDescription)
                return
            }
            do {
                // debug print
                //let object = try JSONSerialization.jsonObject(with: data!, options: [])
                //print(object)

                let result = try JSONDecoder().decode(BitbankTickersResponse.self, from: data!)
                completion(result)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }

//    private func getTicker(pair: String) {
//        let path = "/\(pair)/ticker"
//
//        let urlString = publicEndpoint + path
//        let url = URL(string: urlString)!
//        var request = URLRequest(url: url)
//
//        request.httpMethod = "GET"
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data else { return }
//            do {
//                let object = try JSONSerialization.jsonObject(with: data, options: [])
//                print(object)
//            } catch let error {
//                print(error)
//            }
//        }
//        task.resume()
//    }
//
//    func getPrivateTradeHistory() {
//        let path = "/v1/user/spot/trade_history"
//        let queryParam = "?pair=btc_jpy"
//
//        let urlString = privateEndpoint + path + queryParam
//        let url = URL(string: urlString)!
//        var request = URLRequest(url: url)
//
//        let date: Date = Date()
//        let nonce = String(Int(date.timeIntervalSince1970 * 10000))
//
//        let signature = makeSignature(secret: apiSecret, nonce: nonce, path: path, queryParam: queryParam)
//
//        request.httpMethod = "GET"
//        request.allHTTPHeaderFields = ["ACCESS-KEY": apiKey]
//        request.allHTTPHeaderFields = ["ACCESS-NONCE": nonce]
//        request.allHTTPHeaderFields = ["ACCESS-SIGNATURE": signature]
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data else { return }
//            do {
//                let object = try JSONSerialization.jsonObject(with: data, options: [])
//                print(object)
//            } catch let error {
//                print(error)
//            }
//        }
//        task.resume()
//    }
    
    private func makeSignature(secret: String, nonce: String, path: String, queryParam: String = "") -> String {
        let str = nonce + path + queryParam
        print(str)
        let bytes = str.bytes
        var signature = ""
        do {
            let hmac = try HMAC(key: secret, variant: .sha2(.sha256)).authenticate(bytes)
            signature = hmac.toHexString()
        }
        catch {
            print(error.localizedDescription)
        }
        return signature
    }
}

//extension StringProtocol {
//    var bytes: [UInt8] { .init(utf8) }
//}


