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

  library work;
  use work.edge_detector_utilities.all;

--------------
--  Entity  --
--------------
entity ps2_keyboard_driver is
generic
(
  C_CLK_FREQ_MHZ   : integer := 125  -- System clock frequency in MHz
);
port
(
  I_CLK            : in std_logic;   -- System clk frequency of (C_CLK_FREQ_MHZ)
  I_RESET_N        : in std_logic;   -- System reset (active low)
  I_PS2_DATA       : in std_logic;   -- PS/2 Data pin
  I_PS2_CLK        : in std_logic;   -- PS/2 Clk pin

  -- Output scancode. Only valid if (O_NEW_SCANCODE) triggered
  O_SCANCODE       : out std_logic_vector(7 downto 0);
  O_NEW_SCANCODE   : out std_logic   -- New scancode ready flag
);
end entity ps2_keyboard_driver;

--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture behavioral of ps2_keyboard_driver is

  ----------------
  -- Components --
  ----------------
  component debounce_button is
  generic
  (
    C_CLK_FREQ_MHZ   : integer := 125;  -- System clock frequency in MHz
    C_STABLE_TIME_US : integer := 10    -- Time required for button to remain stable in ms
  );
  port
  (
    I_CLK            : in std_logic;  -- System clk frequency of (C_CLK_FREQ_MHZ)
    I_RESET_N        : in std_logic;  -- System reset (active low)
    I_BUTTON         : in std_logic;  -- Button data to be debounced
    O_BUTTON         : out std_logic  -- Debounced button data
  );
  end component debounce_button;

  component edge_detector is
  generic
  (
    C_CLK_FREQ_MHZ   : integer     := 125;  -- System clock frequency in MHz
    C_TRIGGER_EDGE   : T_EDGE_TYPE := NONE  -- Edge to trigger on
  );
  port
  (
    I_CLK            : in std_logic;  -- System clk frequency of (C_CLK_FREQ_MHZ)
    I_RESET_N        : in std_logic;  -- System reset (active low)
    I_SIGNAL         : in std_logic;  -- Input signal to pass through edge detector
    O_EDGE_SIGNAL    : out std_logic  -- Output pulse on (C_TRIGGER_EDGE) edge
  );
  end component edge_detector;

  ---------------
  -- Constants --
  ---------------
  -- Time required for button to remain stable in us
  constant C_STABLE_TIME_US        : integer := 5;
  constant C_IDLE_TIME_US          : integer := 55;

  -------------
  -- SIGNALS --  -- CDl=> Comment later
  -------------
  signal s_parity_error            : std_logic;
  signal s_ps2_shift_reg           : std_logic_vector(10 downto 0);
  signal s_debounced_ps2_data      : std_logic;
  signal s_debounced_ps2_clk       : std_logic;
  signal s_debounced_ps2_data_prev : std_logic;
  signal s_debounced_ps2_clk_prev  : std_logic;
  signal s_fall_edge_ps2_clk       : std_logic;

