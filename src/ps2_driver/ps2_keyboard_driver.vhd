--------------------------------------------------------------------------------
-- Filename     : ps2_keyboard_driver.vhd
-- Author(s)    : Chris Lloyd, James Alongi, Chandler Kent
-- Class        : EE316 (Project 4)
-- Due Date     : 2021-04-01
-- Target Board : Cora Z7 10
-- Entity       : ps2_keyboard_driver
-- Description  : Scancode decoder for a PS/2 keyboard.
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--------------
--  Entity  --
--------------
entity ps2_keyboard_driver is
generic
(
  C_CLK_FREQ_MHZ : integer := 125  -- System clock frequency in MHz
);
port
(
  I_CLK          : in std_logic;   -- System clk frequency of (C_CLK_FREQ_MHZ)
  I_RESET_N      : in std_logic;   -- System reset (active low)
  I_PS2_DATA     : in std_logic;   -- PS/2 Data pin
  I_PS2_CLK      : in std_logic;   -- PS/2 Clk pin

  -- Output scancode. Only valid if (O_NEW_SCANCODE) triggered
  O_SCANCODE     : out std_logic_vector(7 downto 0);
  O_NEW_SCANCODE : out std_logic   -- New scancode ready flag
);
end entity ps2_keyboard_driver;

--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture behavioral of ps2_keyboard_driver is

  -------------
  -- SIGNALS --
  -------------
  signal s_parity_error  : std_logic;
  signal s_ps2_shift_reg : std_logic_vector(10 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Process Name     : DEBOUNCE_CNTR
  -- Sensitivity List : I_CLK           : System clock
  --                    I_RESET_N       : System reset (active low logic)
  -- Useful Outputs   : s_button_output : The debounced button signal
  -- Description      : Process to debounce an input from push button.
  ------------------------------------------------------------------------------
  DEBOUNCE_CNTR: process (I_CLK, I_RESET_N)
    variable v_debounce_max_count : integer := C_CLK_FREQ_MHZ * C_STABLE_TIME_MS * 1000;
    variable v_debounce_counter   : integer range 0 TO v_debounce_max_count := 0;
  begin
    if (I_RESET_N = '0') then
      v_debounce_counter :=  0;
      s_button_output    <= '0';
      s_button_previous  <= '0';

    elsif (rising_edge(I_CLK)) then
      -- Output logic (output when input has been stable for counter period)
      if (v_debounce_counter = v_debounce_max_count) then
        s_button_output <= I_BUTTON;
      else
        s_button_output <= s_button_output;
      end if;

      -- Counter logic (while signal has not changed, increment counter)
      if ((s_button_previous = '1') xor (I_BUTTON = '1')) then
        v_debounce_counter := 0;
      elsif (v_debounce_counter = v_debounce_max_count) then
        v_debounce_counter := 0;
      else
        v_debounce_counter := v_debounce_counter + 1;
      end if;

      -- Set previous value to current value
      s_button_previous <= I_BUTTON;
    end if;
  end process DEBOUNCE_CNTR;
  ------------------------------------------------------------------------------

  -- Assign final debounced output
  O_BUTTON <= s_button_output;

end architecture behavioral;