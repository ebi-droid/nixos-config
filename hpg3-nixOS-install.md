Super, dzięki za kontekst 🙌 Masz więc:

* **Dysk systemowy**: `sda` → obecny Linux z EFI + root (`/`)
* **Dysk wolny**: `nvme0n1` (pusty, \~238 GB) → tam chcesz NixOS
* **Cel**: NixOS z Cosmic DE (Wayland), root na **btrfs**

---

## 🔹 1. Czy Btrfs to dobry wybór?

Tak ✅ — **Btrfs** dobrze pasuje do NixOS, bo:

* NixOS ma natywny rollback systemu, a Btrfs daje snapshoty → idealne combo.
* Możesz robić snapshoty `/` i `/home` i integrować np. z `snapper` albo `btrbk`.
* Bardziej elastyczny niż ext4 (subvolumes, kompresja, send/receive).

Alternatywa: **ZFS** (ale cięższy w setupie, mniej „oficjalny” w NixOS).

---

## 🔹 2. Proponowany układ partycji

Na `nvme0n1`:

* `nvme0n1p1` → EFI (512 MB, FAT32) *(możesz użyć wspólnego /boot/efi z sda1, ale ja polecam zrobić osobny, czyściej)*
* `nvme0n1p2` → Btrfs root (cała reszta)

Na Btrfs utwórz subvolumes:

* `@` → `/`
* `@home` → `/home`
* `@nix` → `/nix`
* (opcjonalnie `@log`, `@var`, itp.)

---

## 🔹 3. Instalacja krok po kroku

1. Boot z NixOS ISO (unstable → tam masz najnowsze Cosmic).
2. Podział dysku:

   ```bash
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart primary btrfs 512MiB 100%
   ```
3. Format:

   ```bash
   mkfs.fat -F32 /dev/nvme0n1p1
   mkfs.btrfs /dev/nvme0n1p2
   ```
4. Montowanie i subvolumes:

   ```bash
   mount /dev/nvme0n1p2 /mnt
   btrfs subvolume create /mnt/@
   btrfs subvolume create /mnt/@home
   btrfs subvolume create /mnt/@nix
   umount /mnt
   mount -o subvol=@ /dev/nvme0n1p2 /mnt
   mkdir -p /mnt/{boot,home,nix}
   mount -o subvol=@home /dev/nvme0n1p2 /mnt/home
   mount -o subvol=@nix  /dev/nvme0n1p2 /mnt/nix
   mount /dev/nvme0n1p1 /mnt/boot
   ```

   *(jeśli chcesz współdzielić istniejący `/boot/efi` → wtedy zamiast /mnt/boot dajesz /mnt/boot/efi i montujesz sda1)*

---

## 🔹 4. Generacja konfiguracji

```bash
nixos-generate-config --root /mnt
```

Doda `hardware-configuration.nix` z Btrfs.

---

## 🔹 5. Flake z Cosmic DE

Minimalny **flake.nix**:

```nix
{
  description = "NixOS with Cosmic DE";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.cosmic = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
```

**configuration.nix**:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cosmic-nixos";
  time.timeZone = "Europe/Warsaw";

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.cosmic.enable = true;

  # Wayland zamiast X11
  services.xserver.displayManager.gdm.wayland = true;

  users.users.janek = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    password = "changeme"; # do zmiany!
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    vim git htop
  ];
}
```

---

## 🔹 6. Instalacja

```bash
nixos-install --flake .#cosmic
```

Po restarcie masz NixOS z **COSMIC (Wayland, Rust)** na Btrfs 🎉

---

✅ **Podsumowanie**

* Btrfs to dobry wybór → snapshoty + rollbacki = best combo z NixOS.
* Lepiej dać osobny EFI na NVMe, niż mieszać z tym na `sda1`.
* Cosmic DE → `services.xserver.desktopManager.cosmic.enable = true;`

---

👉 Chcesz, żebym Ci zrobił gotowy **flake + partition script** (bash), który od zera przygotuje dysk `nvme0n1` i zainstaluje Ci Cosmic NixOS jednym strzałem?
