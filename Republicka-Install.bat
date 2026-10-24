@echo off
:: ==============================================================================
:: REPUBLICKA-INSTALL.BAT
:: The Official Open-Source Corpus Downloader & AI Gateway
:: Created under CC0 Public Domain Grace by Wendell Charles NeSmith
::
:: "A book is not a static monument; a book is an executable seed."
:: Loads 250+ plain-text works into your local machine for instant ingestion
:: into Google Notebook, local LLMs, and synthetic digital twin environments.
:: ==============================================================================
::
:: HOW IT WORKS
::   Batch part (top)  : menu, settings, friendly messages.
::   PowerShell part   : everything after the #PSBEGIN line at the bottom.
::                       The batch part runs it directly from this same file,
::                       so there are no temp scripts to leave behind.
::
:: SETTINGS (edit the lines below if you need to)
::   REP_ID       Internet Archive item to mirror
::   REP_ALLOWED  File extensions to keep (comma separated)
::   REP_RETRIES  Attempts per file before giving up on it
:: ==============================================================================

setlocal EnableExtensions DisableDelayedExpansion
title REPUBLICKA-INSTALL - Open-Source Corpus Downloader
cd /d "%~dp0"

set "REP_ID=wikkkan"
set "REP_ALLOWED=.txt"
set "REP_RETRIES=5"

set "REP_ROOT=%CD%"
set "REP_SELF=%~f0"
set "REP_MODE="

where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Windows PowerShell was not found on this computer.
    echo  WHAT TO DO: This installer needs Windows 10 or 11, which include it.
    echo.
    pause
    exit /b 1
)

:menu
cls
echo.
echo  =========================================================
echo   REPUBLICKA-INSTALL
echo   The Official Open-Source Corpus Downloader
echo  =========================================================
echo.
echo   Source : https://archive.org/details/%REP_ID%
echo   Saves  : %REP_ROOT%\Republicka_Corpus
echo.
echo   Free forever. CC0 Public Domain. No accounts, no API keys.
echo.
echo  ---------------------------------------------------------
echo   [1] FRESH INSTALL  - delete old copies, download everything again
echo   [2] RESUME         - keep good files, fetch missing or damaged ones
echo   [3] RETRY FAILED   - only retry files that failed last time
echo   [Q] Quit
echo  ---------------------------------------------------------
echo.
choice /C 123Q /N /M " Choose 1, 2, 3 or Q: "
if errorlevel 4 exit /b 0
if errorlevel 3 goto m_retry
if errorlevel 2 goto m_resume
if errorlevel 1 goto m_fresh
goto menu

:m_fresh
echo.
echo  This deletes the existing downloaded files in Republicka_Corpus
echo  and downloads them all again.
choice /C YN /N /M " Are you sure? (Y/N): "
if errorlevel 2 goto menu
set "REP_MODE=fresh"
goto run

:m_resume
set "REP_MODE=resume"
goto run

:m_retry
set "REP_MODE=retry"
goto run

:run
echo.
echo  ---------------------------------------------------------
echo   Starting - mode: %REP_MODE%
echo   You can close this window at any time. Nothing is lost.
echo   Just run this file again and choose 2 (RESUME).
echo  ---------------------------------------------------------
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:REP_SELF); $p=$t.LastIndexOf('#PSBEGIN'); Invoke-Expression $t.Substring($p)"
set "RC=%ERRORLEVEL%"

echo.
echo  =========================================================
if "%RC%"=="0" goto done_ok
if "%RC%"=="1" goto done_partial
if "%RC%"=="2" goto done_network
if "%RC%"=="3" goto done_folder
goto done_unknown

:done_ok
echo   ALL DONE - every file downloaded and verified.
echo  =========================================================
echo.
echo   HOW TO LOAD THE SEEDS INTO YOUR AI WORKSPACE
echo   ---------------------------------------------
echo   Google Notebook:
echo     1. Go to https://notebook.google.com and create a new notebook.
echo     2. Click Add source, then Upload files.
echo     3. Open the Republicka_Corpus folder, press Ctrl+A to select every
echo        file, and drag them all in.
echo.
echo   NOTE: Free accounts have a lower source limit per notebook. To load
echo   every seed into ONE notebook you may need to upgrade to Google
echo   Notebook Pro. Hopefully more open options will appear in future.
echo.
echo   Claude / ChatGPT / Ollama / LM Studio / local models:
echo     Use the Republicka_Corpus folder. It holds every plain-text file.
echo.
echo   Then begin your own Eschaton episode.
echo.
choice /C YN /N /M " Open the Republicka_Corpus folder now? (Y/N): "
if errorlevel 2 goto finish
if exist "%REP_ROOT%\Republicka_Corpus" explorer "%REP_ROOT%\Republicka_Corpus"
goto finish

