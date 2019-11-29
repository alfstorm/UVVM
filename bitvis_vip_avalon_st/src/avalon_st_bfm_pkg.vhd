--================================================================================================================================
-- Copyright (c) 2019 by Bitvis AS.  All rights reserved.
-- You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not,
-- contact Bitvis AS <support@bitvis.no>.
--
-- UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
-- THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
-- OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR OTHER DEALINGS IN UVVM.
--================================================================================================================================

---------------------------------------------------------------------------------------------
-- Description : See library quick reference (under 'doc') and README-file(s)
---------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library std;
use std.textio.all;

--================================================================================================================================
--================================================================================================================================
package avalon_st_bfm_pkg is

  --==========================================================================================
  -- Types and constants for AVALON_ST BFM
  --==========================================================================================
  constant C_SCOPE : string := "AVALON_ST BFM";

  constant C_MAX_BITS_PER_SYMBOL  : positive := 512; -- Recommended maximum in protocol specification (MNL-AVABUSREF)
  constant C_MAX_SYMBOLS_PER_BEAT : positive := 32;  -- Recommended maximum in protocol specification (MNL-AVABUSREF)

  -- Interface record for BFM signals
  type t_avalon_st_if is record
    channel         : std_logic_vector; -- Channel number for data being transferred on the current cycle.
    data            : std_logic_vector; -- Data. Width is constrained when the procedure is called.
    data_error      : std_logic_vector; -- Bit mask to mark errors affecting the data on the current cycle. (NOT IMPLEMENTED)
    ready           : std_logic;        -- Backpressure.
    valid           : std_logic;        -- Data valid.
    empty           : std_logic_vector; -- Number of symbols that are empty (not valid).
    end_of_packet   : std_logic;        -- Active during the last symbol of the packet.
    start_of_packet : std_logic;        -- Active during the first symbol of the packet.
  end record;

  -- Configuration record to be assigned in the test harness.
  type t_avalon_st_bfm_config is
  record
    max_wait_cycles             : integer;       -- Used for setting the maximum cycles to wait before an alert is issued when
                                                 -- waiting for ready or valid signals from the DUT.
    max_wait_cycles_severity    : t_alert_level; -- Severity if max_wait_cycles expires.
    clock_period                : time;          -- Period of the clock signal.
    --clock_period_margin         : time;          -- Input clock period margin to specified clock_period
    --clock_margin_severity       : t_alert_level; -- The above margin will have this severity
    setup_time                  : time;          -- Setup time for generated signals, set to clock_period/4
    hold_time                   : time;          -- Hold time for generated signals, set to clock_period/4
    symbol_width                : natural;       -- Number of data bits per symbol.
    first_symbol_in_msb         : boolean;       -- Symbol ordering. When true, first-order symbol is in most significant bits.
    max_channel                 : natural;       -- Maximum number of channels that the interface supports.
    use_packet_transfer         : boolean;       -- When true, packet signals are enabled: start_of_packet, end_of_packet & empty.
    id_for_bfm                  : t_msg_id;      -- The message ID used as a general message ID in the BFM
  end record;

  -- Define the default value for the BFM config
  constant C_AVALON_ST_BFM_CONFIG_DEFAULT : t_avalon_st_bfm_config := (
    max_wait_cycles             => 100,
    max_wait_cycles_severity    => ERROR,
    clock_period                => 0 ns,
    --clock_period_margin         => 0 ns,
    --clock_margin_severity       => TB_ERROR,
    setup_time                  => 0 ns,
    hold_time                   => 0 ns,
    symbol_width                => 8,
    first_symbol_in_msb         => true,
    max_channel                 => 0,
    use_packet_transfer         => true,
    id_for_bfm                  => ID_BFM
  );

  --==========================================================================================
  -- BFM procedures
  --==========================================================================================
  -- This function returns an Avalon-ST interface with initialized signals.
  -- All input signals are initialized to 0
  -- All output signals are initialized to Z
  function init_avalon_st_if_signals(
    is_master        : boolean; -- When true, this BFM drives data signals
    channel_width    : natural;
    data_width       : natural;
    data_error_width : natural;
    empty_width      : natural
  ) return t_avalon_st_if;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Transmit
  -- BFM -> DUT
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_transmit (
    constant channel_value    : in    std_logic_vector;
    constant data_array       : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  );

  procedure avalon_st_transmit (
    constant data_array       : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  );

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Receive
  -- DUT -> BFM
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_receive (
    variable channel_value    : out   std_logic_vector;
    variable data_array       : out   t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT;
    constant ext_proc_call    : in    string := ""  -- External proc_call. Overwrite if called from other BFM procedure
  );

  procedure avalon_st_receive (
    variable data_array       : out   t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT;
    constant ext_proc_call    : in    string := ""  -- External proc_call. Overwrite if called from other BFM procedure
  );

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Expect
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_expect (
    constant channel_exp      : in    std_logic_vector;
    constant data_exp         : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant alert_level      : in    t_alert_level          := error;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  );

  procedure avalon_st_expect (
    constant data_exp         : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant alert_level      : in    t_alert_level          := error;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  );

