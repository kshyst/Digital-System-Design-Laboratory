# Booth Datapath Step-by-Step Trace

This document traces every datapath field for the example:

```text
Multiplicand = 3
Multiplier   = 7
Expected     = 21
```

The implementation being traced is [`booth_datapath.v`](./booth_datapath.v).

## Timing convention

In the tables below:

- `Load` and `Step` show the values sampled by the datapath immediately before the named edge.
- Stored register columns show their values immediately after that edge.
- Combinational wires are recalculated from those new register values after the edge.
- `Product` is physically present at all times, but it is valid only when the controller asserts `Done`.

## Constant parameters

These values do not change during multiplication.

| Name | Expression | Value | Purpose |
|---|---|---:|---|
| `N` | parameter | 8 | Width of each input operand |
| `DistW` | `$clog2(N+1)` | 4 | Width of `Raw`, `Dist`, and `Remaining` |
| `ShiftAmountW` | `$clog2(2*N+2)` | 5 | Shift-amount width for the 18-bit Booth-register shifter |
| Main shifter `W` | `2*N+2` | 18 | Width of `{A,Q,Q_1}` |
| Map shifter `W` | `N+1` | 9 | Width of `{1'b0,Bmap}` |
| Encoder `MapW` | `N+1` | 9 | Width of the boundary-map encoder input |
| Encoder `MaxSkip` | `MapW-1` | 8 | Default skip when no future boundary exists |

For `N=8`, the main Booth register contains:

```text
A: 9 bits + Q: 8 bits + Q_1: 1 bit = 18 bits
```

## Stored fields and external datapath signals

| Edge or action | `RstN` | `Load` | `Step` | `Multiplicand` | `Multiplier` | `A` (9 bits) | `Q` (8 bits) | `Q_1` | `M` | `Remaining` | `Bmap` | `Product` |
|---|---:|---:|---:|---|---|---|---|---:|---|---:|---|---|
| Reset asserted | 0 | X | X | `00000000` | `00000000` | `000000000` | `00000000` | 0 | `00000000` | 0 | `00000000` | `0000` |
| Reset released, idle | 1 | 0 | 0 | `00000000` | `00000000` | `000000000` | `00000000` | 0 | `00000000` | 0 | `00000000` | `0000` |
| `Start` accepted | 1 | 0 | 0 | `00000011` | `00000111` | `000000000` | `00000000` | 0 | `00000000` | 0 | `00000000` | `0000`, invalid |
| Load edge | 1 | 1 | 0 | `00000011` | `00000111` | `000000000` | `00000111` | 0 | `00000011` | 8 | `00001001` | `0007`, invalid |
| Calculation step 1 | 1 | 0 | 1 | `00000011` | `00000111` | `111111111` (-1) | `10100000` | 1 | `00000011` | 5 | `00000001` | `FFA0`, invalid |
| Calculation step 2 | 1 | 0 | 1 | `00000011` | `00000111` | `000000000` (0) | `00010101` | 0 | `00000011` | 0 | `00000000` | `0015` = **21, valid** |
| Hold result | 1 | 0 | 0 | irrelevant | irrelevant | `000000000` | `00010101` | 0 | `00000011` | 0 | `00000000` | `0015` = 21 |

`X` means that the reset branch has priority, so `Load` and `Step` do not affect the stored values.

## Combinational datapath fields

| Current point | `{Q[0],Q_1}` | `DoAdd` | `DoSub` | `MExt` | `AOp` | `BmapInit` | `Raw` | `Dist` | `DistWide` | `LastStep` | `BmapShifted` | `Shifted` |
|---|---|---:|---:|---|---|---|---:|---:|---|---:|---|---|
| After reset | `00` | 0 | 0 | `000000000` | `000000000` | `00000000` | 8 | 0 | `00000` | 1* | `000000000` | `000000000000000000` |
| Start accepted, before load | `00` | 0 | 0 | `000000000` | `000000000` | `00001001` | 8 | 0 | `00000` | 1* | `000000000` | `000000000000000000` |
| After load, before step 1 | `10` | 0 | 1 | `000000011` (+3) | `111111101` (-3) | `00001001` | 3 | 3 | `00011` | 0 | `000000001` | `111111111101000001` |
| After step 1, before step 2 | `01` | 1 | 0 | `000000011` (+3) | `000000010` (+2) | `00001001` | 8 | 5 | `00101` | 1 | `000000000` | `000000000000101010` |
| After final step | `10` | 0 | 1 | `000000011` (+3) | `111111101` (-3) | `00001001` | 8 | 0 | `00000` | 1* | `000000000` | `111111101000101010` |

`LastStep=1*` outside the `CALC` state is harmless. The controller only uses `LastStep` while it is calculating. After the final step, combinational values such as `AOp` and `Shifted` continue reacting to their inputs, but they are not stored because `Step=0`.

## Row 1: reset asserted

The active-low reset input is asserted:

