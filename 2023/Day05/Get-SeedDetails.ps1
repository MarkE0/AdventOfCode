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

function Get-SeedMapsAttempt3 {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $SeedMapData
    )

    # Set up the initial base range (0-inf initially)
    $baseRanges = @{[long]0 = [PSCustomObject]@{ # TODO: Is this definitely the right way to set this up..?
        baseRangeStart = [long]0;
        baseRangeEnd   = $null;
        shiftAmount    = [long]0;
        shiftedStart   = [long]0;
        shiftedEnd     = $null}
    }

    # Process the mapping details/file
    for ($dataLineArrayNumber = 0; $dataLineArrayNumber -lt $SeedMapData.Length; $dataLineArrayNumber++) {
        $line = $SeedMapData[$dataLineArrayNumber]
        if ($line -match "([a-z\-]) map:") {  # seed-to-soil map:
            # TODO-MaybeNot: Create a semi-clone here? E.g. set the baseRangeStart/End to value of ShiftedStart/End. Then use these new values in the if/else statements below.
            $dataRow = $SeedMapData[$dataLineArrayNumber + 1]
            # $baseRangesTemp = @{}
            while ($dataRow -match '(\d+)\s(\d+)\s(\d+)' -and $dataLineArrayNumber -lt $SeedMapData.Length) { # 50 98 2 (Destination Source Length)
                $dataRow = $SeedMapData[++$dataLineArrayNumber]
                $newDestinationStart, $newSourceStart, $newRangeLength = $dataRow -split '\s' -as [long[]] # Destination Source Length
                $newSourceEnd        = $newSourceStart + $newRangeLength - 1
                # $newDestinationEnd   = $newDestinationStart + $newRangeLength - 1 # Used..?
                $newRangeShift       = $newDestinationStart - $newSourceStart
                $findNewSourceEnd    = $false
                # $startAlreadyShifted = $false
                
                $sortedKeys = $baseRanges.Keys | Sort-Object
                # $originalMappingSplits = $MappingSplits.Clone()
                for ($keyCount = 0; $keyCount -lt $sortedKeys.Count; $keyCount++) { # Loop over the keys in the baseRanges
                    $baseRange = $baseRanges[$sortedKeys[$keyCount]] # Base range is initially 0-inf.; Then 0-49 shifted 0, 50-97 shifted +2, 98-99 shifted -48
                    # If the newSourceStart matches the base range, then update current entry
                    # if ($newSourceStart -eq $baseRange.shiftedStart) {
                    if ($newSourceStart -eq $baseRange.baseRangeStart) {
                            # $baseRange.shiftedStart += $newRangeShift
                        $baseRange.shiftAmount += $newRangeShift
                        $findNewSourceEnd    = $true
                        # $startAlreadyShifted = $true
                    }
                    # Else if the newSourceStart is within the current baseRange, then we need to set a new baseRange for the start of the range, and update the end of the current baseRange
                    # elseif ($newSourceStart -gt $baseRange.shiftedStart -and ($newSourceStart -le $baseRange.shiftedEnd -or $null -eq $baseRange.shiftedEnd)) {
                    elseif ($newSourceStart -gt $baseRange.baseRangeStart -and ($newSourceStart -le $baseRange.baseRangeEnd -or $null -eq $baseRange.baseRangeEnd)) {
                        $newBaseRangeForStart = @{
                            baseRangeStart = $newSourceStart - $baseRange.shiftAmount
                            baseRangeEnd   = $newSourceEnd - $baseRange.shiftAmount;  # TODO: This okay?
                            shiftAmount    = $baseRange.shiftAmount + $newRangeShift  # TODO: These should proably all be type long
                            # shiftedStart   = $newDestinationStart
                            # shiftedEnd     = $newDestinationEnd
                        }
                        # TODO: Now checkf the end of this game also responded in the current range, and say here instead of in about assignment 
                        # If not, then set ends of me take to be that of old game, and look for end in other teams

                        # Update the end of the current baseRange so the new one can start
                        $replacementBaseRange = @{
                            baseRangeStart = $baseRange.baseRangeStart
                            baseRangeEnd   = $newBaseRangeForStart.baseRangeStart - 1
                            shiftAmount    = $baseRange.shiftAmount
                            # shiftedStart   = $baseRange.shiftedStart
                            # shiftedEnd     = $newBaseRangeForStart.shiftedStart - 1
                        }
                        # $baseRange.baseRangeEnd = $newBaseRangeForStart.baseRangeStart - 1
                        # $baseRange.shiftedEnd = $newBaseRangeForStart.shiftedStart - 1
                        $findNewSourceEnd = $true
                    }
                    if ($findNewSourceEnd) {
                        # If the newSourceEnd is within the current baseRange, then we need to set a new baseRange for the end of the range
                        # if ($newSourceEnd -ge $baseRange.shiftedStart -and ($newSourceEnd -lt $baseRange.shiftedEnd -or $null -eq $baseRange.shiftedEnd)) {
                        if ($newSourceEnd -ge $baseRange.baseRangeStart -and ($newSourceEnd -lt $baseRange.baseRangeEnd -or $null -eq $baseRange.baseRangeEnd)) {
                            $newBaseRangeForEnd = @{
                                baseRangeStart = $newSourceEnd - $baseRange.shiftAmount + 1
                                baseRangeEnd   = $baseRange.baseRangeEnd
                                shiftAmount    = $baseRange.shiftAmount
                                # shiftedStart   = $newDestinationEnd + 1
                                # shiftedEnd     = $baseRange.shiftedEnd
                            }
                            $findNewSourceEnd = $false
                            # TODO: Break out of the loop, as we've got the end now
                        }
                        # else {
                        #     if (-not ($startAlreadyShifted)) {
                        #         $baseRange.shiftedStart += $newRangeShift # TODO: All the above "shiftedStart" commented - should be same here..??
                        #     }
                        # }
                    }
                }

                # TODO: Maybe each of these need to make a new set of ranges which are only added (to the baseRanges) at the end of the loop, so that the baseRanges aren't being updated while we're looping over them.
                # Add replacementBaseRange to baseRanges
                if ($replacementBaseRange) {
                    $baseRanges[$replacementBaseRange.baseRangeStart] = $replacementBaseRange
                    # $baseRangesTemp[$replacementBaseRange.baseRangeStart] = $replacementBaseRange
                }

                # Add newBaseRangeForStart to baseRanges
                if ($newBaseRangeForStart) {
                    $baseRanges[$newBaseRangeForStart.baseRangeStart] = $newBaseRangeForStart
                    # $baseRangesTemp[$newBaseRangeForStart.baseRangeStart] = $newBaseRangeForStart
                }

                # Add newBaseRangeForEnd to baseRanges
                if ($newBaseRangeForEnd) {
                    $baseRanges[$newBaseRangeForEnd.baseRangeStart] = $newBaseRangeForEnd
                    # $baseRangesTemp[$newBaseRangeForEnd.baseRangeStart] = $newBaseRangeForEnd
                }

                $dataRow = $SeedMapData[$dataLineArrayNumber + 1]
            }
            # # TODO: Do the update to baseRanges here, so that we're not updating it while we're looping over it.
            # foreach ($baseRangeTemp in $baseRangesTemp.Values) {
            #     $baseRanges[$baseRangeTemp.baseRangeStart] = $baseRangeTemp
            # }

            # TODO: End of the current map set, so apply changes to real baseRanges
            foreach ($baseRangeKey in $baseRanges.Keys) {
                if ($null -eq $baseRanges[$baseRangeKey].shiftedStart) {
                    $baseRanges[$baseRangeKey].shiftedStart = $baseRanges[$baseRangeKey].baseRangeStart
                }
                if ($null -eq $baseRanges[$baseRangeKey].shiftedEnd) {
                    $baseRanges[$baseRangeKey].shiftedEnd = $baseRanges[$baseRangeKey].baseRangeEnd
                }
                $baseRanges[$baseRangeKey].shiftedStart += $baseRanges[$baseRangeKey].shiftAmount
                $baseRanges[$baseRangeKey].shiftedEnd   += $baseRanges[$baseRangeKey].shiftAmount
                # $baseRanges[$baseRangeKey].shiftedStart = $baseRanges[$baseRangeKey].baseRangeStart + $baseRanges[$baseRangeKey].shiftAmount
                # $baseRanges[$baseRangeKey].shiftedEnd   = $baseRanges[$baseRangeKey].baseRangeEnd   + $baseRanges[$baseRangeKey].shiftAmount
            }
        }
    }
    return $baseRanges
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

    # $Mappings = Get-SeedMapsAsSplits -SeedMapData $SeedMap
    $Mappings = Get-SeedMapsAttempt3 -SeedMapData $SeedMap
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