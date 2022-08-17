//
//  Double+toString.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation

extension Double {
    var toCurrency: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "ja_JP")
        f.currencyCode = "JPY"
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var toComma: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        
        // カンマ区切り
        f.groupingSeparator = ","
        f.groupingSize = 3
        
        // 小数部なし、四捨五入
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var toCommaWithSign: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        
        // カンマ区切り
        f.groupingSeparator = ","
        f.groupingSize = 3
        
        // 小数部なし、四捨五入
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        
        f.positivePrefix = "+"
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var toPercent: String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.positivePrefix = "+"
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
