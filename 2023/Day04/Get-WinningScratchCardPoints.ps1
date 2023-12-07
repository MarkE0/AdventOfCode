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


# Script
if (-not([string]::IsNullOrEmpty($Path))) {
    # Execute functions with provided file
    Get-ScratchCardPoints -CardsContent (Get-Content -Path $Path)
}

