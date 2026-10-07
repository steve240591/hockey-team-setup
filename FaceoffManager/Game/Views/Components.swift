import SwiftUI
import UIKit

/// Zeigt ein Bild aus Assets.xcassets, falls vorhanden, sonst ein SF-Symbol als Platzhalter.
/// So erscheinen die KI-Grafiken automatisch, sobald sie mit dem richtigen Namen im Projekt liegen.
struct GameImage: View {
    let name: String
    let fallbackSymbol: String
    var size: CGFloat = 32
    var tint: Color = .accentColor

    var body: some View {
        if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallbackSymbol)
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.25))
        }
    }
}

/// Leiste mit Münzen, Einnahmen pro Sekunde, Pucks und Trainingskarten.
struct CurrencyBar: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        HStack(spacing: 14) {
            Label {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Fmt.number(store.state.coins)).font(.headline.monospacedDigit())
                    Text(LF("common.perSecond", Fmt.number(store.incomePerSecond)))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } icon: {
                GameImage(name: "icon_coin", fallbackSymbol: "dollarsign.circle.fill", size: 26, tint: .yellow)
            }
            Spacer(minLength: 0)
            if store.boostSecondsLeft > 0 {
                Label(Fmt.countdown(store.boostSecondsLeft), systemImage: "bolt.fill")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.orange)
            }
            Label(Fmt.integer(store.state.pucks), systemImage: "circle.fill")
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.primary)
            Label(Fmt.integer(store.state.trainingCards), systemImage: "rectangle.stack.fill")
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.teal)
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct RarityBadge: View {
    let rarity: Rarity

    var body: some View {
        Text(L("rarity.\(rarity.rawValue)"))
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(.white)
            .background(rarity.color, in: Capsule())
    }
}

extension Rarity {
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

/// Knopf, der ein Belohnungsvideo startet. Zeigt die verbleibende Anzahl für heute.
struct AdButton: View {
    @EnvironmentObject var store: GameStore
    let title: String
    let kind: RewardedKind
    let action: () -> Void

    var body: some View {
        let remaining = store.engine.rewardedRemaining(store.state, kind: kind)
        Button(action: action) {
            HStack {
                Image(systemName: store.state.adFree ? "gift.fill" : "play.rectangle.fill")
                Text(title)
                Spacer()
                if let remaining {
                    Text(LF("ad.remaining", Fmt.integer(remaining)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(remaining == 0)
    }
}

/// Kurze Meldung am oberen Rand.
struct MessageBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.bold())
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .shadow(radius: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
