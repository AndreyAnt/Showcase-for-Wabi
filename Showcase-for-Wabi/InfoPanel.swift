//
//  InfoPanel.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import Foundation
import SwiftUI

/// Panel with a title + optional trailing photo, then two metadata rows.
/// Uses measured title height to adjust corner rounding and media alignment.
struct InfoPanel: View {
    @ObservedObject var viewModel: InfoPanelViewModel
    @State private var titleSize: CGSize = .zero

    private enum Layout {
        static let titleTopPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8

        static let mediaSize = CGSize(width: 132, height: 72)
        static let maxTitleLines = 2
        static let cornerRadius: CGFloat = 12
        static let dividerHeight: CGFloat = 1
    }

    private var titleLineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .headline).lineHeight
    }

    private var titleLineCount: Int {
        guard titleLineHeight > 0 else { return 1 }
        return max(1, Int((titleSize.height / titleLineHeight).rounded(.toNearestOrAwayFromZero)))
    }

    private var mediaTopCorners: UIRectCorner {
        titleLineCount <= 1 ? [.topLeft, .topRight] : [.topRight]
    }

    private var titleTopCorners: UIRectCorner {
        viewModel.mediaURL == nil ? [.topLeft, .topRight] : [.topLeft]
    }

    private var mediaVerticalOffset: CGFloat {
        if titleLineCount > 1 {
            let titleBlockHeight = titleSize.height + Layout.titleTopPadding + Layout.verticalPadding
            return Layout.mediaSize.height - titleBlockHeight
        } else {
            return 14
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            titleAndMediaRow
                .zIndex(1)

            identifierRow

            metadataRow
        }
        .overlay(alignment: .bottom) {
            // Using overlay for the divider avoids redraw artifacts during interactive updates.
            Color(uiColor: .separator)
                .frame(height: Layout.dividerHeight / UIScreen.main.scale)
        }
    }

    private var titleAndMediaRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(viewModel.titleText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(Layout.maxTitleLines)
                .foregroundStyle(.primary)
                .readSize { titleSize = $0 }
                .padding(.init(
                    top: Layout.titleTopPadding,
                    leading: Layout.horizontalPadding,
                    bottom: Layout.verticalPadding,
                    trailing: viewModel.mediaURL != nil ? 10 : Layout.horizontalPadding
                ))
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(Layout.cornerRadius, corners: titleTopCorners)

            if let url = viewModel.mediaURL {
                RemoteMediaView(
                    url: url,
                    size: Layout.mediaSize,
                    corners: mediaTopCorners,
                    attribution: viewModel.mediaAttribution
                )
                .offset(y: mediaVerticalOffset)
                .onTapGesture(perform: viewModel.onMediaTap)
            }
        }
    }

    private var identifierRow: some View {
        HStack(spacing: 8) {
            if let badge = viewModel.badgeImage {
                Image(uiImage: badge)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            }

            Text(viewModel.identifierText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.init(
            top: 0,
            leading: Layout.horizontalPadding,
            bottom: Layout.verticalPadding,
            trailing: Layout.horizontalPadding
        ))
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var metadataRow: some View {
        HStack(spacing: 10) {
            if let timeText = viewModel.timeText {
                Text(timeText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Divider()
                    .frame(height: 16)
            }

            Text(viewModel.dateText)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let detail = viewModel.detailText {
                Divider()
                    .frame(height: 16)

                Text(detail)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .font(.footnote)
        .padding(.init(
            top: 0,
            leading: Layout.horizontalPadding,
            bottom: Layout.verticalPadding,
            trailing: Layout.horizontalPadding
        ))
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

// MARK: - Remote media
private struct RemoteMediaView: View {
    let url: URL
    let size: CGSize
    let corners: UIRectCorner
    let attribution: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color(uiColor: .tertiarySystemFill)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .cornerRadius(12, corners: corners)

            if let attribution, !attribution.isEmpty {
                Text(attribution)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(6)
            }
        }
    }
}

// MARK: - Helpers
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
