# VR Studio on this Windows PC: one script that sets up everything the daily run needs, schedules it every
# morning, and keeps a Remote Control session open so the Claude app on your phone can start runs too.
# Run it from normal PowerShell (not as admin):   powershell -ExecutionPolicy Bypass -File windows.ps1
# Safe to run again: every step checks first and skips what's already done.
# Options: -Time 05:30 (daily start)  -Distro Ubuntu-24.04  -Reinstall (re-run the package install)
param([string]$Time = "05:30", [string]$Distro = "Ubuntu-24.04", [switch]$Reinstall)
$ErrorActionPreference = "Stop"
$wslExe = "$env:WINDIR\System32\wsl.exe"
function Step($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "   $m" -ForegroundColor Yellow }
function Ask($q) { (Read-Host "   $q [y/N]") -match '^(y|yes)$' }
# Run: a command in Ubuntu, shown and interactive; stops the script if it fails. (No double quotes inside $cmd.)
function Run([string]$cmd) {
  & $wslExe -d $Distro -- bash -lc $cmd
  if ($LASTEXITCODE -ne 0) { throw "This step failed in Ubuntu. Fix the message above, then run the script again." }
}
# Test: a silent check in Ubuntu, true when it succeeds.
function Test([string]$cmd) { & $wslExe -d $Distro -- bash -lc $cmd *> $null; return ($LASTEXITCODE -eq 0) }
# The scheduled tasks start a script in the Linux home folder (no quoting, so Task Scheduler can't mangle it).
function WslAction([string]$script) { New-ScheduledTaskAction -Execute $wslExe -Argument "-d $Distro --cd ~ -- bash -l vr-studio/scripts/$script" }

Step "1/8  WSL and Ubuntu"
$distros = @()
try { $distros = (& $wslExe -l -q 2>$null) -replace "`0", "" | ForEach-Object { $_.Trim() } } catch {}
if ($distros -notcontains $Distro) {
  Write-Host "   Installing WSL and $Distro. Windows will ask for admin rights."
  Start-Process $wslExe -ArgumentList "--install", "-d", $Distro -Verb RunAs -Wait
  Warn "Restart the PC. After the restart Ubuntu opens and asks for a username and password:"
  Warn "pick any, close the Ubuntu window, then run this script again."
  exit
}
$user = (& $wslExe -d $Distro -- whoami).Trim()
if ($user -eq "root") {
  Warn "Ubuntu has no user yet. Open 'Ubuntu' from the Start menu, pick a username and password,"
  Warn "close it, then run this script again."
  exit
}
Ok "Ubuntu ready (user $user)"
if (Test "nvidia-smi -L") { Ok "NVIDIA GPU found: the voice step will be fast" }
else { Warn "No NVIDIA GPU seen. It still works, but 10 videos will take a few hours." }

Step "2/8  GitHub and the code"
if (-not (Test "command -v gh && command -v git")) { Run "sudo apt-get update && sudo apt-get install -y gh git" }
if (-not (Test "gh auth status")) {
  Write-Host "   Sign in to GitHub: a code appears, press Enter, a browser opens, paste the code."
  Run "gh auth login --hostname github.com --git-protocol https --web"
}
Run "gh auth setup-git && if [ -d ~/vr-studio/.git ]; then git -C ~/vr-studio pull --rebase --autostash -q; else gh repo clone Samanzzz/vr-studio ~/vr-studio; fi"
Ok "code in ~/vr-studio (inside Ubuntu)"

Step "3/8  Install the tools (first time: 20-40 minutes)"
if (-not $Reinstall -and (Test "cd ~/vr-studio && [ -x .tts/bin/python ] && [ -d engine/node_modules/.remotion ] && [ -x ~/.local/bin/claude ]")) { Ok "already installed (run with -Reinstall to redo)" }
else { Run "cd ~/vr-studio && bash setup/setup-wsl.sh" }

Step "4/8  Sign in to Claude"
if (Test "test -s ~/.claude/.credentials.json") { Ok "already signed in" }
else {
  Warn "Claude opens next. Sign in with your Claude account, then type /exit."
  & $wslExe -d $Distro --cd ~ -- bash -lc 'cd vr-studio && ~/.local/bin/claude'
}

Step "5/8  Permissions for the unattended run (your decision)"
if (Test "cmp -s ~/vr-studio/setup/claude-settings.json ~/vr-studio/.claude/settings.local.json") { Ok "already installed and up to date" }
else {
  Write-Host "   The daily run works with nobody watching, so Claude needs permission for the pipeline's commands"
  Write-Host "   (render, voice, ffmpeg, the scripts, git commits). It is denied sudo, downloads, force-push and keys."
  Write-Host "   Read the rules first: \\wsl$\$Distro\home\$user\vr-studio\setup\claude-settings.json"
  if (Ask "Install these rules?") { Run "mkdir -p ~/vr-studio/.claude && cp ~/vr-studio/setup/claude-settings.json ~/vr-studio/.claude/settings.local.json"; Ok "installed" }
  else { Warn "Skipped. The daily run will stop at the first command that needs approval." }
}

Step "6/8  PostRelay key (for posting)"
if (Test-Path "$env:LOCALAPPDATA\vr-studio\postrelay.key.dpapi") { Ok "key already stored (encrypted for your Windows user)" }
else {
  Write-Host "   In the PostRelay dashboard: API keys > Create key, name it 'VR Studio PC', copy it."
  if (Ask "Paste it now?") { Run "cd ~/vr-studio && .tts/bin/python publish/publish.py setup" }
  else { Warn "Skipped. Videos are still made but can't be queued until the key is added (run this script again)." }
}

Step "7/8  Schedule, phone access, power"
$set = New-ScheduledTaskSettingsSet -WakeToRun -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 23)
Register-ScheduledTask -TaskName "VR Studio daily" -Force -Settings $set -Action (WslAction "daily.sh") -Trigger (New-ScheduledTaskTrigger -Daily -At $Time) | Out-Null
Ok "daily run scheduled at $Time (it wakes the PC; stay signed in to Windows)"
$phone = Get-ScheduledTask -TaskName "VR Studio phone" -ErrorAction SilentlyContinue
if ($phone -or (Ask "Let the Claude app on your phone start runs? (keeps a Remote Control window open; recommended)")) {
  $set2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
  Register-ScheduledTask -TaskName "VR Studio phone" -Force -Settings $set2 -Action (WslAction "phone.sh") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) | Out-Null
  if ((Get-ScheduledTask -TaskName "VR Studio phone").State -ne "Running") { Start-ScheduledTask -TaskName "VR Studio phone" }
  Ok "Remote Control starts at every sign-in. In the Claude app, open the vr-studio session and say: start the daily run"
}
powercfg /change standby-timeout-ac 0; powercfg /change hibernate-timeout-ac 0
Ok "sleep and hibernate set to Never while plugged in"

Step "8/8  Test run"
if (Ask "Make 5 test videos now (nothing posts, about 30-90 minutes)?") {
  & $wslExe -d $Distro --cd ~ -- bash -l vr-studio/scripts/daily.sh --count 5 --no-post
  Ok "Test finished: check the VR Board, and ~/vr-studio/runs/<today>/daily.log in Ubuntu"
}
Write-Host "`nAll set. The PC makes and posts the Shorts every morning at $Time; progress is on the VR Board." -ForegroundColor Green
Write-Host "To stop the daily job: schtasks /delete /tn ""VR Studio daily"" /f"
