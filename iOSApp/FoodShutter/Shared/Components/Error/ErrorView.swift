//
//  ErrorView.swift
//  FoodShutter
//
//  Error display view with retry functionality
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .padding(.bottom, 10)

            // Error title
            Text("Analysis Failed")
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(.mainText)

            // Error message
            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineLimit(5)

            // Retry button
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(.body, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue)
                )
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    struct PreviewError: Error, LocalizedError {
        var errorDescription: String? {
            "Failed to connect to the server. Please check your internet connection and try again."
        }
    }

    return ErrorView(error: PreviewError()) {
        print("Retry tapped")
    }
}
