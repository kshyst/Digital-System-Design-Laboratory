# Experiment 5: Booth Multiplier

## 1. Assignment requirements

The assignment document, [`آزمایش پنجم (2).pdf`](./آزمایش%20پنجم%20(2).pdf), asks for a signed multiplier designed with Booth's algorithm.

The design must:

- separate the datapath from the control unit;
- use Booth encoding instead of ordinary shift-and-add multiplication;
- shift the multiplier by more than one bit per clock cycle when possible;
- use a barrel shifter for the variable-distance shift;
- be synthesizable and implemented as a Quartus/FPGA project;
- include commented source code, a testbench, a pre-report, and a final report; and
- be submitted as `Hw5_[StudentId]_[firstName]_[lastName].zip`.

The grading described in the assignment is:

- 35% pre-report;
- 10% attendance;
- 35% FPGA implementation; and
- 20% final report.

## 2. Current implementation

The design is a parameterized signed `N x N` Booth multiplier. It currently uses:

```verilog
parameter N = 8;
```

Therefore:

- the multiplicand and multiplier ranges are `-128` to `+127`;
- the product is 16 bits wide; and
- the required product range is `-16256` to `+16384`.

The top-level structure is:

```text
 Start
   |
   v
booth_control
   | Load, Step
   v
booth_datapath ----------> Product
   |
   +-- LastStep ----------> booth_control ----------> Done
```

[`booth_multiplier.v`](./booth_multiplier.v) connects the control unit and datapath.

## 3. Booth's algorithm

Ordinary binary multiplication examines every multiplier bit. When the bit is `1`, it adds the multiplicand and then shifts. An 8-bit multiplication therefore always needs eight calculation steps.

Booth's algorithm instead examines the current multiplier bit, `Q[0]`, together with the previous bit, `Q_1`:

| `Q[0] Q_1` | Operation |
|---|---|
| `00` | Do nothing |
| `01` | Add the multiplicand |
| `10` | Subtract the multiplicand |
| `11` | Do nothing |

After the selected operation, the combined Booth register is shifted arithmetically to the right.

This is especially efficient for runs of ones. For example:

```text
7 = 00000111b = 8 - 1
```

Instead of adding `M` three times, Booth recoding performs the equivalent operation:

```text
(M << 3) - M
```

This implementation additionally skips several consecutive no-operation positions in one clock cycle.

## 4. Booth register arrangement

The datapath uses the standard combined Booth register:

```text
+----------------+----------+-----+
| A: accumulator | Q        | Q_1 |
| N+1 bits       | N bits   | 1   |
+----------------+----------+-----+
```

For `N=8`, its total width is:

```text
9 + 8 + 1 = 18 bits
```

The datapath contains these registers:

- `A`: 9-bit accumulator;
- `Q`: 8-bit multiplier register;
- `Q_1`: previous multiplier bit;
- `M`: stored multiplicand;
- `Remaining`: number of multiplier bits not yet consumed; and
- `Bmap`: Booth boundary map.

### Why `A` has an extra bit

An 8-bit accumulator cannot safely process every operation involving the most-negative operand, `-128`. A Booth subtraction can require:

```text
0 - (-128) = +128
```

Signed 8-bit form cannot represent `+128`. The extra guard bit prevents overflow and incorrect sign propagation. The stored multiplicand is correspondingly sign-extended:

```verilog
wire [N:0] MExt = {M[N-1], M};
```

## 5. Addition and subtraction selection

The current Booth pair is decoded in [`booth_datapath.v`](./booth_datapath.v):

```verilog
wire DoAdd = (~Q[0]) & Q_1;
wire DoSub = Q[0] & ~Q_1;
```

The next accumulator value is then selected:

```verilog
wire [N:0] AOp = DoSub ? (A - MExt) :
                       DoAdd ? (A + MExt) : A;
```

This implements the Booth table directly:

- `01`: add;
- `10`: subtract; and
- `00` or `11`: preserve `A`.

## 6. Boundary map and multi-bit skipping

The multi-bit skip is the optimization specifically required by the assignment.

The boundary map is calculated when the operands are loaded:

```verilog
wire [N-1:0] BmapInit =
    Multiplier ^ {Multiplier[N-2:0], 1'b0};
```

Conceptually:

```text
Bmap[i] = Multiplier[i] XOR Multiplier[i-1]
Multiplier[-1] = 0
```

