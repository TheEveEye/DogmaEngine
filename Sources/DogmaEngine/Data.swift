//
//  Data.swift
//  dogma-engine
//
//  Created by Oskar on 7/26/25.
//

import Foundation

struct Data {
    let types: [Int: `Type`]
    let typeDogma: [Int: TypeDogmaEffect]
    let dogmaAttributes: [Int: DogmaAttribute]
    let dogmaEffects: [Int: DogmaEffect]
}

extension Data {
    /// Load all DogmaEngine data from a directory containing JSON files
    static func new(from directory: URL) throws -> Data {
        let decoder = JSONDecoder()
        
        // Load types
        let typesURL = directory.appendingPathComponent("types.json")
        let typesData = try Foundation.Data(contentsOf: typesURL)
        let rawTypes = try decoder.decode([String: Type].self, from: typesData)
        let types = rawTypes.reduce(into: [Int: Type]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load typeDogma
        let typeDogmaURL = directory.appendingPathComponent("typeDogma.json")
        let typeDogmaData = try Foundation.Data(contentsOf: typeDogmaURL)
        let rawTypeDogma = try decoder.decode([String: TypeDogmaEffect].self, from: typeDogmaData)
        let typeDogma = rawTypeDogma.reduce(into: [Int: TypeDogmaEffect]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load dogmaAttributes
        let dogmaAttributesURL = directory.appendingPathComponent("dogmaAttributes.json")
        let dogmaAttributesData = try Foundation.Data(contentsOf: dogmaAttributesURL)
        let rawDogmaAttributes = try decoder.decode([String: DogmaAttribute].self, from: dogmaAttributesData)
        let dogmaAttributes = rawDogmaAttributes.reduce(into: [Int: DogmaAttribute]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load dogmaEffects
        let dogmaEffectsURL = directory.appendingPathComponent("dogmaEffects.json")
        let dogmaEffectsData = try Foundation.Data(contentsOf: dogmaEffectsURL)
        let rawDogmaEffects = try decoder.decode([String: DogmaEffect].self, from: dogmaEffectsData)
        let dogmaEffects = rawDogmaEffects.reduce(into: [Int: DogmaEffect]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        return Data(types: types,
                    typeDogma: typeDogma,
                    dogmaAttributes: dogmaAttributes,
                    dogmaEffects: dogmaEffects)
    }
}