:done_partial
echo   FINISHED WITH PROBLEMS - some files did not download.
echo  =========================================================
echo.
echo   WHAT TO DO:
echo     Run this file again and choose 3 (RETRY FAILED), or 2 (RESUME).
echo     Files that already downloaded correctly will not be fetched again.
echo     The list of failed files is in: Republicka_failed.txt
echo     Full details are in: Republicka-Install.log
goto finish

:done_network
echo   COULD NOT GET THE FILE LIST - nothing was downloaded.
echo  =========================================================
echo.
echo   WHAT TO DO:
echo     Check your internet connection, VPN and firewall, then run this
echo     file again and choose 2 (RESUME).
echo     Details are in: Republicka-Install.log
goto finish

:done_folder
echo   COULD NOT WRITE TO THE OUTPUT FOLDER.
echo  =========================================================
echo.
echo   WHAT TO DO:
echo     Move this .bat file to a folder you own, such as Documents or
echo     Desktop, then run it again. Also check that your disk is not full
echo     and that antivirus or Controlled Folder Access is not blocking it.
goto finish

:done_unknown
echo   UNEXPECTED ERROR (code %RC%).
echo  =========================================================
echo.
echo   WHAT TO DO:
echo     Run this file again and choose 2 (RESUME). If it keeps happening,
echo     send Republicka-Install.log to wendell@republicka.life.
goto finish

:finish
echo.
pause
exit /b %RC%

#PSBEGIN
# ==============================================================================
#  POWERSHELL ENGINE  (do not edit below unless you know PowerShell)
# ==============================================================================
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Root      = $env:REP_ROOT
$Id        = $env:REP_ID
$Mode      = $env:REP_MODE
$MaxTries  = [int]$env:REP_RETRIES
$Allowed   = @($env:REP_ALLOWED -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
if ($MaxTries -lt 1)  { $MaxTries = 5 }

$Out       = Join-Path $Root 'Republicka_Corpus'
$LogFile   = Join-Path $Root 'Republicka-Install.log'
$FailFile  = Join-Path $Root 'Republicka_failed.txt'
$BaseUrl   = "https://archive.org/download/$Id/"
$MetaUrl   = "https://archive.org/metadata/$Id"

function Log([string]$Msg, [string]$Level = 'INFO') {
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Msg
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
}
function Say([string]$Msg, [string]$Color = 'Gray') {
    Write-Host $Msg -ForegroundColor $Color
    Log $Msg
}

function Get-Hint($err) {
    $ex  = $err.Exception
    $msg = [string]$ex.Message
    $code = 0
    if ($ex.Response -ne $null) { try { $code = [int]$ex.Response.StatusCode } catch {} }

    if ($msg -like 'INTEGRITY:*') {
        return [pscustomobject]@{ Permanent = $false; Detail = $msg
            Text = 'The file arrived damaged or incomplete. It is deleted and will be fetched again.' }
    }
    if ($code -eq 404) {
        return [pscustomobject]@{ Permanent = $true; Detail = $msg
            Text = 'The server says this file does not exist (404). It may have been renamed or removed. Run again later to refresh the list.' }
    }
    if ($code -eq 401 -or $code -eq 403) {
        return [pscustomobject]@{ Permanent = $true; Detail = $msg
            Text = "Access denied ($code). The server refused the request. Try again later or from a different network." }
    }
    if ($code -eq 429 -or $code -ge 500) {
        return [pscustomobject]@{ Permanent = $false; Detail = $msg
            Text = "The server is busy or rate-limiting ($code). Wait a few minutes, then run again and choose 3 (RETRY FAILED)." }
    }
    if ($msg -match 'could not be resolved|No such host|name resolution|remote name') {
        return [pscustomobject]@{ Permanent = $false; Detail = $msg
            Text = 'No internet or DNS problem. Check your connection, VPN and firewall, then run again.' }
    }
    if ($msg -match 'timed out|timeout') {
        return [pscustomobject]@{ Permanent = $false; Detail = $msg
            Text = 'The connection timed out. Your network may be slow or unstable. Run again to retry.' }
    }
    if ($msg -match 'not enough space|disk is full|disk full') {
        return [pscustomobject]@{ Permanent = $true; Detail = $msg
            Text = 'Your disk is full. Free some space, then run again and choose 2 (RESUME).' }
    }
    if ($msg -match 'Access to the path|UnauthorizedAccess|being used by another process|denied') {
        return [pscustomobject]@{ Permanent = $true; Detail = $msg
            Text = 'Windows blocked writing the file. Check antivirus or Controlled Folder Access, close any program using the file, or move this .bat to Documents or Desktop.' }
    }
    if ($msg -match 'SSL|TLS|secure channel|trust relationship|certificate') {
        return [pscustomobject]@{ Permanent = $false; Detail = $msg
            Text = 'Secure connection failed. Check your PC date and time, and whether antivirus HTTPS scanning is interfering.' }
    }
    return [pscustomobject]@{ Permanent = $false; Detail = $msg
        Text = 'Unexpected download error. Run again to retry.' }
}

function Get-Md5([string]$Path) {
    try { return (Get-FileHash -LiteralPath $Path -Algorithm MD5).Hash.ToLower() } catch { return $null }
}

function Test-Local($Path, $f) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $len = (Get-Item -LiteralPath $Path).Length
    if ($len -le 0) { return $false }
    if ($f.Size -gt 0 -and $len -ne $f.Size) { return $false }
    if ($f.Md5) {
        $h = Get-Md5 $Path
        if ($h -and $h -ne $f.Md5) { return $false }
    }
    return $true
}

