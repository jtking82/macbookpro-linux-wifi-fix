# Post-install verification

This checklist verifies that Linux can see the wireless adapter, that NetworkManager has Wi-Fi enabled, and that nearby access points are visible. It does not expose the Wi-Fi password.

Run these checks after rebooting from the NVRAM installation.

## 1. Check the wireless interface

```bash
ip -brief link
iw dev
```

Look for a wireless interface and a PHY device. The original successful repair showed `wlp3s0` and `phy0`; interface names can vary.

## 2. Check radio and block state

```bash
rfkill list
nmcli radio
nmcli device status
```

If Wi-Fi is soft-blocked, unblock it:

```bash
sudo rfkill unblock wifi
nmcli radio wifi on
```

A hardware block cannot normally be cleared with `rfkill unblock`; investigate the platform or firmware state instead.

## 3. Rescan for access points

Replace no values; these commands only request a scan and list visible networks:

```bash
nmcli device wifi rescan
nmcli device wifi list
```

The network list may contain personally identifying SSIDs or nearby network names. Do not publish an unredacted screenshot or command output.

## 4. Connect without putting a password in shell history

Replace `YOUR_WIFI_NAME` with the network name. The command prompts for credentials rather than placing a password directly in the command:

```bash
nmcli device wifi connect "YOUR_WIFI_NAME" --ask
```

Do not paste passwords, saved connection profiles, or unredacted network output into an issue or public repository.

## 5. Confirm connectivity

```bash
nmcli device status
ping -c 4 1.1.1.1
```

A connected Wi-Fi device and successful replies indicate basic IP connectivity. This ping alone does not test DNS; a hostname lookup can be tested separately if needed.

## 6. Evidence and privacy

For a public portfolio, record only sanitized results such as:

- Wireless interface detected
- Wi-Fi radio enabled
- Access-point scan completed
- NetworkManager reports the device connected
- Basic connectivity test passed

Before sharing output, remove MAC addresses, SSIDs, BSSIDs, private IP addresses, usernames, hostnames, serial numbers, and any other identifying details. Never include passwords or private keys.

## Scope of the original test

The original repair was confirmed to restore Wi-Fi on the tested MacBookPro14,3 with BCM43602. The post-reboot checklist above is provided for repeatable verification; do not claim reboot persistence on another installation unless it has actually been tested.
