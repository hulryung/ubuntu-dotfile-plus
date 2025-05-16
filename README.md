# ubuntu-dotfile-plus

**ubuntu-dotfile-plus** is a turnkey bootstrap kit for fresh Ubuntu systems. It merges traditional *dotfiles* with modular post‑installation scripts so you can transform a vanilla machine into a fully‑equipped development workstation in minutes—consistently and repeatably.

---

## ✨ Key Features

* **One‑command provisioning** – install packages, apply system tweaks, and symlink personalized config files with a single script.
* **Curated dotfiles** – `bash`/`zsh`, `git`, `vim`/`neovim`, `tmux`, `ssh`, and more, all version‑controlled.
* **Modular scripts** – independent install modules (e.g. `docker`, `samba`, `devtools`) that you can turn on/off.
* **Idempotent by design** – safe to re‑run; existing settings are detected before modification.
* **Ubuntu‑focused** – tuned for the latest LTS release, but compatible with most Debian‑based distros.
* **Rollback safety** – critical files are automatically backed up before changes are applied.

---

## Directory Layout

```text
ubuntu-dotfile-plus/
├── bootstrap.sh        # Master launcher: orchestrates all steps
├── scripts/            # Self‑contained provisioning modules
│   └── setup_samba_share.sh  # Example module (see below)
├── dotfiles/           # Actual dotfiles (bashrc, gitconfig…)
├── ansible/            # Optional playbook for remote or headless setups
└── docs/               # Usage notes, troubleshooting, FAQs
```

---

## Included Script Spotlight: `setup_samba_share.sh`

`setup_samba_share.sh` shares the *current* user’s home directory (`/home/<user>`) over Samba with **read/write** access so that a Windows PC can access it immediately after Ubuntu installation.

### What It Does

1. Installs the `samba` package (if missing).
2. Backs up `/etc/samba/smb.conf` with a timestamp.
3. Ensures correct ownership of the user’s home directory.
4. Appends a new share block to `smb.conf` (if it doesn’t already exist).
5. Prompts you to set a Samba password for the user.
6. Restarts the `smbd` and `nmbd` services.

### How to Run

```bash
# Clone the repo and run the script with sudo
cd ubuntu-dotfile-plus/scripts
sudo bash setup_samba_share.sh
```

After the script finishes, access the share from Windows:
`\\<Ubuntu_IP>\<username>` — log in with the same username and the Samba password you just set.

> **Firewall tip** – If UFW is enabled, open ports 137–139 and 445:
>
> ```bash
> sudo ufw allow samba
> ```

---

## Quick Start (Full Bootstrap)

```bash
# 1. Grab the repo
git clone https://github.com/<your‑user>/ubuntu-dotfile-plus.git
cd ubuntu-dotfile-plus

# 2. Provision the system (will prompt for sudo)
./bootstrap.sh
```

Log out/in (or reboot) once the script completes to load your new shell environment.

---

## Contributing

Pull requests are welcome! Please open an issue first to discuss major changes or new modules.

---

## License

Released under the MIT License. See `LICENSE` for details.
