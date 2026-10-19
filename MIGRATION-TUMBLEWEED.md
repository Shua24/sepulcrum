# Moving sepulcrum from NixOS to openSUSE Tumbleweed

Written 2026-10-19. **Status: plan. Nothing in this file has been executed on
this machine, and nothing in it is a claim about a system that does not exist
yet.**

This file exists because the flake stops being the machine's source of truth the
day Tumbleweed is installed. Everything the flake encodes — 39 modules, ~858
packages, the hardware quirks, the service set — becomes a *checklist* instead of
a build input. That conversion is this document's whole job.

Companion plan with the execution order and the pre-verified commands:
`~/.hermes/plans/2026-10-19_2326-sepulcrum-opensuse-migration.md`

## Why this move

FHS. Measured on this box on 2026-10-19, before any of this was written:

    /usr          -> contains only `bin`
    /usr/bin      -> 1 entry: env -> /nix/store/...-coreutils-9.11/bin/env
    /opt          -> empty
    /etc          -> 103 entries, most of them symlinks into /nix/store
    /nix          -> 49G, all of it /nix/store

Vendor installers, AppImages, prebuilt binaries and client tooling assume
`/usr/lib`, `ldconfig` and a real `/opt`. On Tumbleweed they get all three back.
The trade — losing NixOS generations — is covered by snapper rollbacks on the
system side, and partially by keeping Nix installed as a *user-level* package
manager (a guest in the house, not the landlord: `/nix/store` simply coexists
with a real `/usr`).

## How to verify anything in this file

Package names below were checked on 2026-10-19 against the live repositories, not
recalled:

    # package inventory (point a grep at this)
    curl -sL https://download.opensuse.org/tumbleweed/repo/oss/x86_64/   > tw-x86_64.html
    curl -sL https://download.opensuse.org/tumbleweed/repo/oss/noarch/   > tw-noarch.html
    curl -sL https://download.opensuse.org/tumbleweed/repo/non-oss/x86_64/ > tw-non-oss.html
    grep -oE '<name>-[0-9]' tw-x86_64.html   # etc.

    # on the installed system, per package
    zypper se -s <name>

The snapshot these names were read from: `download.opensuse.org/tumbleweed/repo/`,
files dated 2026-10-19 (oss x86_64 9.6 MB, oss noarch 11.5 MB, non-oss 18.9 KB).
Versions quoted below are from that snapshot and move constantly — only the
*name* matters.

## 0. Decisions already taken

| Decision | Choice | Why |
|---|---|---|
| Distribution | **Tumbleweed** | Needs Mesa 26.x / wlroots 0.20 for compositor work; Leap and Slowroll lag |
| Publishing | **OBS** (`build.opensuse.org`) | AUR registration is closed (evidence in §9); OBS builds for Tumbleweed + Arch + Debian/Ubuntu from one project, free, no approval queue |
| Nix | **Keep, user-level** | Pinned dev shells for iris_wm/yarfwm without owning the OS |
| Bootloader | **GRUB2** | `limine` is not packaged in Tumbleweed; GRUB2 has snapper rollback integration |
| Wine prefixes | **Rebuild** | Confirmed gone with the CachyOS home (§2) |

## 1. Disks — read before touching a partitioner

Measured 2026-10-19 (`lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS`):

    nvme0n1    476.9G
    └─nvme0n1p1 476.9G ext4  "Other"   (NOT mounted at boot)
    nvme1n1    953.9G
    ├─nvme1n1p1   1G vfat             /boot     (no label)
    ├─nvme1n1p2  50G btrfs nixos-root /
    ├─nvme1n1p3 150G btrfs nixos-nix  /nix
    └─nvme1n1p4 752.9G btrfs nixos-home /home
    zram0       14.9G swap (zram)

**nvme0n1p1 is the WinBoat Windows VM, and it is not an OS disk.** Contents
measured:

    Other/winboat/
      data.img        256 GiB sparse qcow/raw (27G actually on disk)
      windows.rom     3.5 MB OVMF UEFI firmware
      windows.vars    528 KB UEFI NVRAM — the Windows boot entry lives here
      windows.mac / windows.ver / windows.base / windows.boot

Rules that follow:

1. **A reinstall touches nvme1n1 only.** Never point a partitioner, `wipefs`,
   `mkfs` or `fatlabel` at nvme0n1p1.
