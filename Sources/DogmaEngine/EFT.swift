//
//  EFT.swift
//  dogma-engine
//
//  Created by Oskar on 7/26/25.
//

import Foundation

struct EftCargo {
    var typeId: Int
    var quantity: Int
}

struct EftFit {
    var name: String
    var esfFit: EsfFit
    var cargo: [EftCargo]
}

func sectionIter(_ lines: [String]) -> [[String]] {
    var sections: [[String]] = []
    var current: [String] = []
    for line in lines.dropFirst() {
        if line.isEmpty {
            if !current.isEmpty {
                sections.append(current)
                current.removeAll()
            }
        } else {
            current.append(line)
        }
    }
    if !current.isEmpty {
        sections.append(current)
    }
    return sections
}

func findSlotTypeIndex(info: InfoName, typeId: Int, moduleSlots: inout [EsfSlotType: Int]) -> (EsfSlotType, Int)? {
    let effects = info.getDogmaEffects(typeId)
    for effect in effects {
        switch effect.effectID {
        case 11:
            moduleSlots[.low, default: 0] += 1
            return (.low, moduleSlots[.low]! - 1)
        case 12:
            moduleSlots[.high, default: 0] += 1
            return (.high, moduleSlots[.high]! - 1)
        case 13:
            moduleSlots[.medium, default: 0] += 1
            return (.medium, moduleSlots[.medium]! - 1)
        case 2663:
            moduleSlots[.rig, default: 0] += 1
            return (.rig, moduleSlots[.rig]! - 1)
        case 3772:
            moduleSlots[.subSystem, default: 0] += 1
            return (.subSystem, moduleSlots[.subSystem]! - 1)
        case 6306:
            moduleSlots[.service, default: 0] += 1
            return (.service, moduleSlots[.service]! - 1)
        default:
            continue
        }
    }
    return nil
}

func loadEft(info: InfoName, eft: String) throws -> EftFit {
    let lines = eft.components(separatedBy: .newlines)
    let headerLine = lines.first ?? ""
    guard headerLine.hasPrefix("[") && headerLine.hasSuffix("]") else {
        throw NSError(domain: "EFT", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid EFT header"])
    }
    let headerContent = headerLine.dropFirst().dropLast()
    let parts = headerContent.split(separator: ",", maxSplits: 1).map(String.init)
    let shipTypeName = parts[0]
    let name = parts.count > 1 ? parts[1] : ""
    var eftFit = EftFit(
        name: name,
        esfFit: EsfFit(shipTypeID: info.typeNameToId(shipTypeName), modules: [], drones: []),
        cargo: []
    )

    for section in sectionIter(lines) {
        let isModuleSection = !section.allSatisfy { line in
            if let xPos = line.lastIndex(of: "x") {
                let qtyPart = line[line.index(after: xPos)...]
                return !qtyPart.isEmpty && qtyPart.allSatisfy { $0.isNumber }
            }
            return false
        }

        if isModuleSection {
            var moduleSlots: [EsfSlotType: Int] = [:]
            for var line in section {
                line = line.trimmingCharacters(in: .whitespaces)
                var offline = false
                if line.hasPrefix("[Empty") {
                    let slotType: EsfSlotType
                    switch line {
                    case "[Empty High slot]": slotType = .high
                    case "[Empty Med slot]": slotType = .medium
                    case "[Empty Low slot]": slotType = .low
                    case "[Empty Rig slot]": slotType = .rig
                    case "[Empty Subsystem slot]": slotType = .subSystem
                    default: fatalError("Invalid slot type")
                    }
                    moduleSlots[slotType, default: 0] += 1
                    continue
                }
                if line.hasSuffix("/offline") {
                    offline = true
                    line = String(line.dropLast("/offline".count)).trimmingCharacters(in: .whitespaces)
                }
                let parts = line.split(separator: ",", maxSplits: 1).map(String.init)
                let moduleName = parts[0].trimmingCharacters(in: .whitespaces)
                let chargeName = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

                let moduleTypeId = info.typeNameToId(moduleName)
                let chargeTypeId = chargeName.map(info.typeNameToId)

                guard let (slotType, index) = findSlotTypeIndex(info: info, typeId: moduleTypeId, moduleSlots: &moduleSlots) else {
                    throw NSError(domain: "EFT", code: 2, userInfo: [NSLocalizedDescriptionKey: "Module \(moduleName) does not fit in any slot"])
                }

                let module = EsfModule(
                    typeID: moduleTypeId,
                    slot: EsfSlot(type: slotType, index: index),
                    state: offline ? .passive : .active,
                    charge: chargeTypeId.map { EsfCharge(typeID: $0) }
                )
                eftFit.esfFit.modules.append(module)
            }
        } else {
            var items: [(Int, Int)] = []
            var areDrones = true
            for line in section {
                guard let xPos = line.lastIndex(of: "x") else { continue }
                let typeName = String(line[..<xPos]).trimmingCharacters(in: .whitespaces)
                let qtyString = String(line[line.index(after: xPos)...])
                let quantity = Int(qtyString) ?? 0
                let typeID = info.typeNameToId(typeName)
                areDrones = areDrones && info.getType(typeID).resolvedCategoryID == 18
                items.append((typeID, quantity))
            }
            if areDrones {
                for (typeID, quantity) in items {
                    for _ in 0..<quantity {
                        let drone = EsfDrone(typeID: typeID, state: .active)
                        eftFit.esfFit.drones.append(drone)
                    }
                }
            } else {
                for (typeID, quantity) in items {
                    eftFit.cargo.append(EftCargo(typeId: typeID, quantity: quantity))
                }
            }
        }
    }

    return eftFit
}
