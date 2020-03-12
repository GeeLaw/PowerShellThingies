[CmdletBinding()]
Param
(
    [ValidateRange(7, [uint32]::MaxValue)]
    [uint32]$Days = [uint32](([datetime]::now.Year - 1995) * 365),
    [ValidateSet('Object', 'HashTable', 'Json', 'Csv', 'Html')]
    [string]$Format = 'Object'
)

Process
{
    $local:uri = 'https://eprint.iacr.org/eprint-bin/search.pl?last=' + $Days.ToString([cultureinfo]::InvariantCulture) + '&title=1';
    $local:content = (Invoke-WebRequest -Uri $uri -UseBasicParsing).Content;
    If ($content -eq $null) { Return; }
    If ($Format -eq 'Html') { $content; Return; }
    $local:rgx1 = [regex]'<dt>\s*<a[^>]*>([0-9/]+)</a>(\s|\S)*?<dd><b>((\s|\S)*?)</b>\s*<dd><em>((\s|\S)*?)</em>';
    $local:rgx2 = [regex]'\s+';
    $local:entities = [System.Collections.Generic.Dictionary[string, char]]::new();
    $entities['lt'] = '<'; $entities['gt'] = '>';
    @(('Agrave', 192), ('Aacute', 193), ('Acirc', 194), ('Atilde', 195), ('Auml', 196), ('Aring', 197), ('AElig', 198), ('Ccedil', 199), ('Egrave', 200), ('Eacute', 201), ('Ecirc', 202), ('Euml', 203), ('Igrave', 204), ('Iacute', 205), ('Icirc', 206), ('Iuml', 207), ('ETH', 208), ('Ntilde', 209), ('Ograve', 210), ('Oacute', 211), ('Ocirc', 212), ('Otilde', 213), ('Ouml', 214), ('Oslash', 216), ('Ugrave', 217), ('Uacute', 218), ('Ucirc', 219), ('Uuml', 220), ('Yacute', 221), ('THORN', 222), ('szlig', 223), ('agrave', 224), ('aacute', 225), ('acirc', 226), ('atilde', 227), ('auml', 228), ('aring', 229), ('aelig', 230), ('ccedil', 231), ('egrave', 232), ('eacute', 233), ('ecirc', 234), ('euml', 235), ('igrave', 236), ('iacute', 237), ('icirc', 238), ('iuml', 239), ('eth', 240), ('ntilde', 241), ('ograve', 242), ('oacute', 243), ('ocirc', 244), ('otilde', 245), ('ouml', 246), ('oslash', 248), ('ugrave', 249), ('uacute', 250), ('ucirc', 251), ('uuml', 252), ('yacute', 253), ('thorn', 254), ('yuml', 255)) | ForEach-Object { $entities.Add($_[0], ([char]$_[1]).ToString()) } | Out-Null;
    $local:rgx3 = [regex]'&(#[0-9]+|#x[0-9a-fA-F]+|lt|gt|Agrave|Aacute|Acirc|Atilde|Auml|Aring|AElig|Ccedil|Egrave|Eacute|Ecirc|Euml|Igrave|Iacute|Icirc|Iuml|ETH|Ntilde|Ograve|Oacute|Ocirc|Otilde|Ouml|Oslash|Ugrave|Uacute|Ucirc|Uuml|Yacute|THORN|szlig|agrave|aacute|acirc|atilde|auml|aring|aelig|ccedil|egrave|eacute|ecirc|euml|igrave|iacute|icirc|iuml|eth|ntilde|ograve|oacute|ocirc|otilde|ouml|oslash|ugrave|uacute|ucirc|uuml|yacute|thorn|yuml);';
    $local:ev3 = [System.Text.RegularExpressions.MatchEvaluator] {
        $local:x = $args[0].Groups[1].Value;
        If ($x[0] -eq '#')
        {
            If ($x[1] -eq 'x')
            {
                Return ([char][uint16]::Parse($x.Substring(2), [System.Globalization.NumberStyles]::HexNumber)).ToString();
            }
            Return ([char][uint16]::Parse($x.Substring(1))).ToString();
        }
        Return $entities[$x];
    };
    $local:sanitizeHtml = {
        $rgx2.Replace($rgx3.Replace($args[0].Trim(), $ev3).Replace('&amp;', '&'), ' ')
    };
    $local:getHashTable = {
        $rgx1.Matches($content) | ForEach-Object { @{
            'Id' = $_.Groups[1].Value;
            'Title' = & $sanitizeHtml ($_.Groups[3].Value);
            'Authors' = & $sanitizeHtml ($_.Groups[5].Value);
        } }
    };
    $local:getObject = {
        $rgx1.Matches($content) | ForEach-Object { [pscustomobject]@{
            'Id' = $_.Groups[1].Value;
            'Title' = & $sanitizeHtml ($_.Groups[3].Value);
            'Authors' = & $sanitizeHtml ($_.Groups[5].Value);
        } }
    };
    If ($Format -eq 'Object') { & $getObject; Return; }
    If ($Format -eq 'HashTable') { & $getHashTable; Return; }
    If ($Format -eq 'Json')
    {
        & $getHashTable | ConvertTo-Json -Depth 1 -Compress;
        Return;
    }
    If ($Format -eq 'Csv')
    {
        & $getObject | ConvertTo-Csv -NoTypeInformation;
        Return;
    }
}
