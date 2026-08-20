# DSDL7 UART Code Specification

**Status:** Approved code design

**Source of truth:** All six pages of `آزمایش هفتم.pdf`

**Scope:** Synthesizable UART RTL and executable verification code only

## 1. Scope boundary

This work implements and verifies the code required for Experiment 7. It does
not create or plan the lab report, pre-report, `answers.txt`, TeX, screenshots,
transcripts, submission archives, board pin assignments, or other prose
deliverables.

The assignment contains no separate numbered theory questions. Its code work is
the design of a seven-bit UART sender and receiver, their loopback integration,
and the required simulations.

## 2. Required source files

The assignment explicitly requires at least these four files with these exact
names:

| File | Responsibility |
|---|---|
| `UARTSender.v` | Synthesizable sender and transmit finite-state machine |
| `UARTReceiver.v` | Synthesizable receiver, data capture, parity check, and stop-bit check |
| `UARTTop.v` | Synthesizable direct loopback connection from sender `tx` to receiver `rx` |
| `Tester.v` | Complete self-checking regression covering every mandatory scenario |

The approved verification design also adds these independently runnable
testbenches:

| File | Focus |
|---|---|
| `tb_uart_frame_format.v` | Exact frame order, idle level, symbol duration, and `busy` timing |
| `tb_uart_valid.v` | Required successful reception scenario |
| `tb_uart_parity_error.v` | Required corrupted-parity scenario |
| `tb_uart_stop_error.v` | Required corrupted-stop-bit scenario |
| `tb_uart_back_to_back.v` | Required consecutive-frame scenario |
| `tb_uart_busy_ignore.v` | Repeated `new_data` while the sender is busy |
| `tb_uart_reset_idle.v` | Reset and idle outputs |
| `tb_uart_output_pulses.v` | Completion and validity pulse widths and alignment |
| `tb_uart_all_values.v` | Exhaustive loopback of all 128 seven-bit values |
| `tb_uart_false_start.v` | Rejection of a short false-start pulse |

Each testbench is standalone. It has its own clock, reset, timeout, checks, and
terminal PASS/FAIL result. No shared testbench framework or extra helper file is
required.

All RTL must be synthesizable by Quartus and contain concise comments explaining
the module contract, finite-state phases, counters, and non-obvious timing
decisions. Delay controls, force/release statements, and other simulation-only
constructs are confined to testbench files.

## 3. Explicit protocol requirements

### 3.1 Frame format

- **PROTO-01:** The serial line is logic `1` while idle.
- **PROTO-02:** Each transaction carries exactly seven data bits.
- **PROTO-03:** Each complete frame contains exactly ten serial bits in this
  assignment-specific order:

  ```text
  Start(0) -> Parity -> D0 -> D1 -> D2 -> D3 -> D4 -> D5 -> D6 -> Stop(1)
  ```

- **PROTO-04:** The data is sent least-significant bit first: `D0` through
  `D6`.
- **PROTO-05:** The parity bit is the reduction XOR of all seven data bits:

  ```text
  parity = D0 ^ D1 ^ D2 ^ D3 ^ D4 ^ D5 ^ D6
  ```

  This is even parity over the data and parity bits.
- **PROTO-06:** The start bit is always `0` and the stop bit is always `1`.
- **PROTO-07:** Every frame symbol remains stable for exactly `BIT_TICKS`
  rising edges of `clk`.

### 3.2 Timing

- **TIME-01:** The standard target is 115200 bits per second.
- **TIME-02:** At a 50 MHz system clock, the assignment specifies approximately
  434 clock cycles per bit (`50_000_000 / 115200`).
- **TIME-03:** Both RTL modules expose the same integer parameter
  `BIT_TICKS`, whose default is `434`.
- **TIME-04:** Simulation may override `BIT_TICKS` with a smaller value. The
  implementation supports every value greater than or equal to `2`.
- **TIME-05:** The standalone tests use a 10 ns clock period, as suggested in
  the assignment. Most tests use a small simulation value. The aggregate
  regression exercises `BIT_TICKS = 2`, the assignment's example value, while
  the frame-format test uses the unoverridden default and proves that every
  symbol lasts 434 clock cycles.

## 4. Module interfaces and behavior

### 4.1 `UARTSender`

```verilog
module UARTSender #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       new_data,
    input  wire [6:0] send_data,
    output wire       tx,
    output wire       busy
);
```

- **SEND-01:** `rstN` is an asynchronous active-low reset.
- **SEND-02:** Reset places the sender in `IDLE`, with `tx = 1` and `busy = 0`.
- **SEND-03:** The sender accepts a request only when it is idle and
  `new_data = 1` on a rising clock edge.
