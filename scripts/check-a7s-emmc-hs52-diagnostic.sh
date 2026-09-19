#!/bin/sh
set -eu

dtb=${1:-arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7s.dtb}
node=/soc@3000000/sdmmc@4022000

fail()
{
	printf 'A7S eMMC HS52 diagnostic check failed: %s\n' "$*" >&2
	exit 1
}

test -f "$dtb" || fail "DTB not found: $dtb"
props=$(fdtget -p "$dtb" "$node") || fail "missing node $node"

has_prop()
{
	printf '%s\n' "$props" | grep -qx "$1"
}

test "$(fdtget -t u "$dtb" "$node" bus-width)" = 8 || fail "bus-width is not 8"
test "$(fdtget -t u "$dtb" "$node" max-frequency)" = 52000000 ||
	fail "max-frequency is not 52 MHz"
has_prop cap-mmc-highspeed || fail "missing cap-mmc-highspeed"

for prop in mmc-ddr-1_8v mmc-hs200-1_8v mmc-hs400-1_8v execute_tuning_in_kernel; do
	if has_prop "$prop"; then
		fail "unexpected high-speed diagnostic property: $prop"
	fi
done

printf 'A7S eMMC 8-bit HS52 diagnostic DTB configuration: PASS\n'
