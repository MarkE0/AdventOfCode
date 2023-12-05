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
        $PartNumbersSum = Get-PartNumbersSum -Content $Content

        # Assert
        $PartNumbersSum | Should -Be 4361
    }
}