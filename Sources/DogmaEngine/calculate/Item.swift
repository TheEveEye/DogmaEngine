//
//  Item.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

public enum EffectCategory: Int, Codable, Comparable, CaseIterable {
    public static func < (lhs: EffectCategory, rhs: EffectCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case passive = 0
    case active = 1
    case target = 2
    case area = 3
    case online = 4
    case overload = 5
    case dungeon = 6
    case system = 7

    func isActive() -> Bool {
        switch self {
        case .active, .overload:
            return true
        default:
            return false
        }
    }
}

public enum EffectOperator: Int, Codable, Comparable, CaseIterable {
    public static func < (lhs: EffectOperator, rhs: EffectOperator) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case preAssign = -1
    case preMul = 0
    case preDiv = 1
    case modAdd = 2
    case modSub = 3
    case postMul = 4
    case postDiv = 5
    case postPercent = 6
    case postAssign = 7
}

public enum ObjectType: Codable {
    case ship
    case item(Int)
    case charge(Int)
    case skill(Int)
    case char
    case structure
    case target
}

public struct Effect: Codable {
    public var `operator`: EffectOperator
    public var penalty: Bool
    public var source: ObjectType
    public var sourceCategory: EffectCategory
    public var sourceAttributeId: Int
}

public struct Attribute: Codable {
    public var baseValue: Double
    public var value: Double?
    public var effects: [Effect]

    init(_ value: Double) {
        self.baseValue = value
        self.value = nil
        self.effects = []
    }
}

enum SlotType: Codable {
    case high, medium, low, rig, subSystem, service, droneBay, charge, none
}

public struct Slot: Codable {
    var type: SlotType
    var index: Int?

    func isModule() -> Bool {
        switch type {
        case .high, .medium, .low, .rig, .subSystem:
            return true
        default:
            return false
        }
    }
}

public class Item: Codable {
    public var typeId: Int
    public var slot: Slot
    public var charge: Item?
    public var state: EffectCategory
    public var maxState: EffectCategory
    public var attributes: [Int: Attribute]
    public var effects: [Int]

    init(typeId: Int, slot: Slot, charge: Item?, state: EffectCategory, maxState: EffectCategory) {
        self.typeId = typeId
        self.slot = slot
        self.charge = charge
        self.state = state
        self.maxState = maxState
        self.attributes = [:]
        self.effects = []
    }

    static func newCharge(typeId: Int) -> Item {
        let slot = Slot(type: .charge, index: nil)
        return Item(typeId: typeId, slot: slot, charge: nil, state: .active, maxState: .active)
    }

    static func newModule(typeId: Int, slot: Slot, chargeTypeId: Int?, state: EffectCategory) -> Item {
        let charge = chargeTypeId.map { Item.newCharge(typeId: $0) }
        return Item(typeId: typeId, slot: slot, charge: charge, state: state, maxState: .passive)
    }

    static func newDrone(typeId: Int, state: EffectCategory) -> Item {
        let slot = Slot(type: .droneBay, index: nil)
        return Item(typeId: typeId, slot: slot, charge: nil, state: state, maxState: .active)
    }

    static func newFake(typeId: Int) -> Item {
        let slot = Slot(type: .none, index: nil)
        return Item(typeId: typeId, slot: slot, charge: nil, state: .active, maxState: .active)
    }
}

