import SwiftUI

struct StatusBadge: View {
    let summary: RestaurantComplianceSummary

    var body: some View {
        Label {
            Text(summary.isClean ? "Clean" : "\(summary.violationCount) violation\(summary.violationCount == 1 ? "" : "s")")
        } icon: {
            Image(systemName: summary.isClean ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(summary.isClean ? Color.green : Color.orange)
        .font(.callout)
    }
}
