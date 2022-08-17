//
//  Double+toString.swift
//  Crptoly
//  
//  Created on 2022/08/17
//  
//

import Foundation

// Mark: for bitbank
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

// Mark: for bybit
extension Double {
    var toDecimalString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2 // 1234.5 -> 1,234.50
        f.maximumFractionDigits = 2 // 1234.567 -> 1,234.57
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var toIntegerString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0 // 1234.5 -> 1,235
        f.maximumFractionDigits = 0 // 1234.567 -> 1,235
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var toPercentString: String {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

