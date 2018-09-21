[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $True)]
    [object]$Term,
    [Parameter(Mandatory = $True)]
    [object]$Course,
    [Parameter(Mandatory = $False)]
    [object]$OutlookFolder
)

Begin
{
    If ($Course.CorrId -ne $null)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new('Course is already published.'),
            'CoursePublished',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Course
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
    $olBusy = 2
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
    $week1monday = $Term.Week1Monday
    $Course.Occurrences | ForEach-Object {
        $subject = $_.OverrideSubject
        If ($subject -eq $null)
        {
            $subject = $Course.Subject
        }
        $location = $_.OverrideLocation
        If ($location -eq $null)
        {
            $location = $Course.Location
        }
        $reminder = $_.OverrideReminder
        If ($reminder -eq $null)
        {
            $reminder = $Course.Reminder
        }
        $day = $_.Day
        If ($day -eq 7 -and -not $Term.WeekBeginsOnMonday)
        {
            $day = 0
        }
        $startMinutes = $_.StartHour * 60 + $_.StartMinute
        $duration = $_.EndHour * 60 + $_.EndMinute - $startMinutes
        $_.Weeks | ForEach-Object {
            $item = $OutlookFolder.Items.Add($olAppointmentItem)
            $item.Subject = $subject
            $item.Location = $location
            $item.ReminderOverrideDefault = $True
            If ($reminder -lt 0)
            {
                $item.ReminderMinutesBeforeStart = 0
                $item.ReminderSet = $False
            }
            Else
            {
                $item.ReminderMinutesBeforeStart = $reminder
                $item.ReminderSet = $True
            }
            $item.AllDayEvent = $False
            $startTime = $week1monday.AddDays(7 * $_ + $day - 8).AddMinutes($startMinutes)
            $endTime = $startTime.AddMinutes($duration)
            $item.StartInStartTimeZone = $startTime
            $item.EndInEndTimeZone = $endTime
            $item.BusyStatus = $olBusy
            $item.UserProperties.Add('CourseMgmtCorrId', $olText, $True, $olFormatText).Value = $corrId
            $item.Save()
        } | Out-Null
    }
}

End
{
    # Use the user property to search for created courses.
    # CorrId stands for Correlation Identifer.
    $Course | Add-Member -MemberType NoteProperty -Name 'CorrId' -Value $corrId -Force -PassThru
}
