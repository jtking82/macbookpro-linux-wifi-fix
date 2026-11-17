# Technical explanation

## Hardware and driver

The tested machine is an Apple MacBook Pro `MacBookPro14,3` with a Broadcom BCM43602 wireless adapter (`14e4:43ba`, Apple subsystem `106b:0173`). Linux uses the in-kernel `brcmfmac` driver for this device.

The driver requests both binary firmware and a text NVRAM configuration. Linux kernel source identifies `brcmfmac43602-pcie.bin` and `brcmfmac43602-pcie.txt` as the default firmware/NVRAM pair for the BCM43602 PCIe device. See the kernel source link in [Sources](../references/sources.md).

## Why the NVRAM file matters

The NVRAM text file supplies board-specific parameters to the Broadcom firmware. It is not interchangeable across every BCM43602 board: board identifiers, antenna-chain configuration, regulatory settings, and calibration data can vary. This project documents only the configuration tested on one MacBookPro14,3.

The verified upstream configuration includes, among many other entries:

```text
boardrev=0x1101
sromrev=11
boardtype=0x073e
vendid=0x14e4
devid=0x43ba
ccode=0
regrev=1
rxchain=3
txchain=3
aa2g=3
aa5g=3
```

The repository does not reproduce the complete NVRAM data because its redistribution rights are unclear and the file contains a machine-specific `macaddr=` field after customization.

## Source verification performed

The exact source is pinned to Omarchy commit:

```text
eb8c83e8b5f7931e883adcada3f8eab38f650a93
```

The upstream raw file has SHA-256:

```text
9111375d9552d096cd05ca2ee705e7866882d3bb81372df33b40813bd3a47117
```

On the tested MacBook, both installed text files had SHA-256:

```text
5619fc224e56c82e7fb8d095aaf1f60cac69514e2ad6ab552a543cab64064d21
```

Both installed files were 267 lines / 7,131 bytes and had matching checksums. A `diff` comparison showed no differences between the installed file and the downloaded pinned upstream file after excluding the `macaddr=` line. This demonstrates that the installed configuration is the pinned upstream content with the machine-specific MAC address substituted.

## Result observed

After installing the two text files and reloading the Broadcom modules during the original repair, the system exposed interface `wlp3s0` and PHY `phy0`; two wireless bands were reported, and the user confirmed Wi-Fi was working. This is an observed result on the tested machine, not a guarantee for other systems.

The repair did not replace the Broadcom binary firmware. The `.bin.zst` and `.ap.bin.zst` files remained present. The installer in this repository does not modify binary firmware and does not reload modules; it asks the operator to reboot after installation.
