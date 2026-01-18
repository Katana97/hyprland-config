# Complete RTX 4070 Ti eGPU Setup Guide for CachyOS + Hyprland
**Dell XPS 9500 Multi-GPU Configuration**

**Date Created:** December 27, 2025  
**System:** CachyOS with Hyprland 0.52.2

---

## System Hardware

- **Laptop:** Dell XPS 9500
- **CPU:** Intel Core i7-10875H
- **iGPU:** Intel UHD Graphics (card2, PCI 00:02.0)
- **Internal dGPU:** NVIDIA GTX 1650 Ti Mobile (card1, PCI 01:00.0)
- **External eGPU:** NVIDIA RTX 4070 Ti (card0, PCI 08:00.0, Thunderbolt 3)

---

## Overview

This guide documents the complete process to get the RTX 4070 Ti eGPU working properly on CachyOS with Hyprland, with automatic GPU selection that prioritizes the most powerful GPU available.

**Goal:** 
- Use RTX 4070 Ti when eGPU is connected
- Fallback to GTX 1650 Ti when eGPU is disconnected
- Intel iGPU handles the desktop compositor (for stability)
- Hot-plug/unplug support

---

## Part 1: Initial System Setup

### 1.1 Install CachyOS

During installation:
- **Profile:** Minimal/CLI or Desktop (no specific DE)
- **Kernel:** Default CachyOS kernel
- **Bootloader:** GRUB
- **Network:** NetworkManager

### 1.2 Update System and Install Base Tools

```bash
sudo pacman -Syu
sudo reboot

sudo pacman -S --needed git base-devel networkmanager bolt vim nano
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bolt
```

### 1.3 Install AUR Helper (yay)

```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~
```

---

## Part 2: NVIDIA Driver Installation

### 2.1 Install NVIDIA Drivers

```bash
# Install unified NVIDIA driver (supports both Turing and Ada)
sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

# Additional packages for Wayland and video acceleration
sudo pacman -S egl-wayland libva-nvidia-driver

# Enable persistence daemon
sudo systemctl enable --now nvidia-persistenced
```

**Why nvidia-dkms?**
- Supports GTX 1650 Ti (Turing) and RTX 4070 Ti (Ada Lovelace)
- Dynamic kernel module rebuilds for CachyOS kernels

### 2.2 Configure Kernel Parameters

Edit GRUB:
```bash
sudo nano /etc/default/grub
```

Add `nvidia-drm.modeset=1` to the kernel parameters:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1"
```

Regenerate GRUB:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 2.3 Configure initramfs

Edit mkinitcpio:
```bash
sudo nano /etc/mkinitcpio.conf
```

Add to MODULES array:
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

**Note:** Do NOT add `nvidia-drm.modeset=1` to MODULES - it's a kernel parameter, not a module.

Regenerate initramfs:
```bash
sudo mkinitcpio -P
```

### 2.4 NVIDIA Modprobe Configuration

```bash
sudo nano /etc/modprobe.d/nvidia.conf
```

Add:
```
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
```

### 2.5 Enable NVIDIA Suspend Services

```bash
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
```

**Reboot:**
```bash
sudo reboot
```

---

## Part 3: Intel Graphics and Audio Setup

### 3.1 Install Intel Graphics Stack

```bash
sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
```

### 3.2 Install Wayland Portals and Audio

```bash
# Desktop portals
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Audio stack
sudo pacman -S pipewire pipewire-pulse wireplumber

# Enable audio services
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

**Important:** Do NOT install `xdg-desktop-portal-wlr` - it conflicts with `xdg-desktop-portal-hyprland`.

---

## Part 4: Thunderbolt eGPU Authorization

### 4.1 Authorize eGPU (One-Time Setup)

With eGPU connected:
```bash
boltctl list
sudo boltctl authorize <UUID>
```

Replace `<UUID>` with the UUID shown in `boltctl list`.

This is permanent - the eGPU will auto-connect on future plug-ins.

### 4.2 Verify GPU Detection

```bash
# Check PCI devices
lspci | grep -E "VGA|3D"

# Expected output:
# 00:02.0 VGA compatible controller: Intel Corporation CometLake-H GT2 [UHD Graphics]
# 01:00.0 3D controller: NVIDIA Corporation TU117M [GeForce GTX 1650 Ti Mobile]
# 08:00.0 VGA compatible controller: NVIDIA Corporation AD104 [GeForce RTX 4070 Ti]

# Check NVIDIA driver
nvidia-smi

# Should show both NVIDIA GPUs
```

### 4.3 Verify DRM Device Mapping

```bash
ls -l /dev/dri/by-path/

# Expected:
# pci-0000:00:02.0-card -> ../card2 (Intel)
# pci-0000:01:00.0-card -> ../card1 (GTX 1650 Ti)
# pci-0000:08:00.0-card -> ../card0 (RTX 4070 Ti)
```

