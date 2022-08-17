//
//  BitbankResponse.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation

// MARK: BitbankTickersResponse
struct BitbankTickersResponse: Codable {
    let success: Int
    let data: [BitbankTicker]
}

struct BitbankTicker: Codable {
    let pair, sell, buy, high: String
    let low, datumOpen, last, vol: String
    let timestamp: Int

    enum CodingKeys: String, CodingKey {
        case pair, sell, buy, high, low
        case datumOpen = "open"
        case last, vol, timestamp
    }
}

// MARK: BitbankUserAssetsResponse
struct BitbankUserAssetsResponse: Codable {
    let success: Int
    let data: BitbankUserAssetsResponseData
}

struct BitbankUserAssetsResponseData: Codable {
    let assets: [BitbankAsset]
}

struct BitbankAsset: Codable {
    let asset, freeAmount: String
    let amountPrecision: Int
    let onhandAmount, lockedAmount: String
    let withdrawalFee: WithdrawalFeeUnion
    let stopDeposit, stopWithdrawal: Bool

    enum CodingKeys: String, CodingKey {
        case asset
        case freeAmount = "free_amount"
        case amountPrecision = "amount_precision"
        case onhandAmount = "onhand_amount"
        case lockedAmount = "locked_amount"
        case withdrawalFee = "withdrawal_fee"
        case stopDeposit = "stop_deposit"
        case stopWithdrawal = "stop_withdrawal"
    }
}

enum WithdrawalFeeUnion: Codable {
    case string(String)
    case withdrawalFeeClass(WithdrawalFeeClass)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(WithdrawalFeeClass.self) {
            self = .withdrawalFeeClass(x)
            return
        }
        throw DecodingError.typeMismatch(WithdrawalFeeUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for WithdrawalFeeUnion"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .withdrawalFeeClass(let x):
            try container.encode(x)
        }
    }
}

struct WithdrawalFeeClass: Codable {
    let under, over, threshold: String
}
