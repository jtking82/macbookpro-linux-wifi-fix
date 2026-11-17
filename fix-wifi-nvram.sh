#!/usr/bin/env bash
# Install the pinned BCM43602 NVRAM configuration for MacBookPro14,3.
# The proprietary/calibration text is fetched at runtime and is not bundled.
set -Eeuo pipefail
umask 077

readonly EXPECTED_MODEL='MacBookPro14,3'
readonly EXPECTED_PCI_ID='14e4:43ba'
readonly EXPECTED_SHA256='9111375d9552d096cd05ca2ee705e7866882d3bb81372df33b40813bd3a47117'
readonly SOURCE_URL='https://raw.githubusercontent.com/omacom/omarchy/eb8c83e8b5f7931e883adcada3f8eab38f650a93/default/firmware/apple/brcmfmac43602-pcie.txt'
readonly FIRMWARE_DIR='/usr/lib/firmware/brcm'
readonly GENERIC_FILE="${FIRMWARE_DIR}/brcmfmac43602-pcie.txt"
readonly MODEL_FILE="${FIRMWARE_DIR}/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/fix-wifi-nvram.sh --verify
  sudo bash scripts/fix-wifi-nvram.sh --install

--verify  Download and verify the pinned upstream file. No system changes.
--install Verify, prompt for the machine's Wi-Fi MAC, back up and install
          both NVRAM text files. A reboot is required afterward.
EOF
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }

MODE="${1:-}"
case "$MODE" in
  --verify|--install) ;;
  -h|--help|'') usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

for cmd in curl sha256sum awk grep sed mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT
SOURCE_FILE="${WORKDIR}/upstream-nvram.txt"
CONFIG_FILE="${WORKDIR}/configured-nvram.txt"

info 'Downloading pinned upstream NVRAM file'
curl --fail --location --silent --show-error "$SOURCE_URL" --output "$SOURCE_FILE"
ACTUAL_SHA256="$(sha256sum "$SOURCE_FILE" | awk '{print $1}')"
[[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]] || die "SHA-256 mismatch. Expected ${EXPECTED_SHA256}; received ${ACTUAL_SHA256}. No system files changed."

# Sanity-check key values without displaying the full calibration file.
for expected in \
  'boardrev=0x1101' 'sromrev=11' 'boardtype=0x073e' \
  'vendid=0x14e4' 'devid=0x43ba' 'ccode=0' 'regrev=1' \
  'rxchain=3' 'txchain=3' 'aa2g=3' 'aa5g=3'; do
  grep -qFx "$expected" "$SOURCE_FILE" || die "Source is missing expected setting: ${expected}. No system files changed."
done
MAC_LINES="$(grep -c '^macaddr=' "$SOURCE_FILE" || true)"
[[ "$MAC_LINES" == '1' ]] || die "Expected exactly one macaddr= line in source; found ${MAC_LINES}. No system files changed."

info 'Upstream file verified'
printf '  SHA-256: %s\n' "$ACTUAL_SHA256"
printf '  Lines / bytes: '
wc -l -c < "$SOURCE_FILE"

if [[ "$MODE" == '--verify' ]]; then
  printf '\nVerification only: no system files were changed.\n'
  exit 0
fi

[[ "$EUID" -eq 0 ]] || die 'Installation requires root. Re-run with sudo.'
command -v dmidecode >/dev/null 2>&1 || die 'dmidecode is required (install dmidecode).'
command -v lspci >/dev/null 2>&1 || die 'lspci is required (install pciutils).'

MODEL="$(dmidecode -s system-product-name 2>/dev/null | tr -d '\r' | tail -n1)"
[[ "$MODEL" == "$EXPECTED_MODEL" ]] || die "Expected ${EXPECTED_MODEL}; detected '${MODEL:-unknown}'. No system files changed."
lspci -nn | grep -qi "$EXPECTED_PCI_ID" || die "Broadcom PCI device ${EXPECTED_PCI_ID} not found. No system files changed."

printf '\nTarget hardware confirmed: %s / Broadcom BCM43602 (%s).\n' "$MODEL" "$EXPECTED_PCI_ID"
printf 'Enter the actual Wi-Fi hardware MAC address for this MacBook.\n'
printf 'The value is read silently and will not be printed by this script.\n'
read -r -s -p 'Wi-Fi MAC (aa:bb:cc:dd:ee:ff): ' WIFI_MAC
printf '\n'
WIFI_MAC="$(printf '%s' "$WIFI_MAC" | tr '[:upper:]' '[:lower:]')"
[[ "$WIFI_MAC" =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]] || die 'Invalid MAC address format. No system files changed.'
[[ "$WIFI_MAC" != '00:00:00:00:00:00' ]] || die 'All-zero MAC is invalid. No system files changed.'

sed "s/^macaddr=.*/macaddr=${WIFI_MAC}/" "$SOURCE_FILE" > "$CONFIG_FILE"
[[ "$(grep -c '^macaddr=' "$CONFIG_FILE" || true)" == '1' ]] || die 'MAC substitution validation failed. No system files changed.'

printf '\nThis will back up and install these two files:\n  %s\n  %s\n' "$GENERIC_FILE" "$MODEL_FILE"
printf 'No driver modules will be unloaded or reloaded. A reboot will be needed.\n'
read -r -p "Type INSTALL to continue: " CONFIRM
[[ "$CONFIRM" == 'INSTALL' ]] || die 'Confirmation not received. No system files changed.'

install -d -m 0755 "$FIRMWARE_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE_DIR="$(mktemp -d "${FIRMWARE_DIR}/.bcm43602-stage.XXXXXX")"
cleanup_stage() { rm -rf "$STAGE_DIR"; }
trap 'cleanup_stage; cleanup' EXIT

install -o root -g root -m 0644 "$CONFIG_FILE" "${STAGE_DIR}/generic.txt"
install -o root -g root -m 0644 "$CONFIG_FILE" "${STAGE_DIR}/model.txt"

backup_if_present() {
  local target="$1"
  if [[ -e "$target" ]]; then
    cp -a -- "$target" "${target}.bak.${STAMP}"
    info "Backup created: ${target}.bak.${STAMP}"
  fi
}

backup_if_present "$GENERIC_FILE"
backup_if_present "$MODEL_FILE"
install -o root -g root -m 0644 "${STAGE_DIR}/generic.txt" "$GENERIC_FILE"
install -o root -g root -m 0644 "${STAGE_DIR}/model.txt" "$MODEL_FILE"

printf '\nInstallation completed. Reboot before testing:\n  sudo reboot\n'
printf 'After reboot, verify with: ip -brief link; iw dev; nmcli device status\n'
printf 'The MAC address was not displayed or written into this script.\n'
