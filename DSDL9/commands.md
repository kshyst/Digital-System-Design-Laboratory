# DSDL9: run tests and view waveforms

Run these commands from the repository root:

```bash
cd DSDL9
mkdir -p build
```

## Generate the VCD files

`tcam.v` uses a generate loop; `tcam_no_loop.v` uses an instance array.
Both reuse `tcam_entry.v`. Each bit of `write_enable` selects its own entry.
Data and X masks are packed as `{row_last, ..., row_1, row_0}`; the search key is shared.

Each test below checks **both implementations** against expected results, prints `PASS`,
and saves its VCD in `build/`.
Sizes below mean **entry count × bits per entry**.

### 16 × 16: load sixteen different values on one rising edge

```bash
iverilog -g2012 -Wall -s tb_tcam_write -o /tmp/dsdl9-write.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_write.v &&
vvp /tmp/dsdl9-write.vvp
```

### 4 × 3: independent wildcard masks and all eight search keys

```bash
iverilog -g2012 -Wall -s tb_tcam_4x3 -o /tmp/dsdl9-4x3.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_4x3.v &&
vvp /tmp/dsdl9-4x3.vvp
```

### 4 × 3: update only selected entries

```bash
iverilog -g2012 -Wall -s tb_tcam_selective -o /tmp/dsdl9-selective.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_selective.v &&
vvp /tmp/dsdl9-selective.vvp
```

### 1 × 1: minimum valid size and reset priority

```bash
iverilog -g2012 -Wall -s tb_tcam_1x1 -o /tmp/dsdl9-1x1.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_1x1.v &&
vvp /tmp/dsdl9-1x1.vvp
```

### 3 × 5: non-power-of-two entry count

```bash
iverilog -g2012 -Wall -s tb_tcam_3x5 -o /tmp/dsdl9-3x5.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_3x5.v &&
vvp /tmp/dsdl9-3x5.vvp
```

### 4 × 8: the assignment's three wildcard patterns

```bash
iverilog -g2012 -Wall -s tb_tcam_wildcard -o /tmp/dsdl9-wildcard.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_wildcard.v &&
vvp /tmp/dsdl9-wildcard.vvp
```

## Open the waveforms with the evidence signals already added

The `.gtkw` files retain signal selection, number formats, zoom, and the marker-free view.

```bash
gtkwave build/tb_tcam_write.vcd build/tb_tcam_write.gtkw &
gtkwave build/tb_tcam_4x3.vcd build/tb_tcam_4x3.gtkw &
gtkwave build/tb_tcam_selective.vcd build/tb_tcam_selective.gtkw &
gtkwave build/tb_tcam_1x1.vcd build/tb_tcam_1x1.gtkw &
gtkwave build/tb_tcam_3x5.vcd build/tb_tcam_3x5.gtkw &
gtkwave build/tb_tcam_wildcard.vcd build/tb_tcam_wildcard.gtkw &
```

If a marker is added accidentally, choose **Markers → Delete Primary Marker** and
**Markers → Collect All Named Markers** before taking a screenshot.

| Screenshot in `figs/` | Testbench | What it proves |
| --- | --- | --- |
| `write-16x16.png` | `tb_tcam_write.v` | Different entries load on the same edge; all sixteen search results are correct. |
| `4x3-wildcards.png` | `tb_tcam_4x3.v` | Four 3-bit entries have independent masks; all eight keys are checked. |
| `selective-writes.png` | `tb_tcam_selective.v` | Only enabled entries change; disabled entries retain data and masks. |
| `1x1-reset.png` | `tb_tcam_1x1.v` | One 1-bit entry supports exact/X matches and synchronous reset priority. |
| `3x5-depth.png` | `tb_tcam_3x5.v` | Three 5-bit entries retain separate data and match results. |
| `wildcard-example.png` | `tb_tcam_wildcard.v` | `01101110` matches all three assignment patterns (`0111`); `11111111` gives `0000`. |
| `zero-width-rejected.png` | `tb_tcam_invalid.v` | Both versions reject one 0-bit entry at time zero with exit status 1. |

## 1 × 0 edge case: expected rejection

Zero width is invalid: Verilog `[-1:0]` is a two-bit range, not an empty vector.
Both modules require `DATA_WIDTH >= 1` and `DEPTH >= 1`.
This test must terminate at time zero with `TCAM requires DATA_WIDTH >= 1 and DEPTH >= 1`.
It does not produce a behavioral VCD; the evidence is the terminal output.

Run the loop version:

```bash
iverilog -g2012 -Wall -s tb_tcam_invalid -o /tmp/dsdl9-invalid-loop.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_invalid.v &&
vvp /tmp/dsdl9-invalid-loop.vvp
```

Run the no-loop version:

```bash
iverilog -g2012 -Wall -s tb_tcam_invalid \
  -Ptb_tcam_invalid.NO_LOOP=1 -o /tmp/dsdl9-invalid-no-loop.vvp \
  tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_invalid.v &&
vvp /tmp/dsdl9-invalid-no-loop.vvp
```

Both commands intentionally exit with status 1. The fallback message
`FAIL: invalid dimensions were accepted` would mean the test caught a missing guard.

To check zero/negative width and count automatically for both versions:

```bash
(
for impl in 0 1; do
  for config in 0:1 1:0 -1:1 1:-1; do
    width=${config%:*}
    depth=${config#*:}
    log="build/invalid-${width}x${depth}-${impl}.log"
    iverilog -g2012 -Wall -s tb_tcam_invalid \
      -Ptb_tcam_invalid.DATA_WIDTH="$width" \
      -Ptb_tcam_invalid.DEPTH="$depth" \
      -Ptb_tcam_invalid.NO_LOOP="$impl" \
      -o /tmp/dsdl9-invalid.vvp \
      tcam_entry.v tcam.v tcam_no_loop.v tb_tcam_invalid.v || exit 1
    if vvp /tmp/dsdl9-invalid.vvp > "$log" 2>&1; then
      echo "FAIL: invalid dimensions were accepted"
      exit 1
    fi
    grep -F "TCAM requires DATA_WIDTH >= 1 and DEPTH >= 1" "$log" || exit 1
    grep -F "Time: 0 " "$log" || exit 1
  done
done
)
```

These log filenames use **width × count**, followed by `0` (loop) or `1` (no-loop).
