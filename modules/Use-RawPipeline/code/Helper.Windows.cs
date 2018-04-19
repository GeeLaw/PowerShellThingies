using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace GeeLaw
{
    namespace PSUseRawPipeline
    {
        #region Interfaces

        public interface ITeedProcess
        {
            IntPtr ReleaseStandardOutputReadHandle();
            bool HasExited { get; }
            void Terminate();
        }

        public interface ITeedProcessStartInfo
        {
            bool CanInvoke { get; }
            ITeedProcess Invoke();
        }

        #endregion Interfaces

        #region Win32

        public static class Win32
        {
            public enum Bool : int
            {
                False = 0,
                True = 1
            }

            [StructLayout(LayoutKind.Sequential)]
            public struct SecurityAttributes
            {
                public int StructSize;
                public IntPtr SecurityDescriptor;
                public Bool CanInheritHandle;

                public void Initialize()
                {
                    StructSize = Marshal.SizeOf(typeof(SecurityAttributes));
                    SecurityDescriptor = IntPtr.Zero;
                    CanInheritHandle = Bool.False;
                }
            }

            [StructLayout(LayoutKind.Sequential)]
            public struct ProcessInformation
            {
                public IntPtr HandleToProcess;
                public IntPtr HandleToThread;
                public int ProcessId;
                public int ThreadId;
            }

            [Flags]
            public enum StartProcessFlags : uint
            {
                None = 0,
                UseStdHandles = 256
            }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
            public struct StartupInfo
            {
                public int StructSize;
                public string Reserved;
                public string Desktop;
                public string Title;
                public int X;
                public int Y;
                public int Width;
                public int Height;
                public int CharWidth;
                public int CharHeight;
                public int FillAttribute;
                public StartProcessFlags Flags;
                public short ShowWindow;
                public short Reserved2;
                public IntPtr ReservedPtr2;
                public IntPtr StandardInput;
                public IntPtr StandardOutput;
                public IntPtr StandardError;

                public void Initialize()
                {
                    StructSize = Marshal.SizeOf(typeof(StartupInfo));
                    Reserved = null;
                    Desktop = null;
                    Title = null;
                    X = 0; Y = 0;
                    Width = 0; Height = 0;
                    CharWidth = 0; CharHeight = 0;
                    FillAttribute = 0;
                    Flags = StartProcessFlags.None;
                    ShowWindow = 0;
                    Reserved2 = 0; ReservedPtr2 = IntPtr.Zero;
                    StandardInput = IntPtr.Zero;
                    StandardOutput = IntPtr.Zero;
                    StandardError = IntPtr.Zero;
                }
            }

            public enum StandardHandleId : int
            {
                StandardInput = -10,
                StandardOutput = -11,
                StandardError = -12
            }

            public static IntPtr InvalidHandle { get { return new IntPtr(-1); } }

            [Flags]
            public enum FileAccess : uint
            {
                GenericRead = 0x80000000,
                GenericWrite = 0x40000000,
                AppendData = 0x4
            }

            [Flags]
            public enum FileShare : uint
            {
                Read = 1,
                Write = 2
            }

            [Flags]
            public enum FileAttributes : uint
            {
                Normal = 0x80000000
            }

            public enum FileCreateDisposition : uint
            {
                CreateNew = 1,
                CreateAlways = 2,
                OpenExisting = 3,
                OpenAlways = 4,
                TruncateExisting = 5
            }

            public enum MoveFileMethod : int
            {
                FromBegin = 0,
                FromCurrent = 1,
                FromEnd = 2
            }

            [Flags]
            public enum DuplicateHandleOptions : uint
            {
                None = 0,
                CloseSource = 1,
                SameAccess = 2
            }

            [Flags]
            public enum HandleFlags : uint
            {
                None = 0,
                Inherit = 1,
                ProtectFromClose = 2
            }

            [Flags]
            public enum ProcessCreationFlags : uint
            {
                None = 0,
                CreateSuspended = 4
            }

            [DllImport("kernel32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall, SetLastError = true)]
            public static extern IntPtr CreateFile(
                string fileName,
                FileAccess desiredAccess,
                FileShare shareMode,
                ref SecurityAttributes securityAttributes,
                FileCreateDisposition creationDisposition,
                FileAttributes flagsAndAttributes,
                IntPtr templateFile
            );

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern uint SetFilePointer(IntPtr fileHandle, long distanceToMove, IntPtr distanceToMoveHigh, MoveFileMethod moveMethod);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern Bool CreatePipe(
                out IntPtr readHandle,
                out IntPtr writeHandle,
                ref SecurityAttributes pipeAttributes,
                uint bufferSize);

            [DllImport("kernel32.dll", SetLastError =true)]
            public static extern Bool ReadFile(IntPtr handle,
                [MarshalAs(UnmanagedType.LPArray)]byte[] buffer,
                uint capacity, out uint bytesRead, IntPtr overlapped);

            [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern Bool CreateProcess(
                string applicationName,
                StringBuilder commandLine,
                IntPtr processAttributes,
                IntPtr threadAttributes,
                Bool canInheritHandles,
                ProcessCreationFlags creationFlags,
                IntPtr environmentHandle,
                string currentDirectory,
                ref StartupInfo startupInfo,
                out ProcessInformation processInformation);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern IntPtr GetStdHandle(StandardHandleId handleId);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern Bool CloseHandle(IntPtr handle);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern Bool DuplicateHandle(IntPtr sourceProcess, IntPtr sourceHandle,
                IntPtr targetProcess, out IntPtr targetHandle,
                uint desiredAccess, Bool canInherit, DuplicateHandleOptions options);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern Bool SetHandleInformation(IntPtr handle, HandleFlags change, HandleFlags value);

            public const int ExitCodeStillActive = 259;

            [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern Bool GetExitCodeProcess(IntPtr processHandle, out int exitCode);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern uint ResumeThread(IntPtr hThread);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern Bool TerminateProcess(IntPtr processHandle, uint exitCode);

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern IntPtr GetCurrentProcess();

            public const uint WaitForInfiniteTime = 0xFFFFFFFFu;

            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);
        }

        #endregion Win32

        #region Helper: Win32 helper methods and consumers

        public static class Helper
        {
            const string CouldNotOpenFileErrorFormat = "Could not open file \"{0}\". Win32 GetLastError() returns {1}.";
            const string CouldNotDuplicateHandleErrorFormat = "Could not duplicate handle \"{0}\". Win32 GetLastError() returns {1}.";
            const string CouldNotSetHandleInformationErrorFormat = "Could not set the inheritance of handle \"{0}\". Win32 GetLastError() returns {1}.";
            const string CouldNotRetrieveStandardOutputHandleErrorMessage = "Could not retrieve the standard output handle of the specified ITeedProcess. It might have been taken by others.";

            public static IntPtr OpenReadFile(string fileName)
            {
                if (fileName == null)
                    throw new ArgumentNullException("fileName");
                Win32.SecurityAttributes securityAttributes = new Win32.SecurityAttributes();
                securityAttributes.Initialize();
                IntPtr handle = Win32.CreateFile(fileName,
                    Win32.FileAccess.GenericRead,
                    Win32.FileShare.Read,
                    ref securityAttributes,
                    Win32.FileCreateDisposition.OpenExisting,
                    Win32.FileAttributes.Normal, IntPtr.Zero);
                if (handle == IntPtr.Zero)
                {
                    int lastError = Marshal.GetLastWin32Error();
                    throw new Win32Exception(lastError,
                        string.Format(CouldNotOpenFileErrorFormat, fileName, lastError));
                }
                return handle;
            }

            public static IntPtr OpenTruncatedFile(string fileName)
            {
                if (fileName == null)
                    throw new ArgumentNullException("fileName");
                Win32.SecurityAttributes securityAttributes = new Win32.SecurityAttributes();
                securityAttributes.Initialize();
                IntPtr handle = Win32.CreateFile(fileName,
                    Win32.FileAccess.GenericWrite,
                    Win32.FileShare.Read,
                    ref securityAttributes,
                    Win32.FileCreateDisposition.CreateAlways,
                    Win32.FileAttributes.Normal, IntPtr.Zero);
                if (handle == IntPtr.Zero)
                {
                    int lastError = Marshal.GetLastWin32Error();
                    throw new Win32Exception(lastError,
                        string.Format(CouldNotOpenFileErrorFormat, fileName, lastError));
                }
                return handle;
            }

            public static IntPtr OpenAppendFile(string fileName)
            {
                if (fileName == null)
                    throw new ArgumentNullException("fileName");
                Win32.SecurityAttributes securityAttributes = new Win32.SecurityAttributes();
                securityAttributes.Initialize();
                IntPtr handle = Win32.CreateFile(fileName,
                    Win32.FileAccess.AppendData,
                    Win32.FileShare.Read,
                    ref securityAttributes,
                    Win32.FileCreateDisposition.OpenAlways,
                    Win32.FileAttributes.Normal, IntPtr.Zero);
                if (handle == IntPtr.Zero)
                {
                    int lastError = Marshal.GetLastWin32Error();
                    throw new Win32Exception(lastError,
                        string.Format(CouldNotOpenFileErrorFormat, fileName, lastError));
                }
                return handle;
            }

            public static IntPtr DuplicateHandleForInheritance(IntPtr handle)
            {
                IntPtr resultHandle;
                if (Win32.DuplicateHandle(Win32.GetCurrentProcess(), handle,
                    Win32.GetCurrentProcess(), out resultHandle,
                    0, Win32.Bool.True, Win32.DuplicateHandleOptions.SameAccess) == Win32.Bool.False)
                {
                    int lastError = Marshal.GetLastWin32Error();
                    throw new Win32Exception(lastError,
                        string.Format(CouldNotDuplicateHandleErrorFormat, handle, lastError));
                }
                return resultHandle;
            }

            public static void EnsureHandleInheritable(IntPtr handle)
            {
                if (Win32.SetHandleInformation(handle, Win32.HandleFlags.Inherit, Win32.HandleFlags.Inherit) == Win32.Bool.False)
                {
                    int lastError = Marshal.GetLastWin32Error();
                    throw new Win32Exception(lastError,
                        string.Format(CouldNotSetHandleInformationErrorFormat, handle, lastError));
                }
            }

            public static IEnumerable<byte> EnumerateBytesInStandardOutput(ITeedProcess process)
            {
                IntPtr stdoutReadHandle = process.ReleaseStandardOutputReadHandle();
                if (stdoutReadHandle == IntPtr.Zero)
                {
                    Exception ex = new InvalidOperationException(CouldNotRetrieveStandardOutputHandleErrorMessage);
                    ex.Data.Add("ITeedProcess", process);
                    throw ex;
                }
                byte[] buffer = new byte[4096];
                try
                {
                    while (true)
                    {
                        /* Be careful!
                        * 
                        * Retrieve the status of process before
                        * trying to read. If 0 bytes were read,
                        * it could be the process flushing its
                        * stdout without putting anything into
                        * it, or it could be the process has
                        * exited.
                        * 
                        * However, if one checks the exit status
                        * after reading 0 bytes, it could be the
                        * case that:
                        *     1. The process flushes stdout;
                        *     2. The reading completes;
                        *     3. The process outputs something and quits;
                        *     4. The reader found the process has exited;
                        *     5. The several bytes vomitted by the process
                        *        before it dies are never read.
                        */
                        bool hasExited = process.HasExited;
                        uint count;
                        Win32.ReadFile(stdoutReadHandle, buffer, 4096, out count, IntPtr.Zero);
                        if (count == 0 && hasExited)
                            break;
                        for (int i = 0; i != count; ++i)
                            yield return buffer[i];
                    }
                }
                finally
                {
                    Win32.CloseHandle(stdoutReadHandle);
                }
            }

            static char ProcessCharacters(StringBuilder sb, StreamReader sr, char[] charBuf, char lastSeen, List<string> collect)
            {
                int charRead = sr.Read(charBuf, 0, charBuf.Length);
                int lastBegin = 0;
                for (int i = 0; i != charRead; lastSeen = charBuf[i++])
                    if (charBuf[i] == '\n' || charBuf[i] == '\r')
                    {
                        /* Consecutive \r\n is one line. */
                        if (charBuf[i] != '\n' || lastSeen != '\r')
                        {
                            sb.Append(charBuf, lastBegin, i - lastBegin);
                            collect.Add(sb.ToString());
                            sb.Length = 0;
                        }
                        lastBegin = i + 1;
                    }
                sb.Append(charBuf, lastBegin, charRead - lastBegin);
                return lastSeen;
            }

            static void CleanStreamIfAppropriate(MemoryStream ms, int leastSize, byte[] gapBuf)
            {
                if (ms.Length < leastSize || ms.Length - ms.Position > gapBuf.Length)
                    return;
                int gap = (int)(ms.Length - ms.Position);
                ms.Read(gapBuf, 0, gap);
                ms.SetLength(0);
                ms.Write(gapBuf, 0, gap);
                ms.Position = 0;
            }

            public static IEnumerable<string> EnumerateLinesInStandardOutput(ITeedProcess process, Encoding encoding)
            {
                IntPtr stdoutReadHandle = process.ReleaseStandardOutputReadHandle();
                if (stdoutReadHandle == IntPtr.Zero)
                {
                    Exception ex = new InvalidOperationException(CouldNotRetrieveStandardOutputHandleErrorMessage);
                    ex.Data.Add("ITeedProcess", process.ToString());
                    throw ex;
                }
                byte[] buffer = new byte[4096];
                char[] charBuf = new char[4096];
                char lastSeen = '\0';
                StringBuilder sb = new StringBuilder();
                List<string> collect = new List<string>();
                MemoryStream ms = new MemoryStream();
                try
                {
                    StreamReader sr;
                    if (encoding != null)
                        sr = new StreamReader(ms, encoding);
                    else
                        sr = new StreamReader(ms, true);
                    using (sr)
                    {
                        while (true)
                        {
                            bool hasExited = process.HasExited;
                            uint count;
                            Win32.ReadFile(stdoutReadHandle, buffer, 4096, out count, IntPtr.Zero);
                            if (count == 0 && hasExited)
                                break;
                            /* Attention: Recover the Position after Write. */
                            {
                                long oldPosition = ms.Position;
                                ms.Position = ms.Length;
                                ms.Write(buffer, 0, (int)count);
                                ms.Position = oldPosition;
                            }
                            lastSeen = ProcessCharacters(sb, sr, charBuf, lastSeen, collect);
                            foreach (string s in collect)
                                yield return s;
                            collect.Clear();
                            /* If the stream is at least 1 MB and the gap is
                            * at most the size of buffer, remove the useless
                            * part of the stream.
                            */
                            CleanStreamIfAppropriate(ms, 1048576, buffer);
                        }
                        while (!sr.EndOfStream)
                        {
                            lastSeen = ProcessCharacters(sb, sr, charBuf, lastSeen, collect);
                            foreach (string s in collect)
                                yield return s;
                            collect.Clear();
                        }
                        if (sb.Length != 0)
                            yield return sb.ToString();
                    }
                }
                finally
                {
                    Win32.CloseHandle(stdoutReadHandle);
                    ms.Dispose();
                }
            }

            public static void CopyStandardOutput(ITeedProcess process, Stream target)
            {
                IntPtr stdoutReadHandle = process.ReleaseStandardOutputReadHandle();
                if (stdoutReadHandle == IntPtr.Zero)
                {
                    Exception ex = new InvalidOperationException(CouldNotRetrieveStandardOutputHandleErrorMessage);
                    ex.Data.Add("ITeedProcess", process);
                    throw ex;
                }
                try
                {
                    byte[] buffer = new byte[4096];
                    while (true)
                    {
                        bool hasExited = process.HasExited;
                        uint count;
                        Win32.ReadFile(stdoutReadHandle, buffer, 4096, out count, IntPtr.Zero);
                        if (count == 0 && hasExited)
                            break;
                        target.Write(buffer, 0, (int)count);
                        target.Flush();
                    }
                }
                finally
                {
                    Win32.CloseHandle(stdoutReadHandle);
                }
            }

            public static string StringFromStandardOutput(ITeedProcess process, Encoding encoding)
            {
                MemoryStream ms = new MemoryStream();
                string returnValue = null;
                try
                {
                    CopyStandardOutput(process, ms);
                }
                finally
                {
                    try
                    {
                        ms.Position = 0;
                        StreamReader sr;
                        if (encoding != null)
                            sr = new StreamReader(ms, encoding);
                        else
                            sr = new StreamReader(ms, true);
                        using (sr)
                            returnValue = sr.ReadToEnd();
                    }
                    catch
                    {
                        ms.Dispose();
                    }
                }
                return returnValue;
            }
        }

        #endregion Helper: Win32 helper methods and consumers

        #region Piped process implementation

        public sealed class PipedProcessStartInfo : ITeedProcessStartInfo
        {
            const string CannotInvokeMessage = "Could not invoke the object. The object might have been invoked.";

            public bool CanInvoke { get; private set; }

            List<string> arguments;

            public string FilePath { get; private set; }
            public string BaseDirectory { get; private set; }
            public string WorkingDirectory { get; private set; }
            public IEnumerable<string> Arguments { get { return arguments.AsReadOnly(); } }
            public ITeedProcessStartInfo RedirectedStandardInput { get; private set; }
            public string RedirectedStandardError { get; private set; }
            bool standardErrorAppend;
            public bool? StandardErrorAppend { get { return RedirectedStandardError != null ? (bool?)standardErrorAppend : null; } }

            /// <summary>
            /// Creates a new PipedProcessStartInfo object.
            /// </summary>
            /// <param name="filePath">The path to the executable file. Must not be null.</param>
            /// <param name="baseDirectory">The current searching directory of the executable file.</param>
            /// <param name="workingDirectory">The initial working directory of the process.</param>
            /// <param name="arguments">The arguments to supply to the process. Can be null, equivalent to empty collection.</param>
            /// <param name="redirectedStandardInput">The source of standard input. Can be null (suppress redirection of standard input).</param>
            public PipedProcessStartInfo(string filePath, string baseDirectory, string workingDirectory, IEnumerable<string> arguments, ITeedProcessStartInfo redirectedStandardInput)
                : this(filePath, baseDirectory, workingDirectory, arguments, redirectedStandardInput, null, false)
            { }

            /// <summary>
            /// Creates a new PipedProcessStartInfo object.
            /// </summary>
            /// <param name="filePath">The path to the executable file. Must not be null.</param>
            /// <param name="baseDirectory">The current searching directory of the executable file.</param>
            /// <param name="workingDirectory">The initial working directory of the process.</param>
            /// <param name="arguments">The arguments to supply to the process. Can be null, equivalent to empty collection.</param>
            /// <param name="redirectedStandardInput">The source of standard input. Can be null (suppress redirection of standard input).</param>
            /// <param name="redirectedStandardError">The file name of redirected standard error. Default to null (suppress redirection of standard error).</param>
            /// <param name="append">Indicates whether the standard error will be appended to the file (true) or overwrite the file (false, default).</param>
            public PipedProcessStartInfo(string filePath, string baseDirectory, string workingDirectory, IEnumerable<string> arguments, ITeedProcessStartInfo redirectedStandardInput, string redirectedStandardError, bool append)
            {
                CanInvoke = false;
                if (filePath == null)
                    throw new ArgumentNullException("filePath");
                FilePath = filePath;
                if (baseDirectory == null)
                    baseDirectory = Directory.GetCurrentDirectory();
                BaseDirectory = baseDirectory;
                if (workingDirectory == null)
                    workingDirectory = baseDirectory;
                WorkingDirectory = workingDirectory;
                this.arguments = new List<string>();
                if (arguments != null)
                    this.arguments.AddRange(arguments);
                RedirectedStandardInput = redirectedStandardInput;
                RedirectedStandardError = redirectedStandardError;
                standardErrorAppend = append;
                CanInvoke = true;
            }

            public ITeedProcess Invoke()
            {
                if (!CanInvoke)
                    throw new InvalidOperationException(CannotInvokeMessage);
                CanInvoke = false;
                ITeedProcess stdin = null;
                if (RedirectedStandardInput != null)
                    stdin = RedirectedStandardInput.Invoke();
                try
                {
                    return new PipedProcess(FilePath,
                        BaseDirectory, WorkingDirectory,
                        Arguments, stdin,
                        RedirectedStandardError, standardErrorAppend);
                }
                catch
                {
                    if (stdin != null)
                        stdin.Terminate();
                    throw;
                }
            }

            public override string ToString()
            {
                StringBuilder sb = new StringBuilder();
                if (RedirectedStandardInput != null)
                {
                    sb.AppendLine(RedirectedStandardInput.ToString())
                    .AppendLine("WILL BE REDIRECTED TO");
                }
                sb.AppendLine("{")
                .Append("    FilePath = ")
                .Append(FilePath == null ? "(null)" : FilePath)
                .AppendLine(",")
                .Append("    BaseDirectory = ")
                .Append(BaseDirectory == null ? "(null)" : BaseDirectory)
                .AppendLine(",")
                .Append("    WorkingDirectory = ")
                .Append(WorkingDirectory == null ? "(null)" : WorkingDirectory)
                .AppendLine(",")
                .Append("    RedirectedStandardError = ")
                .Append(RedirectedStandardError == null ? "(null)" : RedirectedStandardError)
                .AppendLine(",")
                .Append("    StandardErrorAppend = ")
                .Append(StandardErrorAppend == null ? "(null)" : StandardErrorAppend.ToString())
                .AppendLine(",")
                .Append("    CanInvoke = ")
                .AppendLine(CanInvoke.ToString())
                .AppendLine("}")
                .Append("Arguments:");
                if (arguments.Count == 0)
                    sb.AppendLine().Append("    (empty)");
                else
                    foreach (string s in arguments)
                        sb.AppendLine().Append("    ").Append(s);
                return sb.ToString();
            }
        }

        public sealed class PipedProcess : ITeedProcess
        {
            const string HandleReleasedMessage = "No process is associated with this object.";
            const string CouldNotGetExitCodeProcessErrorFormat = "Call to GetExitCodeProcess failed with error code {0}.";
            const string CouldNotCreatePipeErrorFormat = "Could not create anonymous pipe for redirection. Win32 GetLastError() returned {0}.";
            const string CouldNotCreateProcessErrorFormat = "Call to CreateProcess failed with error code {0}.";

            static void WaitForProcessExitWorker(object parameter)
            {
                PipedProcess that = (PipedProcess)parameter;
                IntPtr targetHandle = IntPtr.Zero;
                lock (that)
                {
                    targetHandle = that.processHandle;
                }
                if (targetHandle == IntPtr.Zero)
                    return;
                Win32.WaitForSingleObject(targetHandle, Win32.WaitForInfiniteTime);
                lock (that)
                {
                    that.processHandle = IntPtr.Zero;
                    that.hasExited = true;
                    that.ProcessId = null;
                }
                Win32.CloseHandle(targetHandle);
            }

            IntPtr processHandle;
            bool hasExited;
            IntPtr stdoutReadHandle;
            List<string> arguments;

            public string FilePath { get; private set; }
            public string BaseDirectory { get; private set; }
            public string InitialWorkingDirectory { get; private set; }
            public IEnumerable<string> Arguments { get { return arguments.AsReadOnly(); } }
            public ITeedProcess RedirectedStandardInput { get; private set; }
            public string RedirectedStandardError { get; private set; }
            bool standardErrorAppend;
            public bool? StandardErrorAppend { get { return RedirectedStandardError != null ? (bool?)standardErrorAppend : null; } }

            public PipedProcess(string filePath, string baseDirectory, string workingDirectory, IEnumerable<string> arguments, ITeedProcess redirectedStandardInput, string redirectedStandardError, bool append)
            {
                hasExited = true;
                if (filePath == null)
                    throw new ArgumentNullException("filePath");
                FilePath = filePath;
                if (baseDirectory == null)
                    baseDirectory = Directory.GetCurrentDirectory();
                BaseDirectory = baseDirectory;
                if (workingDirectory == null)
                    workingDirectory = baseDirectory;
                InitialWorkingDirectory = workingDirectory;
                this.arguments = new List<string>();
                if (arguments != null)
                    this.arguments.AddRange(arguments);
                RedirectedStandardInput = redirectedStandardInput;
                RedirectedStandardError = redirectedStandardError;
                standardErrorAppend = append;
                string currentWorkingDirectory = Directory.GetCurrentDirectory();
                try
                {
                    Directory.SetCurrentDirectory(baseDirectory);
                    StartProcess();
                }
                finally
                {
                    try { Directory.SetCurrentDirectory(currentWorkingDirectory); }
                    catch { }
                }
            }

            StringBuilder BuildCommandLine()
            {
                StringBuilder sb = new StringBuilder();
                sb.Append('"').Append(FilePath).Append('"');
                foreach (string arg in arguments)
                {
                    sb.Append(' ');
                    bool requiresEscaping = false;
                    foreach (char ch in arg)
                        if (Char.IsWhiteSpace(ch) || ch == '"')
                        {
                            requiresEscaping = true;
                            break;
                        }
                    if (!requiresEscaping)
                    {
                        sb.Append(arg);
                        continue;
                    }
                    int numberOfBackslashes = 0;
                    sb.Append('"');
                    foreach (char ch in arg)
                    {
                        if (ch == '\\')
                        {
                            ++numberOfBackslashes;
                        }
                        else if (ch == '"')
                        {
                            sb.Append('\\', numberOfBackslashes * 2 + 1).Append('"');
                            numberOfBackslashes = 0;
                        }
                        else
                        {
                            sb.Append('\\', numberOfBackslashes).Append(ch);
                            numberOfBackslashes = 0;
                        }
                    }
                    sb.Append('\\', numberOfBackslashes * 2).Append('"');
                }
                return sb;
            }

            void StartProcess()
            {
                IntPtr stdin = IntPtr.Zero;
                IntPtr stdoutRead = IntPtr.Zero;
                IntPtr stdoutWrite = IntPtr.Zero;
                IntPtr stderr = IntPtr.Zero;
                try
                {
                    Win32.StartupInfo startupInfo = new Win32.StartupInfo();
                    startupInfo.Initialize();
                    startupInfo.Flags = Win32.StartProcessFlags.UseStdHandles;
                    #region Set stdin
                    {
                        if (RedirectedStandardInput != null)
                        {
                            stdin = RedirectedStandardInput.ReleaseStandardOutputReadHandle();
                            Helper.EnsureHandleInheritable(stdin);
                        }
                        else
                        {
                            /* Duplicate the handle so that
                            * the cleaning logic is unified.
                            */
                            stdin = Helper.DuplicateHandleForInheritance(
                                Win32.GetStdHandle(Win32.StandardHandleId.StandardInput));
                        }
                        startupInfo.StandardInput = stdin;
                    }
                    #endregion Set stdin
                    #region Set stdout
                    {
                        Win32.SecurityAttributes pipeAttributes = new Win32.SecurityAttributes();
                        pipeAttributes.Initialize();
                        if (Win32.CreatePipe(out stdoutRead, out stdoutWrite,
                            ref pipeAttributes, 4096) == Win32.Bool.False)
                        {
                            stdoutRead = IntPtr.Zero;
                            stdoutWrite = IntPtr.Zero;
                            int lastError = Marshal.GetLastWin32Error();
                            throw new Win32Exception(lastError,
                                string.Format(CouldNotCreatePipeErrorFormat, lastError));
                        }
                        Helper.EnsureHandleInheritable(stdoutWrite);
                        startupInfo.StandardOutput = stdoutWrite;
                    }
                    #endregion Set stdout
                    #region Set stderr
                    {
                        if (RedirectedStandardError != null)
                        {
                            stderr = standardErrorAppend
                                ? Helper.OpenAppendFile(RedirectedStandardError)
                                : Helper.OpenTruncatedFile(RedirectedStandardError);
                            Helper.EnsureHandleInheritable(stderr);
                        }
                        else
                        {
                            stderr = Helper.DuplicateHandleForInheritance(
                                Win32.GetStdHandle(Win32.StandardHandleId.StandardError));
                        }
                        startupInfo.StandardError = stderr;
                    }
                    #endregion Set stderr
                    Win32.ProcessInformation processInformation;
                    /* Create the process suspended,
                     * and resume it only after we
                     * have started waiting for it.
                     */
                    if (Win32.CreateProcess(null,
                        BuildCommandLine(),
                        IntPtr.Zero, IntPtr.Zero,
                        Win32.Bool.True, Win32.ProcessCreationFlags.CreateSuspended, IntPtr.Zero,
                        InitialWorkingDirectory,
                        ref startupInfo, out processInformation)
                        == Win32.Bool.False)
                    {
                        int lastError = Marshal.GetLastWin32Error();
                        throw new Win32Exception(lastError,
                            string.Format(CouldNotCreateProcessErrorFormat, lastError));
                    }
                    hasExited = false;
                    processHandle = processInformation.HandleToProcess;
                    ProcessId = processInformation.ProcessId;
                    new Thread(WaitForProcessExitWorker).Start(this);
                    Win32.ResumeThread(processInformation.HandleToThread);
                    Win32.CloseHandle(processInformation.HandleToThread);
                    stdoutReadHandle = stdoutRead;
                    /* Prevent this very handle from being
                    * closed. Other handles are useless now
                    * and will be closed in "finally".
                    */
                    stdoutRead = IntPtr.Zero;
                }
                finally
                {
                    if (stdin != IntPtr.Zero)
                        Win32.CloseHandle(stdin);
                    if (stdoutRead != IntPtr.Zero)
                        Win32.CloseHandle(stdoutRead);
                    if (stdoutWrite != IntPtr.Zero)
                        Win32.CloseHandle(stdoutWrite);
                    if (stderr != IntPtr.Zero)
                        Win32.CloseHandle(stderr);
                }
            }

            public bool HasExited
            {
                get
                {
                    lock (this)
                    {
                        if (hasExited)
                            return true;
                        if (processHandle == IntPtr.Zero)
                            throw new InvalidOperationException(HandleReleasedMessage);
                        return false;
                    }
                }
            }

            public int? ProcessId { get; private set; }

            public IntPtr ReleaseStandardOutputReadHandle()
            {
                IntPtr result = stdoutReadHandle;
                stdoutReadHandle = IntPtr.Zero;
                return result;
            }

            public void Terminate()
            {
                lock (this)
                {
                    if (processHandle != IntPtr.Zero)
                    {
                        Win32.TerminateProcess(processHandle, 777);
                        if (RedirectedStandardInput != null)
                            RedirectedStandardInput.Terminate();
                    }
                }
            }

            public override string ToString()
            {
                StringBuilder sb = new StringBuilder();
                if (RedirectedStandardInput != null)
                {
                    sb.AppendLine(RedirectedStandardInput.ToString())
                    .AppendLine("REDIRECTED TO");
                }
                sb.AppendLine("{")
                .Append("    FilePath = ")
                .Append(FilePath == null ? "(null)" : FilePath)
                .AppendLine(",")
                .Append("    BaseDirectory = ")
                .Append(BaseDirectory == null ? "(null)" : BaseDirectory)
                .AppendLine(",")
                .Append("    WorkingDirectory = ")
                .Append(InitialWorkingDirectory == null ? "(null)" : InitialWorkingDirectory)
                .AppendLine(",")
                .Append("    RedirectedStandardError = ")
                .Append(RedirectedStandardError == null ? "(null)" : RedirectedStandardError)
                .AppendLine(",")
                .Append("    StandardErrorAppend = ")
                .Append(StandardErrorAppend == null ? "(null)" : StandardErrorAppend.ToString())
                .AppendLine(",")
                .Append("    ProcessId = ")
                .AppendLine(ProcessId == null ? "(null)" : ProcessId.ToString())
                .AppendLine("}")
                .Append("Arguments:");
                if (arguments.Count == 0)
                    sb.AppendLine().Append("    (empty)");
                else
                    foreach (string s in arguments)
                        sb.AppendLine().Append("    ").Append(s);
                return sb.ToString();
            }
        }

        #endregion Piped process implementation

        #region Concatenate file implementation

        public sealed class ConcatenateFileStartInfo : ITeedProcessStartInfo
        {
            const string CannotInvokeMessage = "Could not invoke the object. The object might have been invoked.";

            public string FileName { get; private set; }

            public bool CanInvoke { get; private set; }

            public ConcatenateFileStartInfo(string fileName)
            {
                CanInvoke = false;
                if (fileName == null)
                    throw new ArgumentNullException("fileName");
                FileName = fileName;
                CanInvoke = true;
            }

            public ITeedProcess Invoke()
            {
                if (!CanInvoke)
                    throw new InvalidOperationException(CannotInvokeMessage);
                CanInvoke = false;
                return new ConcatenateFile(FileName);
            }

            public override string ToString()
            {
                return string.Format("{{ FileName = {0}, CanInvoke = {1} }}", FileName, CanInvoke);
            }
        }

        public sealed class ConcatenateFile : ITeedProcess
        {
            IntPtr fileHandle;
            
            public string FileName { get; private set; }

            public ConcatenateFile(string fileName)
            {
                fileHandle = Helper.OpenReadFile(fileName);
                FileName = fileName;
            }

            public bool HasExited
            {
                get
                {
                    return true;
                }
            }
            
            public void Terminate()
            {
            }

            public IntPtr ReleaseStandardOutputReadHandle()
            {
                IntPtr result = fileHandle;
                fileHandle = IntPtr.Zero;
                return result;
            }

            public override string ToString()
            {
                return string.Format("{{ FileName = {0} }}", FileName);
            }
        }

        #endregion Concatenate file implementation

    }
}
