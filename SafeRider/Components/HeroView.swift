//
//  HeroView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 19/09/2026.
//

import SwiftUI

struct HeroView: View {

    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            ZStack {

                // MARK: - Background

                SafeRiderTheme.background
                    .ignoresSafeArea()

                ScrollView(
                    showsIndicators: false
                ) {
                    VStack(
                        spacing: 0
                    ) {

                        // MARK: - Branding

                        VStack(
                            spacing: 8
                        ) {
                            Image("heropage")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: 230,
                                    height: 90
                                )

                            Text(
                                "SAFER JOURNEYS  •  BRIGHTER TOMORROWS"
                            )
                            .font(
                                .system(
                                    size: 10,
                                    weight: .semibold
                                )
                            )
                            .tracking(2)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )
                        }
                        .padding(.top, 36)

                        // MARK: - Hero Illustration

                        ZStack {

                            // Soft orange glow

                            Circle()
                                .fill(
                                    SafeRiderTheme.orange
                                        .opacity(0.16)
                                )
                                .frame(
                                    width: 280,
                                    height: 280
                                )
                                .blur(radius: 2)

                            // Shield

                            Image(
                                systemName:
                                    "shield.fill"
                            )
                            .font(
                                .system(
                                    size: 230,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                SafeRiderTheme.orange
                                    .opacity(0.12)
                            )

                            // Main image

                            Image(
                                systemName:
                                    "figure.2.and.child.holdinghands"
                            )
                            .font(
                                .system(
                                    size: 105,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 300)
                        .padding(.top, 20)

                        // MARK: - Hero Message

                        VStack(
                            spacing: 10
                        ) {

                            Text("Together for")
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )

                            Text("a Safer Tomorrow")
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    SafeRiderTheme.orange
                                )

                            Text(
                                "Real-time school transportation tracking\n"
                                + "for a safer, more connected community."
                            )
                            .font(
                                .system(
                                    size: 16,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)

                        // MARK: - Feature Cards

                        HStack(
                            spacing: 10
                        ) {

                            heroFeature(
                                icon: "location.fill",
                                title: "Live Tracking"
                            )

                            heroFeature(
                                icon: "car.fill",
                                title: "Transportation"
                            )

                            heroFeature(
                                icon: "person.2.fill",
                                title: "Connected"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                        // MARK: - Get Started

                        Button {

                            showLogin = true

                        } label: {

                            HStack(
                                spacing: 12
                            ) {

                                Text("Get Started")
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .bold
                                        )
                                    )

                                Image(
                                    systemName:
                                        "arrow.right"
                                )
                                .font(
                                    .system(
                                        size: 17,
                                        weight: .bold
                                    )
                                )
                            }
                            .foregroundStyle(.white)
                            .frame(
                                maxWidth: .infinity
                            )
                            .frame(height: 56)
                            .background(
                                SafeRiderTheme.orange
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18
                                )
                            )
                            .shadow(
                                color:
                                    SafeRiderTheme.orange
                                        .opacity(0.25),
                                radius: 12,
                                y: 6
                            )
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 30)

                        // MARK: - Login

                        Button {

                            showLogin = true

                        } label: {

                            Text(
                                "Already have an account? "
                                + "Log in"
                            )
                            .font(
                                .system(
                                    size: 14,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 35)
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                isPresented: $showLogin
            ) {
                LoginView()
            }
        }
    }

    // MARK: - Feature Card

    private func heroFeature(
        icon: String,
        title: String
    ) -> some View {

        VStack(
            spacing: 9
        ) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    SafeRiderTheme.orange
                        .opacity(0.12)
                )
                .clipShape(
                    Circle()
                )

            Text(title)
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 92)
        .padding(.horizontal, 4)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                SafeRiderTheme.orange
                    .opacity(0.08),
                lineWidth: 1
            )
        )
    }
}

#Preview {
    HeroView()
}
