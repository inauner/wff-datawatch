<#
  Builds the Data 9 Watch Face Format APK with no Gradle.
  WFF bundles contain no code, so the pipeline is just:
     aapt2 compile -> aapt2 link -> zipalign -> apksigner sign

  Usage:
     .\build.ps1            # build -> build\datawatch.apk
     .\build.ps1 -Install   # build, then adb install -r onto the connected watch
#>
param(
    [switch]$Install
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$sdk  = "$env:LOCALAPPDATA\Android\Sdk"
$bt   = "$sdk\build-tools\34.0.0"
$androidJar = "$sdk\platforms\android-34\android.jar"

$aapt2     = "$bt\aapt2.exe"
$zipalign  = "$bt\zipalign.exe"
$apksigner = "$bt\apksigner.bat"

foreach ($t in @($aapt2, $zipalign, $apksigner, $androidJar)) {
    if (-not (Test-Path $t)) { throw "Missing build tool/platform: $t" }
}

$build = "$root\build"
New-Item -ItemType Directory -Force -Path $build | Out-Null

# Locate keytool (not always on PATH; Android Studio's bundled JBR has it).
function Resolve-Keytool {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in @(
        "$env:JAVA_HOME\bin\keytool.exe",
        "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe")) {
        if (Test-Path $p) { return $p }
    }
    throw "keytool not found. Install a JDK or set JAVA_HOME."
}
$keytool = Resolve-Keytool

# Debug keystore (created once, reused).
$ks = "$root\debug.keystore"
if (-not (Test-Path $ks)) {
    Write-Host "Creating debug keystore (keytool: $keytool)..." -ForegroundColor Cyan
    & $keytool -genkeypair -v -keystore $ks -alias datawatch `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass android -keypass android `
        -dname "CN=Data9,O=inaun,C=US" | Out-Null
}

# Validate the WFF XML first (catches schema errors before packaging).
$validator = "$root\libs\wff-validator.jar"
if (Test-Path $validator) {
    Write-Host "[0/4] WFF validate" -ForegroundColor Cyan
    # Validator logs to stderr; capture it so PowerShell's Stop pref doesn't
    # treat successful (exit 0) runs as errors. Judge by exit code + PASSED.
    $vout = & cmd /c "java -jar `"$validator`" 2 `"$root\res\raw\watchface.xml`" 2>&1"
    $vout | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0 -or ($vout -join "`n") -notmatch "PASSED") {
        throw "WFF validation FAILED - fix watchface.xml before building."
    }
} else {
    Write-Host "[0/4] WFF validate - SKIPPED (libs\wff-validator.jar missing)" -ForegroundColor DarkYellow
}

Write-Host "[1/4] aapt2 compile" -ForegroundColor Cyan
& $aapt2 compile --dir "$root\res" -o "$build\res.zip"

Write-Host "[2/4] aapt2 link" -ForegroundColor Cyan
& $aapt2 link `
    -o "$build\unaligned.apk" `
    -I $androidJar `
    --manifest "$root\AndroidManifest.xml" `
    --min-sdk-version 34 --target-sdk-version 34 `
    "$build\res.zip"

Write-Host "[3/4] zipalign" -ForegroundColor Cyan
& $zipalign -f 4 "$build\unaligned.apk" "$build\aligned.apk"

Write-Host "[4/4] apksigner sign" -ForegroundColor Cyan
$apk = "$build\datawatch.apk"
& $apksigner sign --ks $ks --ks-pass pass:android --key-pass pass:android `
    --out $apk "$build\aligned.apk"

Write-Host "`nBuilt: $apk" -ForegroundColor Green

if ($Install) {
    Write-Host "`nInstalling to connected watch..." -ForegroundColor Cyan
    & adb install -r $apk
}