function Get-RemoteList {
    $list = @()
    $lastErr = $null
    for ($try = 1; $try -le $MaxTries; $try++) {
        try {
            $meta = Invoke-RestMethod -Uri $MetaUrl -TimeoutSec 60
            if (-not $meta -or -not $meta.files) { throw 'The item has no file list (wrong ID, or the item is private).' }
            foreach ($f in $meta.files) {
                $name = [string]$f.name
                $ext  = [IO.Path]::GetExtension($name).ToLower()
                if ($Allowed -notcontains $ext) { continue }
                $size = 0; try { $size = [int64]$f.size } catch {}
                $md5  = $null; if ($f.md5) { $md5 = ([string]$f.md5).ToLower() }
                $list += [pscustomobject]@{
                    Name  = $name
                    Clean = ($name -replace '[\\/:*?"<>|]', '_')
                    Size  = $size
                    Md5   = $md5
                }
            }
            return @($list | Sort-Object Clean)
        } catch {
            $lastErr = Get-Hint $_
            Log ("File list attempt {0}/{1} failed: {2}" -f $try, $MaxTries, $lastErr.Detail) 'WARN'
            if ($try -lt $MaxTries) {
                $wait = [Math]::Min(30, [Math]::Pow(2, $try))
                Say ("  Could not read the file list (attempt {0}/{1}). Retrying in {2}s..." -f $try, $MaxTries, $wait) 'Yellow'
                Start-Sleep -Seconds $wait
            }
        }
    }

    # Fallback: scrape the plain directory page (no sizes or checksums available)
    try {
        Say '  Trying the fallback directory listing...' 'Yellow'
        $html = (Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 60).Content
        foreach ($m in [regex]::Matches($html, 'href="([^"]+)"')) {
            $l = $m.Groups[1].Value
            if ($l.StartsWith('/') -or $l.StartsWith('?') -or $l.StartsWith('http') -or $l.StartsWith('.') -or $l.EndsWith('/')) { continue }
            $name = [Uri]::UnescapeDataString($l)
            $ext  = [IO.Path]::GetExtension($name).ToLower()
            if ($Allowed -notcontains $ext) { continue }
            $list += [pscustomobject]@{
                Name  = $name
                Clean = ($name -replace '[\\/:*?"<>|]', '_')
                Size  = 0
                Md5   = $null
            }
        }
        if ($list.Count -gt 0) { return @($list | Sort-Object Clean) }
    } catch {
        $lastErr = Get-Hint $_
    }

    Say '' 'Red'
    Say 'ERROR: Could not get the list of files from the Internet Archive.' 'Red'
    if ($lastErr) {
        Say ('  Reason : ' + $lastErr.Text) 'Red'
        Say ('  Detail : ' + $lastErr.Detail) 'DarkGray'
    }
    Say 'WHAT TO DO: check your internet connection, then run this script again.' 'Yellow'
    exit 2
}

