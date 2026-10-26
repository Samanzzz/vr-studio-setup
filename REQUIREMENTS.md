# What a machine needs to run VR Studio

You don't install these by hand: on Windows, `setup/windows.ps1` installs all of it (see `WINDOWS.md`). This page is the list, so you can check a laptop before you start.

## The machine

| | Minimum | Better |
|---|---|---|
| System | Windows 10 22H2 or 11 (runs inside WSL, Ubuntu 24.04); or macOS on Apple silicon | Windows 11 |
| Graphics | none (the voice runs on the CPU, slowly) | **NVIDIA card** with the latest Windows driver: the voice step is several times faster |
| Memory | 16 GB | 32 GB |
| Free disk | 30 GB (tools and models ~12 GB, plus a day's renders) | 60 GB |
| Power | plugged in, sleep set to Never during runs | — |
| Internet | needed for setup, posting and research; the voice and Whisper run offline | — |

## Accounts and keys

| What | Why | Where it's kept |
|---|---|---|
| GitHub (access to Samanzzz/vr-studio) | to download the code and save each run | GitHub CLI sign-in |
| Claude (your Claude account) | the agent that writes, makes and checks the videos | Claude Code sign-in |
| PostRelay API key (`VR Studio PC`) | to queue and post videos | encrypted for your Windows user (DPAPI); on the Mac, the Keychain |

YouTube and the other platforms are connected inside PostRelay, not on the laptop.

## Software

| Tool | Version | What it does |
|---|---|---|
| WSL + Ubuntu | 24.04 | Linux inside Windows, where everything runs |
| git, GitHub CLI (`gh`) | current | code and sign-in |
| Node.js | 22 or newer (Mac: 23.7) | runs Remotion, the video engine |
| Remotion + three.js | 4.0.537 / 0.170 (`engine/package.json`) | renders the films; installed by `npm ci` |
| Chrome headless shell | from `npx remotion browser ensure` | Remotion's renderer |
| ffmpeg + ffprobe | 6 or newer (Mac: 9.0) | audio, loudness, phone copies |
| Python | 3.11 (via `uv`) | the voice and the checks |
| Python packages | `setup/requirements.txt` | Chatterbox voice, faster-whisper, numpy, scipy, Pillow, requests |
| Models (offline) | Chatterbox, Whisper small.en (~4 GB, in `~/.cache/huggingface`) | voice and hearing; downloaded once at setup |
| zsh, fonts, Chrome's libraries | from apt | the scripts and the renderer |
| Claude Code | current | the agent (`claude`), plus Remote Control for your phone |

## Check a machine after setup

In Ubuntu, from `~/vr-studio`:
```
node -v && ffmpeg -version | head -1 && .tts/bin/python -c "import chatterbox, faster_whisper, torch; print('voice ok, GPU:', torch.cuda.is_available())" && claude --version
```
