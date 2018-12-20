$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $True

Write-Host 'Open the calendar sheet.'
Pause

$Excel.ActiveWindow.Activate() | Out-Null
$Sheets = $Excel.ActiveWorkbook.Sheets | Write-Output

$TextReplacement = @{}
$TextReplacementSheet = $Sheets | Where-Object Name -eq 'TextReplacement'
1..1024 | ForEach-Object -Begin { $shouldSkip = $False } -Process {
    If ($shouldSkip) { Return }
    $Original = $TextReplacementSheet.Cells($_, 1).Text
    $Replaced = $TextReplacementSheet.Cells($_, 2).Text
    If ($Original -eq '**EXCLUDE**')
    {
        $shouldSkip = $True
        Return
    }
    $TextReplacement[$Original] = $Replaced
}

$shtUPass = $Sheets | Where-Object Name -eq 'UPass'
$shtFee = $Sheets | Where-Object Name -eq 'Fee'
$shtReg = $Sheets | Where-Object Name -eq 'Registration'
$shtGrade = $Sheets | Where-Object Name -eq 'Grade'
$shtInstruction = $Sheets | Where-Object Name -eq 'Instruction'
$shtAddDrop = $Sheets | Where-Object Name -eq 'AddDrop'
$shtHoliday = $Sheets | Where-Object Name -eq 'Holiday'

$ParseDuration = {
    $mo = '(?:(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)'
    $dy = '([0-9]+)'
    $yr = '([0-9]+)'
    $sp = '(?:(?:\s|,)*)'
    $sp1 = '(?:(?:\s|,)+)'
    $to = '(?:[^0-9A-Za-z, \t\r\n]+)'
    $instr = $args[0]
    $reg = @(
        [pscustomobject]@{
            'Regex' = [regex]::new("^$sp$mo$sp$dy$sp1$yr$sp$");
            'Start' = '$1 $2, $3';
            'End' = '$1 $2, $3'
        },
        [pscustomobject]@{
            'Regex' = [regex]::new("^$sp$mo$sp$dy$sp$to$sp$dy$sp1$yr$sp$");
            'Start' = '$1 $2, $4';
            'End' = '$1 $3, $4'
        },
        [pscustomobject]@{
            'Regex' = [regex]::new("^$sp$mo$sp$dy$sp$to$sp$mo$sp$dy$sp1$yr$sp$");
            'Start' = '$1 $2, $5';
            'End' = '$3 $4, $5'
        },
        [pscustomobject]@{
            'Regex' = [regex]::new("^$sp$mo$sp$dy$sp1$yr$sp$to$sp$mo$sp$dy$sp1$yr$sp$");
            'Start' = '$1 $2, $3';
            'End' = '$4 $5, $6'
        }
    )
    $enUS = [cultureinfo]::GetCultureInfo('en-US')
    $res = @($reg | ForEach-Object {
        $mat = $_.Regex.Match($instr)
        If ($mat.Success)
        {
            [pscustomobject]@{
                'SourceString' = $instr;
                'Success' = $True;
                'Start' = [datetime]::Parse($mat.Result($_.Start), $enUS);
                'End' = [datetime]::Parse($mat.Result($_.End), $enUS)
            }
        }
    })
    If ($res.Count -eq 1)
    {
        $res[0] | Add-Member -MemberType NoteProperty -PassThru `
            -Name 'Duration' -Value ([int](($res[0].End - $res[0].Start).TotalDays + 1.1))
    }
    Else
    {
        [pscustomobject]@{
            'SourceString' = $instr;
            'Success' = $False;
            'Start' = [datetime]::new(2000, 1, 1);
            'End' = [datetime]::new(2000, 1, 1);
            'Duration' = -1
        }
    }
};

@($shtUPass, $shtFee, $shtReg, $shtGrade, $shtInstruction, $shtAddDrop) |
    Write-Output -PipelineVariable shtCurrent | ForEach-Object {
    $shtCurrent.Activate() | Out-Null
    $tblCurrent = $shtCurrent.Cells(1, 1).ListObject
    2..($tblCurrent.ListRows.Count + 1) | Write-Output -PipelineVariable rowCurrent | ForEach-Object {
        $eventCurrent = $shtCurrent.Cells($rowCurrent, 1).Text
        $isUnkEvent = $False
        $skipEvent = $False
        If ($TextReplacement[$eventCurrent] -eq $null)
        {
            $isUnkEvent = $True
            $skipEvent = $True
            $shtCurrent.Cells($rowCurrent, 1).Style = 'Bad'
        }
        Else
        {
            $eventCurrent = $TextReplacement[$eventCurrent]
            If ($eventCurrent -eq '**EXCLUDE**')
            {
                $skipEvent = $True
            $shtCurrent.Cells($rowCurrent, 1).Style = 'Neutral'
            }
        }
    2..($tblCurrent.ListColumns.Count) | Write-Output -PipelineVariable colCurrent | ForEach-Object {
        $cellCurrent = $shtCurrent.Cells($rowCurrent, $colCurrent)
        $cellCurrent.Activate() | Out-Null
        $cellCurrent.Style = 'Normal'
        If ($isUnkEvent -or $skipEvent)
        {
            Return
        }
        ElseIf ($cellCurrent.Text.Trim() -eq '' -or
            $cellCurrent.Text.Trim().ToUpperInvariant() -eq 'N/A' -or
            $cellCurrent.Text.Trim().ToUpperInvariant() -eq 'NA')
        {
            Return
        }
        $parsed = & $ParseDuration $cellCurrent.Text
        If (-not $parsed.Success)
        {
            $cellCurrent.Style = 'Bad'
            Return
        }
        $parsed = $parsed | Select-Object Group, Subject, Start, Duration
        $parsed.Group = $shtCurrent.Cells(1, $colCurrent).Text.Trim()
        $parsed.Subject = $eventCurrent;
        $parsed
    }
    }
}

Write-Warning 'Review the cells!'

$shtHoliday.Activate() | Out-Null
Write-Warning 'Add Holidays yourself!'

