--------------------------------------------------------------------------------
-- Filename     : ps2_keyboard_to_ascii.vhd
-- Author(s)    : Chris Lloyd, James Alongi, Chandler Kent
-- Class        : EE316 (Project 4)
-- Due Date     : 2021-04-01
-- Target Board : Cora Z7 10
-- Entity       : ps2_keyboard_to_ascii
-- Description  : Scancode to Ascii decoder for a PS/2 keyboard.
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
entity ps2_keyboard_to_ascii is
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

  -- Output Ascii. Only valid if (O_NEW_ASCII) triggered
  O_ASCII          : out std_logic_vector(7 downto 0);
  O_NEW_ASCII      : out std_logic   -- New ascii ready flag
);
end entity ps2_keyboard_to_ascii;

--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture behavioral of ps2_keyboard_to_ascii is

  ----------------
  -- Components --
  ----------------
  component ps2_keyboard_driver is
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
  end component ps2_keyboard_driver;

  component scancode2ascii_lut is
  port
  (
    scancode         : in std_logic_vector(7 downto 0);
    shift, ctrl, alt : in std_logic;
    ascii            : out std_logic_vector(7 downto 0)
  );
  end component scancode2ascii_lut;

  component edge_detector is  -- CDL=> Remove later?
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
  -- Special scancodes
  constant C_BREAK_CODE  : std_logic_vector(7 downto 0) := x"F0";
  constant C_EXTEN_CODE  : std_logic_vector(7 downto 0) := x"E0";

  -- Modifier scancodes
  constant C_CAPS_CODE   : std_logic_vector(7 downto 0) := x"58";
  constant C_RSHIFT_CODE : std_logic_vector(7 downto 0) := x"59";
  constant C_LSHIFT_CODE : std_logic_vector(7 downto 0) := x"12";
  constant C_CTRL_CODE   : std_logic_vector(7 downto 0) := x"14";
  constant C_ALT_CODE    : std_logic_vector(7 downto 0) := x"11";

  -------------
  -- SIGNALS --  -- CDL=> Comment later
  -------------
  signal s_break_en     : std_logic;
  signal s_ex0_en       : std_logic;
  signal s_scancode     : std_logic_vector(7 downto 0);
  signal s_new_scancode : std_logic;
  signal s_rise_new_scancode : std_logic;
  signal s_caps_en      : std_logic;
  signal s_shift_en     : std_logic;
  signal s_ctrl_en      : std_logic;
  signal s_alt_en       : std_logic;
  signal s_case_en      : std_logic;

begin
  ------------------------------
  -- Component Instantiations --
  ------------------------------

  -- Device driver for PS/2 Scancode decoder
  SCANCODE_DECODER_INST: ps2_keyboard_driver
  generic map
  (
    C_CLK_FREQ_MHZ => C_CLK_FREQ_MHZ
  )
  port map
  (
    I_CLK          => I_CLK,
    I_RESET_N      => I_RESET_N,
    I_PS2_DATA     => I_PS2_DATA,
    I_PS2_CLK      => I_PS2_CLK,

    O_SCANCODE     => s_scancode,
    O_NEW_SCANCODE => s_new_scancode
  );

  -- Device driver for PS/2 Scancode to Ascii converter
  SCAN_TO_ASCII_LUT_INST: scancode2ascii_lut
  port map
  (
    scancode => s_scancode,
    shift    => s_case_en,
    ctrl     => s_ctrl_en,
    alt      => s_alt_en,
    ascii    => O_ASCII  -- Should be latched
  );

  -- Device driver for new scancode flag edge trigger module
  EDGE_TRIG_SCAN_INST: edge_detector
  generic map
  (
    C_CLK_FREQ_MHZ => C_CLK_FREQ_MHZ,
    C_TRIGGER_EDGE => RISING
  )
  port map
  (
    I_CLK          => I_CLK,
    I_RESET_N      => I_RESET_N,
    I_SIGNAL       => s_new_scancode,
    O_EDGE_SIGNAL  => s_rise_new_scancode
  );

  ------------------------------------------------------------------------------
  -- Process Name     : SCANCODE_DECODER
  -- Sensitivity List : I_CLK           : System clock
  --                    I_RESET_N       : System reset (active low logic)
  -- Useful Outputs   :
  -- Description      :
  ------------------------------------------------------------------------------
  SCANCODE_DECODER: process (I_CLK, I_RESET_N)
  begin
    if (I_RESET_N = '0') then
      s_break_en <= '0';
      s_ex0_en <= '0';
      s_caps_en <= '0';
      s_shift_en <= '0';
      s_ctrl_en <= '0';
      s_alt_en <= '0';

    elsif (rising_edge(I_CLK)) then
      O_NEW_ASCII <= '0';
      if (s_rise_new_scancode = '1') then
        -- Disable ascii valid flag
--        O_NEW_ASCII <= '0';

        if    (s_scancode = x"F0") then  -- Break code
          s_break_en <= '1';
        elsif (s_scancode = x"E0") then  -- Extended code
          s_ex0_en   <= '1';
        else                             -- Normal code
          -- Reset break and extended flags
          s_break_en <= '0';
          s_ex0_en   <= '0';

          -- Caps key pressed (no break/extended)
          if    ((s_scancode = C_CAPS_CODE) and
                 (s_break_en = '0') and
                 (s_ex0_en = '0')) then
            s_caps_en <= not s_caps_en;

          -- Shift key pressed (R or L, no extended)
          elsif (((s_scancode = C_LSHIFT_CODE) or
                  (s_scancode = C_RSHIFT_CODE)) and
                 (s_ex0_en = '0')) then
            s_shift_en <= not s_shift_en;

          -- Ctrl key pressed (R or L)
          elsif (s_scancode = C_CTRL_CODE) then
            s_ctrl_en <= not s_ctrl_en;

          -- Alt key pressed (R or L)
          elsif (s_scancode = C_ALT_CODE) then
            s_alt_en <= not s_alt_en;

          else           -- Normal key
            if (s_break_en = '0') then   -- Ensure key is not a break code
              O_NEW_ASCII <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process SCANCODE_DECODER;
  ------------------------------------------------------------------------------

  s_case_en <= s_shift_en xor s_caps_en;

end architecture behavioral;