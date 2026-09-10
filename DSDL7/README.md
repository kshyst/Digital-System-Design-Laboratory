## Tester

```bash
iverilog -g2012 -Wall -s Tester -o /tmp/Tester.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/Tester.v && vvp /tmp/Tester.vvp && gtkwave /tmp/Tester.vcd
```

## tb_uart_frame_format

```bash
iverilog -g2012 -Wall -s tb_uart_frame_format -o /tmp/tb_uart_frame_format.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_frame_format.v && vvp /tmp/tb_uart_frame_format.vvp && gtkwave /tmp/tb_uart_frame_format.vcd
```

## tb_uart_valid

```bash
iverilog -g2012 -Wall -s tb_uart_valid -o /tmp/tb_uart_valid.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_valid.v && vvp /tmp/tb_uart_valid.vvp && gtkwave /tmp/tb_uart_valid.vcd
```

## tb_uart_parity_error

```bash
iverilog -g2012 -Wall -s tb_uart_parity_error -o /tmp/tb_uart_parity_error.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_parity_error.v && vvp /tmp/tb_uart_parity_error.vvp && gtkwave /tmp/tb_uart_parity_error.vcd
```

## tb_uart_stop_error

```bash
iverilog -g2012 -Wall -s tb_uart_stop_error -o /tmp/tb_uart_stop_error.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_stop_error.v && vvp /tmp/tb_uart_stop_error.vvp && gtkwave /tmp/tb_uart_stop_error.vcd
```

## tb_uart_back_to_back

```bash
iverilog -g2012 -Wall -s tb_uart_back_to_back -o /tmp/tb_uart_back_to_back.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_back_to_back.v && vvp /tmp/tb_uart_back_to_back.vvp && gtkwave /tmp/tb_uart_back_to_back.vcd
```

## tb_uart_busy_ignore

```bash
iverilog -g2012 -Wall -s tb_uart_busy_ignore -o /tmp/tb_uart_busy_ignore.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_busy_ignore.v && vvp /tmp/tb_uart_busy_ignore.vvp && gtkwave /tmp/tb_uart_busy_ignore.vcd
```

## tb_uart_reset_idle

```bash
iverilog -g2012 -Wall -s tb_uart_reset_idle -o /tmp/tb_uart_reset_idle.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_reset_idle.v && vvp /tmp/tb_uart_reset_idle.vvp && gtkwave /tmp/tb_uart_reset_idle.vcd
```

## tb_uart_output_pulses

```bash
iverilog -g2012 -Wall -s tb_uart_output_pulses -o /tmp/tb_uart_output_pulses.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_output_pulses.v && vvp /tmp/tb_uart_output_pulses.vvp && gtkwave /tmp/tb_uart_output_pulses.vcd
```

## tb_uart_all_values

```bash
iverilog -g2012 -Wall -s tb_uart_all_values -o /tmp/tb_uart_all_values.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_all_values.v && vvp /tmp/tb_uart_all_values.vvp && gtkwave /tmp/tb_uart_all_values.vcd
```

## tb_uart_false_start

```bash
iverilog -g2012 -Wall -s tb_uart_false_start -o /tmp/tb_uart_false_start.vvp /home/kshyst/Desktop/University/DSDL/DSDL7/UARTSender.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTReceiver.v /home/kshyst/Desktop/University/DSDL/DSDL7/UARTTop.v /home/kshyst/Desktop/University/DSDL/DSDL7/tb_uart_false_start.v && vvp /tmp/tb_uart_false_start.vvp && gtkwave /tmp/tb_uart_false_start.vcd
```
