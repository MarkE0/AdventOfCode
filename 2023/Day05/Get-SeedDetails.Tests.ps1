BeforeAll {
    # Import the Get-SeedDetails.ps1 script
    . $PSScriptRoot\Get-SeedDetails.ps1

    $SeedMapData = @(
        "seeds: 79 14 55 13",
        "",
        "seed-to-soil map:",
        "50 98 2",  # Destination Source Length e.g. 98, 99 --> 50, 51. Shift is 98 to 50 = -48.
        "52 50 48", # Soil        Seed   Length e.g. 50, 51 --> 52, 53. Shift is 50 to 52 = +2.
        "",         #                          Rest: 0, 1   --> 0, 1.   Shift is 0 to 0   = +0.
        "soil-to-fertilizer map:",  # Mapping:  Seed --> Soil
        "0 15 37",                  #          0..49 --> 0..49    <-- Default is 1:1 mapping      : 0..49  --> 0
        "37 52 2",                  #         50..97 --> 52..99   <-- Special case - shift by +2  : 50..97 --> 2
        "39 0 15",                  #         98..99 --> 50..51   <-- Special case - shift by -48 : 98..99 --> -48
        "",                         #        100..on --> 100..on  <-- Default is 1:1 mapping      : 100..  --> 0
        "fertilizer-to-water map:",
        "49 53 8",
        "0 11 42",
        "42 0 7",
        "57 7 4",
        "",
        "water-to-light map:",
        "88 18 7",
        "18 25 70",
        "",
        "light-to-temperature map:",
        "45 77 23",
        "81 45 19",
        "68 64 13",
        "",
        "temperature-to-humidity map:",
        "0 69 1",
        "1 0 69",
        "",
        "humidity-to-location map:",
        "60 56 37",
        "56 93 4"
    )

    Write-Verbose "SeedMapData: $($SeedMapData | Out-String)"
}

Describe "Day 05" {
    Context "Part 1" {
        It "Should return the correct seed details" {
            # Arrange
            $SeedMap = $SeedMapData | Where-Object { [string]::IsNullOrEmpty($_) -eq $false }

            # Act
            $SeedMinLocation = Get-SeedMinLocationP1 -SeedMapData $SeedMap

            # # Assert
            $SeedMinLocation | Should -Be 35
        }

        It "Large numbers should work" {
            $SeedMapData = (
                "seeds: 565778304 341771914",
                "seed-to-soil map:",
                "1136439539 28187015 34421000",
                "soil-to-fertilizer map:",
                "2997768542 2385088490 141138894",
                "fertilizer-to-water map:",
                "1539871014 1431400479 38399903",
                "water-to-light map:",
                "1509583382 1639808290 20361832",
                "light-to-temperature map:",
                "3498288578 2645051323 42074132",
                "temperature-to-humidity map:",
                "1130946446 972737563 146373650",
                "humidity-to-location map:",
                "3903940466 3635148971 125939893"
            )

            $SeedMinLocation = Get-SeedMinLocationP1 -SeedMapData $SeedMapData

            $SeedMinLocation | Should -Be 341771914
        }
    }

    Context "Part 2" {
        It "Should return something" {
            # Arrange
            $SeedMap = $SeedMapData | Where-Object { [string]::IsNullOrEmpty($_) -eq $false }

            # Act
            $SeedMinLocation = Get-SeedMinLocationP2 -SeedMap $SeedMap

            # Assert
            $SeedMinLocation | Should -Be 46
        }
    }

    Context "Part 2 - Better" {
        It "Get-SMAttempt3 Seed-Soil Line 1" {
            # Arrange
            $SeedMap = @(
                "seeds: 79 14 55 13",
                "seed-to-soil map:",
                "50 98 2"
            )

            # Act
            $Map = Get-SeedMapsAttempt3 -SeedMap $SeedMap

            # Assert
            $Map.Keys | Sort-Object | Should -Be 0,98,100

            $Map[[long]0].baseRangeStart | Should -Be 0
            $Map[[long]0].baseRangeEnd   | Should -Be 97
            $Map[[long]0].shiftAmount    | Should -Be 0

            $Map[[long]98].baseRangeStart | Should -Be 98
            $Map[[long]98].baseRangeEnd   | Should -Be 99
            $Map[[long]98].shiftAmount    | Should -Be -48
            
            $Map[[long]100].baseRangeStart | Should -Be 100
            $Map[[long]100].baseRangeEnd   | Should -Be $null
            $Map[[long]100].shiftAmount    | Should -Be 0
        }
        
        It "Get-SMAttempt3 Seed-Soil Line 2" {
            # Arrange
            $SeedMap = @(
                "seeds: 79 14 55 13",
                "seed-to-soil map:",
                "50 98 2",
                "52 50 48"
            )

            # Act
            $Map = Get-SeedMapsAttempt3 -SeedMap $SeedMap

            # Assert
            $Map.Keys | Sort-Object | Should -Be 0,50,98,100

            $Map[[long]0].baseRangeStart | Should -Be 0
            $Map[[long]0].baseRangeEnd   | Should -Be 49
            $Map[[long]0].shiftAmount    | Should -Be 0

            $Map[[long]50].baseRangeStart | Should -Be 50
            $Map[[long]50].baseRangeEnd   | Should -Be 97
            $Map[[long]50].shiftAmount    | Should -Be 2

            $Map[[long]98].baseRangeStart | Should -Be 98
            $Map[[long]98].baseRangeEnd   | Should -Be 99
            $Map[[long]98].shiftAmount    | Should -Be -48
            
            $Map[[long]100].baseRangeStart | Should -Be 100
            $Map[[long]100].baseRangeEnd   | Should -Be $null
            $Map[[long]100].shiftAmount    | Should -Be 0
        }
        
        It "Get-SMAttempt3 Soil-Fertiliser Line 1" {
            # Arrange
            $SeedMap = @(
                "seeds: 79 14 55 13",
                "seed-to-soil map:",
                "50 98 2",
                "52 50 48",
                "soil-to-fertilizer map:",
                "0 15 37"
            )

            # Act
            $Map = Get-SeedMapsAttempt3 -SeedMap $SeedMap

            # Assert
            $Map.Keys | Sort-Object | Should -Be 0,15,50,98,100

            $Map[[long]0].baseRangeStart | Should -Be 0
            $Map[[long]0].baseRangeEnd   | Should -Be 14
            $Map[[long]0].shiftAmount    | Should -Be 0

            $Map[[long]15].baseRangeStart | Should -Be 15
            $Map[[long]15].baseRangeEnd   | Should -Be 49
            $Map[[long]15].shiftAmount    | Should -Be 39

            $Map[[long]50].baseRangeStart | Should -Be 50
            $Map[[long]50].baseRangeEnd   | Should -Be 97
            $Map[[long]50].shiftAmount    | Should -Be 2

            $Map[[long]98].baseRangeStart | Should -Be 98
            $Map[[long]98].baseRangeEnd   | Should -Be 99
            $Map[[long]98].shiftAmount    | Should -Be -48
            
            $Map[[long]100].baseRangeStart | Should -Be 100
            $Map[[long]100].baseRangeEnd   | Should -Be $null
            $Map[[long]100].shiftAmount    | Should -Be 0
        }

        It "Should return 46 (from seed 82)" {
            # Arrange
            $SeedMap = $SeedMapData | Where-Object { [string]::IsNullOrEmpty($_) -eq $false }

            # Act
            $SeedMinLocation = Get-SeedMinLocationP2Better -SeedMap $SeedMap

            # Assert
            $SeedMinLocation | Should -Be 46
        }
    }
}