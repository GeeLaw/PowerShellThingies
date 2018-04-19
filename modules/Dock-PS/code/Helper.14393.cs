using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;

namespace DockPSHelper
{
    public static class AppBarHelper
    {
        const double SizeShrinkFactor = 0.7;

        static IntPtr MessageWindowHandle { get { return new IntPtr(-3); } }

        enum SystemMetric : uint
        {
            PrimaryScreenWidth = 0,
            PrimaryScreenHeight = 1
        }

        [DllImport("user32.dll")]
        static extern int GetSystemMetrics(SystemMetric index);

        enum ThreadDpiAwareContext : int
        {
            Invalid = 0,
            Unaware = -1,
            SystemAware = -2,
            PerMonitorAware = -3,
            /* Fails if used before Creators Update. */
            PerMonitorAwareV2 = -4
        }

        [DllImport("user32.dll")]
        static extern ThreadDpiAwareContext SetThreadDpiAwarenessContext(ThreadDpiAwareContext newContext);

        [DllImport("user32.dll", SetLastError = true)]
        static extern uint RegisterWindowMessage(string messageName);

        [DllImport("user32.dll", SetLastError = true)]
        static extern bool GetWindowRect(IntPtr handle, out Rect rect);

        [Flags]
        enum SetWindowPosFlags : uint
        {
            None = 0x0000,
            AsyncSet = 0x4000,
            HideWindow = 0x0080,
            NoActivate = 0x0010,
            NoMove = 0x0002,
            NoSize = 0x0001,
            NoZOrder = 0x0004,
            ShowWindow = 0x0040
        }

        static IntPtr TopMostWindowHandle { get { return new IntPtr(-1); } }
        static IntPtr NoTopMostWindowHandle { get { return new IntPtr(-2); } }

        [DllImport("user32.dll", SetLastError = true)]
        static extern bool SetWindowPos(IntPtr handle, IntPtr insertAfterHandle, int left, int top, int width, int height, SetWindowPosFlags flags);

        const int WM_CREATE = 0x0001;
        const int WM_DESTORY = 0x0002;
        const int WM_SYSCOMMAND = 0x0112;
        const int WM_DPICHANGED = 0x02E0;

        const int SC_RESTORE = 0xF120;

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr SendMessage(IntPtr handle, int message, IntPtr WParam, IntPtr LParam);

        [DllImport("shell32.dll", SetLastError = true)]
        static extern IntPtr SHAppBarMessage(AppBarMessage message, ref AppBarData appBarData);

        enum WindowLongIndex : int
        {
            Style = -16,
            ExtendedStyle = -20
        }

        [DllImport("user32.dll", SetLastError = true)]
        static extern uint GetWindowLong(IntPtr handle, WindowLongIndex index);

        [DllImport("user32.dll", SetLastError = true)]
        static extern uint SetWindowLong(IntPtr handle, WindowLongIndex index, uint newLong);

        [Flags]
        enum WindowStyle : uint
        {
            None = 0,
            Caption = 12582912,
            ThickFrame = 262144,
            SystemMenu = 524288,
            Popup = 2147483648
        }

        [Flags]
        enum WindowStyleExtended : uint
        {
            None = 0,
            WindowEdge = 256,
            TopMost = 8,
            ToolWindow = 128,
            AppWindow = 262144
        }

        [StructLayout(LayoutKind.Sequential)]
        struct Rect
        {
            public int Left, Top, Right, Bottom;
        }

        enum AppBarMessage : uint
        {
            New = 0,
            Remove = 1,
            QueryPosition = 2,
            SetPosition = 3,
            GetState = 4,
            GetTaskbarPosition = 5,
            Activate = 6,
            GetAutoHideBar = 7,
            SetAutoHideBar = 8,
            WindowPositionChanged = 9,
            SetState = 10
        }

        enum AppBarNotification : uint
        {
            StateChange = 0,
            PositionChanged = 1,
            FullScreenApp = 2,
            WindowArrange = 3
        }

        [Flags]
        enum AppBarState : uint
        {
            None = 0,
            AutoHide = 1,
            AlwaysOnTop = 2
        }

