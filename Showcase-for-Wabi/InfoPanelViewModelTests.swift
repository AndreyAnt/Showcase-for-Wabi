//
//  InfoPanelViewModelTests.swift
//  Showcase-for-Wabi
//
//  Created by Andrey Antropov on 12.02.2026.
//

import Foundation
import XCTest
@testable import ShowcaseCore

final class InfoPanelViewModelTests: XCTestCase {

    // 2020-07-01 11:00:00 UTC
    private let mockNowDate = Date(timeIntervalSince1970: 1_593_601_200)

    func test_init_withoutDetails() {
        // Given
        let badge = UIImage()
        let item = makeItem(badge: badge, timestamp: nil)

        // When
        let sut = InfoPanelViewModel(item: item, details: nil, onMediaTap: {})

        // Then
        XCTAssertEqual(sut.titleText, "Sample Title")
        XCTAssertTrue(sut.badgeImage === badge)
        XCTAssertEqual(sut.identifierText, "AAA / BBBB")
        XCTAssertEqual(sut.detailText, "Metric: 137")
        XCTAssertNil(sut.timeText)
        XCTAssertEqual(sut.dateText, "N/A")
        XCTAssertNil(sut.mediaURL)
        XCTAssertNil(sut.mediaAttribution)
    }

    func test_init_withDetails_usesTimestampForFormatting() {
        // Given
        let badge = UIImage()
        let item = makeItem(badge: badge, timestamp: mockNowDate)
        let details = mockDetails

        // When
        let sut = InfoPanelViewModel(item: item, details: details, onMediaTap: {})

        // Then
        XCTAssertEqual(sut.titleText, "Sample Title")
        XCTAssertTrue(sut.badgeImage === badge)
        XCTAssertEqual(sut.identifierText, "AAA / BBBB")
        XCTAssertEqual(sut.detailText, "Metric: 137")

        XCTAssertEqual(sut.timeText, expectedTimeString(for: mockNowDate))
        XCTAssertEqual(sut.dateText, expectedDateString(for: mockNowDate))

        XCTAssertEqual(sut.mediaURL?.absoluteString, "https://example.com/media.jpg")
        XCTAssertEqual(sut.mediaAttribution, "© Example Author")
    }

    func test_update_details_updatesFormattedStrings_andMedia() {
        // Given
        let badge = UIImage()
        let item = makeItem(badge: badge, timestamp: nil)
        let sut = InfoPanelViewModel(item: item, details: nil, onMediaTap: {})

        // When
        sut.update(details: mockDetails, at: mockNowDate)

        // Then
        XCTAssertEqual(sut.titleText, "Sample Title")
        XCTAssertTrue(sut.badgeImage === badge)
        XCTAssertEqual(sut.identifierText, "AAA / BBBB")
        XCTAssertEqual(sut.detailText, "Metric: 137")

        XCTAssertEqual(sut.timeText, expectedTimeString(for: mockNowDate))
        XCTAssertEqual(sut.dateText, expectedDateString(for: mockNowDate))

        XCTAssertEqual(sut.mediaURL?.absoluteString, "https://example.com/media.jpg")
        XCTAssertEqual(sut.mediaAttribution, "© Example Author")
    }
}

// MARK: - Test scaffolding
private extension InfoPanelViewModelTests {

    struct PanelItem {
        var titleText: String
        var badgeImage: UIImage?
        var identifierText: String
        var detailText: String?
        var timestamp: Date?
    }

    struct PanelDetails {
        var mediaURL: URL?
        var mediaAttribution: String?
    }

    func makeItem(badge: UIImage, timestamp: Date?) -> PanelItem {
        PanelItem(
            titleText: "Sample Title",
            badgeImage: badge,
            identifierText: "AAA / BBBB",
            detailText: "Metric: 137",
            timestamp: timestamp
        )
    }

    var mockDetails: PanelDetails {
        PanelDetails(
            mediaURL: URL(string: "https://example.com/media.jpg"),
            mediaAttribution: "© Example Author"
        )
    }

    func expectedTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm 'UTC'"
        return formatter.string(from: date)
    }

    func expectedDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
}
