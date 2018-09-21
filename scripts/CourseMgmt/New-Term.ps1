[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True, HelpMessage = 'A name for the term (e.g., THU-2014-2015-1)')]
    [string]$Name,
    [Parameter(Mandatory = $True, HelpMessage = 'The campus during this term (e.g., Tsinghua University)')]
    [string]$Campus,
    [Parameter(Mandatory = $False)]
    [datetime]$Week1Monday = [datetime]::new(2001, 1, 1),
    [Parameter(Mandatory = $True, HelpMessage = 'The lower bound of week number (inclusive)')]
    [int]$MinWeek,
    [Parameter(Mandatory = $True, HelpMessage = 'The upper bound of week number (inclusive)')]
    [int]$MaxWeek,
    [switch]$WeekBeginsOnMonday,
    [switch]$WeekBeginsOnSunday
)

Begin
{
    If ($Week1Monday -eq [datetime]::new(2001, 1, 1))
    {
        If ($True -ne [datetime]::TryParseExact(
            (Read-Host -Prompt 'Enter the Monday in week 1 (yyyy-MM-dd)'),
            'yyyy-MM-dd',
            [cultureinfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None,
            [ref]$Week1Monday
        ))
        {
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
                [System.FormatException]::new('Week1Monday is ill-formatted.'),
                'Week1MondayFormat',
                [System.Management.Automation.ErrorCategory]::SyntaxError,
                $null
            ))
        }
    }

    If ($Week1Monday.DayOfWeek -ne [System.DayOfWeek]::Monday)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentOutOfRangeException]::new('Week1Monday', 'Week1Monday is not a Monday.'),
            'Week1MondayNotMonday',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $null
        ))
    }

    If ($MinWeek -gt $MaxWeek)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentOutOfRangeException]::new('MaxWeek', $MaxWeek, 'MaxWeek must be at least MinWeek.'),
            'MaxWeek',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            [PSCustomObject]@{ 'MinWeek' = $MinWeek; 'MaxWeek' = $MaxWeek }
        ))
    }

    If ($WeekBeginsOnMonday -and $WeekBeginsOnSunday)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new('WeekBeginsOnMonday and WeekBeginsOnSunday cannot be both set.'),
            'WeekBeginningConflict',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $null
        ))
    }

    If (-not $WeekBeginsOnMonday -and -not $WeekBeginsOnSunday)
    {
        $dayChoices = [System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]]::new()
        $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Mon (&1)', 'A week begins on Monday.'))
        $dayChoices.Add([System.Management.Automation.Host.ChoiceDescription]::new('Sun (&7)', 'A week begins on Sunday.'))
        $choice = $Host.UI.PromptForChoice('Beginning of a week', 'Choose the day from which a week begins', $dayChoices, 0)
        If ($choice -eq 1)
        {
            $WeekBeginsOnMonday = [switch]::new($False)
        }
        Else
        {
            $WeekBeginsOnMonday = [switch]::new($True)
        }
    }
}

Process
{
    [PSCustomObject]@{
        'Name' = $Name;
        'Campus' = $Campus;
        'Week1Monday' = $Week1Monday.Date;
        'MinWeek' = $MinWeek;
        'MaxWeek' = $MaxWeek;
        'WeekBeginsOnMonday' = [bool]$WeekBeginsOnMonday
    }
}