---

## Part 5: Hyprland Installation and Configuration

### 5.1 Install Hyprland

```bash
sudo pacman -S hyprland kitty
```

### 5.2 Configure Hyprland Environment Variables

If you already have Hyprland configs (e.g., from a dotfiles repo), edit your main config:

```bash
nano ~/dotfiles/hypr/.config/hypr/hyprland.conf
# OR
nano ~/.config/hypr/hyprland.conf
```

Add these environment variables (near other `env` lines):

```bash
# NVIDIA Configuration for Wayland
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = WLR_NO_HARDWARE_CURSORS,1

# Aquamarine DRM device priority (Intel first for compositor)
env = AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card0:/dev/dri/card1

# Force RTX 4070 Ti for Vulkan applications (CRITICAL!)
env = MESA_VK_DEVICE_SELECT,10de:2782
env = VK_ICD_FILENAMES,/usr/share/vulkan/icd.d/nvidia_icd.json

# Wayland app compatibility
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland
env = MOZ_ENABLE_WAYLAND,1

# XWayland scaling fix for fractional scaling
xwayland {
  force_zero_scaling = true
}

# Scale XWayland apps properly (adjust 1.25 to your preference)
env = GDK_SCALE,1.25
env = QT_SCALE_FACTOR,1.25

# Cursor size
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
```

**Critical Variables Explained:**

- **`MESA_VK_DEVICE_SELECT=10de:2782`** - Forces Vulkan to use RTX 4070 Ti by PCI device ID
  - `10de` = NVIDIA vendor ID
  - `2782` = RTX 4070 Ti device ID
- **`AQ_DRM_DEVICES`** - Sets compositor device priority (Intel first)
- **`xwayland.force_zero_scaling`** - Fixes XWayland blurriness with fractional scaling

### 5.3 Monitor Configuration

If using fractional scaling, set your monitor:

```bash
monitor=,preferred,auto,1.25
```

Adjust `1.25` to `1`, `1.5`, `2`, etc. based on your preference.

---

## Part 6: GPU Switching with switcheroo-control

### 6.1 Install and Enable switcheroo-control

```bash
sudo pacman -S switcheroo-control
sudo systemctl enable --now switcheroo-control
```

### 6.2 Initial eGPU Detection

**CRITICAL STEP:** After installing switcheroo-control, unplug and replug the Thunderbolt cable.

This triggers switcheroo-control to detect the eGPU. Verify:

```bash
switcherooctl list
```

Expected output:
```
Device: 0
  Name:        Intel® UHD Graphics
  Default:     yes
  Discrete:    no
  Environment: DRI_PRIME=pci-0000_00_02_0 VK_LOADER_DRIVERS_SELECT=*intel*

Device: 1
  Name:        NVIDIA Corporation TU117M [GeForce GTX 1650 Ti Mobile]
  Default:     no
  Discrete:    yes
  Environment: __GLX_VENDOR_LIBRARY_NAME=nvidia __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only VK_LOADER_DRIVERS_SELECT=*nvidia*

Device: 2
  Name:        NVIDIA Corporation AD104 [GeForce RTX™ 4070 Ti]
  Default:     no
  Discrete:    yes
  Environment: __GLX_VENDOR_LIBRARY_NAME=nvidia __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only VK_LOADER_DRIVERS_SELECT=*nvidia*
```

All 3 GPUs should be listed!

### 6.3 Automatic eGPU Detection on Boot

Create a udev rule for hot-plug detection:

```bash
sudo nano /etc/udev/rules.d/99-egpu-rescan.rules
```

Add:
```
# Trigger switcheroo-control rescan on Thunderbolt hot-plug
ACTION=="add", SUBSYSTEM=="thunderbolt", RUN+="/usr/bin/systemctl restart switcheroo-control"
```

Reload udev:
```bash
sudo udevadm control --reload-rules
```

### 6.4 Ensure Detection on Boot (Belt and Suspenders)

Create a systemd service to restart switcheroo-control after boot:

```bash
sudo nano /etc/systemd/system/egpu-detect.service
```

Add:
```
[Unit]
Description=Ensure eGPU detection by switcheroo-control
After=switcheroo-control.service
Wants=switcheroo-control.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 3
ExecStart=/bin/systemctl restart switcheroo-control.service

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable egpu-detect.service
```

---

## Part 7: Verification and Testing

### 7.1 Verify GPU Selection

```bash
# Check Vulkan can see all GPUs
vulkaninfo | grep "deviceName"

# Should show:
# deviceName = Intel(R) UHD Graphics (CML GT2)
# deviceName = NVIDIA GeForce GTX 1650 Ti
# deviceName = NVIDIA GeForce RTX 4070 Ti
```

### 7.2 Test with vkcube

