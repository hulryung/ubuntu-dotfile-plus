# ubuntu-dotfile-plus

**ubuntu-dotfile-plus** is a turnkey bootstrap kit for fresh Ubuntu systems. It merges traditional *dotfiles* with modular post‑installation scripts so you can transform a vanilla machine into a fully‑equipped development workstation in minutes—consistently and repeatably.

---

## ✨ Key Features

* **One‑command provisioning** – install packages, apply system tweaks, and symlink personalized config files with a single script.
* **User-friendly execution** – can be run as a regular user; sudo privileges are requested only when needed.
* **Curated dotfiles** – `bash`/`zsh`, `git`, `vim`/`neovim`, `tmux`, `ssh`, and more, all version‑controlled.
* **Modular scripts** – independent install modules (e.g. `docker`, `samba`, `devtools`) that you can turn on/off.
* **Idempotent by design** – safe to re‑run; existing settings are detected before modification.
* **Ubuntu‑focused** – tuned for the latest LTS release, but compatible with most Debian‑based distros.
* **Rollback safety** – critical files are automatically backed up before changes are applied.
* **Starship Prompt** – modern cross-shell prompt with Gruvbox theme, Git status, language detection, and more.

---

## Directory Layout

```text
ubuntu-dotfile-plus/
├── bootstrap.sh        # Master launcher: orchestrates all steps
├── config/             # Configuration files
│   ├── starship.toml      # Starship prompt configuration
│   ├── netrate_fast.sh    # Network configuration
│   └── screenrc           # Screen configuration
├── scripts/            # Self‑contained provisioning modules
│   ├── install_starship.sh    # Starship prompt installer
│   ├── setup_samba_share.sh   # Samba share setup
│   └── setup_screen.sh        # Screen setup
```

---

## 🚀 Installation

### Quick Start (Full Bootstrap)

For a complete setup with all features:

```bash
# 1. Clone the repository
git clone https://github.com/hulryung/ubuntu-dotfile-plus.git
cd ubuntu-dotfile-plus

# 2. Run the bootstrap script (sudo will be requested when needed)
./bootstrap.sh
```

Log out/in (or reboot) once the script completes to load your new shell environment.

### Individual Component Installation

If you prefer to install specific components only:

#### Starship Prompt

The **Starship Prompt** is a modern, blazing-fast cross-shell prompt with a custom Gruvbox Dark theme:

**Features:**
* **OS Icon** – Displays your operating system with a beautiful icon
* **User/Host Info** – Shows username@hostname with root user highlighted differently
* **Current Directory** – Smart path truncation with icon substitutions
* **Git Integration** – Branch name and status with color-coded indicators
* **Language Detection** – Automatic detection and version display for:
  * Python, Node.js, Rust, Go, Java, C/C++, PHP, Kotlin, Haskell
* **Environment Detection** – Shows Docker context, Conda/Pixi environments
* **Time Display** – Current time in HH:MM format
* **Exit Status** – Visual indicator for command success (➤) or failure
* **Gruvbox Theme** – Beautiful color scheme that's easy on the eyes

**Installation:**
```bash
# Clone the repo first
git clone https://github.com/hulryung/ubuntu-dotfile-plus.git
cd ubuntu-dotfile-plus/scripts
./install_starship.sh
```

**Manual Installation:**
```bash
# Install Starship
curl -sS https://starship.rs/install.sh | sh

# Copy configuration
mkdir -p ~/.config
cp config/starship.toml ~/.config/starship.toml

# Add to your .bashrc
echo 'eval "$(starship init bash)"' >> ~/.bashrc
source ~/.bashrc
```

#### Samba Share Setup

`setup_samba_share.sh` shares the *current* user's home directory (`/home/<user>`) over Samba with **read/write** access so that a Windows PC can access it immediately after Ubuntu installation.

**What It Does:**
1. Installs the `samba` package (if missing).
2. Backs up `/etc/samba/smb.conf` with a timestamp.
3. Ensures correct ownership of the user's home directory.
4. Appends a new share block to `smb.conf` (if it doesn't already exist).
5. Prompts you to set a Samba password for the user.
6. Restarts the `smbd` and `nmbd` services.

**Installation:**
```bash
# Clone the repo first
git clone https://github.com/hulryung/ubuntu-dotfile-plus.git
cd ubuntu-dotfile-plus/scripts
bash setup_samba_share.sh
```

After the script finishes, access the share from Windows:
`\\<Ubuntu_IP>\<username>` — log in with the same username and the Samba password you just set.

> **Firewall tip** – If UFW is enabled, open ports 137–139 and 445:
>
> ```bash
> sudo ufw allow samba
> ```

---

## Contributing

Pull requests are welcome! Please open an issue first to discuss major changes or new modules.

---

## License

Released under the MIT License. See `LICENSE` for details.
