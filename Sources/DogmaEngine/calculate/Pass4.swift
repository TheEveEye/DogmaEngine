
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

func attributeCpuLoad(info: Info, ship: inout Ship) {
    let cpuLoadID = 49  // cpuLoad attribute ID
    
    var totalCpuLoad: Double = 0
    
    // Sum CPU usage from all modules
    for item in ship.items {
        if let cpuUsage = item.attributes[50]?.value {  // CPU usage attribute ID
            totalCpuLoad += cpuUsage
        }
    }
    
    // Store the total CPU load
    ship.hull.addAttribute(attributeId: cpuLoadID, baseValue: 0, value: totalCpuLoad)
}

func attributePowerLoad(info: Info, ship: inout Ship) {
    let powerLoadID = 15   // powerLoad attribute ID  
    
    var totalPowerLoad: Double = 0
    
    // Sum Power usage from all modules
    for item in ship.items {
        if let powerUsage = item.attributes[30]?.value {  // Power usage attribute ID
            totalPowerLoad += powerUsage
        }
    }
    
    // Store the total Power load
    ship.hull.addAttribute(attributeId: powerLoadID, baseValue: 0, value: totalPowerLoad)
}

struct PassFour: Pass {
    static func pass(info: Info, ship: inout Ship) {
        attributeCapacitorDepletesIn(info: info, ship: &ship)
//        attributeCpuLoad(info: info, ship: &ship)
//        attributePowerLoad(info: info, ship: &ship)
    }
}

