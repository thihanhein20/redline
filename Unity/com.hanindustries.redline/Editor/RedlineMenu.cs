using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace HanIndustries.Redline.Editor
{
    /// <summary>Unity menu: build a macOS development build and run it through Redline.</summary>
    static class RedlineMenu
    {
        const string BuildFolder = "Builds/Redline";
        const string LogFolder = BuildFolder + "/Logs";
        const string DownloadUrl = "https://github.com/thihanhein20/redline/releases";

        static string AppPath => Path.Combine(BuildFolder, PlayerSettings.productName + ".app");

        [MenuItem("Redline/Build and Run with Redline", priority = 1)]
        static void BuildAndRun()
        {
            var command = FindCommandOrExplain();
            if (command == null || !Build()) return;
            Launch(command);
        }

        [MenuItem("Redline/Run Last Build with Redline", priority = 2)]
        static void RunLastBuild()
        {
            var command = FindCommandOrExplain();
            if (command == null) return;
            if (!Directory.Exists(AppPath))
            {
                EditorUtility.DisplayDialog("Redline", "No build yet. Use Redline → Build and Run with Redline first.", "OK");
                return;
            }
            Launch(command);
        }

        [MenuItem("Redline/Open Logs Folder", priority = 20)]
        static void OpenLogs()
        {
            Directory.CreateDirectory(LogFolder);
            EditorUtility.RevealInFinder(Path.GetFullPath(LogFolder) + "/");
        }

        [MenuItem("Redline/Build and Run with Redline", true)]
        [MenuItem("Redline/Run Last Build with Redline", true)]
        static bool IsMacEditor() => Application.platform == RuntimePlatform.OSXEditor;

        static bool Build()
        {
            var scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
            if (scenes.Length == 0)
            {
                EditorUtility.DisplayDialog("Redline", "Add at least one scene in File → Build Profiles first.", "OK");
                return false;
            }
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = AppPath,
                target = BuildTarget.StandaloneOSX,
                options = BuildOptions.Development,
            });
            if (report.summary.result == BuildResult.Succeeded) return true;
            Debug.LogError($"Redline: build failed ({report.summary.result}). See the Console for details.");
            return false;
        }

        static void Launch(string command)
        {
            var log = RedlineLauncher.Run(command, AppPath, LogFolder);
            Debug.Log($"Redline: running {AppPath}. Stats are logged to {log}");
        }

        static string FindCommandOrExplain()
        {
            var command = RedlineLauncher.FindCommand();
            if (command != null) return command;
            if (EditorUtility.DisplayDialog("Redline not found",
                    "Install Redline in your Applications folder first.", "Download Redline", "Cancel"))
                Application.OpenURL(DownloadUrl);
            return null;
        }
    }
}
