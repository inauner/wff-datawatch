<#
  Builds a signed Android App Bundle (.aab) for Google Play upload.
  WFF watch faces are resource-only, so we:
    aapt2 compile -> aapt2 link --proto-format -> zip into base module
    -> bundletool build-bundle -> jarsigner (upload key) -> build\rainbowdata.aab

  First run creates upload.keystore (passwords printed once - SAVE THEM).
  Usage:  .\build-aab.ps1
#>
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$sdk  = "$env:LOCALAPPDATA\Android\Sdk"
$bt   = "$sdk\build-tools\34.0.0"
$androidJar = "$sdk\platforms\android-34\android.jar"
$aapt2 = "$bt\aapt2.exe"
$bundletool = "$root\libs\bundletool.jar"

function Resolve-Tool($name) {
    $c = Get-Command $name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @("$env:JAVA_HOME\bin\$name.exe",
                     "C:\Program Files\Android\Android Studio\jbr\bin\$name.exe")) {
        if (Test-Path $p) { return $p }
    }
    throw "$name not found"
}
$keytool   = Resolve-Tool keytool
$jarsigner = Resolve-Tool jarsigner

foreach ($t in @($aapt2, $androidJar, $bundletool)) {
    if (-not (Test-Path $t)) { throw "Missing: $t" }
}

$build = "$root\build-aab"
if (Test-Path $build) { Remove-Item -Recurse -Force $build }
New-Item -ItemType Directory -Force -Path $build | Out-Null

# --- upload keystore (PERMANENT - keep it to publish updates) ---
$ks = "$root\upload.keystore"
$ksPass = "rainbowdata"   # change/secure as you like; recorded here for you
if (-not (Test-Path $ks)) {
    Write-Host "Creating upload keystore (alias=upload, pass=$ksPass)..." -ForegroundColor Cyan
    & $keytool -genkeypair -v -keystore $ks -alias upload `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $ksPass -keypass $ksPass `
        -dname "CN=AutoGamers, O=AutoGamers, C=US" | Out-Null
    Write-Host "SAVE THESE: keystore=upload.keystore  alias=upload  storepass/keypass=$ksPass" -ForegroundColor Yellow
}

# --- 0: validate WFF ---
$validator = "$root\libs\wff-validator.jar"
if (Test-Path $validator) {
    Write-Host "[0] WFF validate" -ForegroundColor Cyan
    $v = & cmd /c "java -jar `"$validator`" 2 `"$root\res\raw\watchface.xml`" 2>&1"
    if (($v -join "`n") -notmatch "PASSED") { throw "WFF validation FAILED" }
}

Write-Host "[1] aapt2 compile" -ForegroundColor Cyan
& $aapt2 compile --dir "$root\res" -o "$build\res.zip"

Write-Host "[2] aapt2 link (proto)" -ForegroundColor Cyan
& $aapt2 link --proto-format `
    -o "$build\base.apk" `
    -I $androidJar `
    --manifest "$root\AndroidManifest.xml" `
    --min-sdk-version 34 --target-sdk-version 34 `
    "$build\res.zip"

Write-Host "[3] assemble base module zip" -ForegroundColor Cyan
$moduleDir = "$build\module"
New-Item -ItemType Directory -Force -Path "$moduleDir\manifest","$moduleDir\res" | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("$build\base.apk")
try {
    foreach ($e in $zip.Entries) {
        $dest = switch -Wildcard ($e.FullName) {
            "AndroidManifest.xml" { "$moduleDir\manifest\AndroidManifest.xml" }
            "resources.pb"        { "$moduleDir\resources.pb" }
            "res/*"               { "$moduleDir\$($e.FullName)" }
            default               { $null }
        }
        if ($dest) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dest, $true)
        }
    }
} finally { $zip.Dispose() }
$moduleZip = "$build\base.zip"
if (Test-Path $moduleZip) { Remove-Item $moduleZip }
$stream = [System.IO.File]::Create($moduleZip)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = Get-ChildItem -Path $moduleDir -Recurse -File
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($moduleDir.Length + 1)
        $entryName = $relative.Replace('\', '/')
        $entry = $archive.CreateEntry($entryName)
        $entryStream = $entry.Open()
        try {
            $fileStream = [System.IO.File]::OpenRead($file.FullName)
            try {
                $fileStream.CopyTo($entryStream)
            } finally {
                $fileStream.Dispose()
            }
        } finally {
            $entryStream.Dispose()
        }
    }
} finally {
    $archive.Dispose()
    $stream.Dispose()
}

Write-Host "[4] bundletool build-bundle" -ForegroundColor Cyan
$aab = "$build\rainbowdata.aab"
if (Test-Path $aab) { Remove-Item $aab }
& java -jar $bundletool build-bundle --modules="$moduleZip" --output="$aab"

Write-Host "[5] sign the .aab (upload key)" -ForegroundColor Cyan
& $jarsigner -keystore $ks -storepass $ksPass -keypass $ksPass `
    -digestalg SHA-256 -sigalg SHA256withRSA "$aab" upload | Out-Null

Write-Host "`nBuilt + signed: $aab" -ForegroundColor Green
Write-Host "Upload this file to Play Console > Internal testing > Create release." -ForegroundColor Green