        public enum AppBarEdge : uint
        {
            Left = 0,
            Top = 1,
            Right = 2,
            Bottom = 3
        }

        [StructLayout(LayoutKind.Sequential)]
        struct AppBarData
        {
            static uint msgId;
            public static uint MessageIdentifierStatic { get { return msgId; } }

            static AppBarData()
            {
                msgId = RegisterWindowMessage("Dock-PS AppBarMessage");
            }

            public AppBarData(IntPtr ownerWindow)
            {
                StructSize = Marshal.SizeOf(typeof(AppBarData));
                Handle = ownerWindow;
                MessageIdentifier = msgId;
                Edge = AppBarEdge.Left;
                Bounds = new Rect();
                LParam = 0;
            }

            public readonly int StructSize;
            public readonly IntPtr Handle;
            public readonly uint MessageIdentifier;
            public AppBarEdge Edge;
            public Rect Bounds;
            public uint LParam;
        }

        sealed class AppBarPreference
        {
            public AppBarPreference()
            {
                width = 0.4;
                height = 0.4;
            }
            public AppBarEdge DockingPosition { get; set; }
            double width, height;
            public double Width
            {
                get
                {
                    return width;
                }
                set
                {
                    if (value <= 0)
                        return;
                    if (value < 0.2)
                        value = 0.2;
                    if (value > 0.45)
                        value = 0.45;
                    width = value;
                }
            }
            public double Height
            {
                get
                {
                    return height;
                }
                set
                {
                    if (value <= 0)
                        return;
                    if (value < 0.2)
                        value = 0.2;
                    if (value > 0.45)
                        value = 0.45;
                    height = value;
                }
            }
        }

        abstract class AppBarCommand
        {
            public AppBarCommand(IntPtr target)
            {
                TargetWindow = target;
            }

            public IntPtr TargetWindow { get; private set; }
            public abstract void InvokeTask();
        }
        
        sealed class CreateAppBarCommand : AppBarCommand
        {
            public CreateAppBarCommand(IntPtr target, AppBarEdge dockingPosition)
                : base(target)
            {
                DockingPosition = dockingPosition;
            }

            AppBarEdge DockingPosition;

            public override void InvokeTask()
            {
                AppBarData data = new AppBarData(TargetWindow);
                if (SHAppBarMessage(AppBarMessage.New, ref data) == IntPtr.Zero)
                    return;
                SendMessage(TargetWindow, WM_SYSCOMMAND, (IntPtr)SC_RESTORE, IntPtr.Zero);
                SetWindowPos(TargetWindow, TopMostWindowHandle, 0, 0, 0, 0, SetWindowPosFlags.NoMove | SetWindowPosFlags.NoSize | SetWindowPosFlags.NoActivate);
                managedAppBars[TargetWindow] = new AppBarPreference()
                {
                    DockingPosition = DockingPosition
                };
                commands.Enqueue(new RefreshAppBarCommand(TargetWindow, false));
                commands.Enqueue(new RefreshAppBarCommand(TargetWindow, true));
            }
        }

        sealed class RefreshAppBarCommand : AppBarCommand
        {
            public bool Recurs { get; private set; }

            public RefreshAppBarCommand(IntPtr target, bool recurs)
                : base(target)
            {
                Recurs = recurs;
            }

            static void RecurCommand(object param)
            {
                Thread.Sleep(700);
                if (!hasCleanUpStarted)
                    commands.Enqueue((RefreshAppBarCommand)param);
            }

