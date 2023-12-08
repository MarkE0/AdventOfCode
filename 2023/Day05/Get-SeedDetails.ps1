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
    
    # TBD
}

# Main
if (Test-Path -Path $Path) {
    Get-SeedMinLocationP1 -SeedMap (Get-Content -Path $Path)
}