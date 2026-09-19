#!/bin/sh
set -eu

# Vendor stock sdc2 node (no kernel tuning, dtsi tm4 table drives the delays).
# With the boot0 PLL_PERI1 fix the eMMC clock is now nominal (200 MHz), so this
# is the closest match to the vendor's proven setup; the driver's own DS_DL
# retry (which converged at 2 in the vendor log) is left to run.

dtb=${1:-arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7s.dtb}
node=/soc@3000000/sdmmc@4022000

fail()
{
	printf 'A7S eMMC HS400 check failed: %s\n' "$*" >&2
	exit 1
}

test -f "$dtb" || fail "DTB not found: $dtb"

props=$(fdtget -p "$dtb" "$node") || fail "missing node $node"

has_prop()
{
	printf '%s\n' "$props" | grep -qx "$1"
}

test "$(fdtget -t u "$dtb" "$node" bus-width)" = 8 || fail "bus-width is not 8"
test "$(fdtget -t u "$dtb" "$node" max-frequency)" = 200000000 || fail "max-frequency is not 200 MHz"

for prop in mmc-ddr-1_8v mmc-hs200-1_8v mmc-hs400-1_8v; do
	has_prop "$prop" || fail "missing $prop"
done

if has_prop execute_tuning_in_kernel; then
	fail "unexpected execute_tuning_in_kernel (vendor node expected)"
fi

printf 'A7S eMMC HS400 DTB configuration (vendor node): PASS\n'
