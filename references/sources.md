# Sources, provenance, and attribution

## Exact NVRAM source used for verification

- Project: [omacom/omarchy](https://github.com/omacom/omarchy)
- Pull request: [#7487 — Fix broken Wi-Fi on 2015–2017 MacBook Pros by shipping the missing NVRAM file](https://github.com/omacom/omarchy/pull/7487)
- Pinned commit: `eb8c83e8b5f7931e883adcada3f8eab38f650a93`
- File path: `default/firmware/apple/brcmfmac43602-pcie.txt`
- Immutable raw URL: <https://raw.githubusercontent.com/omacom/omarchy/eb8c83e8b5f7931e883adcada3f8eab38f650a93/default/firmware/apple/brcmfmac43602-pcie.txt>
- SHA-256 of unmodified upstream file: `9111375d9552d096cd05ca2ee705e7866882d3bb81372df33b40813bd3a47117`

The downloaded upstream file was 267 lines and 7,131 bytes. On the tested MacBookPro14,3, the installed generic and model-specific files were each 267 lines and 7,131 bytes. Their SHA-256 was `5619fc224e56c82e7fb8d095aaf1f60cac69514e2ad6ab552a543cab64064d21`. A direct diff excluding the `macaddr=` line produced no differences.

## Redistribution caution

The Omarchy discussion around this fix explicitly notes that the NVRAM data is Broadcom-proprietary and that redistribution may be problematic. The file also carries calibration data and a MAC-address field. This repository therefore does not include or mirror the NVRAM file. The installer fetches the pinned upstream file at runtime, verifies its digest, and replaces the MAC-address line locally. This note is informational, not legal advice; users are responsible for reviewing applicable rights and terms.

Relevant community discussion: [Omarchy discussion #4692](https://github.com/omacom/omarchy/discussions/4692).

## Linux kernel driver reference

The Linux `brcmfmac` PCIe driver maps BCM43602 to the `brcmfmac43602-pcie.bin` firmware and `brcmfmac43602-pcie.txt` NVRAM names. See [Linux kernel source — brcmfmac PCIe driver](https://kernel.googlesource.com/pub/scm/linux/kernel/git/davem/net-next/+/ce38aa9cbed3d109355b0169b520362c409c0541/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c).

## Tested machine

- Apple MacBook Pro 15-inch (2017), model `MacBookPro14,3`
- Broadcom BCM43602, PCI ID `14e4:43ba`
- Apple subsystem ID `106b:0173`
- Linux Mint
- Kernel during original troubleshooting: `7.0.0-43-generic`
- Driver: `brcmfmac`

The actual Wi-Fi MAC address, serial number, and unredacted logs are intentionally excluded.

## Attribution

This repository documents an independently performed troubleshooting process and provides original helper code. It does not claim authorship of the upstream NVRAM calibration data, Broadcom firmware, or Linux kernel driver. Follow the terms applicable to each third-party component.
