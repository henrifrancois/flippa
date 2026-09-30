//
//  ContentView.swift
//  flippa
//

import SwiftUI

struct ContentView: View {
    @State private var session = ExperimentSession()
    @State private var isAnimating = false
    @State private var coinSpin: Double = 0
    @State private var objectScale: CGFloat = 1.0
    @State private var objectTilt: Double = 0
    @State private var hapticTrigger = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $session.selectedType) {
                ForEach(ExperimentType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .onChange(of: session.selectedType) {
                withAnimation { session.reset() }
            }

            Spacer()

            // Main visual
            Group {
                switch session.selectedType {
                case .coin:
                    CoinFaceView(result: session.currentResult)
                        .rotation3DEffect(.degrees(coinSpin), axis: (x: 0, y: 1, z: 0))
                        .scaleEffect(objectScale)
                case .die:
                    SingleDieView(value: session.currentResult?.values[0], dimmed: session.currentResult == nil)
                        .scaleEffect(objectScale)
                        .rotationEffect(.degrees(objectTilt))
                case .twoDice:
                    PairDiceView(result: session.currentResult)
                        .scaleEffect(objectScale)
                        .rotationEffect(.degrees(objectTilt))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: session.selectedType.id)

            // Outcome label
            resultLabel
                .frame(height: 44)
                .padding(.top, 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: session.currentResult?.id)

            Spacer()

            // Action button
            Button(action: performExperiment) {
                Text(session.selectedType.actionLabel)
                    .font(.title3.bold())
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .frame(width: 168, height: 56)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
            .disabled(isAnimating)
            .sensoryFeedback(.impact(weight: .heavy), trigger: hapticTrigger)
            .padding(.bottom, 20)

            HistoryPanel(session: session)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Result label

    @ViewBuilder
    private var resultLabel: some View {
        if let result = session.currentResult {
            switch result.type {
            case .coin:
                Text(result.isHeads ? "Heads" : "Tails")
                    .font(.title.bold())
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            case .die:
                Text("You rolled a \(result.values[0])")
                    .font(.title.bold())
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            case .twoDice:
                Text("\(result.values[0])  +  \(result.values[1])  =  \(result.values[0] + result.values[1])")
                    .font(.title.bold().monospacedDigit())
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        } else {
            Text("Tap \(session.selectedType.actionLabel) to begin")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .transition(.opacity)
        }
    }

    // MARK: - Animation

    private func performExperiment() {
        guard !isAnimating else { return }
        isAnimating = true
        hapticTrigger += 1

        switch session.selectedType {
        case .coin:
            withAnimation(.easeInOut(duration: 0.55)) {
                coinSpin += 720
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
                session.perform()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                isAnimating = false
            }

        case .die, .twoDice:
            withAnimation(.easeIn(duration: 0.1)) {
                objectScale = 0.78
                objectTilt = Double.random(in: -14...14)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                session.perform()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.5)) {
                    objectScale = 1.0
                    objectTilt = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Coin

struct CoinFaceView: View {
    let result: ExperimentResult?

    private var isHeads: Bool { result?.isHeads ?? true }
    private var hasResult: Bool { result != nil }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillGradient)
            Circle()
                .strokeBorder(rimColor, lineWidth: 5)
            if hasResult {
                Circle()
                    .strokeBorder(innerRimColor, lineWidth: 2)
                    .padding(10)
            }
            Text(hasResult ? (isHeads ? "H" : "T") : "?")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .foregroundStyle(hasResult ? .white : Color(white: 0.5))
        }
        .frame(width: 200, height: 200)
        .shadow(color: .black.opacity(0.22), radius: 30, y: 14)
    }

    private var fillGradient: RadialGradient {
        guard hasResult else {
            return RadialGradient(
                colors: [Color(white: 0.78), Color(white: 0.58)],
                center: .init(x: 0.35, y: 0.35), startRadius: 5, endRadius: 120
            )
        }
        return isHeads
            ? RadialGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.35), Color(red: 0.75, green: 0.55, blue: 0.08)],
                center: .init(x: 0.35, y: 0.35), startRadius: 5, endRadius: 120
              )
            : RadialGradient(
                colors: [Color(white: 0.88), Color(white: 0.62)],
                center: .init(x: 0.35, y: 0.35), startRadius: 5, endRadius: 120
              )
    }

    private var rimColor: Color {
        guard hasResult else { return Color(white: 0.55) }
        return isHeads ? Color(red: 0.62, green: 0.43, blue: 0.02) : Color(white: 0.44)
    }

    private var innerRimColor: Color {
        isHeads
            ? Color(red: 1.0, green: 0.95, blue: 0.5).opacity(0.45)
            : Color.white.opacity(0.45)
    }
}

// MARK: - Die

struct SingleDieView: View {
    let value: Int?
    let dimmed: Bool

    var body: some View {
        let face = max(1, min(6, value ?? 1))
        Image(systemName: "die.face.\(face)")
            .font(.system(size: 140))
            .foregroundStyle(dimmed ? Color.secondary.opacity(0.35) : Color.primary)
            .symbolRenderingMode(.hierarchical)
    }
}

struct PairDiceView: View {
    let result: ExperimentResult?

    var body: some View {
        let v1 = max(1, min(6, result?.values[0] ?? 1))
        let v2 = max(1, min(6, result?.values[1] ?? 1))
        let hasResult = result != nil

        HStack(spacing: 20) {
            Image(systemName: "die.face.\(v1)")
                .font(.system(size: 108))
            Image(systemName: "die.face.\(v2)")
                .font(.system(size: 108))
        }
        .foregroundStyle(hasResult ? Color.primary : Color.secondary.opacity(0.35))
        .symbolRenderingMode(.hierarchical)
    }
}

// MARK: - History

struct HistoryPanel: View {
    var session: ExperimentSession

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Header row
            HStack(alignment: .center, spacing: 6) {
                Text("Session")
                    .font(.headline)
                if !session.sessionStat.isEmpty {
                    Text("·  \(session.sessionStat)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !session.results.isEmpty {
                    Text("\(session.results.count) result\(session.results.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                Button {
                    withAnimation { session.reset() }
                } label: {
                    Text("Reset")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.leading, 10)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if session.results.isEmpty {
                Text("No results yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .padding(.bottom, 48)
            } else {
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(session.results.enumerated()), id: \.element.id) { index, result in
                            row(index: index, result: result)
                        }
                    }
                }
                .frame(maxHeight: 230)
                .padding(.bottom, 48)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func row(index: Int, result: ExperimentResult) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("#\(session.results.count - index)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .leading)

                rowIcon(result)

                Text(result.historyLabel)
                    .font(.body.monospacedDigit())

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if index < session.results.count - 1 {
                Divider().padding(.leading, 56)
            }
        }
    }

    @ViewBuilder
    private func rowIcon(_ result: ExperimentResult) -> some View {
        switch result.type {
        case .coin:
            Circle()
                .fill(result.isHeads
                    ? Color(red: 0.85, green: 0.65, blue: 0.1)
                    : Color.secondary.opacity(0.35))
                .frame(width: 22, height: 22)
                .overlay {
                    Text(result.isHeads ? "H" : "T")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
        case .die:
            Image(systemName: "die.face.\(result.values[0])")
                .font(.system(size: 22))
                .symbolRenderingMode(.hierarchical)
        case .twoDice:
            HStack(spacing: 3) {
                Image(systemName: "die.face.\(result.values[0])")
                    .font(.system(size: 16))
                Image(systemName: "die.face.\(result.values[1])")
                    .font(.system(size: 16))
            }
            .symbolRenderingMode(.hierarchical)
        }
    }
}

#Preview {
    ContentView()
}
