# .\Get-TrebuchetInput.ps1 -Path .\input.txt

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $Path
)

##### Part 1: Simple digits only
function Get-SumFromDigitOnly {
    param (
        [Parameter(Mandatory = $true)]
        [String[]]
        $Content
    )

    # Get the input from the file
    $Content = $Content -replace '[a-z]', '' -replace '^([0-9])','$1$1' -replace '([0-9])[0-9]*([0-9])','$1$2'
    $Content | Write-Verbose

    # Sum the list of numbers
    $Content | Measure-Object -Sum | Select-Object -ExpandProperty Sum

    # Alternatively, Loop over the input to get the sum
    # $Total = 0
    # $Content | ForEach-Object {
    #     $Total += [int]$_
    # }
    # "Total: $Total"    
}


##### Part 2: Numbers as text
function Get-SumFromDigitsAndText {
    param (
        [Parameter(Mandatory = $true)]
        [String[]]
        $Content
    )

    # Find numbers across the lines
    $NewContent = @()
    foreach ($line in $Content) {
        $newLine = ""
        for ($i = 0; $i -lt $line.Length; $i++) {
            $part = $line.Substring($i)
            switch -Regex ($part) {
                '^zero'  {$newLine += "0"}
                '^one'   {$newLine += "1"}
                '^two'   {$newLine += "2"}
                '^three' {$newLine += "3"}
                '^four'  {$newLine += "4"}
                '^five'  {$newLine += "5"}
                '^six'   {$newLine += "6"}
                '^seven' {$newLine += "7"}
                '^eight' {$newLine += "8"}
                '^nine'  {$newLine += "9"}
                Default  {$newLine += $line[$i]}
            }
        }
        "$line --> $newLine" | Write-Verbose

        $NewContent += $newLine
    }

    Get-SumFromDigitOnly -Content $NewContent
}

##### Main
$FileContent = Get-Content -Path $Path
# Get-SumFromDigitOnly -Content $FileContent
Get-SumFromDigitsAndText -Content $FileContent
