[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $True, HelpMessage = 'The default name')]
    [string]$Subject,
    [Parameter(Mandatory = $True, HelpMessage = 'The default location')]
    [string]$Location,
    [Parameter(Mandatory = $True, HelpMessage = 'The default reminder (in minutes, negative to disable)')]
    [int]$Reminder
)

Begin
{
    $dayChoices = [System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]]::new()
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Cancel (&X)', 'Finish the current course'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Mon (&1)', 'Monday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Tue (&2)', 'Tuesday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Wed (&3)', 'Wednesday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Thu (&4)', 'Thursday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Fri (&5)', 'Friday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Sat (&6)', 'Saturday'))
    $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Sun (&7)', 'Sunday'))
    $GetDayOfWeek = {
        $dowChoice = $Host.UI.PromptForChoice('Day in a week', 'Choose the day in a week for this occurrence', $dayChoices, 0)
        If ($dowChoice -notin @(1, 2, 3, 4, 5, 6, 7))
        {
            0 # PowerShell ISE returns nothing if the user closes the dialog
        }
        Else
        {
            $dowChoice
        }
    }

    If ($Reminder -lt 0)
    {
        $Reminder = -1
    }
}

Process
{
    $regex = [regex]::new('^([01]?[0-9]|2[0123]):([0-4]?[0-9]|5[0-9])-([01]?[0-9]|2[0123]):([0-4]?[0-9]|5[0-9])$')
    $occurrences = @(& {
        While ($true)
        {
            $day = & $GetDayOfWeek
            If ($day -eq 0)
            {
                Break
            }
            $weeks = Read-Host -Prompt 'Weeks (e.g., 0,3,5-9,10; 1 for the first week)'
            $weekErrRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.FormatException]::new('The weeks are ill-formatted.'),
                'WeeksFormat',
                [System.Management.Automation.ErrorCategory]::SyntaxError,
                $weeks
            )
            $weeks = @($weeks.Split(',') | ForEach-Object {
                [int]$startWeek = 0
                [int]$endWeek = 0
                $range = $_.Trim().Split('-').Trim()
                If ($range.Count -eq 1)
                {
                    If (-not [int]::TryParse($range, [ref]$startWeek))
                    {
                        $PSCmdlet.ThrowTerminatingError($weekErrRecord)
                    }
                    Else
                    {
                        $endWeek = $startWeek
                    }
                }
                ElseIf ($range.Count -eq 2)
                {
                    If (-not [int]::TryParse($range[0], [ref]$startWeek) -or -not [int]::TryParse($range[1], [ref]$endWeek))
                    {
                        $PSCmdlet.ThrowTerminatingError($weekErrRecord)
                    }
                    If ($startWeek -gt $endWeek)
                    {
                        $PSCmdlet.ThrowTerminatingError($weekErrRecord)
                    }
                }
                Else
                {
                    $PSCmdlet.ThrowTerminatingError($weekErrRecord)
                }
                $startWeek..$endWeek
            } | Sort-Object | Get-Unique)
            $timeSlot = Read-Host -Prompt 'Time slot (H:m-H:m)'
            $tsErrRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.FormatException]::new('The time slot is ill-formatted.'),
                'TimeSlotFormat',
                [System.Management.Automation.ErrorCategory]::SyntaxError,
                $timeSlot
            )
            $match = $regex.Match($timeSlot)
            If (-not $match.Success)
            {
                $PSCmdlet.ThrowTerminatingError($tsErrRecord)
            }
            $startMinutes = [int]::Parse($match.Groups[1].Value) * 60 + [int]::Parse($match.Groups[2].Value)
            $endMinutes = [int]::Parse($match.Groups[3].Value) * 60 + [int]::Parse($match.Groups[4].Value)
            If ($startMinutes -gt $endMinutes)
            {
                $PSCmdlet.ThrowTerminatingError($tsErrRecord)
            }
            $overrideSubject = Read-Host -Prompt 'Override name (empty for default)'
            $overrideLocation = Read-Host -Prompt 'Override location (empty for default)'
            $overrideReminder = Read-Host -Prompt 'Override reminder (empty for default, negative to disable)'
            If ([string]::IsNullOrWhiteSpace($overrideSubject))
            {
                $overrideSubject = $null
            }
            If ([string]::IsNullOrWhiteSpace($overrideLocation))
            {
                $overrideLocation = $null
            }
            If ([string]::IsNullOrWhiteSpace($overrideReminder))
            {
                $overrideReminder = $null
            }
            Else
            {
                $overrideReminder = [int]::Parse($overrideReminder)
                If ($overrideReminder -lt 0)
                {
                    $overrideReminder = -1
                }
            }
            [PSCustomObject]@{
                'Weeks' = $weeks;
                'Day' = $day;
                'StartHour' = [int]::Parse($match.Groups[1].Value);
                'StartMinute' = [int]::Parse($match.Groups[2].Value);
                'EndHour' = [int]::Parse($match.Groups[3].Value);
                'EndMinute' = [int]::Parse($match.Groups[4].Value);
                'OverrideSubject' = $overrideSubject;
                'OverrideLocation' = $overrideLocation;
                'OverrideReminder' = $overrideReminder
            }
        }
    })
}

End
{
    [PSCustomObject]@{
        'Subject' = $Subject;
        'Location' = $Location;
        'Reminder' = $Reminder;
        'Occurrences' = $occurrences
    }
}