```bash
# Install if needed
sudo pacman -S vulkan-tools

# Run vkcube
vkcube
```

In another terminal:
```bash
nvidia-smi dmon
```

You should see **GPU 1** (RTX 4070 Ti) showing activity, not GPU 0 (1650 Ti).

### 7.3 Test with Steam Games

Install Steam:
```bash
sudo pacman -S steam
```

Launch Steam normally - no special launch options needed! The global `MESA_VK_DEVICE_SELECT` handles GPU selection.

For individual games, you can verify which GPU is being used:
```bash
nvidia-smi dmon -s pucvmet
```

While running a game, GPU 1 should show:
- High `sm` (shader) usage (50-100%)
- High `pclk` (GPU clock, 1500-2800 MHz for 4070 Ti)
- Increased power draw (`pwr` column)

GPU 0 (1650 Ti) should remain idle (0% usage).

---

## Part 8: Optional Wrapper Scripts (Manual GPU Control)

If you want explicit control over which GPU to use, create wrapper scripts:

### 8.1 Wrapper for RTX 4070 Ti

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/run-on-4070
```

Add:
```bash
#!/bin/bash
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export MESA_VK_DEVICE_SELECT=10de:2782
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
exec "$@"
```

Make executable:
```bash
chmod +x ~/.local/bin/run-on-4070
```

### 8.2 Wrapper for GTX 1650 Ti (Battery Saving)

```bash
nano ~/.local/bin/run-on-1650
```

Add:
```bash
#!/bin/bash
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export MESA_VK_DEVICE_SELECT=10de:1f95
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
exec "$@"
```

Make executable:
```bash
chmod +x ~/.local/bin/run-on-1650
```

**Usage:**
```bash
run-on-4070 <application>
run-on-1650 <application>
```

**Note:** With the global `MESA_VK_DEVICE_SELECT` set, these wrappers are optional. Applications will use the 4070 Ti by default.

---

## Part 9: Troubleshooting

### 9.1 eGPU Not Detected After Boot

```bash
# Check if eGPU is authorized
boltctl list

# If needed, re-authorize
sudo boltctl authorize <UUID>

# Manually trigger switcheroo-control rescan
sudo systemctl restart switcheroo-control

# Verify detection
switcherooctl list
```

### 9.2 Games Using Wrong GPU

```bash
# Check current GPU being used
nvidia-smi dmon

# Verify environment variable is set
grep MESA_VK_DEVICE_SELECT ~/.config/hypr/hyprland.conf
# OR
grep MESA_VK_DEVICE_SELECT ~/dotfiles/hypr/.config/hypr/hyprland.conf

# If missing, add it and reload Hyprland
hyprctl reload
```

### 9.3 Check Which GPU is Actually Being Used

```bash
# Verbose Vulkan loader output
VK_LOADER_DEBUG=all vkcube 2>&1 | grep "Selected GPU"

# Should show: Selected GPU 0: NVIDIA GeForce RTX 4070 Ti
```

### 9.4 Steam/Proton Issues

If Steam games aren't using the correct GPU:

1. Remove any custom launch options from games
2. Ensure global `MESA_VK_DEVICE_SELECT` is in Hyprland config
3. Restart Steam:
   ```bash
   pkill -9 steam
   steam &
   ```

### 9.5 XWayland Apps Look Blurry

Ensure these are in your Hyprland config:
```bash
xwayland {
  force_zero_scaling = true
}

