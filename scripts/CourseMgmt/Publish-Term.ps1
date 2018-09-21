[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $True)]
    [object]$Term,
    [Parameter(Mandatory = $False)]
    [object]$OutlookFolder
)

Begin
{
    If ($Term.CorrId -ne $null)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new('Term is already published.'),
            'TermPublished',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Term
        ))
    }

    If ($OutlookFolder -eq $null)
    {
        $selectFolderScript = [System.IO.Path]::Combine($PSScriptRoot, 'Select-OutlookFolder.ps1')
        $OutlookFolder = & $selectFolderScript
    }

    If ($OutlookFolder -eq $null)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentNullException]::new('OutlookFolder'),
            'OutlookFolderNull',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $null
        ))
    }

    $olAppointmentItem = 1
    $olFree = 0
    $olText = 1
    $olFormatText = 1
    If ($OutlookFolder.DefaultItemType -ne $olAppointmentItem)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new('OutlookFolder is not a calendar folder.', 'OutlookFolder'),
            'OutlookFolderNotCalendar',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $OutlookFolder
        ))
    }

    $corrId = [System.Guid]::NewGuid().ToString('n')
}

Process
{
    $adjust = -7
    If (-not $Term.WeekBeginsOnMonday)
    {
        $adjust = -8
    }
    ($Term.MinWeek)..($Term.MaxWeek) | ForEach-Object {
        $item = $OutlookFolder.Items.Add($olAppointmentItem)
        $item.Subject = $Term.Name + ': Week ' + $_.ToString()
        $item.Location = $Term.Campus
        $item.ReminderOverrideDefault = $True
        $item.ReminderMinutesBeforeStart = 0
        $item.ReminderSet = $False
        $item.AllDayEvent = $True
        $startTime = $Term.Week1Monday.AddDays(7 * $_ + $adjust)
        $endTime = $startTime.AddDays(7)
        $item.StartInStartTimeZone = $startTime
        $item.EndInEndTimeZone = $endTime
        $item.BusyStatus = $olFree
        $item.UserProperties.Add('CourseMgmtCorrId', $olText, $True, $olFormatText).Value = $corrId
        $item.Save()
    } | Out-Null
}

End
{
    $Term | Add-Member -MemberType NoteProperty -Name 'CorrId' -Value $corrId -Force -PassThru
}
