import XCTest

final class SchoolDiaryUITests: XCTestCase {
    private var app: XCUIApplication!
    private var shotDir: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        shotDir = ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: shotDir, withIntermediateDirectories: true)
    }

    private func shot(_ name: String) {
        let data = app.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(shotDir!)/\(name).png"))
    }

    func testWalkthrough() throws {
        app.launch()
        Thread.sleep(forTimeInterval: 2)
        shot("01-login")

        if app.textFields["loginName"].exists {
            let nameField = app.textFields["loginName"]
            nameField.tap()
            nameField.typeText("Denys")
            let passField = app.secureTextFields["loginPass"]
            passField.tap()
            passField.typeText("testpass123")
            app.buttons["signIn"].tap()
            Thread.sleep(forTimeInterval: 5)
        }
        shot("02-homework")

        if app.tabBars.buttons["Уроки"].exists {
            app.tabBars.buttons["Уроки"].tap()
            Thread.sleep(forTimeInterval: 1)
            shot("03-schedule")
        }

        if app.tabBars.buttons["Чат"].exists {
            app.tabBars.buttons["Чат"].tap()
            Thread.sleep(forTimeInterval: 2)
            shot("04-chat-list")
        }

        if app.buttons["generalChat"].exists {
            app.buttons["generalChat"].tap()
            Thread.sleep(forTimeInterval: 2)
            shot("05-general-chat")
            let input = app.textFields["messageInput"]
            if input.exists {
                input.tap()
                input.typeText("UI test message from simulator")
                shot("06-message-typed")
                if app.buttons["sendButton"].exists {
                    app.buttons["sendButton"].tap()
                    Thread.sleep(forTimeInterval: 2)
                    shot("07-message-sent")
                }
            }
        }

        // повертаємося на список чатів і відкриваємо профіль
        if app.navigationBars.buttons["chevron.left"].exists {
            app.navigationBars.buttons["chevron.left"].tap()
            Thread.sleep(forTimeInterval: 1)
        }
        if app.buttons["profileButton"].exists {
            app.buttons["profileButton"].tap()
            Thread.sleep(forTimeInterval: 1)
            shot("08-profile")
        }
    }
}
