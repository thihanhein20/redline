using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace HanIndustries.Redline.Editor
{
    /// <summary>Finds the Redline command and runs a built game through it, logging stats to a CSV file.</summary>
    static class RedlineLauncher
    {
        static readonly string[] Candidates =
        {
            "/usr/local/bin/redline",                          // installed from Redline's settings
            "/Applications/Redline.app/Contents/MacOS/Redline" // works even without the Terminal command
        };

        public static string FindCommand() => Candidates.FirstOrDefault(File.Exists);

        /// <returns>Full path of the CSV log for this run. A .txt with the game's output and the
        /// session summary is written next to it.</returns>
        public static string Run(string command, string appPath, string logFolder)
        {
            Directory.CreateDirectory(logFolder);
            var game = Path.GetFullPath(appPath);
            var baseName = Path.GetFullPath(Path.Combine(logFolder,
                $"{Path.GetFileNameWithoutExtension(appPath)}_{DateTime.Now:yyyyMMdd_HHmmss}"));
            var log = baseName + ".csv";

            // Run via a tiny shell script so paths with spaces need no argument-escaping rules.
            var script = Path.GetTempFileName();
            File.WriteAllText(script, $"exec {Quote(command)} run {Quote(game)} > {Quote(log)} 2> {Quote(baseName + ".txt")}\n");
            Process.Start(new ProcessStartInfo("/bin/sh", script) { UseShellExecute = false, CreateNoWindow = true });
            return log;
        }

        static string Quote(string value) => "'" + value.Replace("'", "'\\''") + "'";
    }
}
