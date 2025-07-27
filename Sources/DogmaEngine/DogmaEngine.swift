// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public struct OutputCapacitor: Codable {
    var stable: Bool
    var depletesIn: Double
    var capacity: Double
    var recharge: Double
    var peak: Double
    var percentage: Double
}

public struct OutputOffense: Codable {
    var dps: Double
    var dpsWithReload: Double
    var alpha: Double
    var droneDps: Double
}

public struct OutputDefenseRecharge: Codable {
    var passive: Double
    var shield: Double
    var armor: Double
    var hull: Double
}

public struct OutputDefenseResist: Codable {
    var em: Double
    var therm: Double
    var kin: Double
    var expl: Double
}

public struct OutputDefenseShield: Codable {
    var resist: OutputDefenseResist
    var hp: Double
    var recharge: Double
}

public struct OutputDefenseArmor: Codable {
    var resist: OutputDefenseResist
    var hp: Double
}

public struct OutputDefenseStructure: Codable {
    var resist: OutputDefenseResist
    var hp: Double
}

public struct OutputDefense: Codable {
    var recharge: OutputDefenseRecharge
    var shield: OutputDefenseShield
    var armor: OutputDefenseArmor
    var structure: OutputDefenseStructure
    var ehp: Double
}

public struct OutputTargeting: Codable {
    var lockRange: Double
    var sensorStrength: Double
    var scanResolution: Double
    var signatureRadius: Double
    var maxLockedTargets: Double
}

public struct OutputNavigation: Codable {
    var speed: Double
    var mass: Double
    var agility: Double
    var warpSpeed: Double
    var alignTime: Double
}

public struct OutputDrones: Codable {
    var dps: Double
    var bandwidthLoad: Double
    var bandwidth: Double
    var range: Double
    var active: Double
    var capacityLoad: Double
    var capacity: Double
}

public struct OutputCpu: Codable {
    var free: Double
    var capacity: Double
}

public struct OutputPower: Codable {
    var free: Double
    var capacity: Double
}

public struct OutputSlots: Codable {
    var hi1: String
    var hi2: String
    var hi3: String
    var hi4: String
    var hi5: String
    var hi6: String
    var hi7: String
    var hi8: String
    var med1: String
    var med2: String
    var med3: String
    var med4: String
    var med5: String
    var med6: String
    var med7: String
    var med8: String
    var lo1: String
    var lo2: String
    var lo3: String
    var lo4: String
    var lo5: String
    var lo6: String
    var lo7: String
    var lo8: String
}

public struct Output: Codable {
    var capacitor: OutputCapacitor
    var offense: OutputOffense
    var defense: OutputDefense
    var targeting: OutputTargeting
    var navigation: OutputNavigation
    var drones: OutputDrones
    var cpu: OutputCpu
    var power: OutputPower
    var slots: OutputSlots
}

// Helper to get an attribute value (uses .value if set, otherwise defaultValue)
func getAttributeByName(info: Info, attributes: [Int: Attribute], name: String) -> Double {
    let attributeId = info.attributeNameToId(name)
    let defaultAttribute = info.getDogmaAttribute(attributeId)
    if let attribute = attributes[attributeId], let v = attribute.value {
        return v
    } else {
        return defaultAttribute.defaultValue
    }
}

// Helper to get effect category name for a slot
func effectCategoryToName(items: [Item], slotType: SlotType, index: Int) -> String {
    if let item = items.first(where: { $0.slot.type == slotType && $0.slot.index == index }) {
        switch item.state {
        case .passive:  return "passive"
        case .online:   return "online"
        case .active:   return "active"
        case .overload: return "overload"
        default:        return "unknown"
        }
    } else {
        return "empty"
    }
}