env = GDK_SCALE,1.25
env = QT_SCALE_FACTOR,1.25
```

Reload:
```bash
hyprctl reload
```

---

## Part 10: Understanding What Each Component Does

### 10.1 GPU Device Mapping

- **card0** (`pci-0000:08:00.0`) = RTX 4070 Ti (eGPU)
- **card1** (`pci-0000:01:00.0`) = GTX 1650 Ti (internal dGPU)
- **card2** (`pci-0000:00:02.0`) = Intel UHD (iGPU)

### 10.2 PCI Device IDs

- **10de:2782** = NVIDIA RTX 4070 Ti
- **10de:1f95** = NVIDIA GTX 1650 Ti Mobile
- **10de** = NVIDIA vendor ID (constant for all NVIDIA cards)

### 10.3 How GPU Selection Works

1. **Compositor (Hyprland):** Uses Intel iGPU (via `AQ_DRM_DEVICES` priority)
2. **Vulkan Applications:** Forced to RTX 4070 Ti via `MESA_VK_DEVICE_SELECT=10de:2782`
3. **Mesa device select layer:** Intercepts Vulkan device enumeration and forces the specified PCI device
4. **switcheroo-control:** Provides desktop integration for GPU switching

### 10.4 Why We Need All These Components

- **NVIDIA drivers:** Enable GPU hardware
- **switcheroo-control:** Desktop-level GPU management
- **MESA_VK_DEVICE_SELECT:** Forces specific GPU for Vulkan (most modern games)
- **Hyprland env vars:** Ensures Wayland/NVIDIA compatibility
- **udev rules:** Automatic eGPU detection on hot-plug
- **systemd service:** Ensures detection even if eGPU connected at boot

---

## Part 11: What Approaches DIDN'T Work

For educational purposes, here's what we tried that failed:

### Failed Approach 1: PRIME Render Offload Provider
```bash
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=pci-0000_08_00_0
```
**Why it failed:** These variables work on X11/XWayland, not pure Wayland.

### Failed Approach 2: DRI_PRIME
```bash
export DRI_PRIME=pci-0000_08_00_0
```
**Why it failed:** DRI_PRIME is for Mesa (open-source drivers), not NVIDIA proprietary.

### Failed Approach 3: VK_DEVICE_SELECT
```bash
export VK_DEVICE_SELECT=2
```
**Why it failed:** Vulkan internally re-orders devices, so index 2 wasn't the 4070 Ti.

### Failed Approach 4: Steam Launch Options
```bash
run-on-4070 %command%
```
**Why it failed:** Steam's pressure-vessel container strips environment variables.

### Failed Approach 5: Modifying Proton Script
**Why it failed:** pressure-vessel sandboxes even Proton's environment.

### What Actually Worked
**Global environment variables in Hyprland config** + **switcheroo-control** + **eGPU detection via unplug/replug or systemd service**

---

## Part 12: Post-Setup Checklist

Before proceeding with dotfiles installation:

- [ ] All 3 GPUs show up in `switcherooctl list`
- [ ] `nvidia-smi` shows both NVIDIA GPUs
- [ ] vkcube uses GPU 1 (RTX 4070 Ti) - verified with `nvidia-smi dmon`
- [ ] Steam games use RTX 4070 Ti
- [ ] XWayland apps (Steam, etc.) display clearly, not blurry
- [ ] eGPU hot-plug works (unplug/replug while running)
- [ ] System boots successfully with eGPU connected
- [ ] System boots successfully WITHOUT eGPU connected

---

## Part 13: Backup Before Installing Dotfiles

### 13.1 Backup Current Configuration

```bash
# Backup Hyprland config
cp -r ~/.config/hypr ~/.config/hypr.backup-$(date +%Y%m%d)
# OR if using dotfiles repo:
cp -r ~/dotfiles ~/dotfiles.backup-$(date +%Y%m%d)

# List installed packages
pacman -Qe > ~/package-list-$(date +%Y%m%d).txt

# Backup important configs
tar -czf ~/config-backup-$(date +%Y%m%d).tar.gz \
  ~/.config/hypr \
  ~/.config/kitty \
  ~/.bashrc \
  ~/.config/fish \
  ~/dotfiles
```

### 13.2 Filesystem Snapshot (If Using BTRFS)

If your CachyOS install uses BTRFS:

```bash
# Check if using BTRFS
df -Th | grep btrfs

# Create snapshot
sudo btrfs subvolume snapshot / /.snapshots/before-dotfiles-$(date +%Y%m%d)
```

### 13.3 Create System Restore Point with Timeshift

```bash
# Install Timeshift
sudo pacman -S timeshift

# Create snapshot
sudo timeshift --create --comments "Before end-4 dotfiles installation"
```

---

## Part 14: Ready for Dotfiles Installation

Your system is now ready to install end-4 or any other Hyprland dotfiles!

**Important Notes for Dotfiles Installation:**

1. **Preserve GPU settings:** Make sure any dotfiles don't overwrite:
   - `env = MESA_VK_DEVICE_SELECT,10de:2782`
   - `env = VK_ICD_FILENAMES,/usr/share/vulkan/icd.d/nvidia_icd.json`
   - XWayland scaling settings

2. **Backup first:** Always backup your working config before installing dotfiles

3. **Test incrementally:** After installing dotfiles, verify GPU selection still works

4. **Restore if needed:** Use Timeshift or your backups if something breaks

---

## Summary

**Key to Success:**
1. Unified NVIDIA driver (nvidia-dkms) for both GPUs
2. switcheroo-control for desktop GPU management
3. **MESA_VK_DEVICE_SELECT=10de:2782** in Hyprland config (CRITICAL!)
4. Unplug/replug eGPU after installing switcheroo-control
5. systemd service to ensure eGPU detection on boot
6. XWayland scaling fixes for sharp display

**What You Get:**
- RTX 4070 Ti automatically used for all games/GPU applications
- GTX 1650 Ti fallback when eGPU disconnected
- Intel iGPU handles desktop compositor (stability)
- Hot-plug/unplug support
- Sharp, clear display in all applications

---

**Document Version:** 1.0  
**Last Updated:** December 27, 2025  
**Tested On:** CachyOS with Hyprland 0.52.2, NVIDIA Driver 590.48.01
