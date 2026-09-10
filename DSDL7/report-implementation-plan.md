# Experiment 7 UART Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a professor-ready Persian Experiment 7 report that covers every assignment requirement, explains the implemented UART and every supplied waveform with exact test data, and reserves the approved Quartus evidence figures.

**Architecture:** Write the complete Persian content first in `DSDL7/report.txt`, then encode the same structure in `DSDL7/report.tex` using the root template's commands and the established numbered-listing format. Finish with read-only checks that compare the report against the PDF, live RTL/testbenches, all supplied figures, and the verified simulator transcript.

**Tech Stack:** Persian plain text, XePersian-compatible TeX content commands from `template.tex`, Verilog source listings, Icarus Verilog transcript evidence, GTKWave PNG evidence, and Quartus figure reservations.

## Global Constraints

- Modify only files inside `DSDL7`; leave `template.tex`, RTL, testbenches, and supplied figures unchanged.
- Write report content only: no document class, packages, title page, or bibliography.
- Write formal Persian with Persian digits, correct half-spaces and punctuation, no short-vowel diacritics, and LTR formatting for English identifiers.
- Use every PNG supplied in `DSDL7/figs` exactly once or in a clearly grouped sequence.
- Every TeX figure must use `[H]`, a filename without a directory prefix, a caption, a label, a preceding in-text reference, and an explanation immediately after it.
- Copy code excerpts exactly from the live source and preserve the source line numbers.
- State verified Icarus/GTKWave evidence accurately; do not call it ModelSim evidence.
- Do not invent Quartus results, resource counts, measurements, screenshots, citations, or external references.
- Reserve the exact Quartus filenames `quartus_analysis_synthesis.png`, `quartus_rtl_viewer.png`, and `quartus_resource_utilization.png` with conditional TeX figure frames.
- Do not compile TeX; use text-only validation.

---

### Task 1: Write the complete Persian report source

**Files:**
- Create: `DSDL7/report.txt`

**Interfaces:**
- Consumes: `DSDL7/report-design.md`, the six-page experiment PDF, current RTL/testbenches, and all waveform PNGs.
- Produces: the authoritative section order, exact facts, figure markers, transcript, and conclusions used by `report.tex`.

- [x] **Step 1: Write the theory and architecture sections**

Write formal Persian sections covering:

- abstract, keywords, introduction, and experiment objectives;
- UART asynchronous communication and idle-high serial line;
- the exact ten-symbol frame `Idle, Start, Parity, D0...D6, Stop`;
- seven-bit LSB-first payload and parity `D0 xor D1 xor ... xor D6`;
- `50,000,000 / 115,200 = 434.027...`, hence `434` clocks per bit in hardware;
- the deliberate simulation values `BIT_TICKS=10`, `BIT_TICKS=2`, and the dedicated `BIT_TICKS=434` timing proof;
- responsibilities of `UARTSender`, `UARTReceiver`, `UARTTop`, `Tester`, and each standalone testbench;
- direct `tx`-to-`rx` loopback.

- [x] **Step 2: Write the sender and receiver implementation analysis**

Explain sender input latching, FSM stages, serial output mapping, `busy`, and rejection of requests while busy. Explain receiver synchronization through `rx_meta` and `rx_sync`, midpoint false-start confirmation, parity latching, seven data samples, stop/parity validation, retained last-valid `rec_data`, and the one-clock semantics of `rec_new_data` and `correct_data`.

- [x] **Step 3: Write the test methodology and exact evidence map**

Include a test matrix covering valid transfer, exact frame timing, parity error, stop error, required consecutive values `7'b1011001` then `7'b0101101`, busy-request rejection, reset/idle, output-pulse width, exhaustive `0x00` through `0x7F`, and false-start recovery. Add these exact image markers at the matching analyses:

```text
[تصویر: uart_valid_sender.png]
[تصویر: uart_valid_receiver.png]
[تصویر: uart_parity_error.png]
[تصویر: uart_stop_error.png]
[تصویر: uart_back_to_back.png]
[تصویر: uart_busy_ignore.png]
[تصویر: uart_reset_idle.png]
[تصویر: uart_output_pulses.png]
[تصویر: uart_false_start.png]
[تصویر: uart_all_values_1.png]
[تصویر: uart_all_values_2.png]
[تصویر: uart_all_values_3.png]
[تصویر: uart_all_values_4.png]
```

