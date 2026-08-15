# Run

From the project directory:

```bash
mkdir -p .build

iverilog -g2012 -Wall -s tb_comparator_4bit -o .build/comparator4.out comparator_1bit.v comparator_4bit.v tb_comparator_4bit.v
vvp .build/comparator4.out

iverilog -g2012 -Wall -s tb_serial_comparator -o .build/serial.out serial_comparator.v tb_serial_comparator.v
vvp .build/serial.out
```

Expected output:

```text
PASS: all 256 four-bit comparisons
PASS: all 256 serial comparisons at every prefix
```

## Serial waveform

Generate the waveform for `1010` compared with `1001`:

```bash
iverilog -g2012 -Wall -s tb_serial_waveform -o .build/waveform.out serial_comparator.v tb_serial_waveform.v
vvp .build/waveform.out
gtkwave .build/serial_waveform.vcd
```

If `gtkwave` is missing:

```bash
sudo apt install gtkwave
```
