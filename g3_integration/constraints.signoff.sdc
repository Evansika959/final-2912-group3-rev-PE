create_clock -name clk -period 60.0 [get_ports clk]
create_clock -name clk_b -period 60.0 [get_ports clk_b]
create_clock -name spi_clk -period 160.0 [get_ports spi_clk]
set_false_path -from [get_ports rst_n]

# Set Clock Uncertainties, Latency and Transition
set_clock_uncertainty   -setup  0.4    [get_clocks clk]
set_clock_uncertainty   -hold   0.4    [get_clocks clk]
set_clock_latency               0      [get_clocks clk]
set_clock_transition            0.4    [get_clocks clk]

set_clock_uncertainty   -setup  0.4    [get_clocks clk_b]
set_clock_uncertainty   -hold   0.4    [get_clocks clk_b]
set_clock_latency               0      [get_clocks clk_b]
set_clock_transition            0.4    [get_clocks clk_b]

set_clock_uncertainty   -setup  0.4    [get_clocks spi_clk]
set_clock_uncertainty   -hold   0.4    [get_clocks spi_clk]
set_clock_latency               0      [get_clocks spi_clk]
set_clock_transition            0.4    [get_clocks spi_clk]

# Clock Relations
set_clock_groups -asynchronous -group spi_clk -group clk


# -clock_fall ： set_input_delay 是相对于时钟的下降沿
set_input_delay             5   [get_ports spi_mosi]    -clock spi_clk  -clock_fall
set_input_delay             5   [get_ports spi_csn]     -clock spi_clk  -clock_fall
set_output_delay            5   [get_ports spi_miso]    -clock spi_clk

set input_delay         10
set output_delay        10
set_output_delay            $output_delay   [all_outputs]   -clock clk

set_max_fanout 32 [current_design]
set_load 0.1 [all_outputs]
set_driving_cell -lib_cell gf180mcu_fd_sc_mcu7t5v0__buf_4 [all_inputs]