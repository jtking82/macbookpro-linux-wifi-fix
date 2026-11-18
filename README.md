# MacBook Pro 14,3 Linux Mint BCM43602 Wi-Fi repair

A documented, hardware-specific repair for restoring the Broadcom BCM43602 Wi-Fi adapter on an Apple MacBook Pro `MacBookPro14,3` running Linux Mint.

> **Test status:** The repair was confirmed on one MacBookPro14,3. The installed NVRAM files were compared against the pinned upstream source: all contents matched after excluding the `macaddr=` line. The actual MAC address is intentionally not included in this repository.

## At a glance

| Item | Verified configuration |
|---|---|
| Computer | Apple MacBook Pro 15-inch (2017) |
| Model identifier | `MacBookPro14,3` |
| Wireless chipset | Broadcom BCM43602 |
| PCI ID | `14e4:43ba` |
| Apple subsystem ID | `106b:0173` |
| Driver | `brcmfmac` |
| Kernel during original troubleshooting | `7.0.0-43-generic` |
| Interface after repair | `wlp3s0` |
| PHY after repair | `phy0` |

Other models, chip revisions, Linux distributions, and kernel versions are not established as tested by this project.

## What was wrong

The Broadcom driver and binary firmware were present, but the machine lacked the board-specific NVRAM configuration needed for this BCM43602/Apple hardware combination. The repair installed two text configuration files:

```text
/usr/lib/firmware/brcm/brcmfmac43602-pcie.txt
/usr/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt
```

Both installed files were 267 lines and 7,131 bytes. They were byte-for-byte identical to each other. Their SHA-256 was:

```text
5619fc224e56c82e7fb8d095aaf1f60cac69514e2ad6ab552a543cab64064d21
```

The pinned upstream file, before its MAC-address line was customized, has SHA-256:

```text
9111375d9552d096cd05ca2ee705e7866882d3bb81372df33b40813bd3a47117
```

A direct comparison confirmed there were no differences between the installed file and the pinned upstream file after excluding the `macaddr=` line. The actual MAC address is a machine-specific hardware identifier and is not reproduced here.

## Repository contents

```text
.
├── README.md
├── docs/
│   ├── installation.md
│   ├── technical-explanation.md
│   └── troubleshooting.md
├── scripts/
│   └── fix-wifi-nvram.sh
├── references/
│   └── sources.md
├── LICENSE
└── .gitignore
```

## Important licensing and privacy note

This repository does **not** include the Broadcom NVRAM file. The file is third-party calibration data; its redistribution rights are not established here, and the upstream community discussion explicitly raises proprietary-data concerns. The helper downloads the pinned file directly from its upstream location, verifies its SHA-256, and substitutes the operator's own Wi-Fi MAC address before installation. This is not a legal determination; review the source and applicable terms yourself. See [Sources](references/sources.md).

Never commit your actual `macaddr=` value, serial number, unredacted diagnostic output, or a customized copy of the NVRAM file.

## Quick start

Read [the installation guide](docs/installation.md) before running anything. The helper defaults to verification only and makes no system changes. Installation requires an explicit `--install` argument and a typed confirmation.

Verify the pinned download without changing the machine:

```bash
bash scripts/fix-wifi-nvram.sh --verify
```

To install, use only on the tested model and adapter:

```bash
sudo bash scripts/fix-wifi-nvram.sh --install
```

The installer asks for the correct hardware Wi-Fi MAC address, validates it, makes timestamped backups of existing target files, installs both text files, and stops without reloading kernel modules. Reboot after installation so the driver reads the files on a clean startup.

## Verify after reboot

```bash
ip -brief link
 iw dev
nmcli device status
nmcli device wifi list
```

The original successful session showed `wlp3s0` and `phy0`; interface names may differ. Follow the [post-install verification checklist](docs/verification.md) to check radio state, scan for access points, connect safely, and test basic connectivity. See [troubleshooting](docs/troubleshooting.md) if the interface or 5 GHz networks do not appear.

## License

The MIT license in this repository applies only to original documentation and helper code. It does not grant rights to Broadcom calibration data, firmware, Linux kernel code, or other third-party materials.
