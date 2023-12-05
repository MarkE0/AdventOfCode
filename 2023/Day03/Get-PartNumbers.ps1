Param (
    [Parameter(Mandatory=$false)]
    [string[]]
    $Path
)

Write-Verbose "Path: $Path" -Verbose

function Get-PartNumbersSum {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]
        $Content
    )
    
    $PartNumbersSum = 0

    # TODO: Calculcation..

    $PartNumbersSum
}