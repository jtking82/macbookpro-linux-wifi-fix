# Troubleshooting notes

## Symptoms before the repair

The Broadcom BCM43602 was present, but wireless initialization did not complete as expected. Kernel diagnostics referenced model-specific firmware/NVRAM names for `MacBookPro14,3`. The successful repair installed generic and model-specific NVRAM text files and resulted in a working wireless interface.

## Collect diagnostics

```bash
uname -r
sudo dmidecode -s system-product-name
lspci -nnk | grep -A4 -i network
ip -brief link
iw dev
nmcli device status
sudo journalctl -k -b --no-pager | grep -iE 'brcmfmac|firmware|wlan|wifi'
```

Do not post unredacted output publicly. In particular, remove MAC addresses, serial numbers, and usernames.

## Check the installed NVRAM files without revealing the MAC address

```bash
for F in \
  '/usr/lib/firmware/brcm/brcmfmac43602-pcie.txt' \
  '/usr/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt'
do
  if [ -f "$F" ]; then
    sha256sum "$F"
    wc -l -c "$F"
    if grep -q '^macaddr=' "$F"; then
      echo 'macaddr entry present (value intentionally hidden)'
    else
      echo 'macaddr entry absent'
    fi
  else
    echo "Missing: $F"
  fi
done
```

For the tested machine, the two installed files were identical, each 267 lines / 7,131 bytes, with SHA-256 `5619fc224e56c82e7fb8d095aaf1f60cac69514e2ad6ab552a543cab64064d21`. Do not expect that checksum if the MAC address differs.

## Verify the upstream source

```bash
bash scripts/fix-wifi-nvram.sh --verify
```

The expected upstream digest is documented in [Sources](../references/sources.md). A mismatch means stop and investigate; do not bypass verification.

## After installation

Reboot, then run:

```bash
ip -brief link
iw dev
nmcli device status
nmcli device wifi list
sudo journalctl -k -b --no-pager | grep -iE 'brcmfmac|firmware|wlan|wifi'
```

If the interface is missing or the expected networks do not appear, do not repeatedly overwrite firmware files. Preserve the logs privately and consider restoring the timestamped backups as described in the installation guide.

## Scope limitations

This project does not claim to fix every Broadcom message about `.clm_blob` or `.txcap_blob`; those requests are distinct from the NVRAM text file. The original troubleshooting established that the Wi-Fi repair worked, but did not prove that every firmware request was independently resolved. Do not create substitute calibration or regulatory files based solely on a log message.
