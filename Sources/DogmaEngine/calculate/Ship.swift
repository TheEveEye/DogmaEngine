//
//  Mod.swift
//  dogma-engine

//  Created by Oskar on 7/25/25.
//

import Foundation

struct DamageProfile: Codable {
    var em: Double
    var explosive: Double
    var kinetic: Double
    var thermal: Double
}

class Ship: Codable {
    var hull: Item
    var items: [Item]
    var skills: [Item]
    var char: Item
    var structure: Item
    var target: Item

    var damageProfile: DamageProfile

    init(shipTypeId: Int) {
        self.hull = Item.newFake(typeId: shipTypeId)
        self.items = []
        self.skills = []
        self.char = Item.newFake(typeId: 1373)
        self.structure = Item.newFake(typeId: 0)
        self.target = Item.newFake(typeId: 0)
        self.damageProfile = DamageProfile(em: 0.25, explosive: 0.25, kinetic: 0.25, thermal: 0.25)
    }
}

protocol Pass {
    static func pass(info: Info, ship: inout Ship)
}

func calculate(info: Info) -> Ship {
    var ship = Ship(shipTypeId: info.fit().shipTypeID)
    
    PassOne.pass(info: info, ship: &ship)
    PassTwo.pass(info: info, ship: &ship)
    PassThree.pass(info: info, ship: &ship)
    PassFour.pass(info: info, ship: &ship)
    
    
    return ship
}