For every marker, state the exact stimulus, expected behavior, visible signal transitions, and conclusion. Distinguish the progressive ranges visible in the four exhaustive screenshots from the full self-checking sweep.

- [x] **Step 4: Add transcript, Quartus evidence reservations, and conclusion**

Include the exact aggregate simulator output:

```text
PASS: reset and idle outputs
TEST: exact valid frame and symbol timing
TEST: request asserted while busy
TEST: required consecutive frames
TEST: exhaustive seven-bit loopback
TEST: valid raw receiver frame
TEST: required parity error
TEST: required stop-bit error
TEST: false-start rejection and recovery
PASS: complete DSDL7 UART regression
```

Add markers for the three approved Quartus images and explain, without fabricated results, that they document successful analysis/synthesis, the RTL structure, and device resource utilization. End with a comparison of expected and observed behavior and a concise conclusion.

- [x] **Step 5: Check the plain-text source**

Run:

```bash
rtk rg -n '^\[تصویر:' DSDL7/report.txt
rtk rg -n 'PASS: complete DSDL7 UART regression|۱۱۵۲۰۰|۴۳۴|۰x۵۹|۰x۲D' DSDL7/report.txt
```

Expected: all sixteen image markers are present and the exact transcript plus timing/data facts are present.

---

### Task 2: Build the template-compatible TeX report

**Files:**
- Create: `DSDL7/report.tex`
- Read: `template.tex`
- Read: `DSDL3/report.tex`
- Read: `DSDL7/UARTSender.v`
- Read: `DSDL7/UARTReceiver.v`
- Read: `DSDL7/UARTTop.v`
- Read: `DSDL7/Tester.v`
- Read: `DSDL7/tb_uart_all_values.v`

**Interfaces:**
- Consumes: the completed `DSDL7/report.txt` and exact source lines.
- Produces: TeX main content ready for inclusion by the root report template.

- [x] **Step 1: Add the report structure and listing environment**

Start with the same `dsdlcodeblock` color/savebox environment used in earlier reports, then write `\فصل{چکیده}` and the remaining approved Persian chapters. Do not add preamble or title-page commands.

- [x] **Step 2: Add exact numbered RTL excerpts**

Use nested `dsdlcodeblock` and `verbatim` blocks with exact live lines from:

- `UARTSender.v:45-48` for `tx` and `busy`, and `UARTSender.v:59-108` for the sender FSM;
- `UARTReceiver.v:49-58` for synchronization, and `UARTReceiver.v:71-129` for receive/validation behavior;
- `UARTTop.v:18-34` for direct loopback;
- `Tester.v:62-93` for pulse checking and `Tester.v:279-308` for parity, stop, and false-start scenarios;
- `tb_uart_all_values.v:45-66` for the exhaustive seven-bit loop.

Each excerpt must be introduced and interpreted in Persian; identifiers stay LTR.

- [x] **Step 3: Add all waveform figures and explanations**

For each of the thirteen supplied PNGs, use this exact structural pattern:

```tex
\شروع{شکل}[H]
\centerimg{uart_valid_sender.png}{0.98\linewidth}
\شرح{...}
\برچسب{fig:uart-valid-sender}
\پایان{شکل}

توضیح دقیق شکل، داده، بیت توازن، زمان‌بندی، سیگنال‌ها و نتیجه.
```

Use a unique label and a preceding `\رجوع{...}` reference for every figure. Explain these exact facts:

