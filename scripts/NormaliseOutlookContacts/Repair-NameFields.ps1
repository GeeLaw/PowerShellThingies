[CmdletBinding(DefaultParameterSetName = 'Interactive',
    PositionalBinding = $False)]
Param
(
    [Parameter(ParameterSetName = 'InputObject', Mandatory = $True,
        ValueFromPipeline = $True, Position = 0)]
    [object[]]$InputObject,
    [Parameter(ParameterSetName = 'Interactive')]
    [Parameter(ParameterSetName = 'InputObject')]
    [switch]$FixFullName
)

Begin
{
    $olContact = 40
    $olFolder = 2
    $olContactItem = 2
    If ($PSCmdlet.ParameterSetName -eq 'Interactive')
    {
        $chosenFolder = (New-Object -ComObject Outlook.Application).GetNamespace('MAPI').PickFolder()
        If ($chosenFolder -eq $null)
        {
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new('Operation cancelled.'),
                'OperationCancelled',
                [System.Management.Automation.ErrorCategory]::OperationStopped,
                $null
            ))
        }
        $InputObject = @($chosenFolder)
    }
}

Process
{
    $InputObject | ForEach-Object {
        $toEnum = @()
        If ($_.Class -eq $olContact)
        {
            $toEnum = @($_)
        }
        ElseIf ($_.Class -eq $olFolder)
        {
            $toEnum = @($_.Items | Write-Output | Where-Object { $_.Class -eq $olContact })
            If ($toEnum.Count -eq 0)
            {
                $PSCmdlet.WriteVerbose("Folder does not contain Contact object: $($_.Name)")
            }
        }
        ElseIf ($_.Name -ne $null)
        {
            $PSCmdlet.WriteVerbose("Skipped non-Folder/Contact object: $($_.Name)")
        }
        Else
        {
            $PSCmdlet.WriteVerbose("Skipped non-Folder/Contact object: $_")
        }

        $toEnum | ForEach-Object {
            $fileAs = ''
            $firstName = $_.FirstName.Trim()
            $lastName = $_.LastName.Trim()
            If ($FixFullName)
            {
                $_.FirstName = $firstName
            }
            If ($lastName -ne '')
            {
                $fileAs = $lastName
                If ($firstName -ne '')
                {
                    $fileAs += ', '
                }
            }
            If ($firstName -ne '')
            {
                $fileAs += $firstName
            }
            If ($_.FileAs -ne $fileAs)
            {
                $_.FileAs = $fileAs
            }
            If (-not $_.Saved)
            {
                $_.Save()
            }
        }
    }
}
