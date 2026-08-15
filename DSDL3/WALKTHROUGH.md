# Verilog Comparator Assignment Walkthrough

## 1. Project files

| File | Purpose |
| --- | --- |
| `comparator_1bit.v` | One-bit comparator implemented with continuous assignments |
| `comparator_4bit.v` | Hierarchical four-bit combinational comparator |
| `serial_comparator.v` | Single-module serial sequential comparator |
| `tb_comparator_4bit.v` | Exhaustive testbench for the four-bit comparator |
| `tb_serial_comparator.v` | Exhaustive testbench for the serial comparator |

The three design files use dataflow logic through `assign`. Behavioral constructs
such as `always`, `initial`, `case`, functions, and tasks appear only in the
testbenches, where they are needed to generate inputs and check results.

All comparators have three result outputs:

- `gt = 1`: input `a` is greater than input `b`.
- `eq = 1`: input `a` is equal to input `b`.
- `lt = 1`: input `a` is less than input `b`.

Only one of these outputs should be `1` at a time.

## 2. One-bit comparator

For one-bit inputs, the comparison truth table is:

| `a` | `b` | `gt` | `eq` | `lt` |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 0 | 1 |
| 1 | 0 | 1 | 0 | 0 |
| 1 | 1 | 0 | 1 | 0 |

The corresponding Boolean equations are:

```text
gt = a AND NOT b
eq = NOT (a XOR b)
lt = NOT a AND b
```

They are implemented directly in `comparator_1bit.v`:

```verilog
assign gt =  a & ~b;
assign eq = ~(a ^ b);
assign lt = ~a &  b;
```

This is a combinational circuit: its outputs depend only on the current inputs,
and it contains no stored state.

## 3. Hierarchical four-bit comparator

`comparator_4bit.v` creates four instances of `comparator_1bit`, one for every
bit position:

```text
a[3], b[3] -> c3 -> bit_gt[3], bit_eq[3], bit_lt[3]
a[2], b[2] -> c2 -> bit_gt[2], bit_eq[2], bit_lt[2]
a[1], b[1] -> c1 -> bit_gt[1], bit_eq[1], bit_lt[1]
a[0], b[0] -> c0 -> bit_gt[0], bit_eq[0], bit_lt[0]
```

Bit 3 is the most significant bit (MSB), so it has the highest priority. A lower
bit decides the result only if every more-significant bit is equal.

For example, `a` is greater than `b` when one of these conditions is true:

1. Bit 3 says `a > b`.
2. Bit 3 is equal and bit 2 says `a > b`.
3. Bits 3 and 2 are equal and bit 1 says `a > b`.
4. Bits 3, 2, and 1 are equal and bit 0 says `a > b`.

That rule produces this equation:

```text
gt = gt3
   OR (eq3 AND gt2)
   OR (eq3 AND eq2 AND gt1)
   OR (eq3 AND eq2 AND eq1 AND gt0)
```

The `lt` equation has the same form with each `gt` replaced by `lt`. The numbers
are equal only when all four one-bit comparators report equality:

```verilog
assign eq = &bit_eq;
```

The reduction-AND operator `&` returns `1` only when every bit of `bit_eq` is
`1`. The complete four-bit circuit remains combinational and satisfies the
hierarchical-design requirement because it reuses four one-bit modules.

## 4. Serial comparator

### 4.1 Input order

The serial comparator receives one bit of each number on every clock cycle. The
bits must be supplied from the MSB to the LSB. Once a more-significant pair is
different, later bits cannot change the result.

### 4.2 State encoding

The comparator remembers the result obtained so far in the two-bit `state` wire:

| `state` | Meaning | `gt, eq, lt` |
| --- | --- | --- |
| `2'b00` | Equal so far | `0, 1, 0` |
| `2'b10` | `a` is greater | `1, 0, 0` |
| `2'b01` | `a` is less | `0, 0, 1` |
| `2'b11` | Unused | Not generated |

Reset assigns `2'b00`, because no unequal bit has been seen at the beginning.

### 4.3 Next-state equations

While the state is equal, the current input bits can select greater or less:

