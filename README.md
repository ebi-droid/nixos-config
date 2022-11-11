**简体中文（中国大陆）** | [English (UK)](README_en.md)
<p align="center"><img src="https://user-images.githubusercontent.com/75824585/196194900-101f9d6e-cd97-4d80-ab50-2ac7b5a4f084.png" height=80px></p>
<h2 align="center">Ruixi-rebirth's NixOS Config</h2>
<p align="center"><img src="https://user-images.githubusercontent.com/75824585/196195007-ecebb290-2c6b-4fab-9e1e-2dbb12f7eb44.png" width=300px></p>

![](./screenshot/screenshot.png)

## 目录结构
```
.
├── flake.lock
├── flake.nix
├── hosts
│   ├── default.nix
│   ├── laptop
│   └── system.nix
├── modules
│   ├── desktop
│   ├── dev_lang
│   ├── editors
│   ├── environment
│   ├── fonts
│   ├── hardware
│   ├── programs
│   ├── scripts
│   ├── shell
│   ├── theme
│   └── virtualisation
├── overlays
│   ├── catppuccin-cursors.nix
│   └── catppuccin-gtk.nix
└── README.md
```

## 如何安装?
0. 假设我已经分好两个分区`/dev/nvme0n1p1` `/dev/nvme0n1p3`
1. 格式化分区
```bash
  mkfs.fat -F 32 /dev/nvme0n1p1 
  mkfs.ext4 /dev/nvme0n1p3
```
2. 挂载
```bash
  mount -t tmpfs none /mnt 
  mkdir -p /mnt/{boot,nix}
  mount /dev/nvme0n1p3 /mnt/nix
  mount /dev/nvme0n1p1 /mnt/boot 
```
3. 生成一个基本的配置 
```bash
  nixos-generate-config --root /mnt
```
4. 克隆仓库到本地
```bash
git clone  https://github.com/Ruixi-rebirth/nixos-config.git /mnt/etc/nixos/ 
```
5. 将 /mnt/etc/nixos 中的 `hardware-configuration.nix` 拷贝到 /mnt/etc/nixos/nixos-config/hosts/laptop/hardware-configuration.nix
```bash 
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-config/hosts/laptop/hardware-configuration.nix
```
6. 修改被覆盖后的 `hardware-configuration.nix`
```nix
...
#这只是一个例子
fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/b0f7587b-1eb4-43ad-b4a1-e6385b8511ae";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3C0D-7D32";
      fsType = "vfat";
    };
...
```
7. 进入克隆的仓库并移除 '/mnt/etc/nixos/nixos-config/.git'
```bash 
cd /mnt/etc/nixos/nixos-config && rm -rf .git
```
8. 安装
```bash
nixos-install --no-root-passwd --flake .#laptop
```
