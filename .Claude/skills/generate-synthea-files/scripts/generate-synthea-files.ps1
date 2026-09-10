[CmdletBinding()]
param(
    [ValidateRange(1, 1000000)]
    [int]$PatientCount = 1,

    [string]$State = 'VA',

    [int64]$Seed = 1
)

$ErrorActionPreference = 'Stop'

$stateNames = [ordered]@{
    AL = 'Alabama'; AK = 'Alaska'; AZ = 'Arizona'; AR = 'Arkansas'
    CA = 'California'; CO = 'Colorado'; CT = 'Connecticut'; DE = 'Delaware'
    FL = 'Florida'; GA = 'Georgia'; HI = 'Hawaii'; ID = 'Idaho'
    IL = 'Illinois'; IN = 'Indiana'; IA = 'Iowa'; KS = 'Kansas'
    KY = 'Kentucky'; LA = 'Louisiana'; ME = 'Maine'; MD = 'Maryland'
    MA = 'Massachusetts'; MI = 'Michigan'; MN = 'Minnesota'; MS = 'Mississippi'
    MO = 'Missouri'; MT = 'Montana'; NE = 'Nebraska'; NV = 'Nevada'
    NH = 'New Hampshire'; NJ = 'New Jersey'; NM = 'New Mexico'; NY = 'New York'
    NC = 'North Carolina'; ND = 'North Dakota'; OH = 'Ohio'; OK = 'Oklahoma'
    OR = 'Oregon'; PA = 'Pennsylvania'; RI = 'Rhode Island'; SC = 'South Carolina'
    SD = 'South Dakota'; TN = 'Tennessee'; TX = 'Texas'; UT = 'Utah'
    VT = 'Vermont'; VA = 'Virginia'; WA = 'Washington'; WV = 'West Virginia'
    WI = 'Wisconsin'; WY = 'Wyoming'
}

$skillDirectory = Split-Path -Parent $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $skillDirectory '..\..\..')).Path
$syntheaRunner = Join-Path $repoRoot 'run_synthea.bat'

if (-not (Test-Path -LiteralPath $syntheaRunner -PathType Leaf)) {
    throw "run_synthea.bat was not found at '$syntheaRunner'. Install or copy Synthea into the repository root before running this skill."
}

$requestedStates = if ($State.Trim() -ieq 'All') {
    @($stateNames.Keys)
} else {
    @($State.Split(',') | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ })
}

if ($requestedStates.Count -eq 0) {
    throw "State must be a two-letter U.S. postal abbreviation, a comma-separated list such as 'VA,NJ,CA, NY', or 'All'."
}

$invalidStates = @($requestedStates | Where-Object { -not $stateNames.Contains($_) } | Select-Object -Unique)
if ($invalidStates.Count -gt 0) {
    throw "Invalid state abbreviation(s): $($invalidStates -join ', '). Use two-letter U.S. postal abbreviations, a comma-separated list, or 'All'."
}

$requestedStates = @($requestedStates | Select-Object -Unique)
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputRelative = "./generated/synthea-$runId"
$outputDirectory = Join-Path $repoRoot "generated\synthea-$runId\csv"

Write-Host "Generating $PatientCount patient(s) per state for: $($requestedStates -join ', ')"
Write-Host "Seed: $Seed"
Write-Host "Output: $outputDirectory"

Push-Location $repoRoot
try {
    foreach ($stateCode in $requestedStates) {
        $stateName = $stateNames[$stateCode]
        Write-Host "Generating $stateCode ($stateName)..."

        & $syntheaRunner -p $PatientCount -s $Seed $stateName `
            "--exporter.baseDirectory=$outputRelative" `
            '--exporter.csv.export=true' `
            '--exporter.csv.append_mode=true' `
            '--exporter.csv.folder_per_run=false' `
            '--exporter.fhir.export=false' `
            '--exporter.ccda.export=false'

        if ($LASTEXITCODE -ne 0) {
            throw "Synthea generation failed for $stateCode ($stateName) with exit code $LASTEXITCODE. Partial output remains at '$outputDirectory'."
        }
    }
} finally {
    Pop-Location
}

$patientFile = Join-Path $outputDirectory 'patients.csv'
$actualPatientCount = 0
if (Test-Path -LiteralPath $patientFile -PathType Leaf) {
    $actualPatientCount = @(Import-Csv -LiteralPath $patientFile).Count
}

[pscustomobject]@{
    OutputDirectory  = $outputDirectory
    PatientsPerState = $PatientCount
    States           = $requestedStates -join ','
    Seed             = $Seed
    ActualPatients   = $actualPatientCount
}
