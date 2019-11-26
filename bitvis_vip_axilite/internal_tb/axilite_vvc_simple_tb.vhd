--========================================================================================================================
-- Copyright (c) 2017 by Bitvis AS.  All rights reserved.
-- You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not,
-- contact Bitvis AS <support@bitvis.no>.
--
-- UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
-- OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR OTHER DEALINGS IN UVVM.
--========================================================================================================================

------------------------------------------------------------------------------------------
-- Description   : See library quick reference (under 'doc') and README-file(s)
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_axilite;
context bitvis_vip_axilite.vvc_context;
use bitvis_vip_axilite.axilite_bfm_pkg.all;
use bitvis_vip_axilite.transaction_pkg.all;


-- Test case entity
entity axilite_vvc_simple_tb is
  generic (
    GC_TEST : string := "UVVM"
    );
end entity;

-- Test case architecture
architecture func of axilite_vvc_simple_tb is

  constant C_CLK_PERIOD : time := 10 ns;
  constant C_ADDR_WIDTH_1 : natural := 32;
  constant C_DATA_WIDTH_1 : natural := 32;
  constant C_ADDR_WIDTH_2 : natural := 32;
  constant C_DATA_WIDTH_2 : natural := 64;

  signal clk        : std_logic := '0';
  signal areset     : std_logic := '0';
  signal clock_ena  : boolean   := false;

  -- signals
  -- The axilite interface is gathered in one record, so procedures that use the
  -- axilite interface have less arguments
  signal axilite_if_1       : t_axilite_if( write_address_channel(  awaddr( C_ADDR_WIDTH_1    -1 downto 0)),
                                            write_data_channel(     wdata(  C_DATA_WIDTH_1    -1 downto 0),
                                                                    wstrb(( C_DATA_WIDTH_1/8) -1 downto 0)),
                                            read_address_channel(   araddr( C_ADDR_WIDTH_1    -1 downto 0)),
                                            read_data_channel(      rdata(  C_DATA_WIDTH_1    -1 downto 0))) := init_axilite_if_signals(C_ADDR_WIDTH_1, C_DATA_WIDTH_1);


  signal axilite_if_2       : t_axilite_if( write_address_channel(  awaddr( C_ADDR_WIDTH_2    -1 downto 0)),
                                            write_data_channel(     wdata(  C_DATA_WIDTH_2    -1 downto 0),
                                                                    wstrb(( C_DATA_WIDTH_2/8) -1 downto 0)),
                                            read_address_channel(   araddr( C_ADDR_WIDTH_2    -1 downto 0)),
                                            read_data_channel(      rdata(  C_DATA_WIDTH_2    -1 downto 0))) := init_axilite_if_signals(C_ADDR_WIDTH_2, C_DATA_WIDTH_2);


  signal read_data_interface_1  : std_logic_vector(C_DATA_WIDTH_1-1 downto 0);
  signal read_data_interface_2  : std_logic_vector(C_DATA_WIDTH_2-1 downto 0);

