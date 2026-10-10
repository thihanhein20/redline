import Foundation

/// Pre-filled GitHub issue pages for feedback and bug reports.
enum FeedbackLinks {
    static let repository = URL(string: "https://github.com/thihanhein20/redline")!

    static var sendFeedback: URL {
        newIssue(label: "enhancement", body: """
            **What would make Redline better?**


            ---
            \(SystemInfo.summary)
            """)
    }

    static var reportIssue: URL {
        newIssue(label: "bug", body: """
            **What happened?**


            **Steps to reproduce**
            1.

            **Game (name, App Store / Steam / own build)**


            ---
            \(SystemInfo.summary)
            """)
    }

    static func newIssue(label: String, body: String) -> URL {
        var components = URLComponents(url: repository.appendingPathComponent("issues/new"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "labels", value: label), URLQueryItem(name: "body", value: body)]
        return components.url!
    }
}
