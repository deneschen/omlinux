#!/usr/bin/env python3
"""Compile the driver's actual FIFO branch and check who may bypass the FIFO.

SMHC_SFC (0x0104) bit 0 is BYPASS_EN; manual 11.3.8.30 documents the reset
default as 0x6 (bypass off).  Only controllers that report sfc_dis may set it,
so the A733 eMMC path must keep the sample FIFO enabled.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
s = (root / 'bsp/drivers/mmc/sunxi-mmc-v4p5x.c').read_text()
start = s.index('\tif (host->sfc_dis == true) {')
end = s.index('\n\tif (IS_ENABLED(CONFIG_ARCH_SUN60IW2)', start)
branch = s[start:end]
with tempfile.TemporaryDirectory() as tmp:
    p = Path(tmp)
    (p / 'test.c').write_text('''
#include <assert.h>
#include <stdbool.h>
#define SDXC_SFC_BP 1
#define REG_SFC 0
#define SM_DBG(...) ((void)0)
struct host { bool sfc_dis; int phy_index; };
static unsigned sfc;
#define mmc_readl(h,r) sfc
#define mmc_writel(h,r,v) (sfc = (v))
static void apply(struct host *host)
{
unsigned rval;
''' + branch + '''
}
int main(void) {
 struct host h;
 for (int phy = 0; phy < 4; phy++)
 for (int flag = 0; flag <= 1; flag++)
 for (unsigned old = 0; old <= 0x7; old++) {
  h.sfc_dis = flag; h.phy_index = phy; sfc = old;
  apply(&h);
  unsigned expected = flag ? old | 1 : old;
  assert(sfc == expected);
 }
 return 0;
}
''')
    subprocess.run(['gcc', '-std=c11', '-Wall', '-Wextra', '-Werror',
                    str(p / 'test.c'), '-o', str(p / 'test')], check=True)
    subprocess.run([str(p / 'test')], check=True)
print('A733 sample-FIFO bypass stays revision-gated: PASS')