A `1` marks a transition between adjacent multiplier bits. These transitions are exactly where Booth needs an addition or subtraction. Inside a run of equal bits, the pairs are `00` or `11`, so no arithmetic is required and the design can shift across the run at once.

### Boundary-map examples

For a zero multiplier:

```text
Q    = 00000000
Bmap = 00000000
```

There are no boundaries, so all eight positions can be consumed in one step.

For a multiplier of `-1`:

```text
Q    = 11111111
Bmap = 00000001
```

Only the initial `0 -> 1` boundary exists. The circuit subtracts once and shifts eight positions, completing the calculation in one step.

For an alternating multiplier such as `10101010`, almost every position is a boundary. The design cannot skip positions and needs eight steps, which is its worst case.

## 7. Skip encoder

[`skip_encode.v`](./skip_encode.v) is a combinational priority encoder that returns the distance to the next boundary:

```verilog
for (k = MaxSkip; k >= 1; k = k - 1)
    if (Map[k]) Dist = k;
```

The loop begins at the largest index, but smaller matching indices overwrite earlier assignments. The final result is therefore the smallest set index greater than zero: the nearest upcoming boundary.

If no boundary exists, the encoder returns the maximum skip distance. `Map[0]` is deliberately ignored because the current position's addition or subtraction is already handled during the present step.

The distance is capped so the circuit cannot shift past the unprocessed multiplier bits:

```verilog
wire [DistW-1:0] Dist =
    (Raw < Remaining) ? Raw : Remaining;
```

## 8. Arithmetic-right barrel shifter

[`barrel_ashr.v`](./barrel_ashr.v) implements a combinational arithmetic-right barrel shifter.

For an 18-bit input, the shift-amount width is:

```text
ceil(log2(18)) = 5 bits
```

Each shift-amount bit conditionally applies a power-of-two shift:

```text
amt[0] -> shift by 1
amt[1] -> shift by 2
amt[2] -> shift by 4
amt[3] -> shift by 8
amt[4] -> shift by 16
```

For example, shift amount `00101` applies shifts of `1 + 4 = 5`.

The expression:

```verilog
$signed(dout) >>> (1 << k)
```

performs arithmetic-right shifting and preserves the sign bit, which is necessary for negative partial products.

The shifter is instantiated twice:

- an 18-bit shifter for `{AOp, Q, Q_1}`; and
- a 9-bit shifter for the boundary map.

The boundary-map shifter receives a leading zero, so its arithmetic shift behaves like a logical shift.

## 9. Datapath operation

[`booth_datapath.v`](./booth_datapath.v) performs the arithmetic and stores the intermediate state.

### Reset

`RstN` is an asynchronous active-low reset:

```verilog
always @(posedge Clk or negedge RstN)
```

When reset is asserted, every datapath register becomes zero.

### Load cycle

When `Load=1`:

```text
A         <- 0
Q         <- Multiplier
Q_1       <- 0
M         <- Multiplicand
Remaining <- N
Bmap      <- BmapInit
```

### Calculation step

When `Step=1`, the datapath:

1. decodes `{Q[0], Q_1}`;
2. adds, subtracts, or preserves `A`;
3. finds the distance to the next Booth boundary;
4. shifts `{AOp, Q, Q_1}` right by that distance;
5. shifts the boundary map by the same distance; and
6. subtracts the distance from `Remaining`.

The addition or subtraction and variable-distance shift happen on the same active clock edge.

Before the final step:

```verilog
assign LastStep = (Dist == Remaining);
```

This informs the controller that the current step will consume all remaining multiplier bits.

After every multiplier bit has been processed, the result is:

```verilog
assign Product = {A[N-1:0], Q};
```

The accumulator's extra guard bit is not part of the final `2N`-bit product.

## 10. Control unit

[`booth_control.v`](./booth_control.v) is a four-state finite-state machine:

```text
IDLE -> LOAD -> CALC -> REPORT -> IDLE
```

### `IDLE`

- Wait for `Start=1`.
- Leave the datapath unchanged.

### `LOAD`

- Assert `Load`.
- Capture the operands and initialize the datapath.
- Advance unconditionally to `CALC`.

### `CALC`

- Assert `Step`.
- Continue calculating until `LastStep=1`.

### `REPORT`

- Assert `Done` for one clock cycle.
- Return to `IDLE`.

A `Start` received while the multiplier is busy is ignored. The intended interface sequence is:

