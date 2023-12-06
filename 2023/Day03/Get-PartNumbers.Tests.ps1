BeforeAll {
    # Import the Get-PartNumbers.ps1 script
    . $PSScriptRoot\Get-PartNumbers.ps1
}

Describe "Get-PartNumers" {
    It "Should return the correct part numbers" {
        # Arrange
        $Content = @(
            "467..114..",
            "...*......",
            "..35..633.",
            "......#...",
            "617*......",
            ".....+.58.",
            "..592.....",
            "......755.",
            "...$.*....",
            ".664.598.."
        )

        # Act
        $PartNumbersSum = Get-PartNumbersSumP1 -Content $Content
        # $PartNumbersSum = Get-PartNumbersSum -Content (Get-Content -Path "$PSScriptRoot\input.txt")

        # Assert
        $PartNumbersSum | Should -Be 4361
    }

    It "Should handle dollar signs" {
        # Arrange
        $Content = @(
            "1..788.............................54.........501...........555.........270.................................521......893.................*10"
            "+.../..*963........................*..860......................*....53...../.....................52.................&....347........428*522."            
            "............*......41..481+.......462....$..187......678.......420....-....................&115.+...........................+..............."
            "............................................................................................................................................"
        )

        # Act
        $PartNumbersSum = Get-PartNumbersSumP1 -Content $Content
        # $PartNumbersSum = Get-PartNumbersSum -Content (Get-Content -Path "$PSScriptRoot\input.txt")

        # Assert
        $PartNumbersSum | Should -Be 7274
    }
}