2. That disk is *not* in the fstab, because `nixos-generate-config` only records
   what was mounted when it ran. The new install needs an fstab entry (by UUID)
   or WinBoat's install path will not exist at boot.

Capture the old geometry before the wipe (it exists nowhere else afterwards):

    lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTUUID,MOUNTPOINTS > ~/Paranoia/sepulcrum-storage-pre-wipe.txt
    lsblk -b -o NAME,START >> ~/Paranoia/sepulcrum-storage-pre-wipe.txt
    findmnt -R / >> ~/Paranoia/sepulcrum-storage-pre-wipe.txt

## 2. What does NOT survive, measured

| Thing | State on 2026-10-19 | Consequence |
|---|---|---|
| Wine prefixes | **Zero exist.** `/home/aulus` swept with no depth limit; only Steam's Proton `default_pfx` template and two `compatdata` prefixes (1493710, 438100) | Nothing to migrate. Rebuild on Tumbleweed. Write down the winetricks verbs you used before you forget them — that is the only irreplaceable part |
| `~/Documents/backup` | empty (0 bytes) | Not a backup |
| WinBoat VM | intact on nvme0n1p1 | Re-point WinBoat at `/run/media/aulus/Other` after the reinstall. **Test whether 0.9.2 adopts an existing `data.img` or insists on a fresh one before you rely on it** |
| `~/.winboat` | does not exist (WinBoat never ran on NixOS) | The compose file holding the install-folder choice died with CachyOS. Recreated by setup on the new install |
| `~/Sources/packages/user-packages.txt` | a **Fedora** package dump | Two migrations old. Reference only, never a package source for this move |
| Previous distro | **CachyOS**, replaced 2026-10-17 | The old `/home` is gone; anything not copied off before that day is gone with it |
| `/nix` | 49G | Freed by the reinstall (unless Nix is kept as a guest) |

