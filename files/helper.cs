// Staged file for T1059 test #43 (Add-Type inline compilation).
// This file is NOT pre-compiled — Add-Type compiles it on the fly at
// execution time via csc.exe, which is the whole point of the test
// (watch for a csc.exe child process spawned by powershell.exe).

using System;
using System.IO;

namespace Helper
{
    // Matches the PowerShell reference [Helper.Main]::Go() — namespace
    // "Helper", class "Main" (PowerShell type accelerators use the dotted
    // namespace.class form, not the C# nested-class form).
    public class Main
    {
        public static void Go()
        {
            string evidence = $"{DateTime.Now:o} | helper.cs Add-Type compiled and ran on {Environment.MachineName} as {Environment.UserName}";
            File.AppendAllText(@"C:\purpletest\evidence\addtype_compile.log", evidence + Environment.NewLine);
            Console.WriteLine("helper.cs executed via Add-Type");
        }
    }
}
