<#
 Install_DeityZenith.ps1 - installs, checks or removes the Deity Zenith mod for Majesty Gold HD (by Bener Kaya).
 Easiest: double-click Install.bat, Status.bat or Uninstall.bat in this folder.

   Install    copies DeityZenith\Deity.bcd into the game's Data and DataMX folders (same file, the
              names the game expects), plus the matching text file, and adds two lines to each of
              the game's dataset files so Deity Zenith loads in every game. Backups (.orig) are made first.
   Status     shows whether Deity Zenith is active in the game folder (Steam updates undo it).
   Uninstall  restores the dataset files, removes Deity Zenith's files from the game folder and removes
              folders left by older versions (Documents\My Games\MajestyHD\Mods\Deity,
              Mods\DeityBase, Deity_AutoEnable).

 Options (only if needed):
   -GamePath "<your Majesty HD folder>"   if the installer cannot find the game through Steam
   -SteamPath "<your Steam folder>"       use this Steam folder instead of the one in the registry
   -Placement Start                       put the lines first instead of last (fallback)
#>
param(
  [ValidateSet('Install','Uninstall','Status','Apply','Revert')][string]$Action = 'Install',
  [string]$GamePath = '',
  [string]$SteamPath = '',
  [ValidateSet('End','Start')][string]$Placement = 'End',
  [Alias('GameDir')][string]$LegacyGameDir = ''
)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Latin1 = [System.Text.Encoding]::GetEncoding(28591)   # 1 byte = 1 char: every original byte is kept
if ($GamePath -eq '' -and $LegacyGameDir -ne '') { $GamePath = $LegacyGameDir }
if ($Action -eq 'Apply') { $Action = 'Install' }
if ($Action -eq 'Revert') { $Action = 'Uninstall' }

function J { param([string[]]$Parts) $p = $Parts[0]; foreach ($x in $Parts[1..($Parts.Count - 1)]) { $p = Join-Path $p $x }; return $p }
function Read-Text($p)  { $Latin1.GetString([System.IO.File]::ReadAllBytes($p)) }
function Write-Text($p, $s) { [System.IO.File]::WriteAllBytes($p, $Latin1.GetBytes($s)) }
function Sha($p) { if (Test-Path -LiteralPath $p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() } else { '' } }

# ---------------------------------------------------------------- safety
function Stop-IfBusy {
  $busy = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(?i)(majestyhd.*|cheatengine.*|cheat engine.*)$' })
  if ($busy.Count -gt 0) {
    $what = @()
    if ($busy | Where-Object { $_.ProcessName -match '^(?i)majestyhd' }) { $what += 'Majesty Gold HD' }
    if ($busy | Where-Object { $_.ProcessName -match '^(?i)cheat' }) { $what += 'Cheat Engine' }
    Write-Host ''
    if ($what.Count -gt 1) { $msg = "$($what -join ' and ') are running. Please close both, then run this again." }
    else { $msg = "$($what[0]) is running. Please close it, then run this again." }
    Write-Host $msg -ForegroundColor Red
    exit 1
  }
}

# ---------------------------------------------------------------- find the game
$AppIds = @('73230', '25990')   # Majesty Gold HD, Majesty: Gold Edition (same Steam package)

function Test-GameDir([string]$d) {
  if ($d -eq '' -or -not (Test-Path -LiteralPath $d -PathType Container)) { return $false }
  return ((Test-Path -LiteralPath (J $d,'DataMX','MajestyExpansionDatasetDefinitions.xml')) -and
          (Test-Path -LiteralPath (J $d,'Data','MajestyDatasetDefinitions.xml')))
}

