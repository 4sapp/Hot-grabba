using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

// Minimal LoadLibrary-based module injector for a controlled lab demo.
// Usage: Injector.exe <pid> <full-path-to-dll>
// Opens the target process, allocates memory for the DLL path string,
// and calls CreateRemoteThread on LoadLibraryA so the DLL is loaded
// inside the target. Lab use only.

class Injector
{
    const uint PROCESS_CREATE_THREAD = 0x0002;
    const uint PROCESS_QUERY_INFORMATION = 0x0400;
    const uint PROCESS_VM_OPERATION = 0x0008;
    const uint PROCESS_VM_WRITE = 0x0020;
    const uint PROCESS_VM_READ = 0x0010;
    const uint MEM_COMMIT = 0x1000;
    const uint MEM_RESERVE = 0x2000;
    const uint PAGE_READWRITE = 0x04;

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr addr,
        UIntPtr size, uint allocType, uint protect);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr baseAddr,
        byte[] buffer, UIntPtr size, out UIntPtr written);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetModuleHandle(string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr attrs,
        UIntPtr stackSize, IntPtr startAddr, IntPtr param, uint flags, out uint tid);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern uint WaitForSingleObject(IntPtr handle, uint ms);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr handle);

    static int Main(string[] args)
    {
        if (args.Length != 2)
        {
            Console.WriteLine("usage: Injector.exe <pid> <dll-path>");
            return 2;
        }
        int pid = int.Parse(args[0]);
        string dll = args[1];

        IntPtr h = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION |
            PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, pid);
        if (h == IntPtr.Zero) { Console.WriteLine("OpenProcess failed: " + Marshal.GetLastWin32Error()); return 3; }

        byte[] pathBytes = Encoding.ASCII.GetBytes(dll + "\0");
        IntPtr remote = VirtualAllocEx(h, IntPtr.Zero, (UIntPtr)pathBytes.Length,
            MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        if (remote == IntPtr.Zero) { Console.WriteLine("VirtualAllocEx failed: " + Marshal.GetLastWin32Error()); return 4; }

        UIntPtr written;
        if (!WriteProcessMemory(h, remote, pathBytes, (UIntPtr)pathBytes.Length, out written))
        { Console.WriteLine("WriteProcessMemory failed: " + Marshal.GetLastWin32Error()); return 5; }

        IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
        uint tid;
        IntPtr th = CreateRemoteThread(h, IntPtr.Zero, UIntPtr.Zero, loadLib, remote, 0, out tid);
        if (th == IntPtr.Zero) { Console.WriteLine("CreateRemoteThread failed: " + Marshal.GetLastWin32Error()); return 6; }

        WaitForSingleObject(th, 10000);
        CloseHandle(th);
        CloseHandle(h);
        Console.WriteLine("OK: requested LoadLibrary(\"" + dll + "\") inside pid " + pid + " (thread " + tid + ")");
        return 0;
    }
}
