# DSDL9: run tests and view waveforms

Run these commands from the repository root:

```bash
cd DSDL9
mkdir -p build
```

## Generate the VCD files

Each command compiles and runs one self-checking testbench. A successful run prints `PASS`; the VCD is saved in `build/`.

### Exact match and miss

```bash
iverilog -g2012 -Wall -s tb_tcam_exact -o /tmp/dsdl9-exact.vvp \
  tcam_entry.v tcam.v tb_tcam_exact.v &&
vvp /tmp/dsdl9-exact.vvp
```

### Wildcard matching

```bash
iverilog -g2012 -Wall -s tb_tcam_wildcard -o /tmp/dsdl9-wildcard.vvp \
  tcam_entry.v tcam.v tb_tcam_wildcard.v &&
vvp /tmp/dsdl9-wildcard.vvp
```

### Reset

```bash
iverilog -g2012 -Wall -s tb_tcam_reset -o /tmp/dsdl9-reset.vvp \
  tcam_entry.v tcam.v tb_tcam_reset.v &&
vvp /tmp/dsdl9-reset.vvp
```

## Open the waveforms

The supplied VCD files can also be opened directly, without rerunning the tests:

```bash
gtkwave build/tb_tcam_exact.vcd &
gtkwave build/tb_tcam_wildcard.vcd &
gtkwave build/tb_tcam_reset.vcd &
```

In each GTKWave window:

1. Select the `tb_tcam_...` module in the **SST** panel.
2. Select `clk`, `reset`, `write_enable`, `write_address`, `write_data`, `write_x_mask`, `search_data`, and `match_lines`; click **Append**.
3. Choose **Time → Zoom → Zoom Full**.
4. Use **Data Format → Hex** for the exact-match test, and **Binary** for wildcard and reset buses.

Expected results: exact matching gives `8000 → 0000`; wildcard matching gives `0111 → 0000`; reset gives `01 → 00`.
