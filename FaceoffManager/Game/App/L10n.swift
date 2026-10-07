import Foundation

/// Übersetzter Text zum Schlüssel aus Localizable.xcstrings.
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

/// Übersetzter Text mit Platzhaltern (%@ bzw. %1$@, %2$@ …). Zahlen vorher mit Fmt formatieren.
func LF(_ key: String, _ args: String...) -> String {
    String(format: NSLocalizedString(key, comment: ""), arguments: args.map { $0 as CVarArg })
}

/// Zahlen- und Zeitformate für die Anzeige.
enum Fmt {
    private static let units = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

    /// Kurzform für große Zahlen: 950, 1,25K, 37,4M …
    static func number(_ value: Double) -> String {
        guard value.isFinite else { return "∞" }
        var scaled = abs(value)
        var unit = 0
        while scaled >= 1000 && unit < units.count - 1 {
            scaled /= 1000
            unit += 1
        }
        let digits: Int
        if unit == 0 {
            digits = scaled < 10 && scaled != scaled.rounded() ? 1 : 0
        } else {
            digits = scaled < 10 ? 2 : (scaled < 100 ? 1 : 0)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = digits
        let text = formatter.string(from: NSNumber(value: scaled)) ?? "\(scaled)"
        return (value < 0 ? "-" : "") + text + units[unit]
    }

    static func integer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func percent(_ fraction: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: fraction)) ?? "\(Int(fraction * 100)) %"
    }

    /// Countdown wie „4:05“ oder „1:02:30“.
    static func countdown(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Dauer in Worten, z. B. „2 Std. 15 Min.“
    static func duration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: max(0, seconds)) ?? Fmt.countdown(seconds)
    }
}
