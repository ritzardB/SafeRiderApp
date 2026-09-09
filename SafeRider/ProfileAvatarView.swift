//
//  ProfileAvatarView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 07/09/2026.
//

import SwiftUI

struct ProfileAvatarView: View {
    let name: String
    let photoURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let photoURL,
               let url = URL(string: photoURL),
               !photoURL.isEmpty {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        initialsView

                    case .empty:
                        ProgressView()

                    @unknown default:
                        initialsView
                    }
                }

            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.primary.opacity(0.15), lineWidth: 1)
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.15))

            Text(initials)
                .font(.system(
                    size: size * 0.35,
                    weight: .bold
                ))
                .foregroundStyle(.blue)
        }
    }

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
                .uppercased()
        }

        return String(name.prefix(2)).uppercased()
    }
}
