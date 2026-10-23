import Foundation
import Testing
@testable import Redline

struct CommandLineInstallerTests {
    /// The installed script must pass every argument through unchanged, spaces included.
    @Test func scriptForwardsArgumentsUnchanged() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("redline-script-test")
        try CommandLineInstaller.script(executable: "/usr/bin/printf").write(to: url, atomically: true, encoding: .utf8)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [url.path, "[%s]", "run", "./My Game.app"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        #expect(output == "[run][./My Game.app]")
    }
}
