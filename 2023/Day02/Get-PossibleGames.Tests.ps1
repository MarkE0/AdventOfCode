BeforeAll {
    # Import the Get-PossibleGames.ps1 script
    . $PSScriptRoot\Get-PossibleGames.ps1
}

# Define the tests
Describe "Get-PossibleGamesP1" {
    It "Should process game details correctly" {
        # Arrange
        $Content = @(
            "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
            "Game 2: 2 red, 3 green; 4 blue, 1 red; 5 green"
        )

        # Act
        $GameNumberTotal = Get-PossibleGamesP1 -Content $Content -CubeMaxes $CubesMaxes

        # Assert
        $GameNumberTotal | Should -Be 3
    }

    It "Should ignore games with too many cubes" {
        $Content = @(
            "Game 1: 30 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
            "Game 2: 2 red, 3 green; 4 blue, 1 red; 5 green",
            "Game 3: 1 red, 2 green, 3 blue"
        )

        $GameNumberTotal = Get-PossibleGamesP1 -Content $Content -CubeMaxes $CubesMaxes

        $GameNumberTotal | Should -Be 5
    }

    It "Should match with the example in Advent Of Code" {
        $Content = @(
            "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
            "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue",
            "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red",
            "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
            "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"
        )

        $GameNumberTotal = Get-PossibleGamesP1 -Content $Content -CubeMaxes $CubesMaxes

        $GameNumberTotal | Should -Be 8
    }

    It "Part 2 should return a correct result" {
        $Content = @(
            "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green",
            "Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue",
            "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red",
            "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
            "Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"
        )

        $PowerSum = Get-PossibleGamesP2 -Content $Content

        $PowerSum | Should -Be 2286
    }
}