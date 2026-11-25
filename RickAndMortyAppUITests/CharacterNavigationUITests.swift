//
//  CharacterNavigationUITests.swift
//  RickAndMortyAppUITests
//

import XCTest

/// Navigation from `CharacterSearchView` to `CharacterDetailView`.
/// The app is launched with `-UITesting`, which replaces the network with stubbed characters.
final class CharacterNavigationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    // MARK: - Helpers

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

    func testSearchScreenIsShownOnLaunch() {
        XCTAssertTrue(app.navigationBars["Characters"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("character-detail").exists)
    }

    func testTappingResultNavigatesToCharacterDetail() {
        search("rick")

        let row = element("character-row-1")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Search result not shown")
        row.tap()

        XCTAssertTrue(element("character-detail").waitForExistence(timeout: 5), "Detail screen not shown")
        XCTAssertTrue(app.navigationBars["Rick Sanchez"].waitForExistence(timeout: 5))
        // `LabeledContent` exposes label and value as a single element.
        XCTAssertTrue(app.staticTexts["Status, Alive"].exists)
        XCTAssertTrue(app.staticTexts["Species, Human"].exists)
        XCTAssertTrue(app.staticTexts["Gender, Male"].exists)
    }

    func testDetailShowsTheSelectedCharacter() {
        search("morty")

        let row = element("character-row-2")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.navigationBars["Morty Smith"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Rick Sanchez"].exists)
    }

    func testBackReturnsToSearchResults() {
        search("rick")

        let row = element("character-row-1")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(element("character-detail").waitForExistence(timeout: 5))

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(element("character-row-1").waitForExistence(timeout: 5), "Results should be kept after going back")
        XCTAssertFalse(element("character-detail").exists)
    }
}
