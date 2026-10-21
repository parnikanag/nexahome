$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host 'Setting up NexaHome for Windows...'
flutter --version
if ($LASTEXITCODE -ne 0) { throw 'Install Flutter first and add flutter/bin to PATH.' }
flutter create --project-name smart_home_twin --platforms=windows,android .
if ($LASTEXITCODE -ne 0) { throw 'Flutter could not generate platform files.' }
dart tool/prepare_platforms.dart
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare platform files.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
Write-Host 'Starting Windows app...'
flutter run -d windows
