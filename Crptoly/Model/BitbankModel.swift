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

private struct UserAsset {
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
}

struct BitbankModel {
    func fetch(completion: @escaping (Amount) -> ()) {
        fetchData(completion: { result1, result2 in
            let bitbankAssets = result1.data.assets
            let bitbankTickers = result2.data
            let wallet = Amount()
            
            for asset in bitbankAssets {
                for ticker in bitbankTickers {
                    let pair = asset.asset + "_jpy"
                    if (ticker.pair == pair) {
                        let userAsset = UserAsset(asset: asset, ticker: ticker)
                        wallet.last += userAsset.getLastAmount()
                        wallet.open += userAsset.getOpenAmount()
                        break
                    }
                }
            }
            
            completion(wallet)
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
            self.getUserAssets(completion: { result in
                result1 = result
                dispatchGroup.leave()
                print("[fetchData] getUserAssets: leave")
            })
        }
        
        dispatchGroup.enter()
        dispatchQueue.async {
            print("[fetchData] getTickers: enter")
            self.getTickers(completion:  { result in
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


