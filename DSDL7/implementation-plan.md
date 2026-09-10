# DSDL7 UART Implementation Plan

**Execution status:** Completed and verified on 2026-08-20.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and exhaustively verify the assignment-specific seven-bit UART sender, synchronized midpoint-sampling receiver, and direct loopback top level.

**Architecture:** Three synthesizable Verilog-2001 modules implement the sender, receiver, and direct loopback. Eleven independent self-checking simulations isolate protocol timing, mandatory error cases, integration, and exhaustive data coverage; `Tester.v` repeats the complete regression required by the assignment.

**Tech Stack:** Verilog-2001 RTL, simulator-supported `$fatal` testbench checks, Icarus Verilog 12.0, Yosys 0.33, and Quartus/ModelSim-compatible `.v` sources.

## Global Constraints

- Modify only files under `DSDL7/`.
- Do not create `answers.txt`, report TeX, screenshots, transcripts, packaging, or board configuration.
- Preserve the exact frame order `Start(0) -> Parity -> D0 -> D1 -> D2 -> D3 -> D4 -> D5 -> D6 -> Stop(1)`.
- Use seven-bit data, reduction-XOR parity, LSB-first data, idle-high serial lines, and one stop bit.
- Use the exact required filenames `UARTSender.v`, `UARTReceiver.v`, `UARTTop.v`, and `Tester.v`.
- Keep production RTL synthesizable, vendor-neutral, and free of delay controls and test-only fault paths.
- Set `BIT_TICKS` to `434` by default and support integer values greater than or equal to `2`.
- Use asynchronous active-low `rstN`, a two-register receiver synchronizer, and midpoint sampling.
- Compile every standalone testbench as a separate simulation top.
- Do not add dependencies, scripts, helper modules, or shared testbench includes.

---

## File Map

| File | Responsibility |
|---|---|
| `DSDL7/UARTSender.v` | Latch a seven-bit request and transmit the exact ten-bit frame while reporting `busy`. |
| `DSDL7/UARTReceiver.v` | Synchronize `rx`, confirm start at midpoint, sample the frame, and validate parity and stop. |
| `DSDL7/UARTTop.v` | Connect one sender's `tx` directly to one receiver's `rx`. |
| `DSDL7/Tester.v` | Run the complete aggregate self-checking regression at `BIT_TICKS = 2`. |
| `DSDL7/tb_uart_frame_format.v` | Verify the exact default 434-cycle symbol sequence and `busy` interval. |
| `DSDL7/tb_uart_valid.v` | Verify the required `7'b1011001` loopback. |
| `DSDL7/tb_uart_parity_error.v` | Drive and reject a frame with inverted parity. |
| `DSDL7/tb_uart_stop_error.v` | Drive and reject a frame whose stop bit is zero. |
| `DSDL7/tb_uart_back_to_back.v` | Verify the required two values at the first legal consecutive-frame opportunity. |
| `DSDL7/tb_uart_busy_ignore.v` | Prove a request asserted while busy is neither applied nor queued. |
| `DSDL7/tb_uart_reset_idle.v` | Verify asynchronous reset and all idle outputs. |
| `DSDL7/tb_uart_output_pulses.v` | Verify completion and validity pulse alignment and width. |
| `DSDL7/tb_uart_all_values.v` | Verify all values from zero through 127. |
| `DSDL7/tb_uart_false_start.v` | Verify midpoint confirmation rejects a short low pulse. |
| `DSDL7/specs.txt` | List only the code specifications derived from the assignment PDF. |

### Task 1: Sender FSM and serial-frame timing

**Files:**
- Create: `DSDL7/tb_uart_frame_format.v`
- Create: `DSDL7/UARTSender.v`

**Interfaces:**
- Consumes: `clk`, asynchronous active-low `rstN`, one-cycle `new_data`, and `send_data[6:0]`.
- Produces: idle-high serial `tx` and full-frame `busy` with `parameter integer BIT_TICKS = 434`.

- [ ] **Step 1: Write the failing frame-format test**

Create a standalone `tb_uart_frame_format` that instantiates `UARTSender` with
its default parameter, pulses `new_data` for one clock, and checks this vector
for exactly 434 clocks per symbol:

```verilog
localparam [6:0] TEST_DATA = 7'b1011001;

task check_symbol;
    input expected_tx;
    integer cycle;
    begin
        for (cycle = 0; cycle < 434; cycle = cycle + 1) begin
            if (tx !== expected_tx || busy !== 1'b1)
                $fatal(1, "frame mismatch at symbol cycle %0d", cycle);
            @(negedge clk);
        end
    end
endtask

check_symbol(1'b0);
check_symbol(^TEST_DATA);
for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
    check_symbol(TEST_DATA[bit_index]);
check_symbol(1'b1);
```

