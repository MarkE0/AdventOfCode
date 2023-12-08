[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]
    $Path
)

# Functions
function Get-ScratchCardPoints {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $CardsContent
    )

    $Points = 0

    foreach ($Card in $CardsContent) {
        $null = $Card -match 'Card\s+(\d+): ([\d\s]+) \| ([\d\s]+)'
        $LineSplit = $Matches
        $WinningNumbersCount = 0
        foreach ($Number in ($LineSplit[2] -replace "  +", " ").Trim().Split(' ')) {
            if ($LineSplit[3] -match "\b$Number\b") {
                $WinningNumbersCount++
            }
        }
        if ($WinningNumbersCount -gt 0) {
            $Points += [Math]::Pow(2, $WinningNumbersCount - 1)
        }
    }

    return $Points
}

function Get-CardsSum {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $CardsContent
    )

    $CardCounts = @{}

    foreach ($Card in $CardsContent) {
        $CardNumber, $WinningNumbers, $MyNumbers = $Card -split ':\s+| \| '
        $CardNumber = [int]($CardNumber -replace "Card\s+","")

        # Each card exists once already
        if ($CardCounts.ContainsKey($CardNumber)) {
            $CardCounts[$CardNumber]++
        } else {
            $CardCounts[$CardNumber] = 1
        }

        # Use Compare-Object to find the winning numbers
        # $MyWinningNumbers = Compare-Object -ReferenceObject ($WinningNumbers -split '\s+') -DifferenceObject ($MyNumbers -split '\s+') -IncludeEqual -ExcludeDifferent -PassThru

        # Using a HashSet is faster than using Compare-Object
        $MyWinningNumbers = $WinningNumbers -split '\s+' -as [System.Collections.Generic.HashSet[int]] # Use this as we can perform an intersection between two hashsets
        $MyWinningNumbers.IntersectWith($MyNumbers -split '\s+' -as [System.Collections.Generic.HashSet[int]])

        # Write-Verbose "Wins: $($MyWinningNumbers.Count)" -Verbose

        $CountOfThisCard = $CardCounts[$CardNumber]
        for ($i=1; $i -le $MyWinningNumbers.Count; $i++) {
            if ($CardCounts.ContainsKey($CardNumber)) {
                $CardCounts[$CardNumber+$i] += $CountOfThisCard
            } else {
                $CardCounts[$CardNumber+$i] = 1
            }
        }
    }

    # $CardCounts | Write-Verbose -Verbose
    return $CardCounts.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
}


# Script
if (-not([string]::IsNullOrEmpty($Path))) {
    # Execute functions with provided file
    Get-ScratchCardPoints -CardsContent (Get-Content -Path $Path)
    Get-CardsSum -CardsContent (Get-Content -Path $Path)
}

