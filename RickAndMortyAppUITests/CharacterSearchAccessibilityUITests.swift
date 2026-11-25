//
//  CharacterSearchAccessibilityUITests.swift
//  RickAndMortyAppUITests
//

import XCTest

/// Accessibility of `CharacterSearchView`.
/// The app is launched with `-UITesting`, which replaces the network with stubbed characters.
/// Labels are duplicated here on purpose: the UI test target cannot see the app's `CharacterSearchA11y`.
final class CharacterSearchAccessibilityUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launch(extraArguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"] + extraArguments
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func search(_ text: String) {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found")
        searchField.tap()
        searchField.typeText(text)
    }

    // MARK: - Tests

    func testSearchFieldIsAccessible() {
        launch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertFalse(searchField.label.isEmpty, "Search field needs a label")
        XCTAssertTrue(searchField.isHittable)
    }

    func testInitialStateExplainsHowToSearch() {
        launch()

        XCTAssertTrue(app.navigationBars["Characters"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Search characters"].exists)
        XCTAssertTrue(app.staticTexts["Type a name to find Rick and Morty characters."].exists)
    }

    func testResultRowIsReadAsSingleElement() {
        launch()
        search("rick")

        let row = element("character-row-1")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Search result not shown")

        // Name and species are announced together, not as separate stops.
        XCTAssertTrue(row.label.contains("Rick Sanchez"), "Row label was: \(row.label)")
        XCTAssertTrue(row.label.contains("Human"), "Row label was: \(row.label)")
    }

    func testResultRowIsActionable() {
        launch()
        search("rick")

        let row = element("character-row-1")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.isHittable)
        XCTAssertTrue(row.isEnabled)
    }

    func testRowThumbnailIsNotExposedToAccessibility() {
        launch()
        search("rick")
        XCTAssertTrue(element("character-row-1").waitForExistence(timeout: 5))

        // The thumbnail is decorative: the name already identifies the character.
        XCTAssertEqual(app.images.matching(NSPredicate(format: "label CONTAINS 'Rick'")).count, 0)
    }

    func testEachResultHasItsOwnLabel() {
        launch()
        search("i")   // Matches Rick Sanchez, Morty Smith and Birdperson.

        let rick = element("character-row-1")
        let morty = element("character-row-2")
        XCTAssertTrue(rick.waitForExistence(timeout: 5))
        XCTAssertTrue(morty.exists)
        XCTAssertNotEqual(rick.label, morty.label)
        XCTAssertTrue(morty.label.contains("Morty Smith"), "Row label was: \(morty.label)")
    }

    func testNoResultsStateIsExposed() {
        launch()
        search("zzz")

        XCTAssertTrue(app.staticTexts["No Results for “zzz”"].waitForExistence(timeout: 5)
                      || app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'No Results'")).firstMatch.exists)
    }

    func testResultsRemainAvailableWithLargestAccessibilityTextSize() {
        launch(extraArguments: ["-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"])
        search("rick")

        let row = element("character-row-1")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Rick Sanchez"))
    }

    func testAccessibilityAudit() throws {
        launch()
        search("rick")
        XCTAssertTrue(element("character-row-1").waitForExistence(timeout: 5))

        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .trait]) { issue in
            // The system search field's "Clear text" button is 20pt; it is UIKit's, not ours.
            issue.element?.label == "Clear text"
        }
    }
}
