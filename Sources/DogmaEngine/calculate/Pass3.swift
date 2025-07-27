//
//  Pass3.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

// Penalty factor: 1 / exp((1 / 2.67) ** 2)
let PENALTY_FACTOR: Double = 0.8691199808003974

// Operators that incur stacking penalty
nonisolated(unsafe) let OPERATOR_HAS_PENALTY: [EffectOperator] = [
    .preMul,
    .postMul,
    .postPercent,
    .preDiv,
    .postDiv
]

// Cache for intermediate calculated values
struct Cache {
    var hull: [Int: Double] = [:]
    var char: [Int: Double] = [:]
    var structure: [Int: Double] = [:]
    var target: [Int: Double] = [:]
    var items: [Int: [Int: Double]] = [:]
    var charge: [Int: [Int: Double]] = [:]
    var skills: [Int: [Int: Double]] = [:]
}

extension Attribute {
    func calculateValue(info: Info,
                        ship: Ship,
                        cache: inout Cache,
                        item: ObjectType,
                        attributeID: Int) -> Double {
        // Return cached override if present
        if let v = value {
            return v
        }

        // Check cache
        let cached: Double?
        switch item {
        case .ship:
            cached = cache.hull[attributeID]
        case .char:
            cached = cache.char[attributeID]
        case .structure:
            cached = cache.structure[attributeID]
        case .target:
            cached = cache.target[attributeID]
        case .item(let idx):
            cached = cache.items[idx]?[attributeID]
        case .charge(let idx):
            cached = cache.charge[idx]?[attributeID]
        case .skill(let idx):
            cached = cache.skills[idx]?[attributeID]
        }
        if let c = cached {
            return c
        }

        // Base value
        var currentValue = baseValue

        // Iterate each operator
        for opCase in EffectOperator.allCases {
            var unpenalized: [Double] = []
            var positivePenalty: [Double] = []
            var negativePenalty: [Double] = []

            // Collect values for this operator
            for effect in effects {
                if effect.operator != opCase {
                    continue
                }
                // Determine source item
                let sourceItem: Item
                switch effect.source {
                case .ship:
                    sourceItem = ship.hull
                case .item(let idx):
                    sourceItem = ship.items[idx]
                case .charge(let idx):
                    guard let ch = ship.items[idx].charge else { continue }
                    sourceItem = ch
                case .skill(let idx):
                    sourceItem = ship.skills[idx]
                case .char:
                    sourceItem = ship.char
                case .structure:
                    sourceItem = ship.structure
                case .target:
                    sourceItem = ship.target
                }

                // Skip if source not active
                if effect.sourceCategory > sourceItem.state {
                    continue
                }

                // Compute raw source value
                let rawValue: Double
                if let attr = sourceItem.attributes[effect.sourceAttributeId] {
                    rawValue = attr.calculateValue(
                        info: info,
                        ship: ship,
                        cache: &cache,
                        item: effect.source,
                        attributeID: effect.sourceAttributeId
                    )
                } else {
                    let da = info.getDogmaAttribute(effect.sourceAttributeId)
                    rawValue = da.defaultValue
                }

                // Simplify according to operator
                let simplified: Double
                switch opCase {
                case .preAssign, .modAdd, .postAssign:
                    simplified = rawValue
                case .preMul, .postMul:
                    simplified = rawValue - 1.0
                case .preDiv, .postDiv:
                    simplified = 1.0 / rawValue - 1.0
                case .postPercent:
                    simplified = rawValue / 100.0
                case .modSub:
                    simplified = -rawValue
                }

                // Assign to buckets
                if effect.penalty && OPERATOR_HAS_PENALTY.contains(opCase) {
                    if simplified < 0 {
                        negativePenalty.append(simplified)
                    } else {
                        positivePenalty.append(simplified)
                    }
                } else {
                    unpenalized.append(simplified)
                }
            }

            // Skip if no values
            if unpenalized.isEmpty && positivePenalty.isEmpty && negativePenalty.isEmpty {
                continue
            }

            // Apply operator
            switch opCase {
            case .preAssign, .postAssign:
                let da = info.getDogmaAttribute(attributeID)
                if da.highIsGood {
                    currentValue = unpenalized.max(by: { abs($0) < abs($1) })!
                } else {
                    currentValue = unpenalized.min(by: { abs($0) < abs($1) })!
                }

            case .preMul, .preDiv, .postMul, .postDiv, .postPercent:
                // non-stacking
                for v in unpenalized {
                    currentValue *= 1.0 + v
                }
                // stacking penalties
                positivePenalty.sort(by: { abs($0) > abs($1) })
                negativePenalty.sort(by: { abs($0) > abs($1) })
                for (i, v) in positivePenalty.enumerated() {
                    currentValue *= 1.0 + v * pow(PENALTY_FACTOR, Double(i * i))
                }
                for (i, v) in negativePenalty.enumerated() {
                    currentValue *= 1.0 + v * pow(PENALTY_FACTOR, Double(i * i))
                }

            case .modAdd, .modSub:
                for v in unpenalized {
                    currentValue += v
                }
            }
        }

        // Store in cache
        switch item {
        case .ship:
            cache.hull[attributeID] = currentValue
        case .char:
            cache.char[attributeID] = currentValue
        case .structure:
            cache.structure[attributeID] = currentValue
        case .target:
            cache.target[attributeID] = currentValue
        case .item(let idx):
            if cache.items[idx] == nil {
                cache.items[idx] = [:]
            }
            cache.items[idx]![attributeID] = currentValue
        case .charge(let idx):
            if cache.charge[idx] == nil {
                cache.charge[idx] = [:]
            }
            cache.charge[idx]![attributeID] = currentValue
        case .skill(let idx):
            if cache.skills[idx] == nil {
                cache.skills[idx] = [:]
            }
            cache.skills[idx]![attributeID] = currentValue
        }

        return currentValue
    }
}

