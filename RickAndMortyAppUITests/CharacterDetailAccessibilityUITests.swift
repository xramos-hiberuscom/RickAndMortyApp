//
//  CharacterDetailAccessibilityUITests.swift
//  RickAndMortyAppUITests
//

import XCTest

/// Accessibility of `CharacterDetailView`.
/// The app is launched with `-UITesting`, which replaces the network with stubbed characters.
/// Labels are duplicated here on purpose: the UI test target cannot see the app's `CharacterDetailA11y`.
final class CharacterDetailAccessibilityUITests: XCTestCase {

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

    private func openDetail(search text: String, rowId: Int) {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found")
        searchField.tap()
        searchField.typeText(text)

        let row = app.descendants(matching: .any)["character-row-\(rowId)"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Search result not shown")
        row.tap()

        XCTAssertTrue(app.descendants(matching: .any)["character-detail"].firstMatch
            .waitForExistence(timeout: 5), "Detail screen not shown")
    }

    // MARK: - Tests

    func testCharacterImageIsExposedAsLabelledImage() {
        launch()
        openDetail(search: "rick", rowId: 1)

        let image = app.images["Photo of Rick Sanchez"]
        XCTAssertTrue(image.waitForExistence(timeout: 5), "Image should expose a descriptive label")
        XCTAssertTrue(image.isHittable || image.exists)
    }

    func testImageLabelMatchesSelectedCharacter() {
        launch()
        openDetail(search: "morty", rowId: 2)

        XCTAssertTrue(app.images["Photo of Morty Smith"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["Photo of Rick Sanchez"].exists)
    }

    func testInformationRowsAreReadAsSingleElements() {
        launch()
        openDetail(search: "rick", rowId: 1)

        // Label and value are announced together, not as two separate stops.
        XCTAssertTrue(app.staticTexts["Status, Alive"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Species, Human"].exists)
        XCTAssertTrue(app.staticTexts["Gender, Male"].exists)
    }

    func testStatusIndicatorIsNotExposedToAccessibility() {
        launch()
        openDetail(search: "rick", rowId: 1)
        XCTAssertTrue(app.staticTexts["Status, Alive"].waitForExistence(timeout: 5))

        // The coloured circle is decorative: the status is conveyed by text, not by colour alone.
        let detail = app.descendants(matching: .any)["character-detail"].firstMatch
        XCTAssertEqual(detail.images.matching(NSPredicate(format: "label != 'Photo of Rick Sanchez'")).count, 0,
                       "Only the character photo should be exposed as an image")
    }

    func testBackButtonIsAccessible() {
        launch()
        openDetail(search: "rick", rowId: 1)

        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertFalse(back.label.isEmpty, "Back button needs a label")
        XCTAssertTrue(back.isHittable)
    }

    func testNavigationTitleIsExposed() {
        launch()
        openDetail(search: "rick", rowId: 1)

        XCTAssertTrue(app.navigationBars["Rick Sanchez"].waitForExistence(timeout: 5))
    }

    func testContentRemainsAvailableWithLargestAccessibilityTextSize() {
        launch(extraArguments: ["-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"])
        openDetail(search: "rick", rowId: 1)

        XCTAssertTrue(app.images["Photo of Rick Sanchez"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Status, Alive"].exists)
        XCTAssertTrue(app.staticTexts["Species, Human"].exists)
        XCTAssertTrue(app.staticTexts["Gender, Male"].exists)
    }

    func testAccessibilityAudit() throws {
        launch()
        openDetail(search: "rick", rowId: 1)
        XCTAssertTrue(app.staticTexts["Status, Alive"].waitForExistence(timeout: 5))

        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .trait])
    }
}
