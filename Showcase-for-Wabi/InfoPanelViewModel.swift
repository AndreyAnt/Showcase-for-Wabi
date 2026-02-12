//
//  InfoPanelViewModel.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import Foundation
import UIKit
import SwiftUI

@MainActor
final class InfoPanelViewModel: ObservableObject {

    // MARK: - Non-updating properties
    let titleText: String
    let badgeImage: UIImage?
    let identifierText: String
    let detailText: String?
    let onMediaTap: () -> Void

    // MARK: - Updating properties
    @Published private(set) var timeText: String?
    @Published private(set) var dateText: String
    @Published private(set) var mediaURL: URL?
    @Published private(set) var mediaAttribution: String?

    init(
        titleText: String,
        badgeImage: UIImage?,
        identifierText: String,
        detailText: String?,
        timestamp: Date,
        mediaURL: URL? = nil,
        mediaAttribution: String? = nil,
        onMediaTap: @escaping () -> Void
    ) {
        self.titleText = titleText
        self.badgeImage = badgeImage
        self.identifierText = identifierText
        self.detailText = detailText
        self.onMediaTap = onMediaTap

        self.timeText = nil
        self.dateText = timestamp.formatted(date: .abbreviated, time: .omitted)
        self.mediaURL = mediaURL
        self.mediaAttribution = mediaAttribution

        update(timestamp: timestamp, mediaURL: mediaURL, mediaAttribution: mediaAttribution, showsTime: true)
    }

    func update(
        timestamp: Date,
        mediaURL: URL?,
        mediaAttribution: String?,
        showsTime: Bool
    ) {
        timeText = showsTime ? timestamp.formatted(date: .omitted, time: .shortened) : nil
        dateText = timestamp.formatted(date: .abbreviated, time: .omitted)
        self.mediaURL = mediaURL
        self.mediaAttribution = mediaAttribution
    }
}
