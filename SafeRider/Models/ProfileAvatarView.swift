import SwiftUI

struct ProfileAvatarView: View {
    let name: String
    let photoURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let photoURL,
               !photoURL.isEmpty,
               let url = URL(string: photoURL) {

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
                            .tint(.orange)

                    @unknown default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .background(Color.orange.opacity(0.10))
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    Color.orange.opacity(0.30),
                    lineWidth: 1
                )
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.15))

            Text(initials)
                .font(
                    .system(
                        size: size * 0.35,
                        weight: .bold
                    )
                )
                .foregroundStyle(.orange)
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