begin
  -----------------------------
  -- Instantiate Testharness
  -----------------------------
  i_axilite_test_harness : entity bitvis_vip_axilite.test_harness(struct_vvc)
      generic map(
        C_DATA_WIDTH_1  => C_DATA_WIDTH_1,
        C_ADDR_WIDTH_1  => C_ADDR_WIDTH_1,
        C_DATA_WIDTH_2  => C_DATA_WIDTH_2,
        C_ADDR_WIDTH_2  => C_ADDR_WIDTH_2
      )
      port map(
        clk          => clk,
        areset       => areset,
        axilite_if_1 => axilite_if_1,
        axilite_if_2 => axilite_if_2
      );

  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  -- Set up clock generator
  p_clock: clock_generator(clk, clock_ena, C_CLK_PERIOD, "Axilite CLK");

  ------------------------------------------------
  -- PROCESS: p_main
  ------------------------------------------------
  p_main: process
    constant C_SCOPE              : string  := C_TB_SCOPE_DEFAULT;

    -- BFM config
    variable axilite_bfm_config   : t_axilite_bfm_config := C_AXILITE_BFM_CONFIG_DEFAULT;

    variable v_irq_mask           : std_logic_vector(7 downto 0);
    variable v_irq_mask_inv       : std_logic_vector(7 downto 0);
    variable i                    : integer;
    variable v_timestamp          : time;

    variable v_cmd_idx            : natural;
    variable v_is_ok              : boolean;
    variable v_data               : work.vvc_cmd_pkg.t_vvc_result;


  begin

    -- To avoid that log files from different test cases (run in separate
    -- simulations) overwrite each other.
    set_log_file_name(GC_TEST & "_Log.txt");
    set_alert_file_name(GC_TEST & "_Alert.txt");


    await_uvvm_initialization(VOID);

    -- override default config with settings for this testbench
    axilite_bfm_config.clock_period             := C_CLK_PERIOD;
    axilite_bfm_config.max_wait_cycles          := 10;
    axilite_bfm_config.max_wait_cycles_severity := ERROR;
    axilite_bfm_config.num_aw_pipe_stages       := 2;
    axilite_bfm_config.num_w_pipe_stages        := 1;
    axilite_bfm_config.num_ar_pipe_stages       := 2;
    axilite_bfm_config.num_r_pipe_stages        := 1;
    axilite_bfm_config.num_b_pipe_stages        := 2;

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    disable_log_msg(ALL_MESSAGES);
    enable_log_msg(ID_LOG_HDR);
    enable_log_msg(ID_SEQUENCER);

    disable_log_msg(AXILITE_VVCT,1, ALL_MESSAGES);
    disable_log_msg(AXILITE_VVCT,2, ALL_MESSAGES);
    enable_log_msg(AXILITE_VVCT, 1, ID_BFM);
    enable_log_msg(AXILITE_VVCT, 2, ID_BFM);
    enable_log_msg(AXILITE_VVCT, 1, ID_IMMEDIATE_CMD);
    enable_log_msg(AXILITE_VVCT, 2, ID_IMMEDIATE_CMD);


    log(ID_LOG_HDR, "Start Simulation of AXI-Lite");
    ------------------------------------------------------------
    clock_ena <= true; -- the axilite_reset routine assumes the clock is running
    gen_pulse(areset, 10*C_CLK_PERIOD, "Pulsing reset for 10 clock periods");

    log("Do some axilite writes");
    -- write some data; the current axislave isn't very implemented - doesn't
    -- have FIFO, and just has one RW slave register at addr_valueess 0x6000

    -- Write to VVC 1
    axilite_write(AXILITE_VVCT,1, x"0000", x"5555", "Test of axilite write");
    axilite_write(AXILITE_VVCT,1, x"1000", x"befbeef","Write"); -- op0
    axilite_write(AXILITE_VVCT,1, x"2000", x"efbeef","Write");  -- op1
    axilite_write(AXILITE_VVCT,1, x"3000", x"beef","Write");    -- op2
    axilite_write(AXILITE_VVCT,1, x"6000", x"54321","Write");   -- rw reg

    -- Read from VVC 1
    axilite_read(AXILITE_VVCT, 1, x"3000", x"0"); -- just do a read
    axilite_read(AXILITE_VVCT, 1, x"6000", x"0"); -- do another read - should see this data

    -- verify read data on interface 1
    v_cmd_idx := get_last_received_cmd_idx(AXILITE_VVCT, 1);
    await_completion(AXILITE_VVCT, 1, v_cmd_idx, 1 us, "waiting for axilite_read() to finish");
    fetch_result(AXILITE_VVCT, 1, v_cmd_idx, v_data, v_is_ok, "Fetching read-result.");
    check_value(v_is_ok, ERROR, "Readback OK via fetch_result()");
    check_value(v_data(C_DATA_WIDTH_1-1 downto 0), x"54321", error, "verifying read data on interface 1.");

    -- Write to VVC 2
    axilite_write(AXILITE_VVCT,2, x"0000", x"5555", to_string("Test of axilite write"));
    axilite_write(AXILITE_VVCT,2, x"0010", x"befbeef","Write"); -- op0
    axilite_write(AXILITE_VVCT,2, x"0020", x"efbeef","Write");  -- op1
    axilite_write(AXILITE_VVCT,2, x"0030", x"beef","Write");    -- op2
    axilite_write(AXILITE_VVCT,2, x"0040", x"54321","Write");   -- op3
    axilite_write(AXILITE_VVCT,2, x"0060", x"f00b0","Write");   -- rw reg

    -- Read from VVC 2
    axilite_read(AXILITE_VVCT, 2, x"0040", x"0"); -- just do a read
    axilite_read(AXILITE_VVCT, 2, x"0040", x"0"); -- do another read
    axilite_read(AXILITE_VVCT, 2, x"0060", x"0"); -- do another read - should see this data

    -- verify read data on interface 2
    v_cmd_idx := get_last_received_cmd_idx(AXILITE_VVCT, 2);
    await_completion(AXILITE_VVCT, 2, v_cmd_idx, 1 us, "waiting for axilite_read() to finish");
    fetch_result(AXILITE_VVCT, 2, v_cmd_idx, v_data, v_is_ok, "Fetching read-result.");
    check_value(v_is_ok, ERROR, "Readback OK via fetch_result()");
    check_value(v_data(C_DATA_WIDTH_2-1 downto 0), x"f00b0", error, "verifying read data on interface 2.");



    -- check that is was correctly written on VVC 1
    axilite_check(AXILITE_VVCT,1, x"0006000", x"54321","Check");
    axilite_write(AXILITE_VVCT,1, x"0006000", x"abba1972","Write");
    axilite_check(AXILITE_VVCT,1, x"0006000", x"abba1972","Check");

    -- check that is was correctly written on VVC 2
    axilite_check(AXILITE_VVCT,2, x"0000", x"5555","Check");
    axilite_check(AXILITE_VVCT,2, x"0010", x"befbeef","Check");
    axilite_check(AXILITE_VVCT,2, x"0020", x"efbeef","Check");
    axilite_check(AXILITE_VVCT,2, x"0030", x"beef","Check");
    axilite_check(AXILITE_VVCT,2, x"0040", x"54321","Check");
    axilite_write(AXILITE_VVCT,2, x"0000040", x"abba1972","Write");
    axilite_check(AXILITE_VVCT,2, x"0000040", x"abba1972","Check");

    -- Await completion on both VVCs
    await_completion(AXILITE_VVCT, 1, 1000 ns);
    await_completion(AXILITE_VVCT, 2, 1000 ns);

    log(ID_LOG_HDR, "Test of timeout of check", C_SCOPE);

    -- verify that a warning arises if the data is not what is expected
    increment_expected_alerts(WARNING, 1);
    axilite_check(AXILITE_VVCT,1, x"0006000", x"00000000", "Write", WARNING);
    await_completion(AXILITE_VVCT, 1, 1000 ns);

    -- verify that a warning arises if the data is not what is expected
    increment_expected_alerts(WARNING, 1);
    axilite_check(AXILITE_VVCT,2, x"0000040", x"00000000", "Check", WARNING);
    await_completion(AXILITE_VVCT, 2, 1000 ns);


    log(ID_LOG_HDR, "Test with byte enable", C_SCOPE);

    axilite_write(AXILITE_VVCT,1, x"0006000", x"0","Clearing register");
    axilite_write(AXILITE_VVCT,1, x"0006000", x"dada1960", std_logic_vector'("0011"), "Write to only byte 0 and 1");
    axilite_check(AXILITE_VVCT,1, x"0006000", x"00001960","Checking that only byte 0 and 1 were set");
    axilite_write(AXILITE_VVCT,1, x"0006000", x"0","Clearing register");
    axilite_write(AXILITE_VVCT,1, x"0006000", x"dada1960", std_logic_vector'("1100"), "Write to only byte 2 and 3");
    axilite_check(AXILITE_VVCT,1, x"0006000", x"dada0000","Checking that only byte 2 and 3 were set");


    axilite_write(AXILITE_VVCT,2, x"0000040", x"0","Clearing register");
    axilite_write(AXILITE_VVCT,2, x"0000040", x"abba1972", std_logic_vector'("00000011"), "Write to only byte 0 and 1");
    axilite_check(AXILITE_VVCT,2, x"0000040", x"00001972","Checking that only byte 0 and 1 were set");
    axilite_write(AXILITE_VVCT,2, x"0000040", x"0","Clearing register");
    axilite_write(AXILITE_VVCT,2, x"0000040", x"abba1972", std_logic_vector'("00001100"), "Write to only byte 2 and 3");
    axilite_check(AXILITE_VVCT,2, x"0000040", x"abba0000","Checking that only byte 2 and 3 were set");


    -- Await completion on both VVCs
    await_completion(AXILITE_VVCT, 1, 1000 ns);
    await_completion(AXILITE_VVCT, 2, 1000 ns);


    log(ID_LOG_HDR, "Testing inter-bfm delay");

    log("\rChecking TIME_START2START");
    wait for C_CLK_PERIOD * 51;
    wait until rising_edge(clk);
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_type := TIME_START2START;
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_in_time := C_CLK_PERIOD * 50;
    v_timestamp := now;
    axilite_write(AXILITE_VVCT,1, x"0000", x"1111", "First inter-bfm delay axilite write");
    axilite_write(AXILITE_VVCT,1, x"0000", x"a1a1", "Second inter-bfm delay axilite write");
    await_completion(AXILITE_VVCT, 1, (56 * C_CLK_PERIOD));
    check_value(((now - v_timestamp) = C_CLK_PERIOD*55+C_CLK_PERIOD/4), ERROR, "Checking that inter-bfm delay was upheld");

    log("\rChecking that insert_delay does not affect inter-BFM delay");
    wait for C_CLK_PERIOD * 51;
    wait until rising_edge(clk);
    v_timestamp := now;
    axilite_write(AXILITE_VVCT,1, x"0000", x"ffff", "Third inter-bfm delay axilite write");
    insert_delay(AXILITE_VVCT,1, C_CLK_PERIOD);
    insert_delay(AXILITE_VVCT,1, C_CLK_PERIOD);
    insert_delay(AXILITE_VVCT,1, C_CLK_PERIOD);
    insert_delay(AXILITE_VVCT,1, C_CLK_PERIOD);
    axilite_write(AXILITE_VVCT,1, x"0000", x"abcd", "Fourth inter-bfm delay axilite write");
    await_completion(AXILITE_VVCT, 1, 56 * C_CLK_PERIOD + (4*C_CLK_PERIOD));
    check_value(((now - v_timestamp) = C_CLK_PERIOD*55+C_CLK_PERIOD/4 + (4*C_CLK_PERIOD)), ERROR, "Checking that inter-bfm delay was upheld");


    log("\rChecking TIME_FINISH2START");
    wait for C_CLK_PERIOD * 101;
    wait until rising_edge(clk);
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_type := TIME_FINISH2START;
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_in_time := C_CLK_PERIOD * 100;
    v_timestamp := now;
    axilite_write(AXILITE_VVCT,1, x"0000", x"0001", "First inter-bfm delay axilite write");
    axilite_write(AXILITE_VVCT,1, x"0000", x"1000", "Second inter-bfm delay axilite write");
    await_completion(AXILITE_VVCT, 1, 111 * C_CLK_PERIOD);
    check_value(((now - v_timestamp) = C_CLK_PERIOD*110+C_CLK_PERIOD/4), ERROR, "Checking that inter-bfm delay was upheld");

    log("\rChecking TIME_START2START and provoking inter-bfm delay violation");
    wait for C_CLK_PERIOD * 10;
    increment_expected_alerts(TB_WARNING,2);
    shared_axilite_vvc_config(1).inter_bfm_delay.inter_bfm_delay_violation_severity := TB_WARNING;
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_type := TIME_START2START;
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_in_time := C_CLK_PERIOD;
    axilite_write(AXILITE_VVCT,1, x"0000", x"0001", "First inter-bfm delay axilite write");
    axilite_write(AXILITE_VVCT,1, x"0000", x"1000", "Second inter-bfm delay axilite write");
    await_completion(AXILITE_VVCT, 1, 111 * C_CLK_PERIOD);

    log("Setting delay back to initial value");
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_type := NO_DELAY;
    shared_axilite_vvc_config(1).inter_bfm_delay.delay_in_time := 0 ns;



    -----------------------------------------------------------------------------
    -- Ending the simulation
    -----------------------------------------------------------------------------
    wait for 1000 ns;             -- to allow some time for completion
    report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    -- Finish the simulation
    std.env.stop;
    wait;  -- to stop completely

  end process p_main;
end func;