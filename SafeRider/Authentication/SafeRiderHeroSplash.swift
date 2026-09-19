//
//  SafeRiderHeroSplash.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 19/09/2026.
//

import SwiftUI

struct SafeRiderHeroSplash: View {

    let onFinished: () -> Void

    @State private var imageScale: CGFloat = 0.88
    @State private var imageOpacity: Double = 0
    @State private var contentOffset: CGFloat = 35
    @State private var contentOpacity: Double = 0

    var body: some View {

        ZStack {

            SafeRiderTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // MARK: - Hero Artwork

                Image("heropage")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: 430
                    )
                    .padding(.horizontal, 20)
                    .scaleEffect(imageScale)
                    .opacity(imageOpacity)

                Spacer()

                // MARK: - Branding

                VStack(spacing: 8) {

                    Text(
                        "SAFER JOURNEYS"
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                    Text(
                        "BRIGHTER TOMORROWS"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )

                    Text(
                        "Safe transportation starts with trust."
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .padding(.top, 6)
                }
                .offset(y: contentOffset)
                .opacity(contentOpacity)

                Spacer()
                    .frame(height: 45)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {

        // Artwork enters

        withAnimation(
            .easeOut(duration: 0.75)
        ) {
            imageScale = 1.0
            imageOpacity = 1.0
        }

        // Text follows

        withAnimation(
            .easeOut(duration: 0.65)
                .delay(0.35)
        ) {
            contentOffset = 0
            contentOpacity = 1.0
        }

        // Finish

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.4
        ) {

            withAnimation(
                .easeInOut(duration: 0.45)
            ) {
                imageOpacity = 0
                contentOpacity = 0
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.45
            ) {
                onFinished()
            }
        }
    }
}

#Preview {
    SafeRiderHeroSplash {
        print("Hero finished")
    }
}