**Before the wipe** (from the `machine-migration` skill, in this order):

    for r in ~/Sources/*/; do echo "== $r"; git -C "$r" status --short; git -C "$r" branch -vv | grep -v '\[origin/'; git -C "$r" stash list; done
    git -C <repo> log --oneline @{u}..          # the actual unpushed list
    git ls-remote origin <branch>               # prove the sha is on the remote

Cover each of these explicitly, one at a time, and get a yes/no per item:

- every `~/Sources` repo pushed, remote sha verified
- `~/.hermes/`: `skills/ plans/ plugins/ cron/ scripts/ memories/ config.yaml SOUL.md USER.md` + small `.db` files. `state.db` (session history) is NOT rebuildable — decide on it by name
- credentials: `~/.hermes/auth.json`, `~/.hermes/vault/`, anything under `~/.config/` that holds a token (Messaging gateway bot credentials), keyrings
- `~/Paranoia` (the vault) — its LAN copy is `niel@192.168.18.209:64` (`/home/niel/Vault/Paranoia.git`)
- `~/Sources/dots` (stow dir) — distro-neutral, survives as files
- the Innocephsca Alpha font source (`Shua24/innocephsca-alpha`) is on GitHub; the *built* TTFs are not — copy the built TTFs or rebuild

## 3. Package map — verified against the snapshot

Format: `nixpkgs name -> Tumbleweed package`. Names not shown with an arrow are
identical on both sides (verified present in the snapshot).

### audio-misc (17)
`piper-tts -> piper`, `speechd -> speech-dispatcher`, orca, seahorse,
android-tools, wireplumber, pavucontrol, alsa-utils, playerctl, pamixer,
brightnessctl, keyd, patchelf, binutils, gdb, strace, valgrind

### desktop-applications (62)
`firefox -> MozillaFirefox`, `thunderbird -> MozillaThunderbird`,
`libreoffice-stable -> libreoffice`, `tor-browser -> torbrowser-launcher`,
discord *(non-oss)*, telegram-desktop, keepassxc, vlc, mpv, qbittorrent, haruna,
simple-scan, loupe, papers, showtime, decibels, yelp, gnome-tour,
gnome-user-share, gnome-disk-utility, gnome-system-monitor, gnome-text-editor,
gnome-tweaks, gnome-calculator, gnome-calendar, gnome-clocks, gnome-contacts,
gnome-logs, gnome-maps, gnome-music, gnome-weather, gnome-characters,
gnome-color-manager, gnome-font-viewer, gnome-backgrounds, gnome-connections,
gnome-remote-desktop, grilo-plugins, rygel, gvfs, sushi, baobab, malcontent,
gnome-boxes, nautilus, thunar, thunar-volman, epiphany, xterm,
xfce4-appfinder, xfce4-panel, xfce4-power-manager, xfce4-session,
xfce4-settings, xfce4-terminal, xfdesktop, xfwm4, xfce4-screensaver

Not packaged: brave, ungoogled-chromium, floorp, netsurf, element-desktop → §4

### development (34)
`gnumake -> make`, `pkg-config -> pkgconf`, `php -> php8`,
`phpPackages.composer -> php-composer`, `cmocka -> libcmocka-devel`,
`rustc -> rust`, `jdk21 -> java-21-openjdk-devel`, `gnat15 -> gcc15-ada`,
`nodejs_22 -> nodejs24` *(22 does not exist in Tumbleweed; 24 and 26 do)*,
`corepack -> corepack-default`, `uv -> python313-uv`, gcc, clang, cmake, meson,
ninja, pnpm, yarn, go, cargo, maven, alire *(no)*

Python is **versioned only**: there is no unversioned `python3` package. Pick a
version and use its prefix for every module:

    python3           -> python313  (313 / 314 / 315 all exist)
    python3Packages.pip         -> python313-pip
    python3Packages.defusedxml  -> python313-defusedxml
    python3Packages.packaging   -> python313-packaging
    python3Packages.qrcode      -> python313-qrcode
    python3Packages.ipython     -> python313-ipython

Not packaged: rustup, gradle, dotnet-sdk, gprbuild, alire, opencode → §4

### editors-graphics (8)
gimp, inkscape, fontforge, meld  •  not packaged: vscode, ghidra, birdfont,
ttfautohint → §4

### filesystem (38)
`btrfs-progs -> btrfsprogs`, `usb-modeswitch -> usb_modeswitch`,
`lm_sensors -> sensors`, `cpupower-gui -> cpupower` *(CLI; the GUI is OBS-only)*,
`libinput -> libinput-tools` *(tools; `libinput-udev` for the rules)*, snapper,
e2fsprogs, xfsprogs, dosfstools, exfatprogs, f2fs-tools, jfsutils, nilfs-utils,
lvm2, mdadm, dmraid, cryptsetup, smartmontools, sg3_utils, lsscsi, sysfsutils,
mtools, hdparm, parted, gparted, gptfdisk, nvme-cli, hwinfo, dmidecode,
pciutils, usbutils, lsb-release, powertop, acpi, evtest, fsarchiver, rclone,
libinput-gestures *(no → OBS)*

Note: `btrfsmaintenance` and `snapper` are both packaged and are the Tumbleweed
equivalent of the flake's fstrim + btrfs tooling. `fstrim.timer` comes from
util-linux, not a package.

### gaming (11)
`heroic -> heroic-games-launcher`, wine *(11.19, plus `wine-32bit`,
`wine-staging`, `wine-staging-wow64`, `wine-wow64`, `wine-devel`)*, winetricks
*(20260125, noarch)*, gamescope, gamemode, mangohud *(+ `mangohud-32bit`)*,
goverlay, vkbasalt, steam *(non-oss)*

Not packaged: protonup-qt, bottles → Flathub. `steam-run` has no equivalent and
is not needed off NixOS.

### gpu-hardware (13)
`mesa-demos -> Mesa-demo-x`, `nvtopPackages.full -> nvtop`,
`v4l2loopback -> v4l2loopback-kmp-default` *(+ `v4l2loopback-utils`)*,
libva-utils, amdgpu_top, radeontop, cpu-x, supergfxctl,
`linuxPackages_latest.cpupower -> cpupower`, v4l-utils

Not packaged: `asusctl` and the ROG Control Center → Tuatara repo, OBS or Copr
(§6; the charge limit itself needs none of them), `vdpauinfo` →
Packman, `acpi_call` → not needed

### media (9)
`poppler-utils -> poppler-tools`,
`gst_all_1.gst-libav -> gstreamer-plugins-libav`,
`gst_all_1.gst-plugins-bad -> gstreamer-plugins-bad`,
`gst_all_1.gst-plugins-ugly -> gstreamer-plugins-ugly`,
`libopenraw -> libopenraw9`, tesseract, ffmpegthumbnailer, libgsf

`libdvdcss` is not in any openSUSE repo (legal) → Packman's `libdvdcss2`

### network (14)
`networkmanager -> NetworkManager`,
`networkmanager-openvpn -> NetworkManager-openvpn`,
`networkmanagerapplet -> NetworkManager-applet`, `nssmdns -> nss-mdns`, iwd,
wpa_supplicant, dnsmasq, xl2tpd, openvpn, wireguard-tools, openssh, mosh,
valkey, mailutils

### plasma (50)
Tumbleweed suffixes Plasma 6 *framework* pieces with `6`, keeps KDE Gear app
names plain:

    plasma-desktop                -> plasma6-desktop
    plasma-workspace              -> plasma6-workspace
    plasma-browser-integration    -> plasma6-browser-integration
    plasma-firewall               -> plasma6-firewall
    plasma-nm                     -> plasma6-nm
    plasma-pa                     -> plasma6-pa
    plasma-systemmonitor          -> plasma6-systemmonitor
    plasma-thunderbolt            -> plasma6-thunderbolt
    plasma-login-manager          -> sddm            (or keep gdm)
    kwin                          -> kwin6
    kwin-x11                      -> kwin6-x11
    kscreen                       -> kscreen6
    kscreenlocker                 -> kscreenlocker6
    kinfocenter                   -> kinfocenter6
    systemsettings                -> systemsettings6
    powerdevil                    -> powerdevil6
    polkit-kde-agent-1            -> polkit-kde-agent-6
    kglobalacceld                 -> kglobalacceld6
    kmenuedit                     -> kmenuedit6
    kactivitymanagerd             -> kactivitymanagerd6
    kde-gtk-config                -> kde-gtk-config6
    kdeplasma-addons              -> kdeplasma6-addons
    bluedevil                     -> bluedevil6
    breeze-gtk                    -> gtk3-metatheme-breeze6
    ksshaskpass                   -> ksshaskpass6
    kwallet                       -> kf6-kwallet + kwalletd6
    kwallet-pam                   -> pam_kwallet6
    kio                           -> kf6-kio
    kgamma                        -> kgamma6
    phonon                        -> libphonon4qt6
    phonon-vlc                    -> phonon-vlc-qt6

Same name on both sides: kdialog, kdeconnect-kde, kdegraphics-thumbnailers,
ffmpegthumbs, filelight, gwenview, kate, kcalc, konsole, dolphin, ark,
partitionmanager, kdf, kfind, kompare, spectacle

### shells (71)
`yq-go -> yq`, `micro -> micro-editor`, `delta -> git-delta`, `p7zip -> 7zip`,
`man-db -> man`, `glances -> glances-common` *(+ `python313-Glances`)*,
`dnsutils -> bind-utils`, yash *(no)*, starship, tmux, alacritty, kitty, wezterm,
ghostty, foot, xterm, cmatrix, viu, btop, fastfetch, duf, lf, tecla, less,
man-pages, texinfo, plocate, nano, neovim, vim, vis, ripgrep, fd, fzf, bat,
tree, jq, tig, lazygit, git, git-lfs, gh, stow, rsync, pv, wget, curl, unzip,
unrar, zip, file, which, psmisc, procps, htop, ncdu, dust, inetutils *(no)*,
traceroute, mtr, whois, socat, nmap, tcpdump, bind, ksh, bash, fish, zsh

Two removals that matter: **`yash` is not packaged** and it is this flake's
login shell (`users.users.aulus.shell = pkgs.yash`) — but the POSIX-in-practice
substitutes the user asked for are all in the repo: `ksh` 93vu, `mksh` 59c,
`dash` 0.5.13.5 (no `oksh`, `pdksh`, `posh` or `loksh`). **`net-tools` is gone**
(only a dummy package remains); use `iproute2`.

### theming (3)
sassc  •  `catppuccin-gtk` and `chicago95` are not packaged — Catppuccin sources
live in `~/Sources/Catppuccin-GTK-Theme`, build them there

### virtualisation (13)
`kubectl -> kubernetes-client`, `kubernetes-helm -> helm`,
`terraform -> opentofu` *(terraform itself was removed from the repo)*, docker,
docker-compose, docker-buildx, k9s, minikube, ansible, virt-manager,
virt-viewer, qemu  •  winboat → upstream AppImage (§7)

### wayland (45)
Same name on both sides, verified: niri, labwc, xwayland-satellite, waybar,
rofi *(+ `rofi-wayland`)*, wofi, fuzzel, mako, fnott, eww, wbg, swaybg,
swayidle, wlogout, wlopm, wlr-randr, hypridle, hyprlock, gtklock, waylock,
gammastep, wlsunset, kanshi, wev, wtype, ydotool, grim, slurp, wl-clipboard,
wf-recorder, xsettingsd, xdotool, xsel, picom, awww

`swaylock-effects -> swaylock` (the fork is not packaged; use upstream swaylock
or build the fork). Not packaged: river, ironbar, nwg-panel, sfwbar, tint2,
plank, wpaperd, libsfdo. `nwg-look`, `nwg-bar`, `nwg-displays`, `nwg-drawer`,
`nwg-launchers` *are* packaged.

`river` matters: yarfwm is a river *client*, and the PKGBUILD's build dependency
on river is what makes the river protocol XML visible at build time. On
Tumbleweed river must be built from source before yarfwm can be.

### xorg-utilities (29)
`xorg-server -> xorg-x11-server`; everything else in the group is identical:
xterm, twm, xclock, xev, xinput, xhost, xrefresh, xkill, xwd, xwud, xlsclients,
xlsatoms, xset, xsetroot, xpr, xgamma, x11perf, xcursorgen, xdriinfo, xvinfo,
xbacklight, xkbevd, xkbutils, xcmsdb, smproxy, sessreg, bdftopcf, font-util

## 4. Not in any Tumbleweed repo — the decision list

| Package | Where it comes from | Cost |
|---|---|---|
| `asusctl`, `asusctl-rog-gui` | Tuatara repo (or OBS `home:RN:asusctl`, or Copr) | third-party repo to trust — but charge limit works without it (§6) |
| `vdpauinfo` | Packman | extra repo; the NVIDIA driver provides VDPAU anyway |
| `libdvdcss` | Packman (`libdvdcss2`) | extra repo |
| `bottles`, `protonup-qt` | Flathub | flatpak + remote to add |
| `heroic` | `heroic-games-launcher` is packaged | none — use the repo |
| vscode | Microsoft's own RPM repo, or Flathub `com.visualstudio.code` | third-party repo (Microsoft-signed) |
| `brave` | Brave's own RPM repo | third-party repo |
| `ungoogled-chromium`, `floorp` | OBS / Flatpak / upstream tarball | manual |
| `element-desktop` | Flathub `im.riot.Riot` | flatpak |
| `ghidra` | upstream release tarball (needs `java-21-openjdk` ✓) | manual |
| `tor-browser` | `torbrowser-launcher` is packaged | none — use the repo |
| `dotnet-sdk` / `aspnetcore` | Microsoft's openSUSE repo, or OBS `devel:languages:dotnet` | third-party repo |
| `rustup` | Rust's own installer, or just use packaged `rust` + `cargo` | none if you drop rustup |
| `gradle` | SDKMAN or OBS | manual |
| `alire` (Ada toolchain) | Alire's own installer — it ships its own gnat/gnatprove, so nothing distro-side is needed | manual, once |
| `gprbuild` | comes with Alire's toolchain; `gcc15-ada` is packaged separately | none via Alire |
| `opencode` | upstream install script / npm / bun | manual |
| `yash` (login shell) | OBS or build from source — or switch shells | decide |
| `catppuccin-gtk`, `chicago95` | source (`~/Sources/Catppuccin-GTK-Theme`) | build |
| `wpaperd`, `ironbar`, `nwg-panel`, `sfwbar`, `tint2`, `plank` | upstream / OBS — check whether each is still used before porting anything | triage |
| `libsfdo`, `netsurf`, `birdfont`, `ttfautohint`, `inetutils`, `tty-clock` | drop or upstream | triage |
| `winboat` | upstream AppImage / RPM (v0.9.2 ships both) | see §7 |
| `mpv`/`vlc` codecs | Tumbleweed's own packages cover this; Packman only if you want the extra ones | optional |

## 5. Services — NixOS option to Tumbleweed unit

| Flake option | Tumbleweed |
|---|---|
| `services.openssh.enable` | `sshd.service` (pattern/role; `zypper in openssh`) |
| `services.fwupd.enable` | `fwupd.service` |
| `services.thermald.enable` | `thermald.service` |
| `services.power-profiles-daemon.enable` | `power-profiles-daemon.service` (conflicts with `tuned` — pick one) |
| `services.upower.enable` | `upower.service` |
| `services.gvfs.enable` | `gvfs` package, D-Bus activated |
| `services.tumbler.enable` | `tumbler` package |
| `services.udisks2.enable` | `udisks2.service` |
| `services.avahi` (+`nssmdns4`) | `avahi-daemon` + `nss-mdns` |
| `services.printing.enable` | `cups.service` |
| `services.blueman.enable` | `blueman` |
| `services.logrotate.enable` | `logrotate.timer` |
| `services.fstrim.enable` | `fstrim.timer` (util-linux) |
| `services.gnome.gnome-keyring.enable` | `gnome-keyring` + PAM config in `/etc/pam.d/` |
| `services.pipewire` (+alsa/pulse/jack) | `pipewire`, `pipewire-alsa`, `pipewire-pulseaudio`, `pipewire-jack`, `wireplumber` |
| `security.rtkit.enable` | `rtkit` |
| `services.xserver.videoDrivers` | driver packages (§6) |
| `virtualisation.docker.enable` | `docker.service`; add user to `docker` group |
| `virtualisation.libvirtd.enable` | `libvirtd.service`; add user to `libvirt` group |
| `services.asusd.enable` | `asusd.service` (from OBS asus-linux) |
| `services.supergfxd.enable` | `supergfxctl.service` (packaged) |
| `services.geoclue2.enable` | `geoclue2` |
| `services.redshift` | `redshift` — but the flake gates it to X11 only; on a Wayland-first box it never fires |
| `services.gammastep` (custom user unit) | **recreate the unit**: `~/.config/systemd/user/gammastep.service`, wanted-by `graphical-session.target`, `ConditionEnvironment=XDG_SESSION_TYPE=wayland`, plus the ExecCondition guard that skips KDE/GNOME |
| `networking.firewall.enable` | `firewalld.service` (openSUSE default) |
| `security.polkit.enable` | `polkit` |
| `programs.gnupg.agent` (+SSH, pinentry-qt) | `gpg-agent` + `pinentry-qt6`; `enable-ssh-support` in `~/.gnupg/gpg-agent.conf` |
| `programs.kdeconnect.enable` | `kdeconnect-kde` |
| `programs.obs-studio.enable` | `obs-studio` |
| `programs.partition-manager.enable` | `partitionmanager` |
| `programs.mtr.enable` | `mtr` (`setcap` for non-root) |
| `programs.dconf` / `fish` / `zsh` | `dconf`, `fish`, `zsh` |
| `programs.nix-ld` | obsolete — the FHS is the real one now |

## 6. Hardware specifics

**NVIDIA (RTX 3060 Mobile, open kernel modules).** The flake used
`hardware.nvidia.open = true`, driver `stable`, `modesetting`, power management
on, PRIME offload with the bus IDs force-pinned to `PCI:1:0:0` (NVIDIA) and
`PCI:6:0:0` (AMD iGPU).

Tumbleweed carries the signed **open kernel module** in its own repo
(`nvidia-open-driver-G06-signed-kmp-default`), and NVIDIA's own repo carries the
userspace side for Tumbleweed (`nvidia-gl-G06`, `nvidia-compute-G06`,
`nvidia-video-G06`, `nvidia-utils-G06`, `nvidia-gpucomp-G06`, verified in
`download.nvidia.com/opensuse/tumbleweed`). Install order matters: add the NVIDIA
repo, install userspace, then the kmp. PRIME render offload uses the env-var form
(`__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`, plus
`switcheroo-control` which is packaged), not a switching script — verify with
`switcherooctl list`.

**ASUS ROG (G513RM).** `asusctl` (with `asusd`) and the GUI (`asusctl-rog-gui`,
the ROG Control Center) are not in the distro repos. Verified routes, all
third-party:

| Route | Install | Note |
|---|---|---|
| **Tuatara repo** (current upstream-documented route) | `zypper install --plus-repo 'https://repos.fyralabs.com/tuatara-$releasever' tuatara-release` then `zypper in asusctl asusctl-rog-gui` | Tuatara is the openSUSE counterpart of Fedora's Terra repo, Tumbleweed only |
| OBS `home:RN:asusctl` | addrepo from software.opensuse.org | asusctl 6.3.2 built for Tumbleweed, Slowroll, Leap 16.0 and 15.6 |
| Copr `lukenukem/asus-linux` (openSUSE build) | repo file from copr | the older asus-linux.org guide route; still listed |

`supergfxctl` is in the **main repo**, but upstream now calls it deprecated and
advises against installing it unless you need VFIO or cannot power off the dGPU.

Two conflicts to handle that this flake currently has:

- **`asusd` races `power-profiles-daemon`** over `/sys/firmware/acpi/platform_profile`
  and CPU EPP. This flake enables both (`services.asusd` and
  `services.power-profiles-daemon`). On Tumbleweed either disable
  `power-profiles-daemon` or set `change_platform_profile_on_ac: false`,
  `change_platform_profile_on_battery: false`, `platform_profile_linked_epp: false`
  in `/etc/asusd/asusd.ron`.
- openSUSE may install **`suse-prime`**, which conflicts with `supergfxctl` —
  remove it before installing supergfxctl.

**The de-risking fact: the one thing this flake actually asked asusd for does not
need asusd.** Measured on this machine:

    /sys/class/power_supply/BAT0/charge_control_end_threshold = 60

That is the ASUS WMI driver exposing the charge limit directly — and 60 is
already the value `hardware.asus.battery.chargeUpto` set. A one-line systemd
unit (or udev rule) writing 60 there reproduces it with no third-party repo at
all. What asusctl uniquely adds is fan curves, keyboard RGB and profile
switching; the charge limit is not the reason to keep it. `acpi_call` is not
needed either way.

**zram.** The flake used zram at 100% of RAM with zstd (matching the old CachyOS
`zram0` of 15974006784 bytes). Tumbleweed uses `zram-generator`:

    # /etc/systemd/zram-generator.conf
    [zram0]
    zram-size = ram
    compression-algorithm = zstd

**Kernel.** `boot.kernelParams = [ "quiet" "nowatchdog" ]` →
`GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub` (+ `grub2-mkconfig -o
/boot/grub2/grub.cfg`). AMD microcode: `amd-ucode` package, initrd handled by
openSUSE automatically. `kvm-amd` module: comes with the kernel; no config.

**keyd** (in `audio-misc`) is packaged and has a service — it remaps keys
system-wide, so it is one of the things that silently "isn't there" if forgotten.

## 7. Desktop and sessions

The flake enables, in one machine: **GDM**, Plasma 6, GNOME, XFCE, icewm, niri,
labwc, river-classic. Tumbleweed can do all of that; the session files appear in
`/usr/share/wayland-sessions/` and `/usr/share/xsessions/` as packages land.

- `gdm` (default session → Plasma), `plasma6-desktop`, `gnome-shell`,
  `xfce4-session`, `icewm`, `niri`, `labwc` — all packaged
- **river** and **yarfwm**: both variants of river are packaged for Tumbleweed
  in the **`X11:Wayland`** devel project on OBS — `river` 0.4.8 (the
  non-monolithic one yarfwm talks to) and `river-classic` 0.3.17 with
  `river-classic-riverctl`/`-rivertile` (the monolithic one this flake's
  `programs.river-classic` starts). Neither is in the distro repos. Everything
  needed to build river 0.5.0 from source is in the distro anyway — including
  `zig0.16` 0.16.0, the exact compiler river pins, and `zig-rpm-macros0.16`.
  Either way, river satisfies yarfwm's build dependency (`pkgconfig(river)` is
  what yarfwm reads the protocol XML from), then yarfwm builds against
  `wlroots-0_20-devel` (0.20.2).
- portals: `xdg-desktop-portal` + `-gtk` + `-gnome` + `-kde` (the flake forced
  gtk+gnome; Plasma needs the kde one too or file pickers misbehave)
- input method: `fcitx5`, `fcitx5-configtool`, `fcitx5-mozc`, `mozc` — all
  packaged; set `GTK_IM_MODULE`/`QT_IM_MODULE`/`XMODIFIERS` in
  `~/.config/environment.d/` and enable the autostart
- locales: primary `en_GB.UTF-8`, timezone `Asia/Jakarta`, keymap `us` — set in
  `YaST > System > Language` and `/etc/vconsole.conf`
- fonts, verified: `noto-sans-fonts`, `noto-sans-cjk-fonts`,
  `noto-coloremoji-fonts`, `dejavu-fonts`, `liberation-fonts`, `inconsolata`
  (+ `inconsolata-nerd-font`), `hack-fonts`, `iosevka-fonts` (34.9.0 — same
  version as this repo's font project), `jetbrains-mono-fonts`,
  `fira-code-fonts`; Microsoft corefonts come from `fetchmsttfonts`.
  Not packaged: `poppins` (OBS or Google Fonts), Maple Mono NF and the
  Nerd-Fonts `symbols-only` (upstream downloads), `ttfautohint` (not needed —
  the font build runs its own npm/hint pipeline).
  **Innocephsca Alpha** is built from `Shua24/innocephsca-alpha`; install the
  TTFs to `~/.local/share/fonts/` on the new machine
- `sudo` for wheel: default on Tumbleweed is `sudo` with `wheel` in sudoers —
  matches `security.sudo.wheelNeedsPassword = true`

## 8. WinBoat on Tumbleweed

Upstream **v0.9.2** (2026-08-25) ships `winboat-0.9.2-x86_64.AppImage`,
`.rpm`, `.deb`, a tarball and the guest server. Tumbleweed has every dependency
verified in the repo:

| Requirement | Tumbleweed |
|---|---|
| Docker + Compose v2 + buildx | `docker` 29.7 CE, `docker-compose`, `docker-buildx` (or Podman ≥4 — `podman`, `podman-compose`) |
| KVM | kernel + `qemu-kvm`/libvirt |
| FreeRDP 3.x with sound | `freerdp` 3.32.1, `freerdp-sdl` |
| FUSE for the AppImage | `libfuse2` (or run `--appimage-extract-and-run`) |

Two WinBoat-specific notes: the Windows VM disk is 256 GiB *sparse* (27G real)
and already lives on nvme0n1p1 — point the installer at `/run/media/aulus/Other`
again, and put nothing else there. And test **before** the wipe whether 0.9.2
adopts the existing `data.img`; if it does not, back the WinBoat Windows install
up the way *it* wants, not by copying files around.

## 9. Publishing: AUR is closed, OBS is not

Measured 2026-10-19:

- 2026-06-15 — AUR registration disabled (malicious package wave)
- 2026-07-13 — reopened, hardened (no disposable emails, mandatory verification)
- 2026-07-30 onward — another wave: "27 more infected AUR packages contain
  malware executed via `sudo` during builds"
- 2026-09-01 — a developer on aur-general: "I don't have an AUR account and
  registrations are (rightfully!) stopped"
- 2026-09-12 — Jelle van der Waa (AUR staff): "we don't manually onboard new
  users on the AUR at the moment"
- 2026-10 — no reopening announcement on aur-general; the register page itself
  now sits behind Anubis (proof-of-work bot wall), so it cannot be read without
  a full browser

**So: publish through OBS.** Verified capability (OBS docs): build targets
include Arch Linux (Core/Extra/Community), Debian, Ubuntu, Fedora, openSUSE
Tumbleweed/Leap, and AppImage; recipe formats include PKGBUILD, `.spec`, `.dsc`,
APKBUILD. A free home project has no approval queue.

Seeding it with what already exists:

- `~/Sources/yarfwm/packaging/yarfwm/PKGBUILD` and `yarfwm-git/PKGBUILD` — both
  already in the yarfwm repo, built once with makepkg (the `.pkg.tar.zst` is in
  that directory). OBS builds Arch packages from a PKGBUILD directly; `.SRCINFO`
  is an AUR requirement, not an OBS one.
- write a `.spec` for the same source so Tumbleweed gets an RPM from the same
  project — that is the part that makes this better than AUR was, not a
  replacement for it
- `~/Sources/Yanoch/notion-app-electron/PKGBUILD` is a second candidate

## 10. Open questions

1. Does the reinstalled system keep `/home` as a separate btrfs partition with
   subvolumes (snapper-friendly), or one big root? The old layout had three
   partitions (`/`, `/nix`, `/home`); `/nix` no longer needs to be one, and
   `/home` wants `@`/`@home` subvolumes for snapper to roll back sanely.
2. Keep Nix as a user-level package manager or not? If yes, `/nix` should be a
   directory on a partition with room (it was 49G).
3. yash as the login shell: port it, or change the shell in this checklist.
4. Which of the window managers in `wayland.nix` are actually still used? Six
   panels and five lock screens are not a workflow, they are a museum — triage
   before porting.
5. iris_wm's SPARK toolchain on Tumbleweed: Alire ships its own gnat/gnatprove,
   and `wlroots-0_20-devel` + `wayland-protocols-devel` are verified present,
   but the Ada binding build itself has never been run off NixOS.