- **SEND-04:** On acceptance, it snapshots `send_data` and its XOR parity.
  Changes to `send_data` during transmission cannot alter the active frame.
- **SEND-05:** `new_data` is a one-clock request pulse. Any assertion while
  `busy = 1` is ignored and cannot restart, extend, or corrupt the active
  frame.
- **SEND-06:** The finite-state machine has the observable phases `IDLE`,
  `START`, `PARITY`, `DATA`, and `STOP`.
- **SEND-07:** The `DATA` phase emits the latched bits in index order zero
  through six.
- **SEND-08:** `busy` becomes active with the accepted request, remains active
  throughout all ten complete bit periods, and becomes inactive only after the
  stop-bit period has completed.
- **SEND-09:** Returning to idle restores `tx = 1`.

### 4.2 `UARTReceiver`

```verilog
module UARTReceiver #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       rx,
    output reg  [6:0] rec_data,
    output reg        rec_new_data,
    output reg        correct_data
);
```

- **RECV-01:** `rstN` is an asynchronous active-low reset.
- **RECV-02:** Reset clears `rec_data`, `rec_new_data`, and `correct_data` and
  returns the receiver to `IDLE`.
- **RECV-03:** A two-register synchronizer protects the finite-state machine
  from the asynchronous `rx` input.
- **RECV-04:** The receiver remains idle while synchronized `rx` is `1`.
- **RECV-05:** A synchronized `0` starts candidate-frame detection. The
  receiver waits to the middle of the start-bit interval and confirms that the
  line is still `0`; otherwise it rejects the false start without producing a
  completion pulse.
- **RECV-06:** After start confirmation, the receiver samples once at the
  midpoint of each subsequent bit period, in the exact order parity, `D0`
  through `D6`, then stop.
- **RECV-07:** The received parity is stored separately, and each data bit is
  stored at its matching index in an internal seven-bit register.
- **RECV-08:** A frame is valid only when the stop sample is `1` and the
  reduction XOR of the received data equals the received parity bit.
- **RECV-09:** Every completed frame, valid or invalid, produces exactly one
  clock cycle with `rec_new_data = 1`.
- **RECV-10:** `correct_data` is `1` only during the `rec_new_data` cycle of a
  valid frame. It remains `0` for an invalid frame and at all other times.
- **RECV-11:** `rec_data` updates only for a valid frame. A parity or stop-bit
  error leaves the most recent valid value unchanged, so invalid data is never
  reported as valid.
- **RECV-12:** After completing or rejecting a frame, the receiver returns to
  idle and can process the next frame.

### 4.3 `UARTTop`

```verilog
module UARTTop #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       new_data,
    input  wire [6:0] send_data,
    output wire       tx,
    output wire       busy,
    output wire [6:0] rec_data,
    output wire       rec_new_data,
    output wire       correct_data
);
```

- **TOP-01:** `UARTTop` instantiates exactly one sender and one receiver.
- **TOP-02:** It passes one shared `BIT_TICKS` value to both instances.
- **TOP-03:** Sender `tx` connects directly to receiver `rx`; there is no
  production fault-injection mux or alternate data path.
- **TOP-04:** For every valid accepted request, loopback produces the same
  seven-bit value on `rec_data` with aligned `rec_new_data = 1` and
  `correct_data = 1`.

## 5. Chosen implementation decisions

These details are not fixed by the assignment and are therefore explicit
design choices:

- **CHOICE-01:** Use synthesizable Verilog-2001 RTL in the required `.v` files
  and avoid vendor primitives.
- **CHOICE-02:** Use asynchronous active-low reset because the assignment names
  the signal `rstN` and existing course RTL follows that convention.
- **CHOICE-03:** Use a two-register input synchronizer and midpoint sampling.
  Boundary-only sampling was rejected as fragile; majority-vote oversampling
  was rejected as unnecessary for the stated experiment.
- **CHOICE-04:** Use one local tick counter per RTL module and a three-bit data
  index. Counter widths are derived locally from `BIT_TICKS`; no helper module
  or duplicated baud generator is added.
- **CHOICE-05:** Use one-cycle completion/validity pulses with the semantics in
  `RECV-09` through `RECV-11`.
- **CHOICE-06:** Keep production loopback direct. Fault tests instantiate
  `UARTReceiver` directly and drive deliberately malformed raw frames, matching
  the assignment's permission to corrupt a frame in the testbench.
