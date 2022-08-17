//
//  BybitResponse.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation

struct SpotWalletBalanceResponse: Codable {
    let retCode: Int?
    let retMsg, extCode, extInfo: String?
    let result: Result?

    enum CodingKeys: String, CodingKey {
        case retCode = "ret_code"
        case retMsg = "ret_msg"
        case extCode = "ext_code"
        case extInfo = "ext_info"
        case result
    }

    struct Result: Codable {
        let balances: [Balance]

        struct Balance: Codable {
            let coin, coinID, coinName, total: String
            let free, locked: String

            enum CodingKeys: String, CodingKey {
                case coin
                case coinID = "coinId"
                case coinName, total, free, locked
            }
        }
    }
}

struct SpotTickersResponse: Codable {
    let retCode: Int?
    let retMsg, extCode, extInfo: String?
    let result: [Result]?

    enum CodingKeys: String, CodingKey {
        case retCode = "ret_code"
        case retMsg = "ret_msg"
        case extCode = "ext_code"
        case extInfo = "ext_info"
        case result
    }

    struct Result: Codable {
        let time: Int
        let symbol, bestBidPrice, bestAskPrice, volume: String
        let quoteVolume, lastPrice, highPrice, lowPrice: String
        let openPrice: String
    }
}

struct DerivativesWalletBalanceResponse: Codable {
    let retCode: Int?
    let retMsg, extCode, extInfo: String?
    let result: [String: [String: Double]]?

    enum CodingKeys: String, CodingKey {
        case retCode = "ret_code"
        case retMsg = "ret_msg"
        case extCode = "ext_code"
        case extInfo = "ext_info"
        case result
    }
}

struct DerivativesTickersResponse: Codable {
    let retCode: Int?
    let retMsg, extCode, extInfo: String?
    let result: [Result]?

    enum CodingKeys: String, CodingKey {
        case retCode = "ret_code"
        case retMsg = "ret_msg"
        case extCode = "ext_code"
        case extInfo = "ext_info"
        case result
    }

    struct Result: Codable {
        let symbol, bidPrice, askPrice, lastPrice: String
        let lastTickDirection, prevPrice24H, price24HPcnt, highPrice24H: String
        let lowPrice24H, prevPrice1H, price1HPcnt, markPrice: String
//        let indexPrice: String
//        let openInterest: Int
//        let openValue, totalTurnover, turnover24H: String
//        let totalVolume, volume24H: Int
//        let fundingRate, predictedFundingRate, nextFundingTime: String
//        let countdownHour: Int
//        let deliveryFeeRate, predictedDeliveryPrice, deliveryTime: String

        enum CodingKeys: String, CodingKey {
            case symbol
            case bidPrice = "bid_price"
            case askPrice = "ask_price"
            case lastPrice = "last_price"
            case lastTickDirection = "last_tick_direction"
            case prevPrice24H = "prev_price_24h"
            case price24HPcnt = "price_24h_pcnt"
            case highPrice24H = "high_price_24h"
            case lowPrice24H = "low_price_24h"
            case prevPrice1H = "prev_price_1h"
            case price1HPcnt = "price_1h_pcnt"
            case markPrice = "mark_price"
//            case indexPrice = "index_price"
//            case openInterest = "open_interest"
//            case openValue = "open_value"
//            case totalTurnover = "total_turnover"
//            case turnover24H = "turnover_24h"
//            case totalVolume = "total_volume"
//            case volume24H = "volume_24h"
//            case fundingRate = "funding_rate"
//            case predictedFundingRate = "predicted_funding_rate"
//            case nextFundingTime = "next_funding_time"
//            case countdownHour = "countdown_hour"
//            case deliveryFeeRate = "delivery_fee_rate"
//            case predictedDeliveryPrice = "predicted_delivery_price"
//            case deliveryTime = "delivery_time"
        }
    }
}

struct ExchangeRateResponse: Codable {
    let quotes: [Quote]

    struct Quote: Codable {
        let high, quoteOpen, bid, currencyPairCode: String
        let ask, low: String

        enum CodingKeys: String, CodingKey {
            case high
            case quoteOpen = "open"
            case bid, currencyPairCode, ask, low
        }
    }
}
