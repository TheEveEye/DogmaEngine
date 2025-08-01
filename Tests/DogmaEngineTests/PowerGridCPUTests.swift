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
        
        // Create fit with standard modules
        let fit = standardFit.createFit()
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
