import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case kilograms
    case pounds

    var id: Self { self }
    var symbol: String { self == .kilograms ? "kg" : "lb" }

    func value(fromKilograms kilograms: Double) -> Double {
        self == .kilograms ? kilograms : kilograms / 0.45359237
    }

    func kilograms(from text: String) throws -> Double {
        guard let number = Double(text.replacingOccurrences(of: ",", with: ".")), number > 0 else {
            throw WeightValidationError.invalidWeight(self)
        }
        let kilograms = self == .kilograms ? number : number * 0.45359237
        guard (20...500).contains(kilograms) else {
            throw WeightValidationError.invalidWeight(self)
        }
        return kilograms
    }

    func formatted(kilograms: Double, signed: Bool = false) -> String {
        let value = value(fromKilograms: kilograms)
        let sign = signed && value > 0 ? "+" : ""
        return "\(sign)\(value.formatted(.number.precision(.fractionLength(1)))) \(symbol)"
    }
}

enum WeightValidationError: LocalizedError {
    case invalidWeight(WeightUnit)

    var errorDescription: String? {
        switch self {
        case .invalidWeight(.kilograms): "Enter a weight between 20 and 500 kg."
        case .invalidWeight(.pounds): "Enter a weight between 44 and 1,102 lb."
        }
    }
}