- [ ] **Step 2: Run the test to verify the missing sender fails**

Run:

```bash
iverilog -g2012 -Wall -s tb_uart_frame_format -o /tmp/tb_uart_frame_format.vvp DSDL7/UARTSender.v DSDL7/tb_uart_frame_format.v
```

Expected: compilation fails because `UARTSender.v` does not exist.

- [ ] **Step 3: Implement the minimum sender FSM**

Create `UARTSender` with the approved interface, local state constants
`IDLE`, `START`, `PARITY`, `DATA`, and `STOP`, a locally sized tick counter, a
three-bit data index, and latched data/parity. The state progression is:

```verilog
IDLE:   if (new_data) begin
            data_latch   <= send_data;
            parity_latch <= ^send_data;
            state        <= START;
        end
START:  if (last_tick) state <= PARITY;
PARITY: if (last_tick) begin state <= DATA; bit_index <= 3'd0; end
DATA:   if (last_tick && bit_index == 3'd6) state <= STOP;
        else if (last_tick) bit_index <= bit_index + 1'b1;
STOP:   if (last_tick) state <= IDLE;
```

Drive outputs directly from state:

```verilog
assign busy = state != IDLE;
assign tx = state == START  ? 1'b0 :
            state == PARITY ? parity_latch :
            state == DATA   ? data_latch[bit_index] : 1'b1;
```

- [ ] **Step 4: Run the sender timing test**

Run:

```bash
vvp /tmp/tb_uart_frame_format.vvp
```

Expected: `PASS: sender frame format and 434-cycle timing`.

- [ ] **Step 5: Commit the sender slice**

```bash
git add DSDL7/UARTSender.v DSDL7/tb_uart_frame_format.v
git commit -m "feat: add DSDL7 UART sender"
```

### Task 2: Synchronized midpoint-sampling receiver

**Files:**
- Create: `DSDL7/tb_uart_parity_error.v`
- Create: `DSDL7/tb_uart_stop_error.v`
- Create: `DSDL7/tb_uart_false_start.v`
- Create: `DSDL7/UARTReceiver.v`

**Interfaces:**
- Consumes: `clk`, asynchronous active-low `rstN`, and asynchronous serial `rx`.
- Produces: `rec_data[6:0]`, one-cycle `rec_new_data`, and valid-frame-only one-cycle `correct_data`.

- [ ] **Step 1: Write raw-frame drivers in each receiver test**

Each file independently holds one serial symbol for its local `BIT_TICKS` and
drives the assignment-specific order:

```verilog
task drive_frame;
    input [6:0] data;
    input parity_bit;
    input stop_bit;
    integer bit_index;
    begin
        @(negedge clk);
        hold_rx(1'b0);
        hold_rx(parity_bit);
        for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
            hold_rx(data[bit_index]);
        hold_rx(stop_bit);
        rx = 1'b1;
    end
endtask
```

Use `~(^data)` in the parity-error test and `stop_bit = 0` in the stop-error
test. Seed `rec_data` with one valid frame before each invalid frame, then prove
the invalid frame produces `rec_new_data == 1`, `correct_data == 0`, and leaves
`rec_data` unchanged.

- [ ] **Step 2: Run one receiver test to verify the missing module fails**

Run:

```bash
iverilog -g2012 -Wall -s tb_uart_parity_error -o /tmp/tb_uart_parity_error.vvp DSDL7/UARTReceiver.v DSDL7/tb_uart_parity_error.v
```

Expected: compilation fails because `UARTReceiver.v` does not exist.

- [ ] **Step 3: Implement synchronization and midpoint confirmation**

Add a two-register synchronizer reset to idle-high and receiver states
`IDLE`, `START`, `PARITY`, `DATA`, and `STOP`. Use this sampling contract:

```verilog
IDLE:   if (!rx_sync) begin state <= START; tick_count <= 0; end
START:  if (half_tick) begin
            tick_count <= 0;
            state <= rx_sync ? IDLE : PARITY;
        end
PARITY: if (last_tick) begin
            parity_latch <= rx_sync;
            state <= DATA;
        end
DATA:   if (last_tick) begin
            data_latch[bit_index] <= rx_sync;
            if (bit_index == 6) state <= STOP;
            else bit_index <= bit_index + 1'b1;
        end
STOP:   if (last_tick) begin
            rec_new_data <= 1'b1;
            if (rx_sync && ((^data_latch) == parity_latch)) begin
                rec_data <= data_latch;
                correct_data <= 1'b1;
            end
            state <= IDLE;
        end
```

