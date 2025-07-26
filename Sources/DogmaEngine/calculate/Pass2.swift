//
//  Pass2.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

enum Modifier {
    case LocationRequiredSkillModifier(Int)
    case LocationGroupModifier(Int)
    case LocationModifier(Void)
    case OwnerRequiredSkillModifier(Int)
    case ItemModifier(Void)
}

struct Pass2Effect {
    var modifier: Modifier
    var `operator`: EffectOperator
    var source: ObjectType
    var sourceCatergory: EffectCategory
    var sourceAttributeID: Int
    var target: ObjectType
    var targetAttributeID: Int
}

let ATTRIBUTE_SKILLS: [Int] = [182, 183, 184, 1285, 1289, 1290]

func getModifierFunc(_ func: DogmaEffectModifierInfoFunc, skillTypeID: Int?, groupID: Int?) -> Modifier? {
    switch `func` {
    case .locationRequiredSkillModifier:
        guard let id = skillTypeID else { return nil }
        return .LocationRequiredSkillModifier(id)
    case .locationGroupModifier:
        guard let id = groupID else { return nil }
        return .LocationGroupModifier(id)
    case .locationModifier:
        return .LocationModifier(())
    case .itemModifier:
        return .ItemModifier(())
    case .ownerRequiredSkillModifier:
        guard let id = skillTypeID else { return nil }
        return .OwnerRequiredSkillModifier(id)
    case .effectStopper:
        return nil
    }
}

func getTargetObject(domain: DogmaEffectModifierInfoDomain, origin: ObjectType) -> ObjectType {
    switch domain {
    case .shipID:
        return .ship
    case .charID:
        return .char
    case .otherID:
        switch origin {
        case .item(let index):
            return .charge(index)
        case .charge(let index):
            return .item(index)
        default:
            fatalError("Invalid origin for OtherID domain")
        }
    case .structureID:
        return .structure
    case .itemID:
        return origin
    case .targetID, .target:
        return .target
    }
}

func getEffectCategory(_ category: Int) -> EffectCategory {
    switch category {
    case 0:
        return .passive
    case 1:
        return .active
    case 2:
        return .target
    case 3:
        return .area
    case 4:
        return .online
    case 5:
        return .overload
    case 6:
        return .dungeon
    case 7:
        return .system
    default:
        fatalError("Unknown effect category: \(category)")
    }
}

func getEffectOperator(_ operation: Int) -> EffectOperator? {
    switch operation {
    case -1:
        return .preAssign
    case 0:
        return .preMul
    case 1:
        return .preDiv
    case 2:
        return .modAdd
    case 3:
        return .modSub
    case 4:
        return .postMul
    case 5:
        return .postDiv
    case 6:
        return .postPercent
    case 7:
        return .postAssign
    case 9:
        return nil
    default:
        fatalError("Unknown effect operation: \(operation)")
    }
}

// Exempt categories for stacking penalty (Ship, Charge, Skill, Implant, Subsystem)
let EXEMPT_PENALTY_CATEGORY_IDS: [Int] = [6, 8, 16, 20, 32]

extension Item {
    func addEffect(info: Info, attributeID: Int, sourceCategoryID: Int, effect: Pass2Effect) {
        let attr = info.getDogmaAttribute(attributeID)
        let id = attributeID
        if attributes[id] == nil {
            setAttribute(attributeId: id, value: attr.defaultValue)
        }
        let penalty = !attr.stackable && !EXEMPT_PENALTY_CATEGORY_IDS.contains(sourceCategoryID)
        attributes[id]?.effects.append(Effect(
            operator: effect.operator,
            penalty: penalty,
            source: effect.source,
            sourceCategory: effect.sourceCatergory,
            sourceAttributeId: effect.sourceAttributeID
        ))
    }

