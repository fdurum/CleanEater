import SwiftUI

struct StatusBadge: View {
    let summary: RestaurantComplianceSummary
    let excellentPointsThreshold: Int

    private enum Tier {
        case clean
        case excellent
        case violations

        var label: String {
            switch self {
            case .clean: return "Clean"
            case .excellent: return "Excellent"
            case .violations: return ""
            }
        }

        var systemImage: String {
            switch self {
            case .clean: return "checkmark.seal.fill"
            case .excellent: return "star.fill"
            case .violations: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .clean: return .green
            case .excellent: return .blue
            case .violations: return .orange
            }
        }
    }

    private var tier: Tier {
        if summary.isClean { return .clean }
        if summary.isExcellent(maxViolationPoints: excellentPointsThreshold) { return .excellent }
        return .violations
    }

    var body: some View {
        Label {
            switch tier {
            case .clean, .excellent:
                Text(tier.label)
            case .violations:
                Text("\(summary.violationCount) violation\(summary.violationCount == 1 ? "" : "s")")
            }
        } icon: {
            Image(systemName: tier.systemImage)
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(tier.color)
        .font(.callout)
    }
}
