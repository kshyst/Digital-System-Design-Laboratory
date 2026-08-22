# Experiment 7 UART Report Design

Date: 2026-08-22

## Objective

Create a professor-ready Persian report for Experiment 7 that explains the
assignment-specific seven-bit UART, documents the implemented synthesizable RTL,
analyzes every supplied waveform with exact test data, includes the verified
simulation transcript, and reserves three clearly named Quartus synthesis
figures.

## Authoritative Inputs

- Root `AGENTS.md` and `template.tex`.
- All six pages of `DSDL7/آزمایش هفتم.pdf`.
- Current `UARTSender.v`, `UARTReceiver.v`, `UARTTop.v`, `Tester.v`, and standalone
  testbenches.
- Every PNG currently present in `DSDL7/figs`.
- The `dsdlcodeblock` plus nested `verbatim` convention used in earlier reports.

## Deliverables

1. `DSDL7/report.txt`: complete Persian report text prepared before TeX.
2. `DSDL7/report.tex`: report content only, without document class, packages,
   title pages, or bibliography.

The root template remains unchanged. TeX is not compiled.

## Report Structure

1. Abstract and keywords.
2. Introduction and experiment objectives.
3. UART protocol, idle level, ten-symbol frame, XOR parity, LSB-first data order,
   and timing calculation for 115200 bps at 50 MHz.
4. File/module architecture and direct loopback.
5. Sender interface, FSM, `tx`, `busy`, input latching, and busy-request policy.
6. Receiver interface, two-stage synchronizer, midpoint start confirmation,
   sampling, parity/stop validation, and one-cycle notification semantics.
7. Testbench methodology and table mapping each required and additional test to
   its stimulus and expected result.
8. Waveform results and full interpretation of every supplied image.
9. Exact aggregate `Tester` text output as the required transcript evidence.
10. Quartus synthesis section with three image placeholders.
11. Overall result analysis and conclusion.

## Code Excerpts

Code samples use the same format as the earlier DSDL reports:

```text
\begin{dsdlcodeblock}
\begin{verbatim}
<exact source line number>  <exact source text>
\end{verbatim}
\end{dsdlcodeblock}
```

Each excerpt is copied from the current source and preserves its exact line
numbers. Focused excerpts cover sender output/state behavior, receiver
synchronization and frame validation, top-level loopback wiring, and the
self-checking test methodology. Full files are not duplicated unnecessarily.

## Waveform Evidence

Every image uses `[H]`, has a caption and label, is referenced in preceding text,
and is followed immediately by a Persian explanation of stimulus, exact values,
visible transitions, expected behavior, and conclusion.

- `uart_valid_sender.png` and `uart_valid_receiver.png`: valid `7'b1011001`
  (`0x59`), XOR parity `0`, frame timing, synchronization, reconstructed data,
  and aligned valid completion.
- `uart_parity_error.png`: valid seed `0x59`, then `0x2D` with inverted parity
  `1`; the invalid completion does not update `rec_data`.
- `uart_stop_error.png`: valid seed `0x59`, then `0x2D` with correct parity and
  stop bit `0`; the second frame is rejected.
- `uart_back_to_back.png`: ordered valid frames `0x59` then `0x2D`, with two
  successful completions at the first legal consecutive opportunity.
- `uart_busy_ignore.png`: accepted `0x59` plus a request for `0x2D` during
  `busy`; the active frame remains unchanged and no second completion appears.
- `uart_reset_idle.png`: `send_data = 0x7F`, `new_data = 0`, active-low reset,
  defined idle outputs, and stable idle behavior after reset release.
- `uart_output_pulses.png`: valid loopback `0x59` produces aligned one-clock
  completion/validity pulses; raw `0x59` with inverted parity produces a
  one-clock completion while validity remains low.
- `uart_false_start.png`: a 10 ns low pulse is shorter than the 50 ns midpoint
  threshold at `BIT_TICKS = 10`; no completion occurs, and the following valid
  `0x59` frame proves recovery.
- `uart_all_values_1.png` through `uart_all_values_4.png`: progressive views of
  the exhaustive seven-bit sweep. The report distinguishes the portions visible
  in the images from the complete `0x00` through `0x7F` self-check performed by
  the testbench and confirmed by its terminal result.

Image paths contain filenames only, without directory prefixes.

## Transcript

The report includes the exact `$display` output from the aggregate `Tester` run,
ending in `PASS: complete DSDL7 UART regression`. It is presented as simulator
text output, not as a fabricated ModelSim screenshot.

## Quartus Placeholders

Three `[H]` figures reserve these exact filenames:

- `quartus_analysis_synthesis.png`
- `quartus_rtl_viewer.png`
- `quartus_resource_utilization.png`

The accompanying prose explains what each figure demonstrates but does not claim
unavailable device-specific synthesis results.

## Style and Evidence Boundaries

- Formal Persian with Persian letters/digits, correct half-spaces and
  punctuation, and no short-vowel diacritics.
- English technical identifiers use the template's LTR commands.
- No external citations, URLs, bibliography, title material, invented
  measurements, invented screenshots, or unverified Quartus resource numbers.
- The report describes verified Icarus/GTKWave evidence accurately and does not
  relabel it as ModelSim output.

## Verification

After writing, perform text-only checks for balanced environments, exact code
line numbers, use of all supplied figures, filename-only image references,
`[H]` placement, captions/labels/preceding references, transcript accuracy,
Persian consistency, and coverage of every explicit PDF report requirement.
Do not compile TeX.
