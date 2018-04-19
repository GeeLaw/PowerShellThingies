<#
.Synopsis
    Move the host into a docking position or undock the host.

.Description
    Depending on "Position" parameter, the host will either
    become a docked window (Application Desktop Toolbar) or
    be restored to a usual window.

    "dock" is an alias of this cmdlet.

    Notice: You MUST use "exit" command to quit the host if
    the host is docked, otherwise the docking position will
    not be reclaimed by the system immediately after the
    termination of the process.

.Parameter Position
    Default parameter, default value is "Right".

    Possible values are "Left", "Right", "Top", "Bottom" and
    "Center".

    If the value is "Center", the host will be undocked.
    Otherwise, the host is docked into "Position" of the
    primary screen.

.Example
    Move-Host Left

    If the host is not docked, this docks the host to the
    left of the screen. If the host is already docked, it
    is moved to the left of the screen if not already there.

.Example
    dock Center

    If the host is docked, this undocks the host. Otherwise,
    it does nothing.

    It is also possible to use "Pop-Host" cmdlet to undock
    the host.

#>
Function Move-Host
{
    [Alias('dock')]
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS')]
    Param
    (
        [ValidateSet('Left', 'Right', 'Top', 'Bottom', 'Center')]
        [string]$Position = 'Right'
    )
    Process
    {
        $Position = $Position.ToLower();
        If ($Position -eq 'center')
        {
            Pop-Host;
            Return;
        }
        [DockPSHelper.AppBarHelper]::AddAppBarWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, $Position);
        [DockPSHelper.AppBarHelper]::MoveAppBarWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, $Position);
    }
}

<#
.Synopsis
    Undock the host.

.Description
    If the host is docked, this undocks the host. Otherwise,
    it does nothing. Equivalent to "Move-Host -Position Center".

    "undock" is an alias of this cmdlet.

.Example
    Pop-Host

    If the host is docked, this undocks the host. Otherwise,
    it does nothing.

    It is also possible to use "Move-Host" cmdlet with Position
    being "Center" to undock the host.

#>
Function Pop-Host
{
    [Alias('undock')]
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS')]
    Param()
    Process
    {
        [DockPSHelper.AppBarHelper]::RemoveAppBarWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle);
    }
}

<#
.Synopsis
    Resize the docked host.

.Description
    If the host is docked, this resizes the dock. The size
    is in the percentage of the primary screen size.

    "resize" is an alias of this cmdlet.

    The input value(s) might be adjusted by the docking manager
    so that the window has reasonable size. However, if the
    input value(s) is/are 0, the corresponding size will not be
    modified.

.Parameter Both
    The percentage of either height or width, whichever applies
    to the docking position.

    Notice: The value is multiplied by 100.

.Parameter Height
    The height. This can be set while the host is in all four
    docking positions, but only exhibits immediate effect if
    the host is docked to the top/bottom of the screen.

.Parameter Width
    The width. This can be set while the host is in all four
    docking positions, but only exhibits immediate effect if
    the host is docked to the left/right of the screen.

.Example
    Resize-Host 30

    If the host is docked, this sets the height/width of the
    "free edge" of the host to 30% of the primary screen.
    Otherwise, it does nothing.

.Example
    Resize-Host -Height 30

    If the host is docked, this sets the height of of the
    host to 30% of the primary screen height, which is in
    effect when the host is docked top the top/bottom of
    the screen. Otherwise, it does nothing.

#>
Function Resize-Host
{
    [Alias('resize')]
    [CmdletBinding(HelpUri = 'https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/Dock-PS', DefaultParameterSetName = 'Both', PositionalBinding = $false)]
    Param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Both', Position = 0)]
        [ValidateRange(0, 100)]
        [int]$Both,
        [Parameter(ParameterSetName = 'Separate', Position = 0)]
        [ValidateRange(0, 100)]
        [int]$Width = 0,
        [Parameter(ParameterSetName = 'Separate', Position = 1)]
        [ValidateRange(0, 100)]
        [int]$Height = 0
    )
    Process
    {
        If ($PSCmdlet.ParameterSetName -eq 'Both')
        {
            [DockPSHelper.AppBarHelper]::ResizeAppBarWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, $Both / 100.0, $Both / 100.0);
        }
        Else
        {
            [DockPSHelper.AppBarHelper]::ResizeAppBarWindow([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, $Width / 100.0, $Height / 100.0);
        }
    }
}

Export-ModuleMember -Function @('Move-Host', 'Pop-Host', 'Resize-Host') -Alias @('dock', 'undock', 'resize') -Cmdlet @() -Variable @();
