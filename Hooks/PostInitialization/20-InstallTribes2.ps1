#Requires -Modules Logging
#Requires -Modules Hooks
#Requires -Modules OverlayFS

# Tribes 2 is retail software with no public download. Use an existing install in /config/Server,
# or set T2_ARCHIVE_URL to a zip of the game folder (the one that contains GameData/, at the zip
# root or in a single top-level folder), e.g. a LANCommander archive.

Invoke-Hook "PreInstallTribes2"

$exe = Join-Path $Env:SERVER_DIR 'GameData/Tribes2.exe'

if (Test-Path -Path $exe) {
    Write-Log "Tribes 2 found in $Env:SERVER_DIR"
} elseif ($Env:T2_ARCHIVE_URL) {
    Write-Log "Downloading Tribes 2 from $Env:T2_ARCHIVE_URL"

    $zip     = '/tmp/tribes2.zip'
    $extract = '/tmp/tribes2'

    curl -fL --retry 3 --output $zip "$Env:T2_ARCHIVE_URL"
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $Env:T2_ARCHIVE_URL" }

    Remove-Item -Recurse -Force -Path $extract -ErrorAction SilentlyContinue
    unzip -q -o $zip -d $extract
    if ($LASTEXITCODE -ne 0) { throw "Could not extract $zip" }

    # Accept GameData/ at the zip root or inside one top-level folder
    $root = Get-ChildItem -Path $extract -Filter 'Tribes2.exe' -Recurse -File -Depth 2 |
        Where-Object { $_.Directory.Name -eq 'GameData' } |
        Select-Object -First 1 -ExpandProperty Directory
    if (-not $root) { throw "GameData/Tribes2.exe not found in $Env:T2_ARCHIVE_URL" }

    New-Item -ItemType Directory -Path $Env:SERVER_DIR -Force | Out-Null
    Move-Item -Force -Path (Join-Path $root.Parent.FullName '*') -Destination $Env:SERVER_DIR
    chown -R "$($Env:UID):$($Env:GID)" $Env:SERVER_DIR

    Remove-Item -Recurse -Force -Path $zip, $extract

    # The overlay was mounted before Server/ was populated, and overlayfs doesn't reliably show
    # lower-dir changes made while mounted.
    mountpoint -q $Env:SERVER_ROOT
    if ($LASTEXITCODE -eq 0) {
        umount $Env:SERVER_ROOT
        Remove-Item -Path "$Env:WORK_DIR/*" -Recurse -Force -ErrorAction SilentlyContinue
        Mount-Overlay -MountPoint $Env:SERVER_ROOT -LowerDir $Env:SERVER_DIR -UpperDir $Env:OVERLAY_DIR -WorkDir $Env:WORK_DIR -RequireEmptyWorkDir -OverlayOption "xino=on"
        Write-Log "OverlayFS remounted"
    }

    Write-Log "Tribes 2 installed"
} else {
    Write-Log -Level Error "GameData/Tribes2.exe not found in $Env:SERVER_DIR. Copy a Tribes 2 install there or set T2_ARCHIVE_URL."
}

Invoke-Hook "PostInstallTribes2"

Set-Location $Env:SERVER_ROOT