```text
RstN = 0
```

The reset branch executes immediately, without waiting for a clock edge:

```text
A         <- 000000000
Q         <- 00000000
Q_1       <- 0
M         <- 00000000
Remaining <- 0000
Bmap      <- 00000000
```

The stored fields are therefore all zero.

The Booth-operation wires become:

```text
DoAdd = ~Q[0] & Q_1
      = ~0 & 0
      = 0

DoSub = Q[0] & ~Q_1
      = 0 & ~0
      = 0
```

The stored multiplicand is also zero, so its sign extension is:

```text
MExt = {M[7],M}
     = {0,00000000}
     = 000000000
```

No addition or subtraction is selected:

```text
AOp = A
    = 000000000
```

The zero boundary map contains no future boundary, so the encoder returns its default:

```text
Raw = MaxSkip = 8
```

No multiplier bits are active yet:

```text
Remaining = 0
Dist      = min(Raw,Remaining)
          = min(8,0)
          = 0
```

This makes the combinational comparison true:

```text
LastStep = (Dist == Remaining)
         = (0 == 0)
         = 1
```

This does not incorrectly finish a multiplication. The controller is in `IDLE`, and it only reacts to `LastStep` while in `CALC`.

Both shifter outputs remain zero:

```text
BmapShifted = 000000000
Shifted     = 000000000000000000
Product     = 0000000000000000
```

## Row 2: reset released, idle

Reset is released:

```text
RstN = 1
```

Changing reset from zero to one does not execute the sequential block. It only allows future rising clock edges to operate normally.

Because neither `Load` nor `Step` is active, every stored field remains unchanged:

```text
A         = 000000000
Q         = 00000000
Q_1       = 0
M         = 00000000
Remaining = 0000
Bmap      = 00000000
```

The datapath is ready, but it does not begin until the controller receives `Start`.

## Row 3: `Start` accepted

The external inputs are set to:

```text
Multiplicand = 00000011 = 3
Multiplier   = 00000111 = 7
Start        = 1
```

`Start` belongs to the controller, not the datapath. The controller moves from `IDLE` to `LOAD`, but the datapath registers have not loaded the operands yet because the datapath saw `Load=0` at this edge.

The stored fields therefore remain:

```text
A         = 000000000
Q         = 00000000
Q_1       = 0
M         = 00000000
Remaining = 0000
Bmap      = 00000000
```

`BmapInit` is different from the stored `Bmap`: it is a combinational wire connected directly to the external `Multiplier` input. It changes immediately when `Multiplier` becomes 7:

```text
Multiplier                  = 00000111
{Multiplier[6:0],1'b0}      = 00001110
                               -------- XOR
BmapInit                    = 00001001
```

The stored `Bmap` is still zero. `BmapInit` will be copied into it on the following load edge.

## Row 4: load edge

Immediately before this rising edge:

```text
Load = 1
Step = 0
```

The datapath executes its load branch:

```verilog
A         <= 0;
Q         <= Multiplier;
Q_1       <= 0;
M         <= Multiplicand;
Remaining <= N;
Bmap      <= BmapInit;
```

After the edge:

```text
A         = 000000000 = 0
Q         = 00000111  = 7
Q_1       = 0
M         = 00000011  = 3
Remaining = 1000      = 8
Bmap      = 00001001
```

The continuously driven product now happens to contain 7:

```text
Product = {A[7:0],Q}
        = 00000000 00000111
        = 0000000000000111
```

It is not a valid result because the controller has not asserted `Done`.

### Booth decision for step 1

The current Booth pair is:

```text
Q[0] = 1
Q_1  = 0
Pair = 10
```

The decode wires become:

```text
DoAdd = 0
DoSub = 1
```

The multiplicand is widened from 8 to 9 bits by copying its sign bit:

```text
M    = 00000011
MExt = 000000011 = 3
```

Pair `10` selects subtraction:

```text
AOp = A - MExt
    = 0 - 3
    = -3
```

Nine-bit two's-complement `-3` is:

```text
AOp = 111111101
```

### Shift distance for step 1

The stored map is:

```text
Bmap = 00001001
```

Its set bits are at positions 3 and 0. Position 0 describes the Booth operation being handled now. The nearest future boundary is position 3:

```text
Raw = 3
```

Eight multiplier positions remain:

```text
Dist = min(Raw,Remaining)
     = min(3,8)
     = 3
```

The 4-bit distance is widened for the 18-bit shifter:

```text
Dist     = 0011
DistWide = 00011
```

This shift will not consume everything:

```text
LastStep = (3 == 8)
         = 0
```

### Boundary-map shift for step 1

The map shifter receives a leading zero:

```text
{1'b0,Bmap} = 0 00001001
             = 000001001
```

Shifting it right by three gives:

```text
000001001 >> 3
= 000000001
```

Therefore:

```text
BmapShifted = 000000001
```

### Booth-register shift for step 1

