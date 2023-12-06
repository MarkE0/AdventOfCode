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

    $Content | Select-Object -First 14 | Write-Verbose; Write-Verbose "..."

    $YLength = $Content.Length
    $XLength = $Content[0].Length

    for ($y = 0; $y -lt $YLength; $y++) {
        :NextNumberSearch
        for ($x = 0; $x -le $XLength; $x++) {
            if ($x -lt $XLength) {
                $char = $Content[$y][$x]
            }
            else {
                $char = $null
            }
            
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
                        
                            if ($Content[$y2][$x2] -notlike "[0-9.]") { # E.g. is a symbol
                                $PartNumbersSum += [int]("0" + $number) # Prepend a 0 to the number to handle single digit numbers
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

if (-not([string]::IsNullOrEmpty($Path))) {
    $Content = Get-Content -Path $Path
    Get-PartNumbersSumP1 -Content $Content
}
