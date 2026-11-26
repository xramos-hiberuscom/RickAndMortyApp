//
//  CharacterSearchPaginationUITests.swift
//  RickAndMortyAppUITests
//

import XCTest

/// Pagination of `CharacterSearchView`.
/// With `-UITesting` the query "gherkin" returns 45 characters (ids 100...144) in pages of 20.
final class CharacterSearchPaginationUITests: XCTestCase {

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
        // A trailing return submits the search and hides the software keyboard, so the whole list is
        // visible and scrollable. Typing it is more robust than tapping the key (hardware keyboard, layout).
        searchField.typeText(text + "\n")
    }

    /// Scrolls the results up until the row appears, or gives up after `maxSwipes`.
    @discardableResult
    private func scrollUntilVisible(_ identifier: String, maxSwipes: Int = 15) -> Bool {
        let target = element(identifier)
        for _ in 0..<maxSwipes where !target.exists {
            app.swipeUp(velocity: .slow)
        }
        return target.waitForExistence(timeout: 3)
    }

    // MARK: - Tests

    func testFirstPageIsShownWithoutScrolling() {
        search("gherkin")

        XCTAssertTrue(element("character-row-100").waitForExistence(timeout: 5))
        XCTAssertFalse(element("character-row-144").exists, "Last page must not be loaded up front")
    }

    func testScrollingToTheEndLoadsFurtherPages() {
        search("gherkin")
        XCTAssertTrue(element("character-row-100").waitForExistence(timeout: 5))

        // Rows 120... belong to page 2 and 140... to page 3: they exist only if pages were appended.
        XCTAssertTrue(scrollUntilVisible("character-row-125"), "Second page was not loaded")
        XCTAssertTrue(scrollUntilVisible("character-row-144"), "Third page was not loaded")
    }

    func testReachingTheLastPageShowsNoErrorOrRetry() {
        search("gherkin")
        XCTAssertTrue(scrollUntilVisible("character-row-144"))

        // No more pages: neither the error message nor the retry button may appear.
        XCTAssertFalse(app.staticTexts["Couldn't load more characters."].exists)
        XCTAssertFalse(element("characters-load-more-retry").exists)
        XCTAssertFalse(element("characters-loading-more").waitForExistence(timeout: 1))
    }

    func testFirstPageRemainsAfterLoadingMore() {
        search("gherkin")
        XCTAssertTrue(element("character-row-100").waitForExistence(timeout: 5))
        XCTAssertTrue(scrollUntilVisible("character-row-144"))

        // Pages are appended, not replaced: scrolling back finds the first rows again.
        for _ in 0..<20 where !element("character-row-100").isHittable {
            app.swipeDown(velocity: .slow)
        }
        XCTAssertTrue(element("character-row-100").exists)
    }

    func testResultsThatFitInOnePageDoNotShowLoadMoreIndicator() {
        search("rick")

        XCTAssertTrue(element("character-row-1").waitForExistence(timeout: 5))
        XCTAssertFalse(element("characters-loading-more").exists)
        XCTAssertFalse(element("characters-load-more-retry").exists)
    }

    func testPaginatedRowCanStillBeOpened() {
        search("gherkin")
        XCTAssertTrue(scrollUntilVisible("character-row-125"))

        element("character-row-125").tap()

        XCTAssertTrue(app.navigationBars["Gherkin 25"].waitForExistence(timeout: 5)
                      || element("character-detail").waitForExistence(timeout: 5))
    }
}
