Param (
    [Parameter(Mandatory=$false)]
    [string]
    $Path
)


function Get-PartNumbersSumP1 {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Content
    )
    
    $PartNumbersSum = 0

    $Content = $Content -replace "\.", " "
    $Content | Write-Verbose

    $YLength = $Content.Length
    $XLength = $Content[0].Length

    for ($y = 0; $y -lt $YLength; $y++) {
        :NextNumberSearch
        for ($x = 0; $x -lt $XLength; $x++) {
            $char = $Content[$y][$x]
            
            if ($char -like "[0-9]") {
                if ($null -eq $number) {
                    $number = $char
                    $numberStart = $x
                }
                else {
                    $number += $char
                }
            }
            else {
                if ($number -like "[0-9]*") { # E.g. Have a complete number
                    $numberEnd = $x - 1

                    for ($y2 = ($y - 1); $y2 -le ($y + 1); $y2++) {
                        if ($y2 -lt 0 -or $y2 -ge $YLength) { continue }
                        for ($x2 = ($numberStart - 1); $x2 -le ($numberEnd + 1); $x2++) {
                            if ($x2 -lt 0 -or $x2 -ge $XLength) { continue }
                        
                            if ($Content[$y2][$x2] -notlike "[0-9 ]") { # E.g. is a symbol
                                $PartNumbersSum += [int]$number
                                $number = $null
                                continue NextNumberSearch
                            }
                        }
                    }
                    $number = $null
                }
            }
        }
    }

    $PartNumbersSum
}


Write-Verbose "Path: $Path"

if ($null -ne $Path) {
    $Content = Get-Content -Path $Path
    $Content = (Get-Content -Path $Path -Raw) -split "`r`n"
    Get-PartNumbersSumP1 -Content $Content
}
