//
//  Info.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

protocol Info {
    func skills() -> [Int: Int]
    func fit() -> EsfFit

    func getDogmaAttributes(_ typeId: Int) -> [TypeDogmaAttribute]
    func getDogmaAttribute(_ attributeId: Int) -> DogmaAttribute
    func getDogmaEffects(_ typeId: Int) -> [TypeDogmaEffect]
    func getDogmaEffect(_ effectId: Int) -> DogmaEffect
    func getType(_ typeId: Int) -> `Type`
    func attributeNameToId(_ name: String) -> Int
}

protocol InfoName {
    func getDogmaEffects(_ typeId: Int) -> [TypeDogmaEffect]
    func getType(_ typeId: Int) -> `Type`
    func typeNameToId(_ name: String) -> Int
}
