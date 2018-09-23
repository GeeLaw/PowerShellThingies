[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $False, Position = 0)]
    [object]$DomainDirectory,
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email1Address')]
    [string]$PersonalEmailAddress = '',
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email1AddressType')]
    [string]$PersonalEmailAddressType = 'SMTP',
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email2Address')]
    [string]$WorkEmailAddress = '',
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email2AddressType')]
    [string]$WorkEmailAddressType = 'SMTP',
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email3Address')]
    [string]$OtherEmailAddress = '',
    [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [Alias('Email3AddressType')]
    [string]$OtherEmailAddressType = 'SMTP'
)

Begin
{
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
    $domainRegex = [regex]::new('^.+@(.+?)$', 'CultureInvariant, Singleline')
    # & $resolve "someone@example.com"
    $resolveEmail = {
        $result = [PSCustomObject]@{
            'Address' = $args[0];
            'Domain' = '';
            'Type' = 'Other';
            'Name' = '';
            'Decoration' = '';
            'Exists' = $False;
            'IsSmtp' = $False;
            'Details' = $null
        }
        If ([string]::IsNullOrWhiteSpace($args[0]) -or [string]::IsNullOrWhiteSpace($args[1]))
        {
            Return $result
        }
        $result.Exists = $True
        # Might be an Exchange Distinguished Name.
        If ($args[1].ToUpperInvariant() -ne 'SMTP')
        {
            Return $result
        }
        $match = $domainRegex.Match($args[0])
        If (-not $match.Success)
        {
            Return $result
        }
        $result.IsSmtp = $True
        $domains = @($match.Groups[1].Value.Split('.').Trim() | 
            Where-Object Length -gt 0)
        [array]::Reverse($domains)
        $currentDomain = ''
        $domains | ForEach-Object {
            $currentDomain = '.' + $_ + $currentDomain
            $result.Domain = $currentDomain.Substring(1)
            $info = $DomainDirectory[$result.Domain]
            If ($info -ne $null)
            {
                If ($info.Type -ne '')
                {
                    $result.Type = $info.Type
                }
                If (-not [string]::IsNullOrWhiteSpace($info.Name))
                {
                    $result.Name = $info.Name
                }
            }
        }
        Return $result
    }
    $setDetails = {
        If (-not $args[0].Exists) { Return }
        $addr = $args[0].Address
        $domn = $args[0].Domain
        $name = $args[0].Name
        If (-not $args[0].IsSmtp) { $addr = '' }
        If ([string]::IsNullOrWhiteSpace($domn)) { $domn = $addr }
        If ([string]::IsNullOrWhiteSpace($name)) { $name = $domn }
        $args[0].Details = @($name, $domn, $addr)
    }
}

