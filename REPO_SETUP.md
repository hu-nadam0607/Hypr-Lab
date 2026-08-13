# Local + GitHub repository setup

This document assumes `nadam0607_repo` is a parent directory on the dedicated
repository drive. Put the extracted `Hypr-Lab-v1.0-RC2` folder inside it and
rename that folder to `Hypr-Lab`.

## Local repository

From the `Hypr-Lab` directory:

```bash
./verify-release.sh
git init -b main
git add .
git status
git commit -m "Hypr-Lab v1.0 RC2"
```

If Git has not been given your identity yet:

```bash
git config --global user.name "nadam0607"
git config --global user.email "YOUR_GITHUB_EMAIL"
```

## GitHub

Create an empty private repository named `Hypr-Lab`. Do not initialize the
remote with a README, .gitignore or license because those files already exist
locally.

Copy the repository URL GitHub gives you, then from the local `Hypr-Lab`
directory run one of the following.

SSH:

```bash
git remote add origin git@github.com:YOUR_GITHUB_USER/Hypr-Lab.git
git push -u origin main
```

HTTPS:

```bash
git remote add origin https://github.com/YOUR_GITHUB_USER/Hypr-Lab.git
git push -u origin main
```

## VM workflow after the first push

Instead of copying ZIP files repeatedly, clone the private repository in the
VM. After each host-side fix, commit and push it. In the VM, update with:

```bash
cd ~/Hypr-Lab
git pull
```

Then rerun the installer:

```bash
./install.sh
```

For the final release gate, use a new clean minimal Arch VM and clone/install
from scratch once more.
