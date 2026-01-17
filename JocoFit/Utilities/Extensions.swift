import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var relativeDescription: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Hide the view based on a condition
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let exerciseColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .yellow
    ]

    static func exerciseColor(for index: Int) -> Color {
        exerciseColors[index % exerciseColors.count]
    }

    /// Cross-platform background color (equivalent to iOS systemGray6)
    static var secondaryBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGray6)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - String Extensions

extension String {
    var sanitizedForWorkoutMode: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - Int Extensions

extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Double Extensions

extension Double {
    var formattedPercentage: String {
        String(format: "%.1f%%", self)
    }
}

// MARK: - Collection Extensions

extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
