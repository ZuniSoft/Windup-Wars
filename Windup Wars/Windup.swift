//
//  Windup.swift
//  Windup Wars
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
//  Created by Keith Davis on 10/31/16.
//  Copyright © 2016 ZuniSoft. All rights reserved.
//

import SpriteKit

enum WindupType: Int, CustomStringConvertible {
    case unknown = 0, piggy, frog, bat, gnome, chick, crab
    
    var spriteName: String {
        let spriteNames = [
            "Piggy",
            "Frog",
            "Bat",
            "Gnome",
            "Chick",
            "Crab"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> WindupType {
        return WindupType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
    var description: String {
        return spriteName
    }
}

class Windup: CustomStringConvertible, Hashable {
    var column: Int
    var row: Int
    let windupType: WindupType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, windupType: WindupType) {
        self.column = column
        self.row = row
        self.windupType = windupType
    }
    
    var description: String {
        return "type:\(windupType) square:(\(column),\(row))"
    }
    
    var hashValue: Int {
        return row*10 + column
    }
    
    static func ==(lhs: Windup, rhs: Windup) -> Bool {
        return lhs.column == rhs.column && lhs.row == rhs.row
    }
}
