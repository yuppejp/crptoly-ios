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

struct BitbankModel {
    func fetch(completion: @escaping (AccountAsset) -> ()) {
        fetchData(completion: { result1, result2 in
            let bitbankAssets = result1.data.assets
            let bitbankTickers = result2.data
            var asset = Asset()
            
            for bitbankAsset in bitbankAssets {
                for ticker in bitbankTickers {
                    let pair = bitbankAsset.asset + "_jpy"
                    if (ticker.pair == pair) {
                        let symbol = bitbankAsset.asset
                        let pair = "JPY"
                        let lastPrice = bitbankAsset.asset == "jpy" ? 1.0 : Double(ticker.last) ?? 0.0
                        let openPrice = bitbankAsset.asset == "jpy" ? 1.0 : Double(ticker.datumOpen) ?? 0.0
                        let ticker = Ticker(symbol: symbol, pair: pair, lastPrice: lastPrice, openPrice: openPrice)
                        
                        let balance = Double(bitbankAsset.onhandAmount) ?? 0.0
                        let coin = Coin(ticker: ticker, balance: balance)
                        asset.coins.append(coin)
                        break
                    }
                }
            }
            
            let account = AccountAsset(accountName: "bitbank", spot: asset)
            completion(account)
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