begin
  ------------------------------
  -- Component Instantiations --
  ------------------------------

  -- Device driver for PS/2 CLK debounce module
  DEBOUNCE_PS2_CLK_INST: debounce_button
  generic map
  (
    C_CLK_FREQ_MHZ   => C_CLK_FREQ_MHZ,
    C_STABLE_TIME_US => C_STABLE_TIME_US
  )
  port map
  (
    I_CLK            => I_CLK,
    I_RESET_N        => I_RESET_N,
    I_BUTTON         => I_PS2_CLK,
    O_BUTTON         => s_debounced_ps2_clk
  );

  -- Device driver for PS/2 DATA debounce module
  DEBOUNCE_PS2_DATA_INST: debounce_button
  generic map
  (
    C_CLK_FREQ_MHZ   => C_CLK_FREQ_MHZ,
    C_STABLE_TIME_US => C_STABLE_TIME_US
  )
  port map
  (
    I_CLK            => I_CLK,
    I_RESET_N        => I_RESET_N,
    I_BUTTON         => I_PS2_DATA,
    O_BUTTON         => s_debounced_ps2_data
  );

  -- Device driver for PS/2 CLK edge trigger module
  EDGE_TRIG_PS2_CLK_INST: edge_detector
  generic map
  (
    C_CLK_FREQ_MHZ => C_CLK_FREQ_MHZ,
    C_TRIGGER_EDGE => FALLING
  )
  port map
  (
    I_CLK          => I_CLK_125_MHZ,
    I_RESET_N      => s_reset_n,
    I_SIGNAL       => s_debounced_ps2_clk,
    O_EDGE_SIGNAL  => s_fall_edge_ps2_clk
  );

  ------------------------------------------------------------------------------
  -- Process Name     : PS2_SHIFT_REG
  -- Sensitivity List : I_CLK           : System clock
  --                    I_RESET_N       : System reset (active low logic)
  -- Useful Outputs   : s_ps2_shift_reg : The shift register storing scancodes.
  -- Description      : Process to shift input into scancode shift register.
  ------------------------------------------------------------------------------
  PS2_SHIFT_REG: process (I_CLK, I_RESET_N)
  begin
    if (I_RESET_N = '0') then
      s_ps2_shift_reg   <= (others=>'0');

    elsif (rising_edge(I_CLK)) then
      if (s_fall_edge_ps2_clk = '1') then

        -- Shift input into current data frame
        s_ps2_shift_reg <= s_debounced_ps2_data & s_ps2_shift_reg(10 downto 1);
      end if;
    end if;
  end process PS2_SHIFT_REG;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Process Name     : SCANCODE_DECODER
  -- Sensitivity List : I_CLK          : System clock
  --                    I_RESET_N      : System reset (active low logic)
  -- Useful Outputs   : s_scancode     : New scancode to output
  --                    O_NEW_SCANCODE : New scancode ready flag
  -- Description      : Process to decode a scancode.
  ------------------------------------------------------------------------------
  SCANCODE_DECODER: process (I_CLK, I_RESET_N)
    variable v_idle_max_count : integer := C_CLK_FREQ_MHZ * C_IDLE_TIME_US;
    variable v_idle_cntr      : integer range 0 TO v_idle_max_count := 0;
  begin
    if (I_RESET_N = '0') then
      v_idle_cntr :=  0;

    elsif (rising_edge(I_CLK)) then
      -- Output logic (If frame done and not parity error)
      if ((v_idle_cntr = v_idle_max_count) and (s_parity_error = '0')) then
        s_scancode     <= s_ps2_shift_reg(8 downto 1);
        O_NEW_SCANCODE <= '1';
      else
        s_scancode     <= s_scancode;
        O_NEW_SCANCODE <= '0';
      end if;

      -- Counter logic (Increment idle counter while clock is high)
      if (s_debounced_ps2_clk = '0') then
        v_idle_cntr := 0;
      elsif (v_idle_cntr /= v_idle_max_count) then
        v_idle_cntr := v_idle_cntr + 1;
      else
        v_idle_cntr := v_idle_cntr;
      end if;
    end if;
  end process SCANCODE_DECODER;
  ------------------------------------------------------------------------------

  -- Verify that the parity, start, and stop bits are all correct -- CDL=> Verify later
  s_parity_error <= not (not s_ps2_shift_reg(0) and
                             s_ps2_shift_reg(10) and (
                             s_ps2_shift_reg(9) xor
                             s_ps2_shift_reg(8) xor
                             s_ps2_shift_reg(7) xor
                             s_ps2_shift_reg(6) xor
                             s_ps2_shift_reg(5) xor
                             s_ps2_shift_reg(4) xor
                             s_ps2_shift_reg(3) xor
                             s_ps2_shift_reg(2) xor
                             s_ps2_shift_reg(1)));

  -- Set scancode to local signal
  O_SCANCODE <= s_scancode;

end architecture behavioral;