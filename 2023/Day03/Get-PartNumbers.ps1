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



function Get-GearRatioSumP2 {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Content
    )
    
    $GearRatioSum = 0
    $YLength = $Content.Length
    $XLength = $Content[0].Length

    for ($y = 0; $y -lt $YLength; $y++) {
        for ($x = 0; $x -le $XLength; $x++) {
            $char = $Content[$y][$x]
            
            if ($char -eq "*") {
                $numbers = $null
                for ($y2 = ($y - 1); $y2 -le ($y + 1); $y2++) {
                    if ($y2 -lt 0 -or $y2 -ge $YLength) { continue }
                    $numberLine = $null

                    # Look to left of X coordinate
                    $i = 1
                    $num = $Content[$y2][$x-$i]
                    while ($num -like "[0-9]") {
                        $numberLine = $num + $numberLine
                        $num = $Content[$y2][$x-(++$i)]
                    }

                    # Take any number on the X coordinate
                    $numberLine += $Content[$y2][$x] -replace "[^0-9]", " "

                    # Look to right of X coordinate
                    $i = 1
                    $num = $Content[$y2][$x+$i]
                    while ($num -like "[0-9]") {
                        $numberLine = $numberLine + $num
                        $num = $Content[$y2][$x+(++$i)]
                    }

                    $numbers += " " + $numberLine
                }
                $numbers = ($numbers -replace " +", " ").Trim().Split(" ")
                Write-Verbose "Numbers: $numbers"

                if ($numbers.Count -eq 2) {
                    $GearRatioSum += [int]$numbers[0] * [int]$numbers[1]
                }
            }
        }
    }

    $GearRatioSum
}


Write-Verbose "Path: $Path"

if (-not([string]::IsNullOrEmpty($Path))) {
    $Content = Get-Content -Path $Path
    Get-PartNumbersSumP1 -Content $Content
    Get-GearRatioSumP2 -Content $Content
}