end package avalon_st_bfm_pkg;


--================================================================================================================================
--================================================================================================================================
package body avalon_st_bfm_pkg is

  function init_avalon_st_if_signals(
    is_master        : boolean; -- When true, this BFM drives data signals
    channel_width    : natural;
    data_width       : natural;
    data_error_width : natural;
    empty_width      : natural
  ) return t_avalon_st_if is
    variable init_if : t_avalon_st_if(channel(channel_width-1 downto 0),
                                      data(data_width-1 downto 0),
                                      data_error(data_error_width-1 downto 0),
                                      empty(empty_width-1 downto 0));
  begin
    if is_master then
      -- from slave to master
      init_if.ready           := 'Z';
      -- from master to slave
      init_if.channel         := (init_if.channel'range => '0');
      init_if.data            := (init_if.data'range => '0');
      init_if.data_error      := (init_if.data_error'range => '0');
      init_if.valid           := '0';
      init_if.empty           := (init_if.empty'range => '0');
      init_if.end_of_packet   := '0';
      init_if.start_of_packet := '0';
    else
      -- from slave to master
      init_if.ready           := '0';
      -- from master to slave
      init_if.channel         := (init_if.channel'range => 'Z');
      init_if.data            := (init_if.data'range => 'Z');
      init_if.data_error      := (init_if.data_error'range => 'Z');
      init_if.valid           := 'Z';
      init_if.empty           := (init_if.empty'range => 'Z');
      init_if.end_of_packet   := 'Z';
      init_if.start_of_packet := 'Z';
    end if;
    return init_if;
  end function;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Transmit
  -- BFM -> DUT
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_transmit (
    constant channel_value    : in    std_logic_vector;
    constant data_array       : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  ) is
    constant proc_name : string := "avalon_st_transmit";
    constant proc_call : string := proc_name & "(" & to_string(data_array'length) & " sym, ch:" &
                                   to_string(channel_value, DEC, AS_IS) & ")";
    constant c_sym_width        : natural := config.symbol_width;
    constant c_symbols_per_beat : natural := avalon_st_if.data'length/config.symbol_width; -- Number of symbols transferred per cycle
    -- Normalize to the DUT channel/data widths
    variable v_normalized_chan : std_logic_vector(channel_value'length-1 downto 0) :=
      normalize_and_check(channel_value, avalon_st_if.channel, ALLOW_NARROWER, "channel", "avalon_st_if.channel", msg);
    variable v_normalized_data : t_slv_array(0 to data_array'length-1)(data_array(data_array'low)'length-1 downto 0) := data_array;
    -- Helper variables
    variable v_symbol_array      : t_slv_array_ptr;
    variable v_sym_in_beat       : natural := 0;
    variable v_data_offset       : natural := 0;
    variable v_wait_for_transfer : boolean := false;
  begin

    check_value(c_sym_width <= C_MAX_BITS_PER_SYMBOL, TB_FAILURE, "Sanity check: Check that symbol_width doesn't exceed C_MAX_BITS_PER_SYMBOL.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(c_symbols_per_beat <= C_MAX_SYMBOLS_PER_BEAT, TB_FAILURE, "Sanity check: Check that c_symbols_per_beat doesn't exceed C_MAX_SYMBOLS_PER_BEAT.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(to_integer(unsigned(v_normalized_chan)) <= config.max_channel, TB_FAILURE, "Sanity check: Check that channel number is supported.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(avalon_st_if.data'length mod c_sym_width = 0, TB_FAILURE, "Sanity check: Check that data width is a multiple of symbol_width.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(avalon_st_if.empty'length = log2(c_symbols_per_beat), TB_FAILURE, "Sanity check: Check that empty width equals log2(symbols_per_beat).", scope, ID_NEVER, msg_id_panel, proc_call);
    if config.use_packet_transfer then
      check_value(data_array(data_array'low)'length = c_sym_width, TB_FAILURE, "Sanity check: (Packet mode) Check that data_array elements have the size of the configured symbol.", scope, ID_NEVER, msg_id_panel, proc_call);
    else
      check_value(data_array(data_array'low)'length = avalon_st_if.data'length, TB_FAILURE, "Sanity check: (Stream mode) Check that data_array elements have the size of the data bus.", scope, ID_NEVER, msg_id_panel, proc_call);
    end if;
    check_value(data_array'ascending, TB_FAILURE, "Sanity check: Check that data_array is ascending (defined with 'to'), for symbol order clarity.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(config.clock_period /= 0 ns, TB_FAILURE, "Sanity check: Check that clock_period is set.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(config.setup_time < config.clock_period/2, TB_FAILURE, "Sanity check: Check that setup_time do not exceed clock_period/2.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(config.hold_time < config.clock_period/2, TB_FAILURE, "Sanity check: Check that hold_time do not exceed clock_period/2.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(config.setup_time > 0 ns, TB_FAILURE, "Sanity check: Check that setup_time is more than 0 ns.", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(config.hold_time > 0 ns, TB_FAILURE, "Sanity check: Check that hold_time is more than 0 ns.", scope, ID_NEVER, msg_id_panel, proc_call);

    -- Use a symbol array to make it easier to iterate through the data
    if config.use_packet_transfer then
      v_symbol_array := new t_slv_array(0 to v_normalized_data'length-1)(c_sym_width-1 downto 0);
      v_symbol_array.all := v_normalized_data;
    else
      v_symbol_array := new t_slv_array(0 to v_normalized_data'length*c_symbols_per_beat-1)(c_sym_width-1 downto 0);
      for i in 0 to v_normalized_data'length-1 loop
        for j in 0 to c_symbols_per_beat-1 loop
          if config.first_symbol_in_msb then
            v_data_offset := (c_symbols_per_beat-1-j)*c_sym_width;
          else
            v_data_offset := j*c_sym_width;
          end if;
          v_symbol_array(i*c_symbols_per_beat+j) := v_normalized_data(i)(v_data_offset+c_sym_width-1 downto v_data_offset);
        end loop;
      end loop;
    end if;

    avalon_st_if <= init_avalon_st_if_signals(is_master        => true, -- this BFM drives data signals
                                              channel_width    => avalon_st_if.channel'length,
                                              data_width       => avalon_st_if.data'length,
                                              data_error_width => avalon_st_if.data_error'length,
                                              empty_width      => avalon_st_if.empty'length);

    -- Start transmission during setup time
    wait_until_given_time_before_rising_edge(clk, config.setup_time, config.clock_period);

    log(ID_PACKET_INITIATE, proc_call & "=> " & add_msg_delimiter(msg), scope, msg_id_panel);

    ------------------------------------------------------------
    -- Send all the symbols in the symbol array
    ------------------------------------------------------------
    for symbol in 0 to v_symbol_array'high loop
      v_wait_for_transfer := false;

      -- Set the basic interface signals
      avalon_st_if.valid   <= '1';
      avalon_st_if.channel <= v_normalized_chan;
      -- Insert the symbols into the data bus according to the configured order
      if config.first_symbol_in_msb then
        v_data_offset := (c_symbols_per_beat-1-v_sym_in_beat)*c_sym_width;
      else
        v_data_offset := v_sym_in_beat*c_sym_width;
      end if;
      avalon_st_if.data(v_data_offset+c_sym_width-1 downto v_data_offset) <= v_symbol_array(symbol);
      log(ID_PACKET_DATA, proc_call & "=> " & to_string(v_symbol_array(symbol), HEX, AS_IS, INCL_RADIX) & " (symbol# " &
        to_string(symbol) & "). " & add_msg_delimiter(msg), scope, msg_id_panel);

      -- Set the packet transfer signals
      if config.use_packet_transfer then
        avalon_st_if.start_of_packet <= '1' when symbol/c_symbols_per_beat = 0 else '0';
        avalon_st_if.end_of_packet   <= '1' when symbol = v_symbol_array'high else '0';
        if c_symbols_per_beat > 1 then
          avalon_st_if.empty <= std_logic_vector(to_unsigned(c_symbols_per_beat-1-v_sym_in_beat, avalon_st_if.empty'length));
        end if;
      end if;

      -- Counter for the symbol index within the current cycle
      if v_sym_in_beat = c_symbols_per_beat-1 then
        v_sym_in_beat       := 0;
        v_wait_for_transfer := true;
      else
        v_sym_in_beat       := v_sym_in_beat + 1;
      end if;

      -- Always transfer the data on the last cycle
      if symbol = v_symbol_array'high then
        v_wait_for_transfer := true;
      end if;

      if v_wait_for_transfer then
        -- check for ready ***
        wait until rising_edge(clk);
        -- check clock margin? ***

        -- Wait hold time specified in config record
        wait_until_given_time_after_rising_edge(clk, config.hold_time);

        -- Default values for the next clk cycle
        avalon_st_if <= init_avalon_st_if_signals(is_master        => true, -- this BFM drives data signals
                                                  channel_width    => avalon_st_if.channel'length,
                                                  data_width       => avalon_st_if.data'length,
                                                  data_error_width => avalon_st_if.data_error'length,
                                                  empty_width      => avalon_st_if.empty'length);
      end if;
    end loop;

    -- Done
    log(ID_PACKET_COMPLETE, proc_call & " DONE. " & add_msg_delimiter(msg), scope, msg_id_panel);
  end procedure;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Transmit
  -- BFM -> DUT
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_transmit (
    constant data_array       : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  ) is
    variable v_channel : std_logic_vector(avalon_st_if.channel'range) := (others => '0');
  begin
    avalon_st_transmit(v_channel, data_array, msg, clk, avalon_st_if, scope, msg_id_panel, config);
  end procedure;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Receive
  -- DUT -> BFM
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_receive (
    variable channel_value    : out   std_logic_vector;
    variable data_array       : out   t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT;
    constant ext_proc_call    : in    string := ""  -- External proc_call. Overwrite if called from other BFM procedure
  ) is  
    constant local_proc_name : string := "avalon_st_receive";  -- Internal proc_name; Used if called from sequencer or VVC
    constant local_proc_call : string := local_proc_name & "(" & to_string(data_array'length) & " sym)";
    constant c_sym_width        : natural := config.symbol_width;
    constant c_symbols_per_beat : natural := avalon_st_if.data'length/config.symbol_width; -- Number of symbols transferred per cycle
    -- Normalize to the DUT channel/data widths
    variable v_normalized_chan : std_logic_vector(channel_value'length-1 downto 0);
    variable v_normalized_data : t_slv_array(0 to data_array'length-1)(data_array(data_array'low)'length-1 downto 0);
    -- Helper variables
    variable v_proc_call         : line; -- Current proc_call, external or local
    variable v_symbol_array      : t_slv_array_ptr;
    variable v_sym_in_beat       : natural := 0;
    variable v_sym_cnt           : integer := 0;
    variable v_invalid_count     : integer := 0;  -- # cycles without valid being asserted
    variable v_done              : boolean := false;
    variable v_timeout           : boolean := false;
    variable v_empty_symbols     : natural := 0;
    variable v_data_offset       : natural := 0;
  begin

    -- If called from sequencer/VVC, show 'avalon_st_receive()...' in log
    if ext_proc_call = "" then
      write(v_proc_call, local_proc_call);
    -- If called from other BFM procedure like avalon_st_expect, log 'avalon_st_expect() while executing avalon_st_receive()...'
    else
      write(v_proc_call, ext_proc_call & " while executing " & local_proc_name);
    end if;

    check_value(c_sym_width <= C_MAX_BITS_PER_SYMBOL, TB_FAILURE, "Sanity check: Check that symbol_width doesn't exceed C_MAX_BITS_PER_SYMBOL.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(c_symbols_per_beat <= C_MAX_SYMBOLS_PER_BEAT, TB_FAILURE, "Sanity check: Check that c_symbols_per_beat doesn't exceed C_MAX_SYMBOLS_PER_BEAT.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(avalon_st_if.data'length mod c_sym_width = 0, TB_FAILURE, "Sanity check: Check that data width is a multiple of symbol_width.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(avalon_st_if.empty'length = log2(c_symbols_per_beat), TB_FAILURE, "Sanity check: Check that empty width equals log2(symbols_per_beat).", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    if config.use_packet_transfer then
      check_value(data_array(data_array'low)'length = c_sym_width, TB_FAILURE, "Sanity check: (Packet mode) Check that data_array elements have the size of the configured symbol.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    else
      check_value(data_array(data_array'low)'length = avalon_st_if.data'length, TB_FAILURE, "Sanity check: (Stream mode) Check that data_array elements have the size of the data bus.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    end if;
    check_value(data_array'ascending, TB_FAILURE, "Sanity check: Check that data_array is ascending (defined with 'to'), for symbol order clarity.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(config.clock_period /= 0 ns, TB_FAILURE, "Sanity check: Check that clock_period is set.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(config.setup_time < config.clock_period/2, TB_FAILURE, "Sanity check: Check that setup_time do not exceed clock_period/2.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(config.hold_time < config.clock_period/2, TB_FAILURE, "Sanity check: Check that hold_time do not exceed clock_period/2.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(config.setup_time > 0 ns, TB_FAILURE, "Sanity check: Check that setup_time is more than 0 ns.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    check_value(config.hold_time > 0 ns, TB_FAILURE, "Sanity check: Check that hold_time is more than 0 ns.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);

    -- Use a symbol array to make it easier to iterate through the data
    if config.use_packet_transfer then
      v_symbol_array := new t_slv_array(0 to v_normalized_data'length-1)(c_sym_width-1 downto 0);
    else
      v_symbol_array := new t_slv_array(0 to v_normalized_data'length*c_symbols_per_beat-1)(c_sym_width-1 downto 0);
    end if;

    avalon_st_if <= init_avalon_st_if_signals(is_master        => false,
                                              channel_width    => avalon_st_if.channel'length,
                                              data_width       => avalon_st_if.data'length,
                                              data_error_width => avalon_st_if.data_error'length,
                                              empty_width      => avalon_st_if.empty'length);

    -- Start reception during setup time
    wait_until_given_time_before_rising_edge(clk, config.setup_time, config.clock_period);

    log(ID_PACKET_INITIATE, v_proc_call.all & "=> " & add_msg_delimiter(msg), scope, msg_id_panel);

    while not(v_done) loop
      ------------------------------------------------------------
      -- Assert the ready signal (after valid is high)
      ------------------------------------------------------------
      if v_sym_in_beat = 0 then
        -- To receive the first byte wait until valid goes high before asserting ready
        if v_sym_cnt = 0 and avalon_st_if.valid = '0' and not(v_timeout) then
          wait until avalon_st_if.valid = '1' for (config.max_wait_cycles * config.clock_period);
          if avalon_st_if.valid = '1' then
            avalon_st_if.ready <= '1';
            if clk = '0' then
              -- Align sampling of the data with the rising edge of the clock
              wait until clk = '1';
            else
              -- Valid and Ready are high but it's already past the rising edge of the
              -- clock so the data must be sampled on the next cycle
              --v_sample_on_next_cycle := true; ***
            end if;
          else
            -- Valid timed out
            v_timeout := true;
            v_done    := true;
          end if;
        -- Valid was already high, assert ready right away
        else
          avalon_st_if.ready <= '1';
          -- Align sampling of the data with the rising edge of the clock
          wait until clk = '1';
        end if;
      end if;

      ------------------------------------------------------------
      -- Receive the data
      ------------------------------------------------------------
      if avalon_st_if.valid = '1' and avalon_st_if.ready = '1' then
        v_invalid_count := 0;

        -- Sample the symbols from the data bus according to the configured order
        if config.first_symbol_in_msb then
          v_data_offset := (c_symbols_per_beat-1-v_sym_in_beat)*c_sym_width;
        else
          v_data_offset := v_sym_in_beat*c_sym_width;
        end if;
        v_normalized_chan := avalon_st_if.channel;
        v_symbol_array(v_sym_cnt) := avalon_st_if.data(v_data_offset+c_sym_width-1 downto v_data_offset);
        log(ID_PACKET_DATA, v_proc_call.all & "=> "  & to_string(v_symbol_array(v_sym_cnt), HEX, AS_IS, INCL_RADIX) &
          " (symbol# " & to_string(v_sym_cnt) & "). " & add_msg_delimiter(msg), scope, msg_id_panel);

        -- Sample the packet transfer signals
        if config.use_packet_transfer then
          -- Check that start of packet is received only on the first data transfer
          if v_sym_cnt = 0 and avalon_st_if.start_of_packet = '0' then
            alert(error, v_proc_call.all & "=> Failed. Start of packet not set at first valid transfer. " & add_msg_delimiter(msg), scope);
          elsif v_sym_cnt/c_symbols_per_beat > 0 and v_sym_in_beat = 0 and avalon_st_if.start_of_packet = '1' then
            alert(error, v_proc_call.all & "=> Failed. Start of packet set at symbol #" & to_string(v_sym_cnt) & ". " & add_msg_delimiter(msg), scope);
          end if;
          -- Check the number of empty symbols on the last data transfer
          if c_symbols_per_beat > 1 then
            v_empty_symbols := to_integer(unsigned(avalon_st_if.empty));
          end if;
          -- Check that end of packet is received only on the last data transfer
          if v_sym_cnt = v_symbol_array'length-1 and avalon_st_if.end_of_packet = '0' then
            alert(error, v_proc_call.all & "=> Failed. End of packet not set at last valid transfer. " & add_msg_delimiter(msg), scope);
            v_done := true;
          elsif v_sym_cnt/c_symbols_per_beat < v_symbol_array'length/c_symbols_per_beat-1 and v_sym_in_beat = 0 and avalon_st_if.end_of_packet = '1' then
            alert(error, v_proc_call.all & "=> Failed. End of packet set at symbol #" & to_string(v_sym_cnt) & ". " & add_msg_delimiter(msg), scope);
            v_done := true;
          end if;
        end if;

        -- Finish receiving data when the symbol array ends
        if v_sym_cnt = v_symbol_array'length-1 then
          v_done := true;
          -- Check that empty signal is set on the last data transfer
          if v_sym_in_beat /= c_symbols_per_beat-1-v_empty_symbols then
            alert(error, v_proc_call.all & "=> Failed. Empty signal not set correctly for the last transfer. " & add_msg_delimiter(msg), scope);
          end if;
        end if;

        -- Counter for the symbol index within the current cycle
        if v_sym_in_beat = c_symbols_per_beat-1 then
          v_sym_in_beat := 0;
          -- Don't wait on the last cycle
          if v_sym_cnt < v_symbol_array'length-1 then
            wait for config.clock_period;
          end if;
        else
          v_sym_in_beat := v_sym_in_beat + 1;
        end if;
        -- Counter for the symbols received
        v_sym_cnt := v_sym_cnt + 1;

      ------------------------------------------------------------
      -- Data couldn't be sampled, wait until next cycle
      ------------------------------------------------------------
      elsif not(v_timeout) then
        -- Check for timeout
        if (v_invalid_count >= config.max_wait_cycles-1) then
          v_timeout := true;
          v_done    := true;
        else
          v_invalid_count := v_invalid_count + 1;
        end if;
        wait for config.clock_period;
      end if;
    end loop;

    -- Send the data with the matching interface width
    if config.use_packet_transfer then
      v_normalized_data := v_symbol_array.all;
    else
      for i in 0 to v_normalized_data'length-1 loop
        for j in 0 to c_symbols_per_beat-1 loop
          if config.first_symbol_in_msb then
            v_data_offset := (c_symbols_per_beat-1-j)*c_sym_width;
          else
            v_data_offset := j*c_sym_width;
          end if;
          v_normalized_data(i)(v_data_offset+c_sym_width-1 downto v_data_offset) := v_symbol_array(i*c_symbols_per_beat+j);
        end loop;
      end loop;
    end if;
    data_array    := v_normalized_data;
    check_value(to_integer(unsigned(v_normalized_chan)) <= config.max_channel, TB_FAILURE,
      "Sanity check: Check that channel number is supported.", scope, ID_NEVER, msg_id_panel, v_proc_call.all);
    channel_value := v_normalized_chan;

    avalon_st_if <= init_avalon_st_if_signals(is_master        => false,
                                              channel_width    => avalon_st_if.channel'length,
                                              data_width       => avalon_st_if.data'length,
                                              data_error_width => avalon_st_if.data_error'length,
                                              empty_width      => avalon_st_if.empty'length);

    -- Done. Check if there was a timeout or it was successful
    if v_timeout then
      alert(config.max_wait_cycles_severity, v_proc_call.all & "=> Failed. Timeout while waiting for valid data. " &
        add_msg_delimiter(msg), scope);
    else
      log(ID_PACKET_COMPLETE, v_proc_call.all & " DONE. " & add_msg_delimiter(msg), scope, msg_id_panel);
    end if;
  end procedure;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Receive
  -- DUT -> BFM
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_receive (
    variable data_array       : out   t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT;
    constant ext_proc_call    : in    string := ""  -- External proc_call. Overwrite if called from other BFM procedure
  ) is
    variable v_channel : std_logic_vector(avalon_st_if.channel'range);
  begin
    avalon_st_receive(v_channel, data_array, msg, clk, avalon_st_if, scope, msg_id_panel, config, ext_proc_call);
  end procedure;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Expect
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_expect (
    constant channel_exp      : in    std_logic_vector;
    constant data_exp         : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant alert_level      : in    t_alert_level          := error;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  ) is
    constant proc_name : string := "avalon_st_expect";
    constant proc_call : string := proc_name & "(" & to_string(data_exp'length) & " sym, ch:" &
                                   to_string(channel_exp, DEC, AS_IS) & ")";
    -- Helper variables
    variable v_normalized_exp     : t_slv_array(0 to data_exp'length-1)(data_exp(data_exp'low)'length-1 downto 0) := data_exp;
    variable v_rx_channel         : std_logic_vector(channel_exp'length-1 downto 0);
    variable v_rx_data_array      : t_slv_array(0 to data_exp'length-1)(data_exp(data_exp'low)'length-1 downto 0);
    variable v_data_error_cnt     : natural := 0;
    variable v_first_wrong_symbol : natural;
  begin

    -- Receive data
    avalon_st_receive(v_rx_channel, v_rx_data_array, msg, clk, avalon_st_if, scope, msg_id_panel, config, proc_call);

    -- Check channel
    if v_rx_channel /= channel_exp then
      alert(alert_level, proc_call & "=> Failed. Wrong channel. Was " & to_string(v_rx_channel, HEX, AS_IS, INCL_RADIX) &
        ". Expected " & to_string(channel_exp, HEX, AS_IS, INCL_RADIX) & ". " & msg, scope);
    end if;

    -- Check if each received bit matches the expected.
    -- Report the first wrong symbol (iterate from the last to the first)
    for symbol in v_rx_data_array'high downto 0 loop
      for i in v_rx_data_array(symbol)'range loop
        -- Expected set to don't care or received value matches expected
        if (v_normalized_exp(symbol)(i) = '-') or (v_rx_data_array(symbol)(i) = v_normalized_exp(symbol)(i)) then
          -- Check is OK
        else
          -- Received symbol doesn't match
          v_data_error_cnt     := v_data_error_cnt + 1;
          v_first_wrong_symbol := symbol;
        end if;
      end loop;
    end loop;

    -- Done. Report result
    if v_data_error_cnt /= 0 then
      alert(alert_level, proc_call & "=> Failed in "& to_string(v_data_error_cnt) & " data bits. First mismatch in symbol# " &
        to_string(v_first_wrong_symbol) & ". Was " & to_string(v_rx_data_array(v_first_wrong_symbol), HEX, AS_IS, INCL_RADIX) &
        ". Expected " & to_string(v_normalized_exp(v_first_wrong_symbol), HEX, AS_IS, INCL_RADIX) & "." & LF & add_msg_delimiter(msg), scope);
    else
      log(config.id_for_bfm, proc_call & "=> OK, received " & to_string(v_rx_data_array'length) & " symbols. " &
        add_msg_delimiter(msg), scope, msg_id_panel);
    end if;
  end procedure;

  ---------------------------------------------------------------------------------------------
  -- Avalon-ST Expect
  ---------------------------------------------------------------------------------------------
  procedure avalon_st_expect (
    constant data_exp         : in    t_slv_array;
    constant msg              : in    string                 := "";
    signal   clk              : in    std_logic;
    signal   avalon_st_if     : inout t_avalon_st_if;
    constant alert_level      : in    t_alert_level          := error;
    constant scope            : in    string                 := C_SCOPE;
    constant msg_id_panel     : in    t_msg_id_panel         := shared_msg_id_panel;
    constant config           : in    t_avalon_st_bfm_config := C_AVALON_ST_BFM_CONFIG_DEFAULT
  ) is
    variable v_channel : std_logic_vector(avalon_st_if.channel'range) := (others => '0');
  begin
    avalon_st_expect(v_channel, data_exp, msg, clk, avalon_st_if, alert_level, scope, msg_id_panel, config);
  end procedure;

end package body avalon_st_bfm_pkg;