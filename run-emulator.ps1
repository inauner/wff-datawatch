<#
  Creates (if needed) a Wear OS round AVD, boots it, installs the watch face,
  and sets it as the active face.

  Usage:
     .\run-emulator.ps1            # full: create AVD, boot, install, activate
     .\run-emulator.ps1 -OnlyInstall   # emulator already running: just (re)install + activate
#>
param(
    [string]$Image = "system-images;android-34;android-wear;x86_64",
    [string]$Device = "wearos_large_round",
    [string]$Avd = "datawatch_wear5",
    [switch]$OnlyInstall
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$sdk  = "$env:LOCALAPPDATA\Android\Sdk"
$avdmanager = "$sdk\cmdline-tools\latest\bin\avdmanager.bat"
$emulator   = "$sdk\emulator\emulator.exe"
$apk = "$root\build\datawatch.apk"
$appId = "com.inaun.datawatch"

function Wait-Boot {
    Write-Host "Waiting for emulator to boot..." -ForegroundColor Cyan
    & adb wait-for-device
    for ($i = 0; $i -lt 120; $i++) {
        $b = (& adb shell getprop sys.boot_completed 2>$null).Trim()
        if ($b -eq "1") { Write-Host "Booted." -ForegroundColor Green; return }
        Start-Sleep -Seconds 3
    }
    throw "Emulator did not finish booting in time."
}

if (-not $OnlyInstall) {
    $existing = (& $avdmanager list avd) -join "`n"
    if ($existing -notmatch [regex]::Escape($Avd)) {
        Write-Host "Creating AVD '$Avd' ($Device, $Image)..." -ForegroundColor Cyan
        "no" | & $avdmanager create avd -n $Avd -k $Image -d $Device --force
    } else {
        Write-Host "AVD '$Avd' already exists." -ForegroundColor DarkGray
    }

    Write-Host "Launching emulator..." -ForegroundColor Cyan
    Start-Process -FilePath $emulator `
        -ArgumentList @("-avd", $Avd, "-no-snapshot-save", "-no-boot-anim")
    Wait-Boot
}

Write-Host "Installing $apk ..." -ForegroundColor Cyan
& adb install -r $apk

Write-Host "Activating watch face ($appId)..." -ForegroundColor Cyan
& adb shell am broadcast -a com.google.android.wearable.app.DEBUG_SURFACE `
    --es operation set-watchface --es watchFaceId $appId

Write-Host "`nDone. The watch face should now be on the emulator screen." -ForegroundColor Green
Write-Host "To assign complication providers: long-press the face -> Edit -> tap each slot." -ForegroundColor DarkGray
