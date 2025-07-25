//
//  Untitled.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

private struct Module {
    var capacitorNeed: Double
    var duration: Double
    var timeNext: Double
}

func attributeCapacitorDepletesIn(info: Info, ship: inout Ship) {
    let attrPeakDeltaID    = info.attributeNameToId("capacitorPeakDelta")
    let attrCapacityID     = info.attributeNameToId("capacitorCapacity")
    let attrRechargeRateID = info.attributeNameToId("rechargeRate")
    let attrNeedID         = info.attributeNameToId("capacitorNeed")
    let attrCycleTimeID    = info.attributeNameToId("cycleTime")
    let attrDepletesInID   = info.attributeNameToId("capacitorDepletesIn")

    guard let peakAttr = ship.hull.attributes[attrPeakDeltaID],
          let peakVal  = peakAttr.value,
          peakVal < 0 else { return }

    var depletesIn: Double = -1000.0

    let capacity     = ship.hull.attributes[attrCapacityID]!.value!
    let rechargeRate = ship.hull.attributes[attrRechargeRateID]!.value!

    // Find all active modules consuming capacitor
    var modules: [Module] = []
    for item in ship.items {
        guard item.slot.isModule(), item.state.isActive(),
              let need     = item.attributes[attrNeedID]?.value,
              let duration = item.attributes[attrCycleTimeID]?.value else {
            continue
        }
        modules.append(Module(capacitorNeed: need, duration: duration, timeNext: 0.0))
    }

    if !modules.isEmpty {
        var capacitor = capacity
        var timeLast: Double = 0
        var timeNext: Double = 0

        // Simulate until depletion
        while capacitor > 0 {
            capacitor = pow(
                1 + (sqrt(capacitor / capacity) - 1) * exp(5 * (timeLast - timeNext) / rechargeRate),
                2
            ) * capacity

            timeLast = timeNext
            timeNext = Double.infinity

            for i in modules.indices {
                if modules[i].timeNext <= timeLast {
                    modules[i].timeNext += modules[i].duration
                    capacitor -= modules[i].capacitorNeed
                }
                timeNext = min(timeNext, modules[i].timeNext)
            }
        }
        depletesIn = timeLast
    }

    ship.hull.setAttribute(attributeId: attrDepletesInID, value: depletesIn / 1000)
}
