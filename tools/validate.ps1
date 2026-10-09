param(
  [Parameter(Mandatory = $true)][string]$FlutterRoot,
  [string]$IntegrationDevice
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$pin = Get-Content -Raw toolchain.json | ConvertFrom-Json
$version = Get-Content -Raw (Join-Path $FlutterRoot 'bin/cache/flutter.version.json') | ConvertFrom-Json
$nodeVersion = (& node --version).TrimStart('v')
if ($version.frameworkVersion -ne $pin.flutter -or $version.dartSdkVersion -ne $pin.dart -or $nodeVersion -ne $pin.node) {
  throw 'Toolchain mismatch; install the versions in toolchain.json.'
}
$dartExe = Join-Path $FlutterRoot 'bin/cache/dart-sdk/bin/dart.exe'
$flutterTool = Join-Path $FlutterRoot 'bin/cache/flutter_tools.snapshot'
if (!(Test-Path -LiteralPath $dartExe) -or !(Test-Path -LiteralPath $flutterTool)) {
  throw 'Flutter SDK cache is incomplete.'
}
function Invoke-Check([string]$Label, [scriptblock]$Run) {
  # Windows PowerShell wraps stderr notices as errors even for exit code zero.
  # Each command here is native; its exit code determines success.
  $ErrorActionPreference = 'Continue'
  Write-Host $Label
  & $Run
  if ($LASTEXITCODE -ne 0) { throw "$Label failed ($LASTEXITCODE)." }
}
Invoke-Check 'Formatting' { & $dartExe --disable-analytics format --output=none --set-exit-if-changed lib test integration_test test_driver }
Invoke-Check 'Analysis' { & $dartExe $flutterTool analyze --no-fatal-infos }
Invoke-Check 'Flutter tests' { & $dartExe $flutterTool test --no-pub }
Invoke-Check 'Shared server tests' { & node --test tools/serve_local.test.mjs services/shared_api/server.test.mjs services/shared_api/load.mjs services/document_verification/server.test.mjs }
Invoke-Check 'Shared pilot release' { & $dartExe $flutterTool build web --release --no-pub --no-web-resources-cdn --dart-define=SHARED_API_ORIGIN=http://localhost:8080 }
Invoke-Check 'Local demo release' { & $dartExe $flutterTool build web --release --no-pub --no-web-resources-cdn --dart-define=APP_MODE=demo }
if ($IntegrationDevice) {
  Invoke-Check 'Real platform database' { & $dartExe $flutterTool test integration_test/drift_spike_test.dart --no-pub -d $IntegrationDevice }
} else {
  Write-Warning 'Platform integration was not requested. Release acceptance still requires a supported device run.'
}
