[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $True)]
    [ValidatePattern('UW 20[0-9]{2}-20[0-9]{2} (Spring|Summer|Summer A|Summer B|Autumn|Winter)', Options='Compiled')]
    [string]$Term,
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$Subject,
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
    [DateTime]$Start,
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
    [int]$Duration,
    [Parameter(Mandatory = $False)]
    [object]$OutlookFolder
)

Begin
{
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

    $corrId = $Term
}

Process
{
    & {
        $item = $OutlookFolder.Items.Add($olAppointmentItem)
        $item.Subject = $Term + ': ' + $Subject
        $item.Location = 'University of Washington'
        $item.ReminderOverrideDefault = $True
        $item.ReminderMinutesBeforeStart = 7200
        $item.ReminderSet = $True
        $item.AllDayEvent = $True
        $startTime = $Start.Date
        $endTime = $Start.Date.AddDays($Duration)
        $item.StartInStartTimeZone = $startTime
        $item.EndInEndTimeZone = $endTime
        $item.BusyStatus = $olFree
        $item.UserProperties.Add('CourseMgmtCorrId', $olText, $True, $olFormatText).Value = $corrId
        $item.Save()
    } | Out-Null
}