extension Item {
    func calculateValues(info: Info, ship: Ship, cache: inout Cache, item: ObjectType) {
        for attributeID in attributes.keys {
            _ = attributes[attributeID]?.calculateValue(
                info: info,
                ship: ship,
                cache: &cache,
                item: item,
                attributeID: attributeID
            )
        }
    }

    func storeCachedValues(info: Info, cache: [Int: Double]) {
        for (attributeID, value) in cache {
            if var attr = attributes[attributeID] {
                attr.value = value
                attributes[attributeID] = attr
            } else {
                let da = info.getDogmaAttribute(attributeID)
                var attr = Attribute(da.defaultValue)
                attr.value = value
                attributes[attributeID] = attr
            }
        }
    }
}

// Third pass: final calculation pass
struct PassThree: Pass {
    static func pass(info: any Info, ship: inout Ship) {
        var cache = Cache()
        
        ship.hull.calculateValues(info: info, ship: ship, cache: &cache, item: .ship)
        ship.char.calculateValues(info: info, ship: ship, cache: &cache, item: .char)
        ship.structure.calculateValues(info: info, ship: ship, cache: &cache, item: .structure)
        ship.target.calculateValues(info: info, ship: ship, cache: &cache, item: .target)
        
        for (index, item) in ship.items.enumerated() {
            item.calculateValues(info: info, ship: ship, cache: &cache, item: .item(index))
            if let chargeItem = item.charge {
                chargeItem.calculateValues(info: info, ship: ship, cache: &cache, item: .charge(index))
            }
        }
        
        for (index, skill) in ship.skills.enumerated() {
            skill.calculateValues(info: info, ship: ship, cache: &cache, item: .skill(index))
        }
        
        ship.hull.storeCachedValues(info: info, cache: cache.hull)
        ship.char.storeCachedValues(info: info, cache: cache.char)
        ship.structure.storeCachedValues(info: info, cache: cache.structure)
        ship.target.storeCachedValues(info: info, cache: cache.target)
        
        for (index, item) in ship.items.enumerated() {
            item.storeCachedValues(info: info, cache: cache.items[index] ?? [:])
            if let chargeItem = item.charge {
                chargeItem.storeCachedValues(info: info, cache: cache.charge[index] ?? [:])
            }
        }
        
        for (index, skill) in ship.skills.enumerated() {
            skill.storeCachedValues(info: info, cache: cache.skills[index] ?? [:])
        }
    }
}
