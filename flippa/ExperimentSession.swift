//
//  ExperimentSession.swift
//  flippa
//

import Foundation
import Observation

enum ExperimentType: String, CaseIterable, Identifiable {
    case coin = "Coin"
    case die = "Die"
    case twoDice = "Two Dice"

    var id: String { rawValue }

    var actionLabel: String {
        self == .coin ? "Flip" : "Roll"
    }
}

struct ExperimentResult: Identifiable {
    let id = UUID()
    let type: ExperimentType
    let values: [Int]

    var isHeads: Bool { type == .coin && values[0] == 0 }

    var historyLabel: String {
        switch type {
        case .coin:    return values[0] == 0 ? "Heads" : "Tails"
        case .die:     return "\(values[0])"
        case .twoDice: return "\(values[0])  +  \(values[1])  =  \(values[0] + values[1])"
        }
    }
}

@Observable
final class ExperimentSession {
    var selectedType: ExperimentType = .coin
    var results: [ExperimentResult] = []
    var currentResult: ExperimentResult?

    func perform() {
        let values: [Int]
        switch selectedType {
        case .coin:    values = [Int.random(in: 0...1)]
        case .die:     values = [Int.random(in: 1...6)]
        case .twoDice: values = [Int.random(in: 1...6), Int.random(in: 1...6)]
        }
        let result = ExperimentResult(type: selectedType, values: values)
        currentResult = result
        results.insert(result, at: 0)
    }

    func reset() {
        results = []
        currentResult = nil
    }

    var headsCount: Int { results.filter { $0.isHeads }.count }
    var tailsCount: Int { results.filter { !$0.isHeads }.count }

    var sessionStat: String {
        guard !results.isEmpty else { return "" }
        switch selectedType {
        case .coin:
            let pct = Int(round(Double(headsCount) / Double(results.count) * 100))
            return "\(pct)% heads"
        case .die:
            let avg = Double(results.map { $0.values[0] }.reduce(0, +)) / Double(results.count)
            return String(format: "avg %.1f", avg)
        case .twoDice:
            let avg = Double(results.map { $0.values[0] + $0.values[1] }.reduce(0, +)) / Double(results.count)
            return String(format: "avg sum %.1f", avg)
        }
    }
}
