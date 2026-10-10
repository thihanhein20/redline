import Foundation

/// Web links: developer site, feedback form (no account needed) and pre-filled GitHub bug reports.
enum FeedbackLinks {
    static let repository = URL(string: "https://github.com/thihanhein20/redline")!
    static let developer = URL(string: "https://www.hanindustries.net/")!
    static let sendFeedback = URL(string: "https://forms.gle/Gi6vb9GKv4Ars1xc8")!

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