function Download-One($f) {
    $dest = Join-Path $Out $f.Clean
    $tmp  = $dest + '.part'
    $enc  = ($f.Name -split '/' | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
    $url  = $BaseUrl + $enc
    $last = $null

    for ($try = 1; $try -le $MaxTries; $try++) {
        try {
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 120 | Out-Null

            if (-not (Test-Path -LiteralPath $tmp)) { throw 'INTEGRITY: no data was written' }
            $len = (Get-Item -LiteralPath $tmp).Length
            if ($len -le 0) { throw 'INTEGRITY: downloaded file is empty' }
            if ($f.Size -gt 0 -and $len -ne $f.Size) {
                throw ('INTEGRITY: size mismatch (got {0} bytes, expected {1})' -f $len, $f.Size)
            }
            if ($f.Md5) {
                $h = Get-Md5 $tmp
                if ($h -and $h -ne $f.Md5) { throw 'INTEGRITY: checksum mismatch' }
            }
            Move-Item -LiteralPath $tmp -Destination $dest -Force
            return [pscustomobject]@{ Ok = $true; Tries = $try; Text = ''; Detail = '' }
        } catch {
            $last = Get-Hint $_
            Log ("{0} attempt {1}/{2} failed: {3}" -f $f.Clean, $try, $MaxTries, $last.Detail) 'WARN'
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
            if ($last.Permanent -or $try -ge $MaxTries) { break }
            $wait = [Math]::Min(30, [Math]::Pow(2, $try))
            Say ("         attempt {0}/{1} failed - retrying in {2}s" -f $try, $MaxTries, $wait) 'Yellow'
            Start-Sleep -Seconds $wait
        }
    }
    return [pscustomobject]@{ Ok = $false; Tries = $MaxTries; Text = $last.Text; Detail = $last.Detail }
}

# ------------------------------------------------------------------------------
#  MAIN
# ------------------------------------------------------------------------------
try {
    $started = Get-Date
    Log ('===== Run started. Mode={0} Item={1} =====' -f $Mode, $Id)

    # Step 1: directory setup + write test
    Say 'Step 1/3  Preparing folders...' 'Cyan'
    try {
        New-Item -ItemType Directory -Force -Path $Out | Out-Null
        $probe = Join-Path $Out '_write_test.tmp'
        Set-Content -LiteralPath $probe -Value 'ok'
        Remove-Item -LiteralPath $probe -Force
    } catch {
        $h = Get-Hint $_
        Say '' 'Red'
        Say 'ERROR: Cannot write to the output folder.' 'Red'
        Say ('  Folder : ' + $Out) 'Red'
        Say ('  Reason : ' + $h.Text) 'Red'
        Say ('  Detail : ' + $h.Detail) 'DarkGray'
        exit 3
    }

    # Clean leftovers from interrupted runs
    Get-ChildItem -LiteralPath $Out -Filter '*.part' -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    if ($Mode -eq 'fresh') {
        Say '  Fresh install: clearing old downloaded files...' 'Yellow'
        Get-ChildItem -LiteralPath $Out -File -ErrorAction SilentlyContinue |
            Where-Object { $Allowed -contains $_.Extension.ToLower() } |
            Remove-Item -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $FailFile) { Remove-Item -LiteralPath $FailFile -Force -ErrorAction SilentlyContinue }
    }

    # Step 2: file list
    Say 'Step 2/3  Getting the file list from the Internet Archive...' 'Cyan'
    $files = Get-RemoteList
    Say ('  Found {0} file(s) in the archive.' -f $files.Count) 'Gray'

    if ($Mode -eq 'retry') {
        if (-not (Test-Path -LiteralPath $FailFile)) {
            Say '' 'Gray'
            Say 'Nothing to retry - no failed-file list exists.' 'Green'
            Say 'If files are missing, run again and choose 2 (RESUME).' 'Yellow'
            exit 0
        }
        $wanted = @(Get-Content -LiteralPath $FailFile | Where-Object { $_.Trim() })
        $files  = @($files | Where-Object { $wanted -contains $_.Clean })
        Say ('  Retrying {0} previously failed file(s).' -f $files.Count) 'Gray'
        if ($files.Count -eq 0) {
            Say 'None of the failed files are in the current archive list. Run again and choose 2 (RESUME).' 'Yellow'
            exit 0
        }
    }

    # Step 3: download
    Say ('Step 3/3  Downloading (up to {0} tries per file)...' -f $MaxTries) 'Cyan'
    $ok = 0; $skipped = 0; $failed = @()
    $n = 0; $total = $files.Count
    foreach ($f in $files) {
        $n++
        $tag  = '[{0,3}/{1}]' -f $n, $total
        $dest = Join-Path $Out $f.Clean

        if ($Mode -ne 'fresh' -and (Test-Local $dest $f)) {
            Say ("$tag SKIP  $($f.Clean)  (already good)") 'DarkGray'
            $skipped++
            continue
        }
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue }

        Say ("$tag GET   $($f.Clean)") 'White'
        $r = Download-One $f
        if ($r.Ok) {
            $ok++
        } else {
            Say ("         FAILED: $($r.Text)") 'Red'
            Log ("FAILED {0} : {1}" -f $f.Clean, $r.Detail) 'ERROR'
            $failed += [pscustomobject]@{ Name = $f.Clean; Text = $r.Text }
        }
    }

    if ($failed.Count -gt 0) {
        $failed | ForEach-Object { $_.Name } | Set-Content -LiteralPath $FailFile -Encoding UTF8
    } elseif (Test-Path -LiteralPath $FailFile) {
        Remove-Item -LiteralPath $FailFile -Force -ErrorAction SilentlyContinue
    }

    # Check for very large files
    $big = @(Get-ChildItem -LiteralPath $Out -File | Where-Object { $_.Length -gt 3MB })
    if ($big.Count -gt 0) {
        Say '' 'Yellow'
        Say 'NOTE: These files are very large and may exceed the Google Notebook per-source limit.' 'Yellow'
        Say '      If an upload is rejected, split the file into parts:' 'Yellow'
        foreach ($b in $big) { Say ('        {0}  ({1:N1} MB)' -f $b.Name, ($b.Length / 1MB)) 'Yellow' }
    }

    # Summary
    $secs = [int]((Get-Date) - $started).TotalSeconds
    Say '' 'Gray'
    Say '---------------------------------------------------------' 'Gray'
    Say ('  Downloaded : {0}' -f $ok) 'Green'
    Say ('  Skipped    : {0}  (already good)' -f $skipped) 'Gray'
    $failColor = 'Gray'; if ($failed.Count -gt 0) { $failColor = 'Red' }
    Say ('  Failed     : {0}' -f $failed.Count) $failColor
    Say ('  Time       : {0}s' -f $secs) 'Gray'
    Say '---------------------------------------------------------' 'Gray'

    if ($failed.Count -gt 0) {
        Say '' 'Red'
        Say 'These files failed:' 'Red'
        foreach ($x in $failed) {
            Say ('  - {0}' -f $x.Name) 'Red'
            Say ('      {0}' -f $x.Text) 'DarkYellow'
        }
        Say '' 'Yellow'
        Say 'WHAT TO DO: run this script again and choose 3 (RETRY FAILED).' 'Yellow'
        Log ('===== Run finished with {0} failure(s) =====' -f $failed.Count)
        exit 1
    }

    Log '===== Run finished OK ====='
    exit 0
} catch {
    Say '' 'Red'
    Say 'UNEXPECTED ERROR: the installer stopped.' 'Red'
    Say ('  Detail : ' + $_.Exception.Message) 'Red'
    Log ('Unhandled: ' + $_.Exception.ToString()) 'ERROR'
    Say 'WHAT TO DO: run this script again and choose 2 (RESUME).' 'Yellow'
    exit 9
}