```verilog
assign next_state[1] = state[1] | (~state[1] & ~state[0] &  a & ~b);
assign next_state[0] = state[0] | (~state[1] & ~state[0] & ~a &  b);
```

If `state[1]` is already `1`, the first OR expression keeps it at `1`. The same
rule applies to `state[0]`. Therefore, after a difference is found, less-
significant bits do not overwrite it.

### 4.4 Clocked storage using only `assign`

The assignment forbids procedural descriptions, so the module cannot use an
`always` block. It instead models master and slave storage using continuous
feedback:

```verilog
assign master = reset ? 2'b00 : (~clk ? next_state : master);
assign state  = reset ? 2'b00 : ( clk ? master     : state);
```

- When `reset = 1`, both stored values become `2'b00`.
- While `clk = 0`, `master` follows `next_state` and `state` holds its value.
- While `clk = 1`, `master` holds and `state` receives the saved master value.
- Consequently, the visible result changes when the clock rises.

The outputs decode the stored state:

```verilog
assign gt =  state[1];
assign eq = ~state[1] & ~state[0];
assign lt =  state[0];
```

This continuous-feedback technique satisfies the assignment's `assign`-only
simulation constraint in Icarus Verilog. In normal synthesizable RTL, clocked
storage would usually be written with an edge-triggered `always`/`always_ff`
block instead.

### 4.5 Serial example

Consider `a = 1010` and `b = 1001`, supplied MSB-first:

| Clock | Input `a,b` | Compared prefix | Result |
| ---: | --- | --- | --- |
| Reset | - | none | equal |
| 1 | `1,1` | `1` vs. `1` | equal |
| 2 | `0,0` | `10` vs. `10` | equal |
| 3 | `1,0` | `101` vs. `100` | greater |
| 4 | `0,1` | `1010` vs. `1001` | greater |

The fourth bit cannot change the result because the more-significant third bit
already proved that `a` is greater.

## 5. Verification

### 5.1 Four-bit testbench

`tb_comparator_4bit.v` uses two nested loops to test every possible pair:

```text
16 possible values of a x 16 possible values of b = 256 comparisons
```

For every pair, the circuit outputs are checked against Verilog's `>`, `==`,
and `<` operators. The simulation stops immediately if any result is incorrect.

### 5.2 Serial testbench

`tb_serial_comparator.v` also tests all 256 four-bit pairs. Before each pair it
resets the circuit, then sends bits 3, 2, 1, and 0 on successive clock cycles.
The testbench checks the output after every prefix, not only after the complete
four-bit numbers have been received.

The procedural code in both testbenches is simulation-only and is not part of
the submitted comparator hardware.

## 6. Running with Icarus Verilog

Icarus Verilog 12.0 is installed locally in `.tools/iverilog`. Run these commands
from this directory.

Create the build directory:

```bash
mkdir -p .build
```

Compile and run the four-bit comparator test:

```bash
.tools/iverilog/usr/bin/iverilog \
  -B .tools/iverilog/usr/lib/x86_64-linux-gnu/ivl \
  -g2012 -Wall \
  -s tb_comparator_4bit \
  -o .build/comparator4.out \
  comparator_1bit.v comparator_4bit.v tb_comparator_4bit.v

.tools/iverilog/usr/bin/vvp .build/comparator4.out
```

Expected result:

```text
PASS: all 256 four-bit comparisons
```

Compile and run the serial comparator test:

```bash
.tools/iverilog/usr/bin/iverilog \
  -B .tools/iverilog/usr/lib/x86_64-linux-gnu/ivl \
  -g2012 -Wall \
  -s tb_serial_comparator \
  -o .build/serial.out \
  serial_comparator.v tb_serial_comparator.v

.tools/iverilog/usr/bin/vvp .build/serial.out
```

Expected result:

```text
PASS: all 256 serial comparisons at every prefix
```

## 7. Summary

- The one-bit comparator is a direct dataflow implementation of three Boolean
  equations.
- The four-bit comparator is combinational and hierarchical, using four one-bit
  comparator instances with MSB priority.
- The serial comparator is sequential, resets to equal, accepts inputs MSB-first,
  and reports the comparison after every received bit.
- All 256 possible four-bit input pairs pass both testbenches.
