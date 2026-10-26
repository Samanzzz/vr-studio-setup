# VR Studio setup

The public setup kit for the VR Studio daily-video PC. It holds only the installer and the requirements; the studio itself (`Samanzzz/vr-studio`) is private, and the installer downloads it after you sign in to GitHub.

## Run it on the Windows PC

Open **PowerShell** (normal, not admin) and paste:

```
irm https://raw.githubusercontent.com/Samanzzz/vr-studio-setup/main/windows.ps1 -OutFile $HOME\windows.ps1; powershell -ExecutionPolicy Bypass -File $HOME\windows.ps1
```

Or, with Git installed:

```
git clone https://github.com/Samanzzz/vr-studio-setup; powershell -ExecutionPolicy Bypass -File vr-studio-setup\windows.ps1
```

The first run stops after installing WSL: restart, create the Ubuntu user, then run the same line again. It skips what's already done.

- `WINDOWS.md`: what each of the 8 steps does and what you'll be asked.
- `REQUIREMENTS.md`: what the machine needs (hardware, accounts, software and versions), plus a check to run afterwards.
- `requirements.txt`: the pinned Python packages (the installer in the private repo uses its own copy).
