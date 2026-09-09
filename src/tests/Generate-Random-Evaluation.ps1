<##
.SYNOPSIS
Creates a synthetic evaluation.csv from an agent-responses.json file.

.DESCRIPTION
The scores and comments are randomly generated for classroom/demo use only.
They are not a quality evaluation of the agent's responses.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Experiment
)

$ErrorActionPreference = 'Stop'

$jsonPath = Join-Path "experiments/$Experiment" 'agent-responses.json'
$csvPath = Join-Path "experiments/$Experiment" 'evaluation.csv'

if (-not (Test-Path $jsonPath)) {
    throw "No se encontró '$jsonPath'. Ejecuta primero: python src/tests/run_batch_tests.py $Experiment"
}

$comments = @(
    'Clear and comprehensive response',
    'Good safety focus and practical guidance',
    'Helpful and actionable answer',
    'Relevant response with useful detail',
    'Concise response that addresses the request'
)

$results = Get-Content $jsonPath -Raw | ConvertFrom-Json
$sourceRows = @($results.test_results)

if ($sourceRows.Count -eq 0) {
    throw "El archivo '$jsonPath' no contiene resultados de prueba."
}

# Create the rows before exporting them so every JSON test result becomes one CSV row.
$csvRows = @(
    $sourceRows | ForEach-Object {
        $response = [string]$_.response
        # CSV can hold line breaks, but collapsing them makes the file easier to view in Excel.
        $excerpt = ($response -replace '\s+', ' ').Trim()
        $excerpt = $excerpt.Substring(0, [Math]::Min(160, $excerpt.Length))

        [PSCustomObject]@{
            test_prompt            = $_.test_name
            agent_response_excerpt = $excerpt
            intent_resolution      = Get-Random -Minimum 3 -Maximum 6
            relevance               = Get-Random -Minimum 3 -Maximum 6
            groundedness            = Get-Random -Minimum 3 -Maximum 6
            comments                = $comments | Get-Random
        }
    }
)

$csvRows | Export-Csv $csvPath -NoTypeInformation -Encoding utf8 -Force

Write-Host "Creado: $csvPath ($($csvRows.Count) filas; JSON: $($sourceRows.Count) resultados)"
Write-Warning 'Las puntuaciones y comentarios son sinteticos y aleatorios; no representan una evaluacion real.'
