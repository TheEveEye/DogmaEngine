//
//  Data.swift
//  dogma-engine
//
//  Created by Oskar on 7/26/25.
//

import Foundation

public struct Data {
    public let types: [Int: `Type`]
    public let groups: [Int: Group]
    public let typeDogma: [Int: TypeDogma]
    public let dogmaAttributes: [Int: DogmaAttribute]
    public let dogmaEffects: [Int: DogmaEffect]
}

extension Data {
    /// Load all DogmaEngine data from a directory containing JSON files
    public static func new(from directory: URL) throws -> Data {
        let decoder = JSONDecoder()
        
        // Load types
        let typesURL = directory.appendingPathComponent("types.json")
        let typesData = try Foundation.Data(contentsOf: typesURL)
        let rawTypes = try decoder.decode([String: Type].self, from: typesData)
        var types = rawTypes.reduce(into: [Int: Type]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load groups
        let groupsURL = directory.appendingPathComponent("groups.json")
        let groupsData = try Foundation.Data(contentsOf: groupsURL)
        let rawGroups = try decoder.decode([String: Group].self, from: groupsData)
        let groups = rawGroups.reduce(into: [Int: Group]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Resolve categoryID for types from groups
        for (typeId, type) in types {
            var updatedType = type
            if let group = groups[type.groupID] {
                updatedType.categoryID = group.categoryID
            }
            types[typeId] = updatedType
        }
        
        // Load typeDogma
        let typeDogmaURL = directory.appendingPathComponent("typeDogma.json")
        let typeDogmaData = try Foundation.Data(contentsOf: typeDogmaURL)
        let rawTypeDogma = try decoder.decode([String: TypeDogma].self, from: typeDogmaData)
        let typeDogma = rawTypeDogma.reduce(into: [Int: TypeDogma]()) { dict, entry in
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
                    groups: groups,
                    typeDogma: typeDogma,
                    dogmaAttributes: dogmaAttributes,
                    dogmaEffects: dogmaEffects)
    }
    
    /// Load all DogmaEngine data from individual JSON files in the main bundle
    public static func newFromBundle() throws -> Data {
        let decoder = JSONDecoder()
        
        // Load types
        guard let typesURL = Bundle.main.url(forResource: "types", withExtension: "json") else {
            throw DataError.missingResource("types.json")
        }
        let typesData = try Foundation.Data(contentsOf: typesURL)
        let rawTypes = try decoder.decode([String: Type].self, from: typesData)
        var types = rawTypes.reduce(into: [Int: Type]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load groups
        guard let groupsURL = Bundle.main.url(forResource: "groups", withExtension: "json") else {
            throw DataError.missingResource("groups.json")
        }
        let groupsData = try Foundation.Data(contentsOf: groupsURL)
        let rawGroups = try decoder.decode([String: Group].self, from: groupsData)
        let groups = rawGroups.reduce(into: [Int: Group]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Resolve categoryID for types from groups
        for (typeId, type) in types {
            var updatedType = type
            if let group = groups[type.groupID] {
                updatedType.categoryID = group.categoryID
            }
            types[typeId] = updatedType
        }
        
        // Load typeDogma
        guard let typeDogmaURL = Bundle.main.url(forResource: "typeDogma", withExtension: "json") else {
            throw DataError.missingResource("typeDogma.json")
        }
        let typeDogmaData = try Foundation.Data(contentsOf: typeDogmaURL)
        let rawTypeDogma = try decoder.decode([String: TypeDogma].self, from: typeDogmaData)
        let typeDogma = rawTypeDogma.reduce(into: [Int: TypeDogma]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load dogmaAttributes
        guard let dogmaAttributesURL = Bundle.main.url(forResource: "dogmaAttributes", withExtension: "json") else {
            throw DataError.missingResource("dogmaAttributes.json")
        }
        let dogmaAttributesData = try Foundation.Data(contentsOf: dogmaAttributesURL)
        let rawDogmaAttributes = try decoder.decode([String: DogmaAttribute].self, from: dogmaAttributesData)
        let dogmaAttributes = rawDogmaAttributes.reduce(into: [Int: DogmaAttribute]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        // Load dogmaEffects
        guard let dogmaEffectsURL = Bundle.main.url(forResource: "dogmaEffects", withExtension: "json") else {
            throw DataError.missingResource("dogmaEffects.json")
        }
        let dogmaEffectsData = try Foundation.Data(contentsOf: dogmaEffectsURL)
        let rawDogmaEffects = try decoder.decode([String: DogmaEffect].self, from: dogmaEffectsData)
        let dogmaEffects = rawDogmaEffects.reduce(into: [Int: DogmaEffect]()) { dict, entry in
            if let key = Int(entry.key) {
                dict[key] = entry.value
            }
        }
        
        return Data(types: types,
                    groups: groups,
                    typeDogma: typeDogma,
                    dogmaAttributes: dogmaAttributes,
                    dogmaEffects: dogmaEffects)
    }
}

public enum DataError: Error {
    case missingResource(String)
}
