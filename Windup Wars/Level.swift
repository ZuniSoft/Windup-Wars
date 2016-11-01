//
//  Level.swift
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

import Foundation

let NumColumns = 9
let NumRows = 9
let NumLevels = 4

class Level {
    
    fileprivate var windups = Array2D<Windup>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    private var comboMultiplier = 0
    var targetScore = 0
    var maximumMoves = 0
    
    init(filename: String) {
        guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename: filename) else { return }
        guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
        
        for (row, rowArray) in tilesArray.enumerated() {
            let tileRow = NumRows - row - 1
            
            for (column, value) in rowArray.enumerated() {
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
        targetScore = dictionary["targetScore"] as! Int
        maximumMoves = dictionary["moves"] as! Int
    }
    
    func windupAt(column: Int, row: Int) -> Windup? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return windups[column, row]
    }
    
    func tileAt(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    func shuffle() -> Set<Windup> {
        var set: Set<Windup>
        repeat {
            set = createInitialWindups()
            detectPossibleSwaps()
            print("possible swaps: \(possibleSwaps)")
        } while possibleSwaps.count == 0
        
        return set
    }
    
    private func createInitialWindups() -> Set<Windup> {
        var set = Set<Windup>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                if tiles[column, row] != nil {
                    var windupType: WindupType
                    repeat {
                        windupType = WindupType.random()
                    } while (column >= 2 &&
                        windups[column - 1, row]?.windupType == windupType &&
                        windups[column - 2, row]?.windupType == windupType)
                        || (row >= 2 &&
                            windups[column, row - 1]?.windupType == windupType &&
                            windups[column, row - 2]?.windupType == windupType)
                
                    let windup = Windup(column: column, row: row, windupType: windupType)
                    windups[column, row] = windup
                
                    set.insert(windup)
                }
            }
        }
        return set
    }
    
    private func hasChainAt(column: Int, row: Int) -> Bool {
        let windupType = windups[column, row]!.windupType
        
        // Horizontal chain check
        var horzLength = 1
        
        // Left
        var i = column - 1
        while i >= 0 && windups[i, row]?.windupType == windupType {
            i -= 1
            horzLength += 1
        }
        
        // Right
        i = column + 1
        while i < NumColumns && windups[i, row]?.windupType == windupType {
            i += 1
            horzLength += 1
        }
        if horzLength >= 3 { return true }
        
        // Vertical chain check
        var vertLength = 1
        
        // Down
        i = row - 1
        while i >= 0 && windups[column, i]?.windupType == windupType {
            i -= 1
            vertLength += 1
        }
        
        // Up
        i = row + 1
        while i < NumRows && windups[column, i]?.windupType == windupType {
            i += 1
            vertLength += 1
        }
        return vertLength >= 3
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for row in 0..<NumRows {
            var column = 0
            while column < NumColumns-2 {
                if let windup = windups[column, row] {
                    let matchType = windup.windupType
                    
                    if windups[column + 1, row]?.windupType == matchType &&
                        windups[column + 2, row]?.windupType == matchType {
                        
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(windup: windups[column, row]!)
                            column += 1
                        } while column < NumColumns && windups[column, row]?.windupType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                
                column += 1
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows-2 {
                if let windup = windups[column, row] {
                    let matchType = windup.windupType
                    
                    if windups[column, row + 1]?.windupType == matchType &&
                        windups[column, row + 2]?.windupType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(windup: windups[column, row]!)
                            row += 1
                        } while row < NumRows && windups[column, row]?.windupType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removeWindups(chains: horizontalChains)
        removeWindups(chains: verticalChains)
        
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        
        return horizontalChains.union(verticalChains)
    }
    
    private func removeWindups(chains: Set<Chain>) {
        for chain in chains {
            for windup in chain.windups {
                windups[windup.column, windup.row] = nil
            }
        }
    }
    
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let windup = windups[column, row] {
                    // Is it possible to swap this windup with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a windup in this spot? If there is no tile, there is no cookie.
                        if let other = windups[column + 1, row] {
                            // Swap them
                            windups[column, row] = other
                            windups[column + 1, row] = windup
                            
                            // Is either windup now part of a chain?
                            if hasChainAt(column: column + 1, row: row) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(windupA: windup, windupB: other))
                            }
                            
                            // Swap them back
                            windups[column, row] = windup
                            windups[column + 1, row] = other
                        }
                    }
                    
                    if row < NumRows - 1 {
                        if let other = windups[column, row + 1] {
                            windups[column, row] = other
                            windups[column, row + 1] = windup
                            
                            // Is either windup[ now part of a chain?
                            if hasChainAt(column: column, row: row + 1) ||
                                hasChainAt(column: column, row: row) {
                                set.insert(Swap(windupA: windup, windupB: other))
                            }
                            
                            // Swap them back
                            windups[column, row] = windup
                            windups[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.windupA.column
        let rowA = swap.windupA.row
        let columnB = swap.windupB.column
        let rowB = swap.windupB.row
        
        windups[columnA, rowA] = swap.windupB
        swap.windupB.column = columnA
        swap.windupB.row = rowA
        
        windups[columnB, rowB] = swap.windupA
        swap.windupA.column = columnB
        swap.windupA.row = rowB
    }
    
    func fillHoles() -> [[Windup]] {
        var columns = [[Windup]]()
        
        for column in 0..<NumColumns {
            var array = [Windup]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && windups[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let windup = windups[column, lookup] {
                            windups[column, lookup] = nil
                            windups[column, row] = windup
                            windup.row = row
                            array.append(windup)
                            break
                        }
                    }
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpWindups() -> [[Windup]] {
        var columns = [[Windup]]()
        var windupType: WindupType = .unknown
        
        for column in 0..<NumColumns {
            var array = [Windup]()
            var row = NumRows - 1
            
            while row >= 0 && windups[column, row] == nil {
                if tiles[column, row] != nil {
                    var newWindupType: WindupType
                    repeat {
                        newWindupType = WindupType.random()
                    } while newWindupType == windupType
                    windupType = newWindupType
                    
                    let windup = Windup(column: column, row: row, windupType: windupType)
                    windups[column, row] = windup
                    array.append(windup)
                }
                
                row -= 1
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
}
