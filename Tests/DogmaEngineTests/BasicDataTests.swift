//
//  BasicDataTests.swift
//  DogmaEngine Tests
//
//  Created by GitHub Copilot on 7/28/25.
//

import Testing
import Foundation
@testable import DogmaEngine

/// Basic tests for data loading and integrity
struct BasicDataTests {
    
    @Test func testDataLoading() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Verify basic data is loaded
        #expect(data.types.count > 0, "Types should be loaded")
        #expect(data.groups.count > 0, "Groups should be loaded")
        #expect(data.typeDogma.count > 0, "TypeDogma should be loaded")
        #expect(data.dogmaAttributes.count > 0, "Dogma attributes should be loaded")
        #expect(data.dogmaEffects.count > 0, "Dogma effects should be loaded")
        
        print("✅ Loaded data: \(data.types.count) types, \(data.groups.count) groups, \(data.dogmaAttributes.count) attributes")
    }
    
    @Test func testRifterDataIntegrity() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Test that Rifter (typeID 587) exists and has expected properties
        try TestHelpers.verifyTypeID(587, expectedName: "Rifter", in: data)
        
        let rifter = data.types[587]!
        #expect(rifter.groupID > 0, "Rifter should have a valid group ID")
        
        // Verify Rifter has dogma attributes
        if let rifterDogma = data.typeDogma[587] {
            #expect(rifterDogma.dogmaAttributes.count > 0, "Rifter should have dogma attributes")
            
            // Check for basic ship attributes
            let attributeIDs = rifterDogma.dogmaAttributes.map { $0.attributeID }
            #expect(attributeIDs.contains(9), "Rifter should have structure HP (attribute 9)")
            #expect(attributeIDs.contains(265), "Rifter should have armor HP (attribute 265)")
            #expect(attributeIDs.contains(263), "Rifter should have shield capacity (attribute 263)")
        }
        
        print("✅ Rifter data integrity verified")
    }
}
