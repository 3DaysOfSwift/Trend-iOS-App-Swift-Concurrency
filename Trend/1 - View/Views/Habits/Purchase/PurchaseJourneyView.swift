// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import SwiftUI

private enum PurchaseJourneyPhase: Int, Comparable {
    case closed, thanking, unlocked, todayUpgrade, featureIntroduction, benefits, extras, ready

    var showsThankYou: Bool { self <= .todayUpgrade }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct PurchaseJourneyView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var phase = PurchaseJourneyPhase.closed
    @State private var feedback = 0
    @State private var showsHabitLibrary = false

    var body: some View {
        ZStack(alignment: .bottom) {
            themeManager.palette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 26) {
                    Spacer(minLength: 50)
                    lock
                    if phase.showsThankYou { thankYou.transition(.opacity) }
                    else { benefits.transition(.opacity.combined(with: .offset(y: 18))) }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
            }
            confetti.allowsHitTesting(false)
        }
        .interactiveDismissDisabled()
        .sensoryFeedback(.success, trigger: feedback)
        .task { await animateJourney() }
        .sheet(isPresented: $showsHabitLibrary, onDismiss: { dismiss() }) {
            HabitLibraryView()
        }
    }

    private var lock: some View {
        ZStack {
            Circle().fill(themeManager.palette.success.opacity(0.13))
                .frame(width: 154, height: 154)
                .scaleEffect(phase >= .thanking ? 1 : 0.72)
            Circle().stroke(themeManager.palette.success.opacity(0.18), lineWidth: 4)
                .frame(width: 154, height: 154)
                .scaleEffect(phase >= .unlocked ? 1.34 : 0.88)
                .opacity(phase >= .unlocked ? 0 : 1)
            Image(systemName: phase >= .unlocked ? "lock.open.fill" : "lock.fill")
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(themeManager.palette.success.gradient)
        }
        .frame(height: 174)
        .accessibilityLabel(phase >= .unlocked ? "Habits unlocked" : "Unlocking Habits")
    }

    private var thankYou: some View {
        VStack(spacing: 26) {
            VStack(spacing: 12) {
                Text("Thank you").font(.largeTitle.bold())
                Text("Your support means a lot to us.")
                    .font(.title3).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .opacity(phase >= .thanking ? 1 : 0)
            .offset(y: phase >= .thanking ? 0 : 12)

            Label("We’ll upgrade your Today screen too.", systemImage: "sparkles")
                .font(.headline).foregroundStyle(themeManager.palette.accent)
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(.ultraThinMaterial, in: Capsule())
                .opacity(phase >= .todayUpgrade ? 1 : 0)
                .offset(y: phase >= .todayUpgrade ? 0 : 10)
        }
        .frame(minHeight: 290, alignment: .top)
    }

    private var benefits: some View {
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                Text("Feature Unlocked").font(.largeTitle.bold())
                Text("Your next level of daily tracking is ready.").foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                Image(systemName: "dumbbell.fill").font(.system(size: 54)).foregroundStyle(themeManager.palette.accent)
                Text("Track your reps in the gym").font(.title.bold())
                Text("Record every set and turn your effort into a visible daily habit.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(24)
            .background(themeManager.palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: themeManager.palette.accent.opacity(0.10), radius: 22, y: 10)
            .opacity(phase >= .benefits ? 1 : 0).offset(y: phase >= .benefits ? 0 : 18)

            HStack(spacing: 14) {
                treat("Coffee", "Count this week’s cups", "cup.and.saucer.fill")
                treat("Water", "Notice every glass", "drop.fill")
            }
            .opacity(phase >= .extras ? 1 : 0).offset(y: phase >= .extras ? 0 : 16)

            Button("Choose my habits", systemImage: "arrow.right.circle.fill") { showsHabitLibrary = true }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .opacity(phase >= .ready ? 1 : 0).offset(y: phase >= .ready ? 0 : 12)
                .disabled(phase < .ready)
        }
    }

    private func treat(_ title: String, _ message: String, _ symbol: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: symbol).font(.title2).foregroundStyle(themeManager.palette.accent)
            Text(title).font(.headline)
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 118).padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var confetti: some View {
        HStack(spacing: 15) {
            ForEach(0..<17, id: \.self) { index in
                Capsule().fill(confettiColor(index))
                    .frame(width: index.isMultiple(of: 3) ? 7 : 5, height: index.isMultiple(of: 2) ? 18 : 12)
                    .rotationEffect(.degrees(Double((index * 47) % 130) - 65))
                    .offset(y: Double((index * 19) % 55))
            }
        }
        .offset(y: phase == .todayUpgrade && !reduceMotion ? -88 : 70)
        .opacity(phase == .todayUpgrade ? 1 : 0)
        .animation(reduceMotion ? .linear(duration: 0.15) : .easeOut(duration: 0.75), value: phase)
    }

    private func confettiColor(_ index: Int) -> Color {
        switch index % 5 {
        case 0: themeManager.palette.accent
        case 1: themeManager.palette.success
        case 2: .yellow
        case 3: .orange
        default: .pink
        }
    }

    private func animateJourney() async {
        await advance(to: .thanking, after: 160)
        await advance(to: .unlocked, after: 650)
        feedback += 1
        await advance(to: .todayUpgrade, after: 520)
        await advance(to: .featureIntroduction, after: 1_650)
        await advance(to: .benefits, after: 180)
        await advance(to: .extras, after: 520)
        await advance(to: .ready, after: 480)
    }

    private func advance(to nextPhase: PurchaseJourneyPhase, after milliseconds: Int) async {
        try? await Task.sleep(for: .milliseconds(milliseconds))
        guard !Task.isCancelled else { return }
        withAnimation(reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.58, dampingFraction: 0.72)) {
            phase = nextPhase
        }
    }
}
