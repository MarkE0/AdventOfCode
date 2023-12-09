[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

# Functions
function Get-SeedMinLocationP1 {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    # $SeedMapData
    $AllMaps = @{}
    for ($i = 0; $i -lt $SeedMapData.Length; $i++) {
        $Line = $SeedMapData[$i]
        if ($Line -match "seeds:") {
            $Seeds = ($Line -replace "seeds: ", "") -split "\s"
        }

        if ($Line -match " map:") {
            $MapName = ($Line -replace " map:", "")
            $Line = $SeedMapData[$i + 1]
            $Map = [System.Collections.ArrayList]@()
            while ($Line -match '\d+ \d+ \d+' -and $i -lt $SeedMapData.Length) {
                $i++
                $Destination, $SourceStart, $Length = ($Line -split "\s")
                $SourceEnd = [Int64]$SourceStart + [Int64]$Length - 1
                $Shift = [Int64]$Destination - [Int64]$SourceStart

                $null = $Map.Add([PSCustomObject]@{
                    SourceStart = $SourceStart -as [Int64]
                    SourceEnd = $SourceEnd -as [Int64]
                    Shift = $Shift -as [Int64]
                })

                $Line = $SeedMapData[$i + 1]
            }
            $AllMaps.Add($MapName, $Map)
        }
    }

    $SeedToLocationMap = @{}
    foreach ($Seed in $Seeds) {
        $MapNamePart = "seed-to-"
        $MappedValue = $Seed -as [Int64]
        while ($AllMaps.Keys -like "$MapNamePart*") {
            $Shift = 0
            $MapName = $AllMaps.Keys | Where-Object { $_ -match $MapNamePart }
            $Map = $AllMaps[$MapName]
            $Shift = $Map | Where-Object { $_.SourceStart -le $MappedValue -and $_.SourceEnd -ge $MappedValue } | Select-Object -ExpandProperty Shift
            $MappedValue += [Int64]$Shift
            $MapNamePart = $MapName -replace "$MapNamePart", "" -replace '$', '-to-'
        }
        $SeedToLocationMap.Add($Seed, $MappedValue)
    }

    return $SeedToLocationMap.Values | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
}

# Main
if (Test-Path -Path $Path) {
    Get-SeedMinLocationP1 -SeedMap (Get-Content -Path $Path | Where-Object { [string]::IsNullOrEmpty($_) -eq $false} )
}