Process
{
    $resolvedPersonal = & $resolveEmail $PersonalEmailAddress $PersonalEmailAddressType
    $resolvedWork = & $resolveEmail $WorkEmailAddress $WorkEmailAddressType
    $resolvedOther = & $resolveEmail $OtherEmailAddress $OtherEmailAddressType

    # Replace Other with appropriate value
    If ($resolvedPersonal.Exists -and $resolvedPersonal.Type -ne 'Work')
    {
        $resolvedPersonal.Type = 'Personal'
    }
    If ($resolvedWork.Exists -and $resolvedWork.Type -ne 'Personal')
    {
        $resolvedWork.Type = 'Work'
    }
    # Replace Other by inferring
    If ($resolvedOther.Exists -and $resolvedOther.Type -ne 'Personal' -and $resolvedOther.Type -ne 'Work')
    {
        If ($resolvedPersonal.Exists -and $resolvedWork.Exists)
        {
            $likePersonal = $False
            $likeWork = $False
            If ($resolvedPersonal.IsSmtp -and $resolvedPersonal.Domain -eq $resolvedOther.Domain)
            {
                $likePersonal = $True
            }
            If ($resolvedWork.IsSmtp -and $resolvedWork.Domain -eq $resolvedOther.Domain)
            {
                $likeWork = $True
            }
            If ($likePersonal -and -not $likeWork)
            {
                $resolvedOther.Type = 'Personal'
            }
            ElseIf (-not $likePersonal -and $likeWork)
            {
                $resolvedOther.Type = 'Work'
            }
            # Otherwise, no heuristics available
        }
        # Personal = empty, Work = non-empty, Other = non-empty
        # it is probable that this is another Work
        ElseIf ($resolvedWork.Exists)
        {
            $resolvedOther.Type = 'Work'
        }
        # Personal = non-empty, Work = empty, Other = non-empty
        # it is probable that this is another Personal
        Else
        {
            $resolvedOther.Type = 'Personal'
        }
    }

    & $setDetails $resolvedPersonal
    & $setDetails $resolvedWork
    & $setDetails $resolvedOther

    $targets = @($resolvedPersonal, $resolvedWork, $resolvedOther | Where-Object Exists)
    $detailStat = [System.Collections.Generic.Dictionary[string, int]]::new()

    $nType = @($targets | Select-Object -ExpandProperty Type | Group-Object).Count
    $nEach = @{}
    $nEach['Personal'] = @($targets | Where-Object Type -eq 'Personal').Count
    $nEach['Work'] = @($targets | Where-Object Type -eq 'Work').Count
    # Always show details for 'Other' if there are at least 2 e-mail addresses
    $nEach['Other'] = $targets.Count

    $targets | ForEach-Object {
        $_.Details | Get-Unique | ForEach-Object { $detailStat[$_] += 1 }
    }

    $targets | ForEach-Object {
        $showType = ''
        $showDetails = ''
        If ([object]::ReferenceEquals($_, $resolvedOther))
        {
            If ($_.Type -eq 'Personal' -and $nEach['Personal'] -ge 2)
            {
                If ($nType -eq 1)
                {
                    $showType = 'Other'
                }
                Else
                {
                    $showType = 'Other Personal'
                }
            }
            ElseIf ($_.Type -eq 'Work' -and $nEach['Work'] -ge 2)
            {
                $similarItemCount = @($targets | Where-Object {
                    $_.Type -eq 'Work' -and -not [object]::ReferenceEquals($_, $resolvedOther)
                } | Where-Object {
                    $commonLast = 0
                    $str1 = $_.Domain
                    $str2 = $resolvedOther.Domain
                    $len = [System.Math]::Min($str1.Length, $str2.Length)
                    While ($commonLast -lt $len)
                    {
                        If ($str1[-1 - $commonLast] -eq $str2[-1 - $commonLast])
                        {
                            $commonLast += 1
                        }
                        Else
                        {
                            Return ($commonLast / $len -ge 0.5)
                        }
                    }
                    Return ($commonLast / $len -ge 0.8)
                }).Count
                # This person has two addresses in the same institute
                If ($similarItemCount -ne 0)
                {
                    If ($nType -eq 1) { $showType = 'Other' }
                    Else { $showType = 'Other Work' }
                }
                # This person works for two institutes
                Else
                {
                    If ($nType -eq 1) { $showType = '' }
                    Else { $showType = 'Work' }
                }
            }
            ElseIf ($_.Type -ne 'Other' -and $nType -ge 2)
            {
                $showType = $_.Type
            }
        }
        ElseIf ($nType -ge 2 -and $_.Type -ne 'Other')
        {
            $showType = $_.Type
        }
        If ($nEach[$_.Type] -ge 2)
        {
            $showDetails = $_.Details |
                Where-Object { $detailStat[$_] -le 1 } |
                Select-Object -First 1
            If ($showDetails -eq $null)
            {
                $showDetails = $_.Details[-1]
            }
        }
        $_.Decoration = @($showType, $showDetails | Where-Object Length -gt 0) -join ' - '
    }

    [PSCustomObject]@{
        'ByIndex' = [PSCustomObject]@{
            'Email1' = $resolvedPersonal;
            'Email2' = $resolvedWork;
            'Email3' = $resolvedOther
        };
        'BySemantics' = [PSCustomObject]@{
            'Personal' = $resolvedPersonal;
            'Work' = $resolvedWork;
            'Other' = $resolvedOther
        }
    }

}
