# OS screenshot of the controlled-value frame, for the one comparison the course asks for
# (in-engine capture vs. OS screenshot). Windows only. Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File godot/tools/os_screenshot.ps1 -Godot <path to Godot .exe>
# Pass the windowed (non-console) Godot executable so no console window covers the game.
# Starts tools/capture_burn_values.gd in hold mode (window stays open), waits, and grabs only the game
# window's client area with GDI (the same path as PrintScreen), so nothing else on the desktop is
# saved. The client area comes from window.txt, which the game writes once its frame is captured.
# Then: godot --headless --path godot --script res://tools/compare_os_screenshot.gd

param([Parameter(Mandatory = $true)][string]$Godot)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System.Runtime.InteropServices;
public static class Dpi { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }
"@
[Dpi]::SetProcessDPIAware() | Out-Null   # physical pixels, as Godot reports its window

$out = "evidence/controlled_values/os_compare"
Remove-Item "$out/window.txt" -ErrorAction SilentlyContinue
$p = Start-Process -FilePath $Godot -ArgumentList "--path godot --script res://tools/capture_burn_values.gd -- --hold" -PassThru
Start-Sleep -Seconds 7
if (-not (Test-Path "$out/window.txt")) { throw "window.txt not written: the game did not reach its hold" }

$win = @{}
Get-Content "$out/window.txt" | ForEach-Object { $k, $v = $_ -split "=", 2; $win[$k] = $v }
$pos = $win["client_position"].Trim("()") -split ",\s*"
$size = $win["client_size"].Trim("()") -split ",\s*"
$bmp = New-Object System.Drawing.Bitmap ([int]$size[0]), ([int]$size[1])
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen([int]$pos[0], [int]$pos[1], 0, 0, $bmp.Size)
$bmp.Save((Join-Path (Get-Location) "$out/os_screenshot.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"image_origin=($($pos[0]), $($pos[1]))" | Set-Content -Encoding ascii "$out/screenshot_origin.txt"
$p.WaitForExit()
Write-Output "saved $out/os_screenshot.png, client area at ($($pos[0]), $($pos[1])) size $($size[0])x$($size[1])"