1. set `Multiplicand` and `Multiplier`;
2. pulse `Start` for one cycle;
3. keep the operands stable through the load edge;
4. wait for `Done`; and
5. read `Product`.

`Product` remains available until the next load.

## 11. Timing and performance

Each request follows this sequence:

```text
Start accepted
    |
    v
one LOAD cycle
    |
    v
1 to 8 CALC cycles
    |
    v
one REPORT/DONE cycle
```

Only the number of `CALC` cycles varies.

Fresh simulation of the current source gives:

```text
Plain shift-and-add / one-bit Booth: 8 CALC steps always
This implementation:
    minimum: 1
    maximum: 8
    average: 4.50
```

The average calculation work is therefore:

```text
4.5 / 8 = 56.25%
```

This is a `43.75%` average reduction in calculation steps. The reduction in complete transaction latency is smaller because loading and reporting still have fixed costs.

## 12. Testbench

[`booth_multiplier_tb.v`](./booth_multiplier_tb.v) is a self-checking testbench with a 10 ns clock period, corresponding to 100 MHz.

Its `do_mul` task:

- supplies two operands;
- pulses `Start`;
- waits for `Done`;
- calculates the expected result using Verilog signed multiplication;
- compares the actual and expected values; and
- records the calculation-step count.

### Directed tests

The first phase checks important corner cases:

| Multiplication | Result | CALC steps |
|---|---:|---:|
| `0 x 0` | 0 | 1 |
| `0 x -128` | 0 | 2 |
| `1 x 1` | 1 | 2 |
| `-1 x -1` | 1 | 1 |
| `3 x 5` | 15 | 4 |
| `-3 x 5` | -15 | 4 |
| `3 x -5` | -15 | 3 |
| `-3 x -5` | 15 | 3 |
| `3 x 7` | 21 | 2 |
| `-128 x 2` | -256 | 3 |
| `-128 x -128` | 16384 | 2 |
| `127 x 127` | 16129 | 2 |
| `-128 x 127` | -16256 | 2 |
| `85 x -86` | -7310 | 8 |
| `5 x -1` | -5 | 1 |

### Exhaustive verification

The second phase tests every pair of 8-bit inputs:

```text
256 x 256 = 65,536 products
```

A fresh compilation and execution of the current sources produced:

```text
65536 products checked against Verilog signed multiply
0 errors
PASS: booth_multiplier clean
```

This verifies the simulated result for every signed 8-bit input pair.

## 13. Generated artifacts

### `booth_multiplier_tb.vcd`

[`booth_multiplier_tb.vcd`](./booth_multiplier_tb.vcd) is the waveform dump. It includes:

- external inputs and outputs;
- controller state and control signals;
- `A`, `Q`, `Q_1`, and `M`;
- the boundary map;
- shift distance and remaining count; and
- addition/subtraction selection.

The testbench disables waveform generation before exhaustive testing:

```verilog
$dumpoff;
```

Otherwise, 65,536 transactions would produce a very large and unhelpful waveform file.

### `booth_tb.out`

[`booth_tb.out`](./booth_tb.out) is an Icarus Verilog `vvp` simulation executable. It is not an FPGA programming file.

The bundled `.out` and `.vcd` artifacts are slightly older than the latest source-file timestamps, and the VCD contains older internal parameter names. They should be regenerated before submission.

## 14. Regenerating the simulation

From this directory:

```bash
iverilog -Wall -g2005-sv -o booth_tb.out \
  barrel_ashr.v skip_encode.v booth_datapath.v \
  booth_control.v booth_multiplier.v booth_multiplier_tb.v

vvp booth_tb.out
gtkwave booth_multiplier_tb.vcd
```

The compiler currently reports only that the design modules do not define explicit time units. This does not affect the present testbench because timing delays are used only in the testbench itself.

## 15. Missing submission components

The current implementation is complete for source-level simulation, but it is not yet a complete laboratory submission. The directory does not currently contain:

- a pre-report based on [`../template.tex`](../template.tex);
- a final report;
- Quartus project files;
- synthesis results;
- an FPGA board-level wrapper;
- pin assignments;
- hardware input/output mapping;
- board screenshots or hardware evidence; or
- the final submission ZIP.

The existing `booth_multiplier` is an algorithmic top level. Physical-board implementation will likely need a small wrapper for switches, push buttons, clock/reset handling, one-cycle `Start` generation, and result display.

The source has passed exhaustive Icarus Verilog simulation, but Quartus synthesis and physical FPGA behavior have not yet been verified.
