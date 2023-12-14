[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

# Functions
function Get-SeedMaps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    $AllMaps = @{}
    for ($i = 0; $i -lt $SeedMapData.Length; $i++) {
        $Line = $SeedMapData[$i]
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
    $AllMaps
}

function Get-SeedMapsAsSplits {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $SeedMapData
    )

    $MappingSplits = @{[long]0 = 0}
    for ($i = 0; $i -lt $SeedMapData.Length; $i++) {
        $line = $SeedMapData[$i]
        if ($line -match "([a-z\-]) map:") {
            # $MapName = $matches[0]
            $line = $SeedMapData[$i + 1]
            while ($line -match '\d+\s\d+\s\d+' -and $i -lt $SeedMapData.Length) {
                $i++
                $Destination, $SourceStart, $Length = ($line -split "\s")
                $SourceStart = [long]$SourceStart
                $SourceNext = [long]$SourceStart + [long]$Length
                $Shift = [long]$Destination - [long]$SourceStart

                # Attempt 2
                $sortedKeys = $MappingSplits.Keys | Sort-Object
                $originalMappingSplits = $MappingSplits.Clone()
                $findNewEnd = $false
                for ($keyNumber = 0; $keyNumber -lt $sortedKeys.Count; $keyNumber++) {
                    $rangeStart = $sortedKeys[$keyNumber]
                    $nextRangeStart = $sortedKeys[$keyNumber + 1]
                    if ($findNewEnd) {
                        $originalShift = $originalMappingSplits[$rangeStart]
                        $MappingSplits[$rangeStart] = $originalShift + $Shift
                        if ($SourceNext -gt $rangeStart -and ($null -eq $nextRangeStart -or $SourceNext -lt $nextRangeStart)) { # Also NextRangeStart null..?
                            if (-not($MappingSplits.ContainsKey($SourceNext))) { # Should this be in, copying the below entry..?
                                $MappingSplits[$SourceNext] = $originalShift
                            }
                            $findNewEnd = $false
                        }
                    }
                    elseif ($SourceStart -ge $rangeStart -and ($null -eq $nextRangeStart -or $SourceStart -lt $nextRangeStart)) { # Also NextRangeStart null..?
                        $originalShift = $originalMappingSplits[$rangeStart]
                        $MappingSplits[$SourceStart] = $originalShift + $Shift
                        if ($SourceNext -gt $rangeStart -and ($null -eq $nextRangeStart -or $SourceNext -lt $nextRangeStart)) { # Also NextRangeStart null..?
                            if (-not($MappingSplits.ContainsKey($SourceNext))) {
                                $MappingSplits[$SourceNext] = $originalShift
                            }
                        }
                        else {
                            if ($SourceNext -ne $nextRangeStart) {
                                $findNewEnd = $true
                            }
                        }
                    }
                }

                $line = $SeedMapData[$i + 1]
            }
        }
    }
    Write-Verbose "MappingSplits: $($MappingSplits.GetEnumerator() | Sort-Object -Property Key | Out-String)"
    $MappingSplits
}

function Get-SeedNumbers {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    for ($i = 0; $i -lt $SeedMapData.Length; $i++) {
        $Line = $SeedMapData[$i]
        if ($Line -match "seeds:") {
            return ($Line -replace "seeds: ", "") -split "\s"
        }
    }
    Write-Error "No seeds found in SeedMapData"
    exit 1
}

function Get-SeedRanges {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    for ($i = 0; $i -lt $SeedMapData.Length; $i++) {
        $Line = $SeedMapData[$i]
        if ($Line -match "seeds:") {
            $SeedRanges = [System.Collections.ArrayList]@()
            $SeedNumbers = ($Line -replace "seeds: ","") -split "\s"
            for ($j = 0; $j -lt $SeedNumbers.Length; $j++) {
                $SeedStart = $SeedNumbers[$j] -as [Int64]
                $SeedEnd = $SeedStart + ($SeedNumbers[++$j] -as [Int64]) - 1
                $null = $SeedRanges.Add([PSCustomObject]@{
                    SeedStart = $SeedStart
                    SeedEnd = $SeedEnd
                })
            }
            return $SeedRanges
        }
    }
    Write-Error "No seeds found in SeedMapData"
    exit 1
}

function Get-SeedMinLocationP1 {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    $Seeds = Get-SeedNumbers -SeedMapData $SeedMapData
    $AllMaps = Get-SeedMaps -SeedMapData $SeedMapData

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

function Get-SeedMinLocationP2 {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $SeedMapData
    )
    
    $SeedRanges = Get-SeedRanges -SeedMapData $SeedMapData
    $AllMaps = Get-SeedMaps -SeedMapData $SeedMapData

    foreach ($SeedRange in $SeedRanges) {
        for ($Seed = $SeedRange.SeedStart; $Seed -le $SeedRange.SeedEnd; $Seed++) {
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
            if ($null -eq $SeedLocationMinimum -or $MappedValue -lt $SeedLocationMinimum){
                $SeedLocationMinimum = $MappedValue
            }
        }
    }
    return $SeedLocationMinimum
}

function Get-SeedMinLocationP2Better {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $SeedMap
    )

    $Mappings = Get-SeedMapsAsSplits -SeedMapData $SeedMap
    $SeedRanges = Get-SeedRanges -SeedMapData $SeedMap
    $MinimumLocation = $null
    foreach ($seedRange in $SeedRanges) {
        $Mappings.Keys | Where-Object { $_ -ge $seedRange.SeedStart -and $_ -le $seedRange.SeedEnd } | ForEach-Object {
            $lowestLocation = $_ + [long]$Mappings[$_]
            Write-Verbose "Lowest location: $_ : $lowestLocation"
            if ($Null -eq $MinimumLocation -or $MinimumLocation -gt $lowestLocation) {
                $MinimumLocation = $lowestLocation
            }
        }
    }
    Write-Verbose "Minimum: $MinimumLocation"
    return $MinimumLocation
}

# Main
if (Test-Path -Path $Path) {
    Get-SeedMinLocationP1 -SeedMap (Get-Content -Path $Path | Where-Object { [string]::IsNullOrEmpty($_) -eq $false} )
    # Get-SeedMinLocationP2 -SeedMap (Get-Content -Path $Path | Where-Object { [string]::IsNullOrEmpty($_) -eq $false} )
    Get-SeedMinLocationP2Better -SeedMap (Get-Content -Path $Path | Where-Object { [string]::IsNullOrEmpty($_) -eq $false} )
}