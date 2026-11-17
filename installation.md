# Installation guide

## Scope and warnings

This procedure is for the tested combination:

- Apple MacBook Pro `MacBookPro14,3`
- Broadcom BCM43602, PCI ID `14e4:43ba`
- Linux Mint

The original test used kernel `7.0.0-43-generic`. Other models or environments are not covered. Do not run this installer on another Mac model just because it also has a Broadcom adapter.

The helper downloads third-party NVRAM calibration data from a pinned upstream commit. Its redistribution rights are not established in this project, so the repository does not bundle the data. Review [Sources and provenance](../references/sources.md).

## 1. Confirm the hardware

```bash
sudo dmidecode -s system-product-name
lspci -nn -d 14e4:43ba
uname -r
```

Expected model: `MacBookPro14,3`. The PCI output should identify Broadcom BCM43602 with ID `14e4:43ba`. Stop if either does not match.

## 2. Record the current state

```bash
ip -brief link
iw dev
nmcli device status
sudo journalctl -k -b --no-pager | grep -iE 'brcmfmac|firmware|wlan|wifi'
```

Keep diagnostic output private. Before sharing it, redact MAC addresses, serial numbers, usernames, and other identifiers.

## 3. Verify the pinned source (no system changes)

From the repository root:

```bash
bash scripts/fix-wifi-nvram.sh --verify
```

The script downloads the exact file from the immutable commit URL and checks this SHA-256:

```text
9111375d9552d096cd05ca2ee705e7866882d3bb81372df33b40813bd3a47117
```

It does not install or modify anything in `--verify` mode. A mismatch is a hard stop; do not bypass it or casually update the expected digest.

## 4. Obtain the correct Wi-Fi hardware MAC address

The NVRAM configuration needs the actual hardware Wi-Fi MAC address for this Mac. Do not use an address copied from another computer, an Ethernet adapter, or an unrelated virtual interface. The original troubleshooting record did not preserve a reproducible EFI extraction command, so this project does not invent one.

Use a trusted source for the hardware Wi-Fi address (for example, macOS System Information if available, or another verified record for this machine). Do not publish the address. The installer reads it silently and does not echo it.

## 5. Install (explicit action)

Run:

```bash
sudo bash scripts/fix-wifi-nvram.sh --install
```

The installer will:

1. Confirm the model and PCI ID.
2. Download the pinned upstream text file and verify its SHA-256.
3. Confirm the expected board configuration and exactly one `macaddr=` line.
4. Prompt for the machine's actual Wi-Fi MAC address without displaying it.
5. Require you to type `INSTALL` before changing files.
6. Back up any existing target files with a timestamped `.bak.*` suffix.
7. Install the customized file under both the generic and MacBookPro14,3-specific names.

It deliberately does **not** unload/reload the driver. This avoids disrupting a running network session and avoids module-dependency surprises. Reboot after installation.

## 6. Verify after reboot

```bash
ip -brief link
iw dev
nmcli device status
nmcli device wifi list
```

The original successful session showed interface `wlp3s0` and PHY `phy0`. Your interface name may differ. Confirm that wireless networks are visible and that the adapter behaves normally.

## 7. Roll back

Find the backups created by the installer:

```bash
ls -lt /usr/lib/firmware/brcm/brcmfmac43602-pcie*.bak.*
```

Restore the appropriate backups, substituting the exact timestamped filenames shown on your machine:

```bash
sudo cp -a '/usr/lib/firmware/brcm/brcmfmac43602-pcie.txt.bak.TIMESTAMP' \
  '/usr/lib/firmware/brcm/brcmfmac43602-pcie.txt'

sudo cp -a '/usr/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt.bak.TIMESTAMP' \
  '/usr/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt'
```

If a target did not exist before installation, remove only the file created by this procedure. Reboot after rollback. Do not delete the backup files until the system has been tested.
