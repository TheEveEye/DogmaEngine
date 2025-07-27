//
//  SimpleInfo.swift
//  DogmaEngine
//
//  Created by Oskar on 7/27/25.
//

import Foundation

public class SimpleInfo: Info {
    private let data: Data
    private let esfFit: EsfFit
    private let skillLevels: [Int: Int]
    
    public init(data: Data, fit: EsfFit, skills: [Int: Int] = [:]) {
        self.data = data
        self.esfFit = fit
        self.skillLevels = skills
    }
    
    public func skills() -> [Int: Int] {
        return skillLevels
    }
    
    public func fit() -> EsfFit {
        return esfFit
    }
    
    public func getDogmaAttributes(_ typeId: Int) -> [TypeDogmaAttribute] {
        return data.typeDogma[typeId]?.dogmaAttributes ?? []
    }
    
    public func getDogmaAttribute(_ attributeId: Int) -> DogmaAttribute {
        return data.dogmaAttributes[attributeId] ?? DogmaAttribute(
            attributeID: attributeId,
            categoryID: nil,
            dataType: nil,
            defaultValue: 0.0,
            highIsGood: true,
            iconID: nil,
            published: nil,
            stackable: true,
            unitID: nil
        )
    }
    
    public func getDogmaEffects(_ typeId: Int) -> [TypeDogmaEffect] {
        return data.typeDogma[typeId]?.dogmaEffects ?? []
    }
    
    public func getDogmaEffect(_ effectId: Int) -> DogmaEffect {
        return data.dogmaEffects[effectId] ?? DogmaEffect(
            descriptionID: nil,
            disallowAutoRepeat: nil,
            effectCategory: 0,
            effectID: effectId,
            effectName: nil,
            electronicChance: false,
            isAssistance: false,
            isOffensive: false,
            isWarpSafe: true,
            modifierInfo: [],
            propulsionChance: false,
            published: nil,
            rangeChance: false
        )
    }
    
    public func getType(_ typeId: Int) -> `Type` {
        return data.types[typeId] ?? `Type`(
            groupID: 0,
            categoryID: 0,
            basePrice: nil,
            graphicID: nil,
            iconID: nil,
            portionSize: nil,
            published: nil,
            raceID: nil,
            radius: nil,
            volume: nil
        )
    }
    
    public func attributeNameToId(_ name: String) -> Int {
        // For simplicity, return a default ID
        // In a real implementation, this would map attribute names to IDs
        return 0
    }
}
