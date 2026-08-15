# 50 MHz reference oscillator (typical Cyclone IV lab board), used only to
# determine the design's achievable Fmax on this device -- the design itself
# runs correctly at any clock enable rate, per the report's frequency
# analysis (a ~1 Hz logical update rate derived from a clock-enable divider).
create_clock -name clk -period 20.000 [get_ports clk]
derive_clock_uncertainty
