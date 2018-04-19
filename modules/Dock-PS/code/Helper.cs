using System;

namespace DockPSHelper
{
    public static class AppBarHelper
    {
        public enum AppBarEdge : uint
        {
            Left = 0,
            Top = 1,
            Right = 2,
            Bottom = 3
        }

        public static void CleanUp()
        {
        }

        public static void AddAppBarWindow(IntPtr target, AppBarEdge dockingPosition)
        {
            throw new PlatformNotSupportedException("The operation is not supported until Windows 10 Anniversary Update, Version 1607 (Build 14393).");
        }

        public static void MoveAppBarWindow(IntPtr target, AppBarEdge dockingPosition)
        {
            throw new PlatformNotSupportedException("The operation is not supported until Windows 10 Anniversary Update, Version 1607 (Build 14393).");
        }

        public static void ResizeAppBarWindow(IntPtr target, double newWidth, double newHeight)
        {
            throw new PlatformNotSupportedException("The operation is not supported until Windows 10 Anniversary Update, Version 1607 (Build 14393).");
        }

        public static void RemoveAppBarWindow(IntPtr target)
        {
            throw new PlatformNotSupportedException("The operation is not supported until Windows 10 Anniversary Update, Version 1607 (Build 14393).");
        }

    }
}
