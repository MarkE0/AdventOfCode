BeforeAll {
    # Import the Get-WinningScratchCardPoints.ps1 script
    . $PSScriptRoot\Get-WinningScratchCardPoints.ps1
}

Describe "Day 04" {
    Context "Part 01" {
        It "Should return the correct number of points from small test set" {
            # Arrange
            $ScratchCards = @(
                "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53",
                "Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19",
                "Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1",
                "Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83",
                "Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36",
                "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11"
            )

            # Act
            $Points = Get-ScratchCardPoints -CardsContent $ScratchCards -Verbose

            # Assert
            $Points | Should -Be 13
        }
        
        It "Should return the correct number of points from wider test set" {
            # Arrange
            $ScratchCards = @(
                "Card   1: 71 88 83  5 15 54 89 55 69 79 | 83 39 58 32 99 54 91 19 44  5 57 29 88  9 95 15 79 71 90 69 43 66 55 12 89",
                "Card   2: 33 11 66 48 67 95 78 71 98 65 | 66  2  1 59 77 95 61 71  8 38 18 62 10 65 53 17 75 92 64 50 67 21 51 78 98"
            )

            # Act
            $Points = Get-ScratchCardPoints -CardsContent $ScratchCards -Verbose

            # Assert
            $Points | Should -Be 576
        }
    }

    Context "Part 02" {
        It "Should return the correct number of points" -Skip {
            # Arrange
            $ScratchCards = @(
                "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53",
                "Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19",
                "Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1",
                "Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83",
                "Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36",
                "Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11"
            )

            # Act
            $Points = Get-ScratchCardPoints -CardsContent $ScratchCards

            # Assert
            $Points | Should -Be 13
        }
    }
}