function Get-SteamRoots {
  if ($SteamPath -ne '') { return @($SteamPath) }
  $roots = @()
  foreach ($k in @(@('HKCU:\Software\Valve\Steam','SteamPath'),
                   @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','InstallPath'),
                   @('HKLM:\SOFTWARE\Valve\Steam','InstallPath'))) {
    try {
      $v = (Get-ItemProperty -Path $k[0] -Name $k[1] -ErrorAction Stop).($k[1])
      if ($v) { $roots += ($v -replace '/', '\') }
    } catch { }
  }
  return $roots
}

function Get-SteamLibraries {
  $libs = New-Object System.Collections.Generic.List[string]
  foreach ($root in Get-SteamRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    if (-not $libs.Contains($root)) { $libs.Add($root) }
    foreach ($vdf in @((J $root,'steamapps','libraryfolders.vdf'), (J $root,'config','libraryfolders.vdf'))) {
      if (-not (Test-Path -LiteralPath $vdf)) { continue }
      $txt = [System.IO.File]::ReadAllText($vdf)
      # new format: "path"  "E:\\SteamLibrary"   old format: "1"  "E:\\SteamLibrary"
      foreach ($m in [regex]::Matches($txt, '(?m)^\s*"(?:path|\d+)"\s+"([^"]+)"')) {
        $p = $m.Groups[1].Value -replace '\\\\', '\'
        if ($p -match '[\\/:]' -and -not $libs.Contains($p)) { $libs.Add($p) }
      }
    }
  }
  return $libs
}

function Find-Game {
  if ($GamePath -ne '') {
    if (Test-GameDir $GamePath) { return $GamePath }
    throw "'$GamePath' is not the Majesty Gold HD folder (it must contain the Data and DataMX folders)."
  }
  foreach ($lib in Get-SteamLibraries) {
    $apps = J $lib,'steamapps'
    foreach ($id in $AppIds) {
      $acf = J $apps,"appmanifest_$id.acf"
      if (Test-Path -LiteralPath $acf) {
        $m = [regex]::Match([System.IO.File]::ReadAllText($acf), '"installdir"\s+"([^"]+)"')
        if ($m.Success) {
          $d = J $apps,'common',($m.Groups[1].Value -replace '\\\\', '\')
          if (Test-GameDir $d) { return $d }
        }
      }
    }
    $d = J $apps,'common','Majesty HD'
    if (Test-GameDir $d) { return $d }
  }
  throw ("Majesty Gold HD was not found through Steam.`n" +
         "Find the game folder (Steam > right-click Majesty Gold HD > Manage > Browse local files),`n" +
         "then run:  Install.bat -GamePath ""<that folder>""")
}

# ---------------------------------------------------------------- what goes where
# The game keeps the original and the expansion scripts in two data folders, each with its own
# dataset file. Deity Zenith is ONE bytecode (internal file name Deity.bcd) for both rulesets; it is copied into both folders.
$Mod = Join-Path $Here 'DeityZenith'
$Sets = @(
  @{ Name = 'Expansion / Freestyle'; Folder = 'DataMX'; Def = 'MajestyExpansionDatasetDefinitions.xml'; Anchor = 'MX_Build.bcd';
     Bcd = 'Deity.bcd'; Txt = 'Deity_MX_Text.xml';
     GplLine = '<GPL>$(MajestyExpansionBytecodeDataPath)/Deity.bcd</GPL>';
     StrLine = '<Strings>$(MajestyExpansionDataPath)/Deity_MX_Text.xml</Strings>' },
  @{ Name = 'Original Majesty'; Folder = 'Data'; Def = 'MajestyDatasetDefinitions.xml'; Anchor = 'Bytecode.bcd';
     Bcd = 'DeityBase.bcd'; Txt = 'Deity_Text.xml';
     GplLine = '<GPL>$(MajestyBytecodeDataPath)/DeityBase.bcd</GPL>';
     StrLine = '<Strings>$(MajestyDataPath)/Deity_Text.xml</Strings>' }
)

function Find-BcdDir([string]$game, $set, [string]$defDir) {
  # the folder that holds the game's own bytecode (MX_Build.bcd / Bytecode.bcd)
  if (Test-Path -LiteralPath (Join-Path $defDir $set.Anchor)) { return $defDir }
  $hit = Get-ChildItem -LiteralPath $game -Recurse -Filter $set.Anchor -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hit) { return $hit.DirectoryName }
  return $defDir
}

function Has-Line([string]$s, [string]$line) { return ($s.IndexOf($line, [StringComparison]::OrdinalIgnoreCase) -ge 0) }

function Remove-Line([string]$s, [string]$line) {
  # removes one whole line (indent + text + line break)
  $i = $s.IndexOf($line, [StringComparison]::OrdinalIgnoreCase)
  if ($i -lt 0) { return $s }
  $ls = $s.LastIndexOf("`n", $i) + 1
  $end = $i + $line.Length
  if ($end -lt $s.Length -and $s[$end] -eq "`r") { $end++ }
  if ($end -lt $s.Length -and $s[$end] -eq "`n") { $end++ }
  elseif ($ls -gt 0) { $ls = $ls - 1; if ($ls -gt 0 -and $s[$ls - 1] -eq "`r") { $ls-- } }
  return $s.Remove($ls, $end - $ls)
}

function Patch-Text([string]$s, $set, [string]$file) {
  if ($s.Length -ge 2 -and (($s[0] -eq [char]0xFF -and $s[1] -eq [char]0xFE) -or ($s[0] -eq [char]0xFE -and $s[1] -eq [char]0xFF))) { throw "$file is UTF-16; not changed." }
  if ((Has-Line $s $set.GplLine) -and (Has-Line $s $set.StrLine)) { return $s }
  $s = Remove-Line (Remove-Line $s $set.GplLine) $set.StrLine
  $loadStart = $s.IndexOf('<Load>'); $loadEnd = $s.IndexOf('</Load>')
  if ($loadStart -lt 0 -or $loadEnd -lt $loadStart) { throw "No <Load>...</Load> in $file" }
  $eol = if ($s.Contains("`r`n")) { "`r`n" } else { "`n" }
  if ($Placement -eq 'End') {
    $i = $s.LastIndexOf('</GPL>', $loadEnd)
    if ($i -lt $loadStart) { throw "No </GPL> inside <Load> of $file" }
    $gplOpen = $s.LastIndexOf('<GPL>', $i)
  } else {
    $gplOpen = $s.IndexOf('<GPL>', $loadStart)
    if ($gplOpen -lt 0 -or $gplOpen -gt $loadEnd) { throw "No <GPL> inside <Load> of $file" }
  }
  $ls = $s.LastIndexOf("`n", $gplOpen) + 1
  $indent = $s.Substring($ls, $gplOpen - $ls)
  if ($indent.Trim().Length -ne 0) { $indent = '' }
  if ($Placement -eq 'End') { return $s.Insert($i + '</GPL>'.Length, $eol + $indent + $set.GplLine + $eol + $indent + $set.StrLine) }
  return $s.Insert($gplOpen, $set.GplLine + $eol + $indent + $set.StrLine + $eol + $indent)
}

function Assert-Writable([string]$dir) {
  $probe = Join-Path $dir ('.deity_write_test_' + [guid]::NewGuid().ToString('N'))
  try { [System.IO.File]::WriteAllBytes($probe, [byte[]]@()); Remove-Item -LiteralPath $probe -Force }
  catch { throw "Windows does not allow changes in '$dir'. Right-click the .bat file and choose 'Run as administrator'." }
}

# folders made by older versions (nothing in them is needed for auto-loading)
function Remove-OldLayout {
  $docs = [Environment]::GetFolderPath('MyDocuments')
  if (-not $docs) { return }
  $root = J $docs,'My Games','MajestyHD'
  foreach ($o in @(@((J $root,'Mods','Deity'), 'Deity.mmxml'), @((J $root,'Mods','DeityBase'), 'DeityBase.mmxml'), @((J $root,'Deity_AutoEnable'), 'Deity_AutoEnable.ps1'))) {
    if ((Test-Path -LiteralPath $o[0]) -and (Test-Path -LiteralPath (Join-Path $o[0] $o[1]))) {
      Remove-Item -LiteralPath $o[0] -Recurse -Force
      Write-Host "Removed old folder $($o[0])"
    }
  }
}

# ---------------------------------------------------------------- main
try {
  if ($Action -ne 'Status') { Stop-IfBusy }
  if ($Action -eq 'Install') {
    foreach ($f in 'Deity.bcd','Deity_MX_Text.xml','Deity_Text.xml') {
      if (-not (Test-Path -LiteralPath (Join-Path $Mod $f))) { throw "DeityZenith\$f not found next to Install_DeityZenith.ps1. Unzip the whole package first, then run Install.bat from it." }
    }
  }
  $Game = Find-Game
  Write-Host "Majesty Gold HD: $Game"
  $allOk = $true
  foreach ($set in $Sets) {
    $defDir = Join-Path $Game $set.Folder
    $def = Join-Path $defDir $set.Def
    $orig = $def + '.orig'
    $bcdDir = Find-BcdDir $Game $set $defDir
    $ib = Join-Path $bcdDir $set.Bcd; $it = Join-Path $defDir $set.Txt
    switch ($Action) {
      'Status' {
        $s = Read-Text $def
        $lines = (Has-Line $s $set.GplLine) -and (Has-Line $s $set.StrLine)
        $files = (Test-Path -LiteralPath $ib) -and (Test-Path -LiteralPath $it)
        $same = (-not (Test-Path -LiteralPath $Mod)) -or (((Sha $ib) -eq (Sha (Join-Path $Mod 'Deity.bcd'))) -and ((Sha $it) -eq (Sha (Join-Path $Mod $set.Txt))))
        if ($lines -and $files -and $same) { $state = 'ACTIVE' }
        elseif ($lines -and $files) { $state = 'ACTIVE (a different version - run Install.bat to update)' }
        else { $state = 'NOT ACTIVE'; $allOk = $false }
        Write-Host ("Deity Zenith, {0}: {1}" -f $set.Name, $state)
      }
      'Install' {
        Assert-Writable $defDir; Assert-Writable $bcdDir
        $s = Read-Text $def
        $new = Patch-Text $s $set $def               # throws before anything is written
        Copy-Item -LiteralPath (Join-Path $Mod 'Deity.bcd') -Destination $ib -Force
        Copy-Item -LiteralPath (Join-Path $Mod $set.Txt) -Destination $it -Force
        if ($new -ne $s) {
          Copy-Item -LiteralPath $def -Destination $orig -Force   # backup of the file as it is before this change
          Write-Text $def $new
          Write-Host "$($set.Name): enabled"
        } else {
          Write-Host "$($set.Name): already enabled, files refreshed"
        }
      }
      'Uninstall' {
        Assert-Writable $defDir
        $s = Read-Text $def
        if ((Has-Line $s $set.GplLine) -or (Has-Line $s $set.StrLine)) {
          $useOrig = $false
          if (Test-Path -LiteralPath $orig) { $o = Read-Text $orig; $useOrig = -not ((Has-Line $o $set.GplLine) -or (Has-Line $o $set.StrLine)) }
          if ($useOrig) { Copy-Item -LiteralPath $orig -Destination $def -Force }
          else { Write-Text $def (Remove-Line (Remove-Line $s $set.GplLine) $set.StrLine) }
          Write-Host "$($set.Name): original dataset file restored"
        } else {
          Write-Host "$($set.Name): dataset file has no Deity Zenith lines"
        }
        if (Test-Path -LiteralPath $orig) { Remove-Item -LiteralPath $orig -Force }
        foreach ($f in @($ib, $it)) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Write-Host "   removed $f" } }
      }
    }
  }
  switch ($Action) {
    'Install' {
      Remove-OldLayout
      Write-Host ''
      Write-Host 'Deity Zenith is installed. Start Majesty Gold HD, then open Deity Zenith MajestyHD.CT in Cheat Engine.' -ForegroundColor Green
      Write-Host 'After a Steam update or a file check, run Install.bat again (Status.bat tells you when).'
    }
    'Uninstall' {
      Remove-OldLayout
      Write-Host ''
      Write-Host 'Deity Zenith is uninstalled.' -ForegroundColor Green
    }
    'Status' {
      if (-not $allOk) {
        Write-Host ''
        Write-Host 'Deity Zenith is not active. This is normal after a Steam update or "Verify integrity of game files": run Install.bat again.'
      }
    }
  }
} catch {
  Write-Host ''
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
