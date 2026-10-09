# Laedt das Anthropic-Java-SDK (fuer den Claude-Coach) nach lib\ und prueft
# jede Datei mit ihrer SHA-256-Pruefsumme aus abhaengigkeiten.txt.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
New-Item -ItemType Directory -Force -Path 'lib' | Out-Null
foreach ($zeile in Get-Content 'werkzeuge\abhaengigkeiten.txt') {
    if ($zeile.StartsWith('#') -or -not $zeile.Trim()) { continue }
    $teile = $zeile -split ' '
    $datei = $teile[0]; $soll = $teile[1]; $url = $teile[2]
    $ziel = Join-Path 'lib' $datei
    if ((Test-Path $ziel) -and ((Get-FileHash $ziel -Algorithm SHA256).Hash.ToLower() -eq $soll)) { continue }
    Write-Host "Lade $datei ..."
    Invoke-WebRequest -Uri $url -OutFile "$ziel.tmp" -UseBasicParsing
    if ((Get-FileHash "$ziel.tmp" -Algorithm SHA256).Hash.ToLower() -ne $soll) {
        Remove-Item "$ziel.tmp"
        throw "Pruefsumme von $datei stimmt nicht."
    }
    Move-Item -Force "$ziel.tmp" $ziel
}
