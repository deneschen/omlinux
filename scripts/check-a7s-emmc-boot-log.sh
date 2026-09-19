#!/bin/sh
set -eu

log=${1:?usage: check-a7s-emmc-boot-log.sh UART_LOG}

fail()
{
	printf 'A7S eMMC HS400 boot check failed: %s\n' "$*" >&2
	exit 1
}

grep -Fq 'sunxi_mmc_host-4022000.sdmmc' "$log" ||
	fail 'missing SDC2/eMMC controller log'

if grep -Eq 'mmc0: (error .* whilst initialising MMC card|switch to high-speed from hs200 failed)' "$log"; then
	fail 'mmc0 failed during the HS200 to HS400 transition'
fi

grep -Eq 'mmc0: new HS400(ES)? MMC card' "$log" ||
	fail 'missing successful HS400 card enumeration'

printf 'A7S eMMC HS400 hardware initialization: PASS\n'