    func collectEffects(info: Info, origin: ObjectType, effects: inout [Pass2Effect]) {
        for typeEntry in info.getDogmaEffects(typeId) {
            let dogma = info.getDogmaEffect(typeEntry.effectID)
            let category = getEffectCategory(dogma.effectCategory)

            // Update maxState
            if category > maxState && category <= .overload {
                maxState = category
            }

            if !dogma.modifierInfo.isEmpty {
                for modifier in dogma.modifierInfo {
                    // Determine modifier
                    let modFunc = getModifierFunc(
                        modifier.func,
                        skillTypeID: modifier.skillTypeID.map { $0 },
                        groupID: modifier.groupID.map { $0 }
                    )
                    guard let mod = modFunc else { continue }

                    // Determine operator
                    guard let opRaw = modifier.operation,
                          let op = getEffectOperator(opRaw) else {
                        continue
                    }

                    // Skip OtherID with no charge
                    if case .item(_) = origin,
                       modifier.domain == .otherID,
                       charge == nil {
                        continue
                    }

                    // Build effect entry
                    guard let srcAttr = modifier.modifyingAttributeID,
                          let tgtAttr = modifier.modifiedAttributeID else {
                        continue
                    }
                    let targetObj = getTargetObject(domain: modifier.domain, origin: origin)
                    effects.append(Pass2Effect(
                        modifier: mod,
                        operator: op,
                        source: origin,
                        sourceCatergory: category,
                        sourceAttributeID: srcAttr,
                        target: targetObj,
                        targetAttributeID: tgtAttr
                    ))
                }
            } else {
                // Collect effect ID for default effects
                self.effects.append(typeEntry.effectID)
            }
        }

        // Any module with capacitorNeed (ID 6) can be activated
        if attributes.keys.contains(6), maxState < .active {
            maxState = .active
        }

        // Ensure current state does not exceed maxState
        if state > maxState {
            state = maxState
        }
    }
}

public struct PassTwo: Pass {
    static func pass(info: any Info, ship: inout Ship) {
        var effects: [Pass2Effect] = []

        // Collect all the effects in a single list.
        ship.hull.collectEffects(info: info, origin: .ship, effects: &effects)
        ship.char.collectEffects(info: info, origin: .char, effects: &effects)
        for (index, item) in ship.items.enumerated() {
            item.collectEffects(info: info, origin: .item(index), effects: &effects)
            if let chargeItem = ship.items[index].charge {
                chargeItem.collectEffects(info: info, origin: .charge(index), effects: &effects)
            }
        }
        for (index, skill) in ship.skills.enumerated() {
            skill.collectEffects(info: info, origin: .skill(index), effects: &effects)
        }

        // Depending on the modifier, move the effects to the correct attribute.
        for effect in effects {
            let sourceTypeID: Int
            switch effect.source {
            case .ship:
                sourceTypeID = info.fit().shipTypeID
            case .item(let index):
                sourceTypeID = ship.items[index].typeId
            case .charge(let index):
                sourceTypeID = ship.items[index].charge!.typeId
            case .skill(let index):
                sourceTypeID = ship.skills[index].typeId
            case .char:
                sourceTypeID = 1373
            case .structure, .target:
                continue
            }

            let categoryID = info.getType(sourceTypeID).categoryID

            switch effect.modifier {
            case .ItemModifier:
                switch effect.target {
                case .ship:
                    ship.hull.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .char:
                    ship.char.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .structure:
                    ship.structure.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .item(let index):
                    ship.items[index].addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .charge(let index):
                    ship.items[index].charge!.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .skill(let index):
                    ship.skills[index].addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                case .target:
                    ship.target.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                }

            case .LocationModifier:
                ship.hull.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                for i in ship.items.indices {
                    ship.items[i].addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                    if let chargeItem = ship.items[i].charge {
                        chargeItem.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                    }
                }

            case .LocationGroupModifier(let groupID):
                let typeInfo = info.getType(ship.hull.typeId)
                if typeInfo.groupID == groupID {
                    ship.hull.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                }
                for i in ship.items.indices {
                    let itemType = info.getType(ship.items[i].typeId)
                    if itemType.groupID == groupID {
                        ship.items[i].addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                    }
                    if let chargeItem = ship.items[i].charge {
                        let chargeType = info.getType(chargeItem.typeId)
                        if chargeType.groupID == groupID {
                            chargeItem.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                        }
                    }
                }

            case .OwnerRequiredSkillModifier(let skillTypeID), .LocationRequiredSkillModifier(let skillTypeID):
                let finalSkillTypeID = skillTypeID == -1 ? sourceTypeID : skillTypeID
                for attributeSkillID in ATTRIBUTE_SKILLS {
                    if let baseValue = ship.hull.attributes[attributeSkillID]?.baseValue, baseValue == Double(finalSkillTypeID) {
                        ship.hull.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                    }
                    for i in ship.items.indices {
                        if let baseValue = ship.items[i].attributes[attributeSkillID]?.baseValue, baseValue == Double(finalSkillTypeID) {
                            ship.items[i].addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                        }
                        if let chargeItem = ship.items[i].charge, let baseValue = chargeItem.attributes[attributeSkillID]?.baseValue, baseValue == Double(finalSkillTypeID) {
                            chargeItem.addEffect(info: info, attributeID: effect.targetAttributeID, sourceCategoryID: categoryID, effect: effect)
                        }
                    }
                }
            }
        }
    }
}