- **CHOICE-07:** Use deterministic tests rather than randomized stimulus. The
  exhaustive 128-value test covers the entire input domain with simpler and
  reproducible evidence.
- **CHOICE-08:** Compile each standalone testbench as its own simulation top.
  This prevents one test's `$finish` or fault stimulus from interfering with
  another test.

## 6. Testbench methodology

Every testbench must:

- generate a clock with a known 10 ns period;
- assert reset before applying stimulus;
- change driven inputs away from the receiver's sampling edge to avoid races;
- pulse `new_data` for exactly one clock when testing the sender;
- use bounded waits so a broken DUT cannot hang simulation indefinitely;
- compare outputs with case equality so unknown values fail the test;
- use `$display` for important values and a clear PASS message;
- terminate mismatches with `$fatal` and a diagnostic naming the expected and
  observed values;
- leave `clk`, `rstN`, `new_data`, `send_data`, `tx`, `busy`, `rec_data`,
  `rec_new_data`, and `correct_data` directly visible for later ModelSim wave
  inspection.

### 6.1 Required and supplemental coverage

| Testbench | DUT | Required stimulus and assertions |
|---|---|---|
| `tb_uart_frame_format.v` | `UARTSender` | Use the default `BIT_TICKS = 434`; assert idle `tx`; send a known mixed-bit value; verify start, XOR parity, each `D0`-`D6`, and stop for exactly 434 cycles; verify `busy` spans the complete frame and then clears. |
| `tb_uart_valid.v` | `UARTTop` | Send `7'b1011001`; require one completion, `rec_data == 7'b1011001`, and `correct_data == 1`. |
| `tb_uart_parity_error.v` | `UARTReceiver` | Drive a complete raw frame with inverted XOR parity and a valid stop bit; require one completion, `correct_data == 0`, and no change to the last valid `rec_data`. |
| `tb_uart_stop_error.v` | `UARTReceiver` | Drive correct data/parity with stop bit `0`; require one completion, `correct_data == 0`, and no change to the last valid `rec_data`. |
| `tb_uart_back_to_back.v` | `UARTTop` | Send `7'b1011001`, then `7'b0101101` at the first legal opportunity; require two ordered valid completions with matching data. |
| `tb_uart_busy_ignore.v` | `UARTTop` | Start one frame, then pulse `new_data` with different data while `busy`; require the original frame unchanged and prove that no second completion occurs. |
| `tb_uart_reset_idle.v` | All RTL through `UARTTop` | Assert and release reset; verify `tx == 1`, `busy == 0`, completion flags low, and receiver data reset. |
| `tb_uart_output_pulses.v` | `UARTTop` and direct `UARTReceiver` | Verify `rec_new_data` is one cycle for valid and invalid frames; verify `correct_data` is aligned for valid frames and stays low for invalid frames. |
| `tb_uart_all_values.v` | `UARTTop` | Loop through values 0 through 127; require exactly one valid, matching completion for every accepted value. |
| `tb_uart_false_start.v` | `UARTReceiver` | Pull `rx` low for less than half a bit and return it high; require no completion and successful reception of the next valid frame. |
| `Tester.v` | Sender, receiver, and top-level loopback | Run the four assignment-mandated scenarios plus reset, frame timing, busy-ignore, output-pulse, false-start, and exhaustive checks as one complete regression. |

The four assignment-mandated scenarios are therefore independently covered and
also repeated in `Tester.v`:

1. successful reception of `7'b1011001`;
2. deliberate parity corruption;
3. deliberate zero stop bit;
4. at least two consecutive distinct values, specifically `7'b1011001` and
   `7'b0101101`.

## 7. Acceptance criteria

Implementation is complete only when all of the following are true:

1. The three RTL files compile without errors or warnings that indicate width,
   latch, multiple-driver, or unsynthesizable RTL problems.
2. Every standalone testbench compiles and passes independently.
3. `Tester.v` compiles and reports a complete aggregate PASS.
4. The frame-format test proves the assignment's nonstandard parity-before-data
   ordering and the default 434-clock `BIT_TICKS` duration; the aggregate
   regression also passes with `BIT_TICKS = 2`.
5. The mandatory valid, parity-error, stop-error, and back-to-back scenarios
   each pass in their dedicated testbench and in the aggregate regression.
6. The busy-ignore test proves an active frame cannot be disturbed.
7. The exhaustive test passes all 128 possible input values.
8. RTL comments explain the interfaces, state progression, and timing logic,
   and all simulation-only constructs remain outside the synthesizable files.
9. No report, TeX, screenshot, prose evidence, board configuration, or
   submission archive is created as part of this code-only implementation.
