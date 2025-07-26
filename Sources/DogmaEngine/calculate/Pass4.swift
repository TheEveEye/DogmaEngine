
//
//  Pass4.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

extension Item {
    func addAttribute(attributeId: Int, baseValue: Double, value: Double) {
        var attribute = Attribute(baseValue)
        attribute.value = value
        attributes[attributeId] = attribute
    }
}

struct PassFour: Pass {
    static func pass(info: Info, ship: inout Ship) {
        attributeCapacitorDepletesIn(info: info, ship: &ship)
    }
}

