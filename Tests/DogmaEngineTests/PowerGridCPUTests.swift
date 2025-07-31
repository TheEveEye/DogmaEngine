//
//  PowerGridCPUTests.swift
//  DogmaEngine Tests
//
//  Created on July 31, 2025.
//

import Testing
@testable import DogmaEngine

/// Tests for CPU and Powergrid calculations
struct PowerGridCPUTests {
    
    @Test func testStandardRifterFitCPUAndPowergrid() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Verify all modules exist in SDE data
        try standardFit.verifyAllModules(in: data)
        
        // Create modules for the fit
        let modules = [
            // High slots - 3x 200mm AutoCannon II
            EsfModule(typeID: standardFit.highSlot1TypeID, slot: EsfSlot(type: .high, index: 0), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot2TypeID, slot: EsfSlot(type: .high, index: 1), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot3TypeID, slot: EsfSlot(type: .high, index: 2), state: .active, charge: nil),
            
            // Mid slots
            EsfModule(typeID: standardFit.midSlot1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil), // 5MN Microwarpdrive II
            EsfModule(typeID: standardFit.midSlot2TypeID, slot: EsfSlot(type: .medium, index: 1), state: .active, charge: nil), // Warp Scrambler II
            EsfModule(typeID: standardFit.midSlot3TypeID, slot: EsfSlot(type: .medium, index: 2), state: .active, charge: nil), // Stasis Webifier II
            
            // Low slots
            EsfModule(typeID: standardFit.lowSlot1TypeID, slot: EsfSlot(type: .low, index: 0), state: .passive, charge: nil), // Damage Control II
            EsfModule(typeID: standardFit.lowSlot2TypeID, slot: EsfSlot(type: .low, index: 1), state: .passive, charge: nil), // Multispectrum Coating II
            EsfModule(typeID: standardFit.lowSlot3TypeID, slot: EsfSlot(type: .low, index: 2), state: .passive, charge: nil), // Small Ancillary Armor Repairer
            EsfModule(typeID: standardFit.lowSlot4TypeID, slot: EsfSlot(type: .low, index: 3), state: .passive, charge: nil), // 200mm Steel Plates II
            
            // Rig slots
            EsfModule(typeID: standardFit.rigSlot1TypeID, slot: EsfSlot(type: .rig, index: 0), state: .passive, charge: nil), // Small Projectile Burst Aerator I
            EsfModule(typeID: standardFit.rigSlot2TypeID, slot: EsfSlot(type: .rig, index: 1), state: .passive, charge: nil), // Small Projectile Ambit Extension I
            EsfModule(typeID: standardFit.rigSlot3TypeID, slot: EsfSlot(type: .rig, index: 2), state: .passive, charge: nil), // Small Semiconductor Memory Cell I
        ]
        
        // Create the fit
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        let info = SimpleInfo(data: data, fit: fit, skills: [:]) // No skills for baseline test
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Test CPU calculations
        let cpuOutputID = 48  // cpuOutput
        let cpuLoadID = 49    // cpuLoad
        
        // Test Power calculations  
        let powerOutputID = 11  // powerOutput
        let powerLoadID = 15    // powerLoad
        
        // Verify CPU values
        guard let cpuOutput = ship.hull.attributes[cpuOutputID]?.value else {
            throw TestError.missingTestData("CPU output not found")
        }
        
        guard let cpuLoad = ship.hull.attributes[cpuLoadID]?.value else {
            throw TestError.missingTestData("CPU load not found")
        }
        
        // Verify Power values
        guard let powerOutput = ship.hull.attributes[powerOutputID]?.value else {
            throw TestError.missingTestData("Power output not found")
        }
        
        guard let powerLoad = ship.hull.attributes[powerLoadID]?.value else {
            throw TestError.missingTestData("Power load not found")
        }
        
        print("=== CPU/POWER CALCULATIONS ===")
        print("CPU: \(cpuLoad)/\(cpuOutput) (available: \(cpuOutput - cpuLoad))")
        print("Power: \(powerLoad)/\(powerOutput) (available: \(powerOutput - powerLoad))")
        
        // Expected values from user specification
        let expectedCpuUsage: Double = 169
        let expectedCpuCapacity: Double = 130
        let expectedPowerUsage: Double = 52.52
        let expectedPowerCapacity: Double = 41
        
        // Allow small floating point differences
        #expect(abs(cpuLoad - expectedCpuUsage) < 0.1, 
                "CPU usage should be \(expectedCpuUsage), got \(cpuLoad)")
        #expect(abs(cpuOutput - expectedCpuCapacity) < 0.1, 
                "CPU capacity should be \(expectedCpuCapacity), got \(cpuOutput)")
        #expect(abs(powerLoad - expectedPowerUsage) < 0.1, 
                "Power usage should be \(expectedPowerUsage), got \(powerLoad)")
        #expect(abs(powerOutput - expectedPowerCapacity) < 0.1, 
                "Power capacity should be \(expectedPowerCapacity), got \(powerOutput)")
        
        print("✅ CPU and Power calculations verified successfully")
    }
}
