[CmdletBinding(DefaultParameterSetName = 'Interactive',
    PositionalBinding = $False,
    SupportsShouldProcess = $True)]
Param
(
    [Parameter(ParameterSetName = 'InputObject', Mandatory = $True,
        ValueFromPipeline = $True, Position = 0)]
    [object[]]$InputObject,
    [Parameter(ParameterSetName = 'InputObject', Mandatory = $False)]
    [Parameter(ParameterSetName = 'UI', Mandatory = $False)]
    [object]$DomainDirectory = $null,
    [Parameter(ParameterSetName = 'InputObject', Mandatory = $False)]
    [Parameter(ParameterSetName = 'UI', Mandatory = $False)]
    [ScriptBlock]$DisplayNameComposer = $null
)

Begin
{
    $olContact = 40
    $olFolder = 2
    $olContactItem = 2
    If ($DomainDirectory -eq $null)
    {
        $DomainDirectory = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $queryWildcards = [System.IO.Path]::Combine($PSScriptRoot, 'domain-*.csv')
        Get-ChildItem $queryWildcards | ForEach-Object {
            $_ | Get-Content -Encoding UTF8 -Raw | ConvertFrom-Csv | ForEach-Object {
                $DomainDirectory[$_.Domain.Trim()] = $_
            }
        }
    }
    If ($DisplayNameComposer -eq $null)
    {
        $DisplayNameComposer = {
            If ($args[1].Decoration -eq '') { $args[0].FullName }
            Else { $args[0].FullName + ' (' + $args[1].Decoration + ')' }
        }
    }
    $ResolveEmailAnnotation = [System.IO.Path]::Combine($PSScriptRoot, 'Resolve-EmailAnnotation.ps1')
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

        $toEnum |
            Write-Output -PipelineVariable contact |
            & $ResolveEmailAnnotation -DomainDirectory $DomainDirectory |
            ForEach-Object {
                $res = $_.ByIndex
                $isCompliant = $True
                $actionDescription = $contact.FullName + ' has the following e-mail address(es) on file:'
                1..3 | ForEach-Object {
                    $currentEmail = $res."Email$_"
                    If ($currentEmail.Exists)
                    {
                        $currentEmail | Add-Member -MemberType NoteProperty `
                            -Name 'CurrentDisplayName' `
                            -Value ($contact."Email$($_)DisplayName") `
                            -Force
                        $actionDescription += [System.Environment]::NewLine
                        $actionDescription += '    ' + $currentEmail.CurrentDisplayName
                        If ($currentEmail.IsSmtp)
                        {
                            $actionDescription += ' <' + $currentEmail.Address + '>'
                        }
                        Else
                        {
                            $actionDescription += ' <non-SMTP address>'
                        }
                    }
                }
                $actionDescription += [System.Environment]::NewLine
                $actionDescription += 'The new e-mail display name(s) will be:'
                1..3 | ForEach-Object {
                    $currentEmail = $res."Email$_"
                    If ($currentEmail.Exists)
                    {
                        $currentEmail | Add-Member -MemberType NoteProperty `
                            -Name 'ComposedDisplayName' `
                            -Value (& $DisplayNameComposer $contact $currentEmail) `
                            -Force
                        $actionDescription += [System.Environment]::NewLine
                        $actionDescription += '    ' + $currentEmail.ComposedDisplayName
                        If ($currentEmail.IsSmtp)
                        {
                            $actionDescription += ' <' + $currentEmail.Address + '>'
                        }
                        Else
                        {
                            $actionDescription += ' <non-SMTP address>'
                        }
                        If ($currentEmail.ComposedDisplayName -ne $currentEmail.CurrentDisplayName)
                        {
                            $isCompliant = $False
                        }
                    }
                }
                $warningText = $actionDescription + [System.Environment]::NewLine
                $warningText += 'Do you want to perform this operation?'
                If ($isCompliant)
                {
                    $PSCmdlet.WriteVerbose("Skipped compliant contact: $($contact.FullName)")
                }
                ElseIf ($PSCmdlet.ShouldProcess($actionDescription, $warningText, 'Editing Contact'))
                {
                    1..3 | ForEach-Object {
                        $currentEmail = $res."Email$_"
                        If ($currentEmail.Exists)
                        {
                            $contact."Email$($_)DisplayName" = $currentEmail.ComposedDisplayName
                        }
                    }
                    $contact.Save()
                    $PSCmdlet.WriteVerbose("Edited: $($contact.FullName)")
                }
        }
    }
}
