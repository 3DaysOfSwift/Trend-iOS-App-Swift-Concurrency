// © www.3DaysOfSwiftConcurrency.com. All rights reserved.

import Foundation

enum WeightCSVDecoder {
    static func decode(_ text: String, timeZone: TimeZone) throws -> WeightImportDocument {
        let rows = try CSVRows.decode(text)
        guard let first = rows.first else { throw WeightImportError.invalid("This CSV is empty.") }
        let isDiary = first.first?.lowercased() == "units"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.isLenient = false
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let iso = ISO8601DateFormatter()
        let fractionalISO = ISO8601DateFormatter()
        fractionalISO.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func date(_ text: String) -> Date? {
            if text.count == 19, let date = formatter.date(from: text), formatter.string(from: date) == text { return date }
            if let date = fractionalISO.date(from: text) ?? iso.date(from: text) { return date }
            if text.count == 10, let date = formatter.date(from: text + " 12:00:00"),
               formatter.string(from: date) == text + " 12:00:00" { return date }
            return nil
        }
        func kilograms(_ text: String, unit: String) -> Double? {
            guard let value = Double(text.replacingOccurrences(of: ",", with: ".")), value.isFinite else { return nil }
            switch unit.lowercased() {
            case "kg", "kilograms": return value
            case "lb", "lbs", "pounds": return value * 0.45359237
            default: return nil
            }
        }

        var entries: [WeightEntry] = []
        if isDiary {
            guard first.count == 2, ["kg", "lb", "lbs", "kilograms", "pounds"].contains(first[1].lowercased()) else {
                throw WeightImportError.invalid("This Weight Diary unit is not supported. Export in kilograms or pounds.")
            }
            let metadata = Set(["goal", "height", "birthdate", "gender"])
            for (index, row) in rows.dropFirst().enumerated() {
                try Task.checkCancellation()
                if metadata.contains(row[0].lowercased()) { continue }
                guard (2...4).contains(row.count), let timestamp = date(row[0]),
                      let weight = kilograms(row[1], unit: first[1]) else {
                    throw WeightImportError.invalid("CSV record \(index + 2) is not a supported Weight Diary entry. Nothing has been changed.")
                }
                entries.append(WeightEntry(date: timestamp, kilograms: weight, note: row.count == 4 ? row[3] : ""))
            }
        } else {
            let headers = first.map { $0.lowercased() }
            guard Set(headers).count == headers.count,
                  let dateIndex = headers.firstIndex(of: "date"),
                  let weightIndex = headers.firstIndex(of: "weight"),
                  let unitIndex = headers.firstIndex(of: "unit") else {
                throw WeightImportError.invalid("CSV format not recognized. Use Weight Diary CSV, or columns date,weight,unit,note with kg or lb units.")
            }
            let noteIndex = headers.firstIndex(of: "note")
            for (index, row) in rows.dropFirst().enumerated() {
                try Task.checkCancellation()
                guard row.count == headers.count, let timestamp = date(row[dateIndex]),
                      let weight = kilograms(row[weightIndex], unit: row[unitIndex]) else {
                    throw WeightImportError.invalid("CSV record \(index + 2) has an invalid date, weight or unit. Use YYYY-MM-DD, YYYY-MM-DD HH:mm:ss or an ISO 8601 timestamp.")
                }
                entries.append(WeightEntry(date: timestamp, kilograms: weight, note: noteIndex.map { row[$0] } ?? ""))
            }
        }
        return WeightImportDocument(source: isDiary ? "Weight Diary CSV" : "Weight CSV", entries: entries,
            explanation: "Dates without a time zone use \(timeZone.identifier). Date-only records use noon. Only weight, date and notes are imported; profile, goal and body-fat data are not changed or imported.")
    }
}

/// RFC-style quoted fields, doubled quotes and embedded newlines. Reject broken
/// quoting rather than guessing columns and importing the wrong measurements.
private enum CSVRows {
    static func decode(_ text: String) throws -> [[String]] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var closedQuote = false
        func finishField() {
            row.append(field.trimmingCharacters(in: .whitespaces))
            field = ""
            closedQuote = false
        }
        func finishRow() throws {
            finishField()
            if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
            row = []
            if rows.count > 50_010 { throw WeightImportError.invalid("Import up to 50,000 entries at a time.") }
        }
        for character in normalized {
            if quoted {
                if character == "\"" {
                    quoted = false
                    closedQuote = true
                } else { field.append(character) }
            } else if character == "\"", closedQuote {
                field.append("\"")
                quoted = true
                closedQuote = false
            } else if character == "," {
                finishField()
            } else if character == "\n" {
                try finishRow()
            } else if character == "\"", field.isEmpty, !closedQuote {
                quoted = true
            } else if closedQuote || character == "\"" {
                throw WeightImportError.invalid("The CSV contains malformed quotation marks. Nothing has been changed.")
            } else { field.append(character) }
        }
        guard !quoted else { throw WeightImportError.invalid("The CSV ends inside a quoted field. Nothing has been changed.") }
        if !field.isEmpty || !row.isEmpty || closedQuote { try finishRow() }
        return rows
    }
}
