# Testbench

Run from the `DSDL5` directory:

## Normal run

```bash
iverilog -Wall -g2005-sv -s booth_multiplier_tb -o booth_tb.out \
  barrel_ashr.v skip_encode.v booth_datapath.v \
  booth_control.v booth_multiplier.v booth_multiplier_tb.v
vvp booth_tb.out
```

## Open waveform

```bash
gtkwave booth_multiplier_tb.vcd
```

## Simple 3 x 7 test

```bash
iverilog -Wall -g2005-sv -s booth_multiplier_3x7_tb -o booth_3x7_tb.out \
  barrel_ashr.v skip_encode.v booth_datapath.v \
  booth_control.v booth_multiplier.v booth_multiplier_3x7_tb.v
vvp booth_3x7_tb.out
gtkwave booth_multiplier_3x7_tb.vcd
```