- valid `0x59`: parity `0`; symbols `Start=0, P=0, D0..D6=1,0,0,1,1,0,1, Stop=1`;
- parity error: seed `0x59`, then `0x2D` with inverted parity `1`, completion without validity, prior data retained;
- stop error: seed `0x59`, then `0x2D` with stop `0`, completion without validity, prior data retained;
- consecutive frames: `0x59` then `0x2D`, two ordered completions;
- busy ignore: active `0x59`, attempted `0x2D`, one completion only;
- reset idle: `send_data=0x7F`, reset low until about `20 ns`, stable idle afterward;
- output pulses: valid loopback `0x59`, then raw invalid-parity `0x59`, each completion pulse one clock while only the valid frame asserts correctness;
- false start: `BIT_TICKS=10`, `10 ns` low pulse versus `50 ns` midpoint, then valid `0x59` recovery;
- exhaustive images: progressive screenshot windows only, while the loop self-check covers all 128 values.

- [x] **Step 4: Add transcript and conditional Quartus figures**

Place the exact simulator output in a `dsdlcodeblock`/`verbatim` block. For each Quartus filename, use `\IfFileExists` so the report remains structurally valid before the screenshot is supplied:

```tex
\IfFileExists{quartus_analysis_synthesis.png}
  {\centerimg{quartus_analysis_synthesis.png}{0.9\linewidth}}
  {\fbox{\parbox[c][5cm][c]{0.86\linewidth}{\centering محل تصویر نتیجهٔ Analysis \& Synthesis در Quartus}}}
```

Wrap each conditional image in a `[H]` figure with a caption and label, reference it beforehand, and explain what evidence the final screenshot documents without asserting unavailable counts or device-specific results.

- [x] **Step 5: Check TeX structure without compilation**

Run:

```bash
rtk rg -n '^\\فصل|^\\قسمت|^\\زیرقسمت' DSDL7/report.tex
rtk rg -n '\\شروع\{شکل\}\[H\]' DSDL7/report.tex
rtk rg -n '\\centerimg\{[^/]+\.png\}' DSDL7/report.tex
rtk rg -n 'PASS: complete DSDL7 UART regression' DSDL7/report.tex
```

Expected: the report starts with content, all sixteen figures are fixed-position figures with filename-only references, and the exact aggregate pass line is present.

---

### Task 3: Perform the final assignment-compliance audit

**Files:**
- Verify: `DSDL7/report.txt`
- Verify: `DSDL7/report.tex`
- Compare: `DSDL7/آزمایش هفتم.pdf`, all current RTL/testbenches, and all files in `DSDL7/figs`

**Interfaces:**
- Consumes: the two completed report artifacts.
- Produces: text-only evidence that the final report is internally consistent and complete.

- [x] **Step 1: Verify every supplied image is used**

Run a filename set comparison between `DSDL7/figs/*.png` and `report.tex`. Expected: no supplied filename is absent and no supplied waveform is duplicated accidentally.

- [x] **Step 2: Verify environments, references, and labels**

Count starts/ends for `شکل`, `جدول`, `latin`, `lrbox`, `minipage`, `dsdlcodeblock`, and `verbatim`. Compare every `\رجوع{...}` key against a matching `\برچسب{...}` key. Expected: all counts and key sets match.

- [x] **Step 3: Verify every numbered listing against live source**

Compare each manually numbered line in the TeX excerpts with the corresponding current Verilog line. Expected: line numbers and source text match exactly.

- [x] **Step 4: Re-run the existing simulations as evidence**

Run every existing Icarus command from `DSDL7/README.md` without modifying RTL or tests. Expected: all testbenches report `PASS`, including the aggregate final line `PASS: complete DSDL7 UART regression`.

- [x] **Step 5: Scan forbidden and missing content**

Run text searches confirming there is no `\documentclass`, `\usepackage`, bibliography, URL, `figs/` image prefix, claim of ModelSim execution, or fabricated Quartus number. Re-read the report against every PDF deliverable: protocol/frame, sender FSM/outputs, receiver FSM/checks, top loopback, testbench/scenarios, waveform evidence, simulator transcript, and result analysis.

- [x] **Step 6: Check patch hygiene**

Run:

```bash
rtk git diff --check -- DSDL7/report.txt DSDL7/report.tex DSDL7/report-implementation-plan.md
rtk git status --short
```

Expected: no whitespace errors and no files outside the requested assignment scope changed by this report implementation.