            public override void InvokeTask()
            {
                AppBarPreference preference;
                if (!managedAppBars.TryGetValue(TargetWindow, out preference))
                    return;
                uint style = GetWindowLong(TargetWindow, WindowLongIndex.Style);
                bool isFullScreen = ((style & (uint)WindowStyle.Popup) != 0);
                if (!isFullScreen)
                {
                    style &= ~(uint)(WindowStyle.Caption | WindowStyle.ThickFrame | WindowStyle.SystemMenu);
                    SetWindowLong(TargetWindow, WindowLongIndex.Style, style);
                    style = GetWindowLong(TargetWindow, WindowLongIndex.ExtendedStyle);
                    style |= (uint)(WindowStyleExtended.WindowEdge | WindowStyleExtended.TopMost);
                    SetWindowLong(TargetWindow, WindowLongIndex.ExtendedStyle, style);
                }
                int scrWidth = GetSystemMetrics(SystemMetric.PrimaryScreenWidth);
                int scrHeight = GetSystemMetrics(SystemMetric.PrimaryScreenHeight);
                AppBarData data = new AppBarData(TargetWindow);
                data.Edge = preference.DockingPosition;
                data.Bounds.Left = 0;
                data.Bounds.Right = scrWidth;
                data.Bounds.Top = 0;
                data.Bounds.Bottom = scrHeight;
                SHAppBarMessage(AppBarMessage.QueryPosition, ref data);
                switch (data.Edge)
                {
                    case AppBarEdge.Left:
                        data.Bounds.Right = Math.Min(
                            data.Bounds.Right,
                            data.Bounds.Left + (int)(scrWidth * preference.Width));
                        break;
                    case AppBarEdge.Right:
                        data.Bounds.Left = Math.Max(
                            data.Bounds.Left,
                            data.Bounds.Right - (int)(scrWidth * preference.Width));
                        break;
                    case AppBarEdge.Top:
                        data.Bounds.Bottom = Math.Min(
                            data.Bounds.Bottom,
                            data.Bounds.Top + (int)(scrHeight * preference.Height));
                        break;
                    case AppBarEdge.Bottom:
                        data.Bounds.Top = Math.Max(
                            data.Bounds.Top,
                            data.Bounds.Bottom - (int)(scrHeight * preference.Height));
                        break;
                }
                SHAppBarMessage(AppBarMessage.SetPosition, ref data);
                preference.DockingPosition = data.Edge;
                if (!isFullScreen)
                {
                    SetWindowPos(TargetWindow, IntPtr.Zero,
                        data.Bounds.Left, data.Bounds.Top,
                        data.Bounds.Right - data.Bounds.Left,
                        data.Bounds.Bottom - data.Bounds.Top,
                        SetWindowPosFlags.NoZOrder | SetWindowPosFlags.NoActivate);
                }
                if (!hasCleanUpStarted && Recurs)
                {
                    Thread recurThread = new Thread(RecurCommand);
                    recurThread.IsBackground = true;
                    recurThread.Start(this);
                }
            }
        }
        
        sealed class RemoveAppBarCommand : AppBarCommand
        {
            public RemoveAppBarCommand(IntPtr target)
                : base(target)
            {
            }

            public override void InvokeTask()
            {
                AppBarPreference preference;
                bool preferenceSuccess = managedAppBars.TryRemove(TargetWindow, out preference);
                AppBarData data = new AppBarData(TargetWindow);
                SHAppBarMessage(AppBarMessage.Remove, ref data);
                uint style = GetWindowLong(TargetWindow, WindowLongIndex.Style);
                bool isFullScreen = ((style & (uint)WindowStyle.Popup) != 0);
                if (!isFullScreen)
                {
                    style |= (uint)(WindowStyle.Caption | WindowStyle.ThickFrame | WindowStyle.SystemMenu);
                    SetWindowLong(TargetWindow, WindowLongIndex.Style, style);
                }
                style = GetWindowLong(TargetWindow, WindowLongIndex.ExtendedStyle);
                style &= ~(uint)(WindowStyleExtended.WindowEdge | WindowStyleExtended.TopMost);
                SetWindowLong(TargetWindow, WindowLongIndex.ExtendedStyle, style);
                if (preferenceSuccess && !isFullScreen)
                {
                    SetWindowPos(TargetWindow, NoTopMostWindowHandle, 0, 0,
                        (int)(GetSystemMetrics(SystemMetric.PrimaryScreenWidth) * preference.Width),
                        (int)(GetSystemMetrics(SystemMetric.PrimaryScreenHeight) * preference.Height),
                        SetWindowPosFlags.NoMove | SetWindowPosFlags.NoActivate);
                }
                else
                {
                    SetWindowPos(TargetWindow, NoTopMostWindowHandle, 0, 0, 0, 0,
                        SetWindowPosFlags.NoMove | SetWindowPosFlags.NoSize | SetWindowPosFlags.NoActivate);
                }
            }
        }

