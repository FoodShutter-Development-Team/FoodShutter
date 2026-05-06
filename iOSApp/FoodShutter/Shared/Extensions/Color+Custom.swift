//
//  Color+Custom.swift
//  FoodShutter
//

import SwiftUI

extension Color {
    // MARK: - Background
    // display-p3: R=0xFA G=0xFA B=0xF0
    static let backGround     = Color(red: 0.980, green: 0.980, blue: 0.941)
    // display-p3: R=240 G=238 B=231
    static let backGroundDark = Color(red: 0.941, green: 0.933, blue: 0.906)

    // MARK: - Text & Interactive
    // display-p3: R=0x3D G=0x3D B=0x3A
    static let mainText   = Color(red: 0.239, green: 0.239, blue: 0.227)
    // display-p3: R=0xD2 G=0x78 B=0x5A
    static let mainEnable = Color(red: 0.824, green: 0.471, blue: 0.353)
    // display-p3: R=0x50 G=0x58 B=0x9C
    static let userEnable = Color(red: 0.314, green: 0.345, blue: 0.612)

    // MARK: - Nutrition macros
    // display-p3: R=0x7B G=0x9F B=0xAD
    static let protein      = Color(red: 0.482, green: 0.624, blue: 0.678)
    // display-p3: R=0xC9 G=0xA9 B=0x6E
    static let fat          = Color(red: 0.788, green: 0.663, blue: 0.431)
    // display-p3: R=0x8B G=0x9A B=0x7E
    static let carbohydrate = Color(red: 0.545, green: 0.604, blue: 0.494)
}

// MARK: - ShapeStyle convenience (lets .mainText / .backGround work as ShapeStyle)

extension ShapeStyle where Self == Color {
    static var mainText:      Color { .mainText }
    static var backGround:    Color { .backGround }
    static var backGroundDark: Color { .backGroundDark }
    static var mainEnable:    Color { .mainEnable }
    static var userEnable:    Color { .userEnable }
    static var protein:       Color { .protein }
    static var fat:           Color { .fat }
    static var carbohydrate:  Color { .carbohydrate }
}
