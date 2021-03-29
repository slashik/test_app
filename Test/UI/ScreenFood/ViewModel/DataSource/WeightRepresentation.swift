//
//  WeightRepresentation.swift
//  Test
//
//  Created by Dmitry Yaskel on 26.03.2021.
//

import Foundation

class WeightRepresentation {
    private let raw: Weight?
    
    init(raw: Weight?) {
        self.raw = raw
    }
    
    var value: Weight? {
        return raw
    }
    
    var weight: String {
        guard let raw = raw else {
            return "-"
        }
        let usesMetricSystem = NSLocale.current.usesMetricSystem
        let kgToLbsIfNeeded = usesMetricSystem ? 1 : 2.20462
        return String(format: "%.1f", raw * kgToLbsIfNeeded)
    }
    
    var measureValue: String {
        guard raw != nil else {
            return ""
        }
        let usesMetricSystem = NSLocale.current.usesMetricSystem
        return usesMetricSystem ? "Kg" : "lbs"
    }
}
