// Source for mod.dll (payload #25) and lib.dll (payload #42).
// Benign PoC assembly — just proves reflective load reached execution.
// Compile on a Windows host that has .NET Framework (csc.exe) or the SDK:
//
//   csc.exe /target:library /out:mod.dll PurpleTestModule.cs
//   copy mod.dll lib.dll
//
// mod.dll goes on the HOSTING server (served over HTTP for payload #25,
// which downloads it before loading).
// lib.dll goes directly into C:\purpletest\stage\ on the TARGET host
// (payload #42 reads local bytes, no network involved).

using System;
using System.IO;

namespace PurpleTest
{
    public class Module
    {
        // Runs automatically on load in some reflection patterns; also
        // callable explicitly if you extend the test payload to invoke it.
        public static void Announce()
        {
            string evidence = $"{DateTime.Now:o} | PurpleTestModule loaded on {Environment.MachineName} as {Environment.UserName}";
            File.AppendAllText(@"C:\purpletest\evidence\reflective_load.log", evidence + Environment.NewLine);
        }

        static Module()
        {
            // Static constructor fires the moment the type is first touched
            // by the CLR, which happens as soon as Assembly.Load/LoadFile
            // brings the type into scope — good signal that the reflective
            // load actually completed and initialized the type.
            Announce();
        }
    }
}
