# How We Fixed RTX 4070 Ti GPU Selection on CachyOS + Hyprland

**Date:** December 26, 2025  
**System:** Dell XPS 9500  
**GPUs:**
- Intel UHD Graphics (integrated) - card2
- NVIDIA GTX 1650 Ti (internal dGPU) - card1  
- NVIDIA RTX 4070 Ti (external eGPU) - card0

---

## The Problem

Applications were defaulting to the GTX 1650 Ti instead of the more powerful RTX 4070 Ti eGPU, even though all three GPUs were detected correctly by the system.

### Why It Happened

1. **NVIDIA driver enumeration order**: The NVIDIA driver enumerates GPUs in PCI bus order, making the GTX 1650 Ti (01:00.0) "GPU 0" and the RTX 4070 Ti (08:00.0) "GPU 1"
2. **Vulkan's default behavior**: Without explicit configuration, Vulkan applications select the first NVIDIA GPU (GPU 0 = 1650 Ti)
3. **Standard PRIME offload variables don't work on Wayland**: Variables like `__NV_PRIME_RENDER_OFFLOAD_PROVIDER` are primarily for X11/XWayland, not pure Wayland

---

## The Solution: MESA Device Select Layer

We used the Mesa Vulkan device selection layer with the specific PCI device ID of the RTX 4070 Ti to force GPU selection.

### Step-by-Step Fix

#### 1. Identify GPU PCI Device IDs

```bash
lspci -nn | grep -E "VGA|3D" | grep NVIDIA
```

Output:
```
01:00.0 3D controller [0302]: NVIDIA Corporation TU117M [GeForce GTX 1650 Ti Mobile] [10de:1f95] (rev a1)
08:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104 [GeForce RTX 4070 Ti] [10de:2782] (rev a1)
```

**Key info:** RTX 4070 Ti has device ID `10de:2782`

#### 2. Verify DRM Device Mapping

```bash
ls -l /dev/dri/by-path/
```

Output showed:
```
pci-0000:00:02.0-card -> ../card2  (Intel)
pci-0000:01:00.0-card -> ../card1  (GTX 1650 Ti)
pci-0000:08:00.0-card -> ../card0  (RTX 4070 Ti)
```

#### 3. Create GPU Selection Wrapper Script

```bash
nano ~/.local/bin/run-on-4070
```

Content:
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

#### 4. Test the Fix

```bash
run-on-4070 vkcube
```

Verify with nvidia-smi:
```bash
nvidia-smi dmon
```

GPU 1 (RTX 4070 Ti) should show activity (sm column shows ~37-38% usage).

---

## What Each Environment Variable Does

| Variable | Purpose |
|----------|---------|
| `VK_ICD_FILENAMES` | Points Vulkan loader to NVIDIA ICD (installable client driver) |
| `MESA_VK_DEVICE_SELECT` | Forces Mesa's device selection layer to use specific PCI device ID |
| `__NV_PRIME_RENDER_OFFLOAD` | Enables NVIDIA PRIME render offload mode |
| `__GLX_VENDOR_LIBRARY_NAME` | Forces GLX to use NVIDIA implementation |

**The critical variable:** `MESA_VK_DEVICE_SELECT=10de:2782` - This is what actually forces the RTX 4070 Ti selection.

---

## How to Use

### For Individual Applications

```bash
run-on-4070 <application-name>
```

Examples:
```bash
run-on-4070 steam
run-on-4070 lutris
run-on-4070 vkcube
```

### For Steam Games

Right-click game → Properties → Launch Options:
```
run-on-4070 %command%
```

### For Lutris

Game configuration → System options → Command prefix:
```
run-on-4070
```

### For Heroic Games Launcher

Settings → Advanced → Wrapper/Prefix:
```
run-on-4070
```

---

## Verification Commands

Check which GPU is being used:
```bash
# Test Vulkan device
run-on-4070 vkcube
# In another terminal:
nvidia-smi dmon
# GPU 1 should show activity

# Check Vulkan device name
vulkaninfo | grep "deviceName"
# Should list all 3 GPUs

# Verbose Vulkan loader output (for debugging)
VK_LOADER_DEBUG=all run-on-4070 vkcube 2>&1 | grep "Selected GPU"
# Should show: Selected GPU 0: NVIDIA GeForce RTX 4070 Ti
```

---

## Alternative: Wrapper for GTX 1650 Ti (Battery/Mobile Use)

If you want to use the internal GPU (for battery life), create:

```bash
nano ~/.local/bin/run-on-1650
```

Content:
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

---

## What Didn't Work (Learning Notes)

We tried several approaches that failed before finding the solution:

### ❌ Failed Approach 1: `__NV_PRIME_RENDER_OFFLOAD_PROVIDER`
```bash
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=pci-0000_08_00_0
```
**Why it failed:** These variables are for X11/XWayland, not pure Wayland sessions.

### ❌ Failed Approach 2: `DRI_PRIME`
```bash
export DRI_PRIME=pci-0000_08_00_0
```
**Why it failed:** DRI_PRIME is for open-source drivers (Mesa), not NVIDIA proprietary.

### ❌ Failed Approach 3: `VK_DEVICE_SELECT`
```bash
export VK_DEVICE_SELECT=2
```
**Why it failed:** Vulkan was re-ordering devices internally, so device index 2 wasn't the 4070 Ti.

### ❌ Failed Approach 4: `CUDA_VISIBLE_DEVICES`
```bash
export CUDA_VISIBLE_DEVICES=1
```
**Why it failed:** This only affects CUDA applications, not Vulkan/graphics.

### ✅ What Actually Worked: `MESA_VK_DEVICE_SELECT=10de:2782`
This uses the Mesa Vulkan device selection layer with the explicit PCI device ID, which can't be confused or re-ordered.

---

## System Configuration Notes

### Current Hyprland Environment (from ~/dotfiles/hypr/.config/hypr/hyprland.conf)

```bash
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = WLR_NO_HARDWARE_CURSORS,1
env = AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card0:/dev/dri/card1
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland
env = MOZ_ENABLE_WAYLAND,1
```

**Note:** The `AQ_DRM_DEVICES` line sets Aquamarine's device priority, but this doesn't affect application-level GPU selection. Our wrapper script overrides this for applications.

### NVIDIA Driver Version
```
NVIDIA-SMI 590.48.01
Driver Version: 590.48.01
CUDA Version: 13.1
```

---

## When to Use This Fix

This solution is specifically needed when:
- You have multiple NVIDIA GPUs in the same system
- You're running Wayland (not X11)
- You want applications to use a specific GPU that isn't the first in PCI enumeration order
- Standard PRIME offload variables aren't working

If you only have one NVIDIA GPU, or you're fine with using whichever GPU the driver picks first, you don't need this fix.

---

## Troubleshooting

### GPU Not Being Used
1. Check wrapper script is executable: `ls -la ~/.local/bin/run-on-4070`
2. Verify device ID is correct: `lspci -nn | grep RTX`
3. Test with verbose output: `VK_LOADER_DEBUG=all run-on-4070 vkcube 2>&1 | grep "Selected GPU"`

### Wrong GPU Still Selected
- Make sure the PCI device ID in `MESA_VK_DEVICE_SELECT` matches your GPU
- Format is: `vendor_id:device_id` (e.g., `10de:2782`)
- `10de` = NVIDIA vendor ID (always the same for NVIDIA cards)
- Second part is device-specific (check your lspci output)

### Script Not Found
```bash
# Make sure ~/.local/bin is in your PATH
echo $PATH | grep -o ~/.local/bin
# If not found, add to your shell config:
# For fish: fish_add_path ~/.local/bin
# For bash/zsh: export PATH="$HOME/.local/bin:$PATH"
```

---

## Future-Proofing

If you replace the RTX 4070 Ti with a different GPU:

1. Get the new PCI device ID:
   ```bash
   lspci -nn | grep -E "VGA|3D" | grep NVIDIA
   ```

2. Update the wrapper script with the new device ID:
   ```bash
   nano ~/.local/bin/run-on-4070
   # Change: export MESA_VK_DEVICE_SELECT=10de:XXXX
   ```

3. Test with vkcube and nvidia-smi dmon

---

## References

- [Arch Wiki: PRIME](https://wiki.archlinux.org/title/PRIME)
- [Arch Wiki: NVIDIA](https://wiki.archlinux.org/title/NVIDIA)
- [Mesa Vulkan Device Select Documentation](https://docs.mesa3d.org/envvars.html)
- [NVIDIA PRIME Render Offload Documentation](https://download.nvidia.com/XFree86/Linux-x86_64/435.17/README/primerenderoffload.html)

---

## Summary

**The fix:** Use `MESA_VK_DEVICE_SELECT` with the PCI device ID to force Vulkan applications to use the RTX 4070 Ti.

**Why it works:** The Mesa device selection layer intercepts Vulkan device enumeration and forces the specified PCI device to be selected, regardless of driver ordering.

**Key learning:** On Wayland with multiple NVIDIA GPUs, you need explicit PCI device ID selection, not just provider names or device indices.

---

**Document Version:** 1.0  
**Last Updated:** December 26, 2025  
**Author:** Troubleshooting session with Claude (Anthropic)