        sealed class CommandQueue
        {
            Queue<AppBarCommand> internalQueue;
            AutoResetEvent incoming;

            public CommandQueue()
            {
                internalQueue = new Queue<AppBarCommand>();
                incoming = new AutoResetEvent(false);
            }

            public void Enqueue(AppBarCommand command)
            {
                lock (internalQueue)
                {
                    internalQueue.Enqueue(command);
                }
                incoming.Set();
            }

            public void Unblock()
            {
                incoming.Set();
            }

            public bool TryDequeue(out AppBarCommand command)
            {
                lock (internalQueue)
                {
                    if (internalQueue.Count != 0)
                    {
                        command = internalQueue.Dequeue();
                        return true;
                    }
                    command = null;
                    return false;
                }
            }

            public bool WaitDeque(int milliseconds, out AppBarCommand command)
            {
                bool success = TryDequeue(out command);
                if (success)
                    return true;
                incoming.WaitOne(milliseconds);
                return TryDequeue(out command);
            }
        }

        static ConcurrentDictionary<IntPtr, AppBarPreference> managedAppBars;
        static CommandQueue commands;
        static volatile bool hasCleanUpStarted;
        static Thread worker;

        static AppBarHelper()
        {
            managedAppBars = new ConcurrentDictionary<IntPtr, AppBarPreference>();
            commands = new CommandQueue();
            hasCleanUpStarted = false;
            worker = new Thread(AppBarWorkerThread);
            worker.IsBackground = false;
            worker.Start();
        }

        static void AppBarWorkerThread()
        {
            /* Console windows belong to CSRSS and are DPI aware.
             * As for Windows 10 Anniversary Update, powershell.exe
             * is not DPI-aware thus we have to set the current
             * thread as per-monitor DPI aware.
             */
            SetThreadDpiAwarenessContext(ThreadDpiAwareContext.PerMonitorAware);
            while (!hasCleanUpStarted)
            {
                AppBarCommand command;
                if (commands.WaitDeque(-1, out command))
                    command.InvokeTask();
                else
                    Thread.Yield();
            }
            while (true)
            {
                AppBarCommand command;
                if (commands.TryDequeue(out command))
                    command.InvokeTask();
                else
                    break;
            }
            foreach (IntPtr handle in managedAppBars.Keys.ToArray())
                new RemoveAppBarCommand(handle).InvokeTask();
        }

        /* This method is called when PowerShell is exited by typing "exit". */
        public static void CleanUp()
        {
            hasCleanUpStarted = true;
            /* In case the queue is empty. */
            commands.Unblock();
            /* Gracefully shutdown. */
            worker.Priority = ThreadPriority.Highest;
            worker.Join();
        }

        public static void AddAppBarWindow(IntPtr target, AppBarEdge dockingPosition)
        {
            commands.Enqueue(new CreateAppBarCommand(target, dockingPosition));
        }

        public static void MoveAppBarWindow(IntPtr target, AppBarEdge dockingPosition)
        {
            AppBarPreference preference;
            if (!managedAppBars.TryGetValue(target, out preference))
                return;
            preference.DockingPosition = dockingPosition;
            commands.Enqueue(new RefreshAppBarCommand(target, false));
        }

        public static void ResizeAppBarWindow(IntPtr target, double newWidth, double newHeight)
        {
            AppBarPreference preference;
            if (!managedAppBars.TryGetValue(target, out preference))
                return;
            preference.Width = newWidth;
            preference.Height = newHeight;
            commands.Enqueue(new RefreshAppBarCommand(target, false));
        }

        public static void RemoveAppBarWindow(IntPtr target)
        {
            commands.Enqueue(new RemoveAppBarCommand(target));
        }

    }
}