Clear `rec_new_data` and `correct_data` by default on every non-reset clock so
they last exactly one cycle. Do not update `rec_data` in the invalid branch.

- [ ] **Step 4: Implement the false-start test**

In `tb_uart_false_start.v`, hold `rx` low for one clock with `BIT_TICKS = 10`,
prove no completion occurs, then prove the next valid raw frame succeeds.

- [ ] **Step 5: Compile and run all three receiver tests**

Run each top separately with `iverilog -g2012 -Wall` and `vvp`.

Expected PASS messages:

```text
PASS: parity errors are rejected
PASS: stop-bit errors are rejected
PASS: false starts are rejected
```

- [ ] **Step 6: Synthesize-check the receiver**

Run:

```bash
yosys -p 'read_verilog DSDL7/UARTReceiver.v; hierarchy -check -top UARTReceiver; proc; opt; check -assert'
```

Expected: zero hierarchy/check errors and no inferred latches.

- [ ] **Step 7: Commit the receiver slice**

```bash
git add DSDL7/UARTReceiver.v DSDL7/tb_uart_parity_error.v DSDL7/tb_uart_stop_error.v DSDL7/tb_uart_false_start.v
git commit -m "feat: add DSDL7 UART receiver"
```

### Task 3: Direct loopback and integration tests

**Files:**
- Create: `DSDL7/UARTTop.v`
- Create: `DSDL7/tb_uart_valid.v`
- Create: `DSDL7/tb_uart_back_to_back.v`
- Create: `DSDL7/tb_uart_busy_ignore.v`
- Create: `DSDL7/tb_uart_reset_idle.v`
- Create: `DSDL7/tb_uart_output_pulses.v`
- Create: `DSDL7/tb_uart_all_values.v`

**Interfaces:**
- Consumes: the exact `UARTSender` and `UARTReceiver` interfaces from Tasks 1 and 2.
- Produces: direct `tx`-to-`rx` loopback with top-level `tx`, `busy`, `rec_data`, `rec_new_data`, and `correct_data` outputs.

- [ ] **Step 1: Write the required valid-loopback test**

Instantiate `UARTTop` with its unoverridden default `BIT_TICKS = 434`, send
`7'b1011001`, use a bounded wait, and assert:

```verilog
if (rec_data !== 7'b1011001 || rec_new_data !== 1'b1 ||
    correct_data !== 1'b1)
    $fatal(1, "valid loopback failed");
```

- [ ] **Step 2: Run it to verify the missing top fails**

Run:

```bash
iverilog -g2012 -Wall -s tb_uart_valid -o /tmp/tb_uart_valid.vvp DSDL7/UARTSender.v DSDL7/UARTReceiver.v DSDL7/UARTTop.v DSDL7/tb_uart_valid.v
```

Expected: compilation fails because `UARTTop.v` does not exist.

- [ ] **Step 3: Implement direct loopback**

Instantiate one sender and receiver, pass the same `BIT_TICKS` to both, and
connect the receiver port directly with `.rx(tx)`. Add no corruption mux and no
test-only input.

- [ ] **Step 4: Add required consecutive-frame coverage**

In `tb_uart_back_to_back.v`, send `7'b1011001`, wait for `busy` to fall, assert
the second request at the next negative edge using `7'b0101101`, and record the
two receiver completion events. Require exactly two valid results in that
order.

- [ ] **Step 5: Add busy-ignore coverage**

In `tb_uart_busy_ignore.v`, start one frame and pulse a different request early
while `busy` is high. Require only the original value and keep observing for
longer than one complete frame to prove the second request was not queued.

- [ ] **Step 6: Add exhaustive data coverage**

In `tb_uart_all_values.v`, loop from zero through 127. For each value, issue one
legal request, wait with a fixed timeout, and require exactly one valid matching
completion before proceeding.

- [ ] **Step 7: Complete reset/idle integration checks**

Instantiate `UARTTop` in `tb_uart_reset_idle.v` and check every specified reset
and idle output both during reset and after reset release.

- [ ] **Step 8: Add output-pulse integration checks**

In `tb_uart_output_pulses.v`, instantiate one `UARTTop` and one directly driven
`UARTReceiver`. Require one valid loopback completion cycle followed by both
flags low, then one invalid raw completion with `correct_data` remaining low.

- [ ] **Step 9: Compile and run all six integration tests**

Expected PASS messages:

```text
PASS: valid UART loopback
PASS: consecutive UART frames
PASS: busy requests are ignored
PASS: reset and idle behavior
PASS: receiver completion pulses are one cycle
PASS: all 128 UART values
```

- [ ] **Step 10: Synthesize-check the complete RTL hierarchy**

Run:

```bash
yosys -p 'read_verilog DSDL7/UARTSender.v DSDL7/UARTReceiver.v DSDL7/UARTTop.v; hierarchy -check -top UARTTop; proc; opt; check -assert; stat'
```

Expected: zero hierarchy/check errors, no latches, and one sender plus one
receiver in the hierarchy.

- [ ] **Step 11: Commit the loopback slice**

```bash
git add DSDL7/UARTTop.v DSDL7/tb_uart_valid.v DSDL7/tb_uart_back_to_back.v DSDL7/tb_uart_busy_ignore.v DSDL7/tb_uart_all_values.v DSDL7/tb_uart_reset_idle.v DSDL7/tb_uart_output_pulses.v
git commit -m "test: verify DSDL7 UART loopback"
```

### Task 4: Complete aggregate `Tester.v`

**Files:**
- Create: `DSDL7/Tester.v`

**Interfaces:**
- Consumes: all three RTL modules and their exact ports.
- Produces: one complete assignment-compatible testbench with a 10 ns clock, initial reset, `$display` diagnostics, bounded self-checks, and a final aggregate PASS.

- [ ] **Step 1: Build the aggregate fixture**

Instantiate one `UARTTop #(.BIT_TICKS(2))` for sender/loopback scenarios and one
direct `UARTReceiver #(.BIT_TICKS(2))` for malformed raw frames. Define finite
tasks for reset, legal requests, completion waits, symbol driving, and raw
frames; every wait has a cycle limit and calls `$fatal` on expiry.

- [ ] **Step 2: Add the complete ordered regression**

Run these checks in one `initial` block:

```text
1. asynchronous reset and idle outputs
2. exact valid frame 7'b1011001
3. request ignored while busy
4. 7'b1011001 then 7'b0101101 at the first legal opportunity
5. all values 0 through 127
6. raw frame with inverted parity
7. raw frame with stop bit zero
8. short false-start pulse followed by a valid raw frame
9. one-cycle rec_new_data and correct_data semantics throughout
```

- [ ] **Step 3: Compile and run the aggregate**

Run:

```bash
iverilog -g2012 -Wall -s Tester -o /tmp/Tester.vvp DSDL7/UARTSender.v DSDL7/UARTReceiver.v DSDL7/UARTTop.v DSDL7/Tester.v
vvp /tmp/Tester.vvp
```

Expected final line: `PASS: complete DSDL7 UART regression`.

- [ ] **Step 4: Commit the aggregate testbench**

```bash
git add DSDL7/Tester.v
git commit -m "test: add complete DSDL7 UART regression"
```

### Task 5: Source-derived `specs.txt` and final verification

**Files:**
- Create: `DSDL7/specs.txt`
- Modify only if verification exposes a defect: files created in Tasks 1-4

**Interfaces:**
- Consumes: the assignment PDF requirements and verified implementation.
- Produces: a plain bullet list with no report prose, plus a fully passing code tree.

- [ ] **Step 1: Write the list-only specification inventory**

Create `specs.txt` using only `- ` list entries. Include every source-derived
code requirement: seven-bit width, exact ten-bit order, parity equation,
LSB-first order, idle/start/stop values, sender and receiver FSM behavior,
`busy`, `new_data`, validity semantics, 115200/50 MHz/434 timing, configurable
`BIT_TICKS`, exact required filenames, direct loopback, commented synthesizable
RTL, clock/reset/stimulus methodology, `$display` diagnostics, and all four
mandatory simulations. Do not add headings, paragraphs, report requirements, or
implementation commentary.

- [ ] **Step 2: Compile every standalone test independently**

For each test module, run `iverilog -g2012 -Wall -s <module>` with the required
RTL files and then run the resulting `/tmp/<module>.vvp` with `vvp`. All eleven
test tops must report PASS.

- [ ] **Step 3: Run final synthesis and text checks**

Run the full Yosys hierarchy check, `git diff --check`, an unfinished-marker
scan, and a file-name inventory under `DSDL7/`.

Expected: all simulations pass; Yosys reports no design problems; text checks
are clean; no report files exist.

- [ ] **Step 4: Commit the final verified inventory**

```bash
git add DSDL7/specs.txt DSDL7/implementation-plan.md
git commit -m "docs: record verified DSDL7 UART requirements"
```
