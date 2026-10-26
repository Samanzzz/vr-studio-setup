# Run VR Studio's daily job on the Windows PC

The PC makes and posts the daily Shorts on its own every morning, and you can also start a run from the Claude app on your phone. Your Mac isn't needed. Everything runs inside **WSL** (Linux built into Windows), because the voice model, ffmpeg and the renderer work best there.

**What the PC needs:**
- Windows 10 (22H2) or 11;
- about 30 GB of free space;
- to stay on and signed in during the run.

An **NVIDIA graphics card** makes the voice step several times faster. Without one, a 10-video day takes a few hours. If you have one, install the latest NVIDIA driver for Windows from nvidia.com first; WSL uses it automatically.

The full list of what gets installed, and a check to run afterwards, is in `setup/REQUIREMENTS.md`.

## Set it up: one script

1. Download the script: in PowerShell, `irm https://raw.githubusercontent.com/Samanzzz/vr-studio-setup/main/windows.ps1 -OutFile $HOME\Downloads\windows.ps1`
2. Open **PowerShell** (normal, not admin) and run:
   ```
   powershell -ExecutionPolicy Bypass -File $HOME\Downloads\windows.ps1
   ```
3. Answer what it asks. The first time, it stops after installing WSL: restart the PC, create the Ubuntu user when Ubuntu opens, then run the same command again. It picks up where it left off.

The script runs 8 steps and skips any that are already done, so it's safe to run again any time (for example, after adding the PostRelay key later):

| Step | What happens | What you do |
|---|---|---|
| 1. WSL + Ubuntu | Installs WSL and Ubuntu 24.04; checks for an NVIDIA GPU | Approve admin once, restart, pick a Linux username and password |
| 2. Code | Installs git and the GitHub CLI, downloads vr-studio into Ubuntu | Sign in to GitHub in the browser |
| 3. Tools | ffmpeg, Node, Chrome, the Python voice and check packages, the offline voice and Whisper models, Claude Code (20-40 min) | Type your Ubuntu password once |
| 4. Claude | Opens Claude Code | Sign in with your Claude account, then type `/exit` |
| 5. Permissions | Shows where `setup/claude-settings.json` is: the commands the unattended run may use (no sudo, no downloads, no force-push, no keys) | Read it, then answer y |
| 6. PostRelay | Stores the PostRelay key, encrypted for your Windows user | Create a key named `VR Studio PC` in the PostRelay dashboard and paste it |
| 7. Schedule | Daily task at 05:30 that wakes the PC; a sign-in task that keeps Remote Control open for your phone; sleep set to Never while plugged in | Answer y to phone access |
| 8. Test | Optional: 5 videos, nothing posts | Watch the VR Board |

To change the start time: run the script again with `-Time 06:00`.

## From your phone

In the Claude app, open the **vr-studio** session (the PC's Remote Control) and say:
- **"start the daily run"**, or "start the daily run, 10 videos, don't post": it starts in the background and replies straight away;
- **"how's the run going"**.

Only one run goes at a time: if the morning run is already going, it tells you so. Progress, videos and Approve buttons are on the VR Board as usual. If the PC restarts, Remote Control comes back on its own when you sign in to Windows.

## Stop or remove

- Stop the morning run: `schtasks /delete /tn "VR Studio daily" /f`
- Stop phone access: close the Remote Control window, and `schtasks /delete /tn "VR Studio phone" /f`