The main shifter receives:

```text
AOp = 111111101
Q   = 00000111
Q_1 = 0
```

Concatenating the three fields gives:

```text
{AOp,Q,Q_1}
= 111111101 00000111 0
= 111111101000001110
```

Arithmetic-right shifting by three preserves the negative sign:

```text
111111101000001110 >>> 3
= 111111111101000001
```

Thus:

```text
Shifted = 111111111101000001
```

Splitting this value into its future register fields gives:

```text
A   = 111111111
Q   = 10100000
Q_1 = 1
```

These values are combinational until the next rising edge stores them.

## Row 5: calculation step 1

Immediately before this edge:

```text
Load = 0
Step = 1
Dist = 3
```

The datapath stores all step results together:

```text
{A,Q,Q_1} <- Shifted
Remaining  <- Remaining - Dist
Bmap       <- BmapShifted[7:0]
```

After the edge:

```text
A         = 111111111 = -1
Q         = 10100000
Q_1       = 1
M         = 00000011  = 3
Remaining = 0101      = 5
Bmap      = 00000001
```

The intermediate product is:

```text
Product = {A[7:0],Q}
        = 11111111 10100000
        = 1111111110100000
        = 16'hFFA0
```

Interpreted as signed 16-bit data this is `-96`, but it is not a multiplication result because `Done=0`.

### Booth decision for step 2

The new pair is:

```text
Q[0] = 0
Q_1  = 1
Pair = 01
```

Therefore:

```text
DoAdd = 1
DoSub = 0
```

Pair `01` selects addition:

```text
AOp = A + MExt
    = -1 + 3
    = 2
```

Nine-bit representation:

```text
AOp = 000000010
```

### Shift distance for step 2

The current map is:

```text
Bmap = 00000001
```

Only position 0 is set, and that is the operation currently being handled. No later boundary exists, so the encoder uses its default:

```text
Raw = MaxSkip = 8
```

Only five multiplier positions remain:

```text
Dist = min(8,5)
     = 5
```

The main shifter receives the zero-extended distance:

```text
Dist     = 0101
DistWide = 00101
```

This step consumes exactly the remaining positions:

```text
LastStep = (Dist == Remaining)
         = (5 == 5)
         = 1
```

### Boundary-map shift for step 2

```text
{1'b0,Bmap} = 000000001

000000001 >> 5
= 000000000
```

Therefore:

```text
BmapShifted = 000000000
```

### Booth-register shift for step 2

The main shifter receives:

```text
AOp = 000000010
Q   = 10100000
Q_1 = 1
```

Concatenation gives:

```text
{AOp,Q,Q_1}
= 000000010 10100000 1
= 000000010101000001
```

Arithmetic-right shift by five:

```text
000000010101000001 >>> 5
= 000000000000101010
```

Thus:

```text
Shifted = 000000000000101010
```

Splitting it gives:

```text
A   = 000000000
Q   = 00010101
Q_1 = 0
```

## Row 6: calculation step 2

Immediately before the final calculation edge:

```text
Load     = 0
Step     = 1
Dist     = 5
LastStep = 1
```

The datapath stores:

```text
A         <- 000000000
Q         <- 00010101
Q_1       <- 0
Remaining <- 5 - 5 = 0
Bmap      <- 00000000
```

After the edge:

```text
A         = 000000000
Q         = 00010101
Q_1       = 0
M         = 00000011
Remaining = 0000
Bmap      = 00000000
```

The output is now:

```text
Product = {A[7:0],Q}
        = 00000000 00010101
        = 0000000000010101
        = 21
```

At the same edge, the controller sees `LastStep=1` and enters `REPORT`, so `Done=1` and this product is valid.

The combinational calculation wires continue to react to the final stored values:

```text
Q[0]     = 1
Q_1      = 0
DoSub    = 1
AOp      = -3
Raw      = 8
Remaining = 0
Dist     = 0
LastStep = 1
```

These values do not begin another subtraction because the controller has left `CALC`, making `Step=0`.

## Row 7: hold result

At the following edge:

```text
Load = 0
Step = 0
```

Neither sequential branch executes. Every datapath register retains its previous value:

```text
A         remains 000000000
Q         remains 00010101
Q_1       remains 0
M         remains 00000011
Remaining remains 0000
Bmap      remains 00000000
```

Because `Product` is continuously assigned from `A` and `Q`, it also remains:

```text
Product = 0000000000010101 = 21
```

The result stays available until a later `Load` edge initializes the datapath for another multiplication.

## Summary

For multiplier 7:

```text
7 = 8 - 1
```

The two boundary bits in `Bmap=00001001` cause two calculation steps:

1. Pair `10` subtracts 3 at position 0 and shifts three positions.
2. Pair `01` adds 3 at position 3 and shifts the final five positions.

The hardware therefore implements:

```text
3 x 7
= 3 x (8 - 1)
= 24 - 3
= 21
```
