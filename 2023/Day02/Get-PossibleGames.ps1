# .\Get-PossibleGames.ps1 -Path .\input.txt

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]
    $Path
)

$CubesMaxes = @{
    'red'   = 12
    'green' = 13
    'blue'  = 14
}
$GameNumberTotal = 0

function Get-PossibleGamesP1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Content,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $CubeMaxes
    )

    # foreach line in Content, split the line on a colon
    :NextLine
    foreach ($Line in $Content) {                             # Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        $GameText    = $line.Split(':')[0].Trim()             # Game 1
        $GameDetails = $line.Split(':')[1].Trim()             # 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        foreach ($Draw in $GameDetails.Split(';')) {          # 3 blue, 4 red
            foreach ($ColourSet in $draw.Split(',').Trim()) { # 3 blue
                $Colour = $ColourSet.Split(' ')[1].Trim()     # blue
                [int]$Count = $ColourSet.Split(' ')[0].Trim() # 3
                if ($Count -gt $CubeMaxes[$Colour]) {
                    continue NextLine
                }
            }
        }
        $GameNumberTotal += [int]$GameText.Split(' ')[1].Trim()
    }
    $GameNumberTotal
}

function Get-PossibleGamesP2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Content
    )

    $PowerSum = 0
    foreach ($Line in $Content) {                             # Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        $RedMax = $GreenMax = $BlueMax = 0
        $GameText    = $line.Split(':')[0].Trim()             # Game 1
        $GameDetails = $line.Split(':')[1].Trim()             # 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        foreach ($Draw in $GameDetails.Split(';')) {          # 3 blue, 4 red
            foreach ($ColourSet in $draw.Split(',').Trim()) { # 3 blue
                $Colour = $ColourSet.Split(' ')[1].Trim()     # blue
                [int]$Count = $ColourSet.Split(' ')[0].Trim() # 3

                switch ($Colour) {
                    'red'   { if ($Count -gt $RedMax)   {$RedMax = $Count}}
                    'green' { if ($Count -gt $GreenMax) {$GreenMax = $Count}}
                    'blue'  { if ($Count -gt $BlueMax)  {$BlueMax = $Count}}
                    Default { Write-Warning "Colour not found: $Colour" }
                }
            }
        }
        if ($RedMax -lt 1 -or $GreenMax -lt 1 -or $BlueMax -lt 1) {
            Write-Warning "Game $GameText is missing one colour"
        }
        else {
            $Power = $RedMax * $GreenMax * $BlueMax
            $PowerSum += $Power
        }
    }
    $PowerSum
}

Write-Verbose "Path: $Path"
if (Test-Path -Path $Path) {
    # Get the input from the file
    $Content = Get-Content -Path $Path

    Get-PossibleGamesP1 -Content $Content -CubeMaxes $CubesMaxes
    Get-PossibleGamesP2 -Content $Content
} else {
    Write-Information "Path does not exist" -InformationAction Continue
}
