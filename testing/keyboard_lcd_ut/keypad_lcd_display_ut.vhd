--------------------------------------------------------------------------------
-- Filename     : keypad_lcd_display_ut.vhd
-- Author(s)    : Chris Lloyd
-- Class        : EE316 (Project 2)
-- Due Date     : 2021-02-23
-- Target Board : Altera DE2 Devkit
-- Entity       : keypad_lcd_display_ut
-- Description  : Unit Test (ut) to test a 16x2 Liquid Crystal Display Driver
--                (LCD) using an external matrix keypad.
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.lcd_screen_util.all;

--------------
--  Entity  --
--------------
entity keypad_lcd_display_ut is
port
(
  I_CLK          : in std_logic;                      -- System clk frequency of (C_CLK_FREQ_MHZ)
  I_RESET      : in std_logic;                      -- System reset (active low)

  I_PS2_DATA   : in std_logic;
  I_PS2_CLK    : in std_logic;

  -- Pass through external signals
  O_LCD_DATA       : out std_logic_vector(7 downto 0);
  O_LCD_ENABLE     : out std_logic;
  O_LCD_RS         : out std_logic;
  O_LCD_RW         : out std_logic
);
end entity keypad_lcd_display_ut;

--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture behavioral of keypad_lcd_display_ut is

  ----------------
  -- Components --
  ----------------
  component lcd_display_driver is
  generic
  (
    C_CLK_FREQ_MHZ   : integer := 50;      -- System clock frequency in MHz

    -- LCD Specific Settings
    C_NUM_DISP_LINES : std_logic := '1';   -- Number of lines to display (1-line mode: '0', 2-line mode: '1')
    C_CHAR_FONT      : std_logic := '1';   -- Character font (5x8 dot: '0', 5x10 dots: '1')
    C_DISP_EN        : std_logic := '1';   -- Display enable (display off: '0', display on: '1')
    C_CURSOR_EN      : std_logic := '1';   -- Cursor enable (cursor off: '0', cursor on: '1')
    C_BLINK_EN       : std_logic := '1';   -- Cursor blink enable (blink off: '0', blink on: '1')
    C_INC_DEC        : std_logic := '1';   -- Increment/decrement (decrement: '0', increment: '1')
    C_SHIFT_EN       : std_logic := '1'    -- Shift enable (shift off: '0', shift on: '1')
  );
  port
  (
    I_CLK            : in std_logic;                      -- System clk frequency of (C_CLK_FREQ_MHZ)
    I_RESET_N        : in std_logic;                      -- System reset (active low)

    -- User signals
    I_LCD_DATA       : in t_lcd_display_data;
    O_LCD_BUSY       : out std_logic;

    -- Pass through external signals
    O_LCD_DATA       : out std_logic_vector(7 downto 0);
    O_LCD_ENABLE     : out std_logic;
    O_LCD_RS         : out std_logic;
    O_LCD_RW         : out std_logic
  );
  end component lcd_display_driver;

--    component ps2_keyboard_to_ascii IS
--  GENERIC(
--      clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
--      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
--  PORT(
--      clk        : IN  STD_LOGIC;                     --system clock input
--      ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
--      ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
--      ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
--      ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)); --ASCII value
--END component ps2_keyboard_to_ascii;
component ps2_keyboard_to_ascii is
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
end component ps2_keyboard_to_ascii;
  ---------------
  -- Constants --
  ---------------

  constant C_CLK_FREQ_MHZ   : integer := 125;  -- System clock frequency in MHz

  -- LCD Specific Settings
  constant C_NUM_DISP_LINES : std_logic := '1';   -- Number of lines to display (1-line mode: '0', 2-line mode: '1')
  constant C_CHAR_FONT      : std_logic := '0';   -- Character font (5x8 dot: '0', 5x10 dots: '1')
  constant C_DISP_EN        : std_logic := '1';   -- Display enable (display off: '0', display on: '1')
  constant C_CURSOR_EN      : std_logic := '0';   -- Cursor enable (cursor off: '0', cursor on: '1')
  constant C_BLINK_EN       : std_logic := '0';   -- Cursor blink enable (blink off: '0', blink on: '1')
  constant C_INC_DEC        : std_logic := '1';   -- Increment/decrement (decrement: '0', increment: '1')
  constant C_SHIFT_EN       : std_logic := '0';   -- Shift enable (shift off: '0', shift on: '1')

  -- Ascii constants for writing "Strings"
  constant C_A  : std_logic_vector(7 downto 0) := x"41";  -- A
  constant C_B  : std_logic_vector(7 downto 0) := x"42";  -- B
  constant C_C  : std_logic_vector(7 downto 0) := x"43";  -- C
  constant C_D  : std_logic_vector(7 downto 0) := x"44";  -- D
  constant C_E  : std_logic_vector(7 downto 0) := x"45";  -- E
  constant C_F  : std_logic_vector(7 downto 0) := x"46";  -- F
  constant C_G  : std_logic_vector(7 downto 0) := x"47";  -- G
  constant C_H  : std_logic_vector(7 downto 0) := x"48";  -- H
  constant C_I  : std_logic_vector(7 downto 0) := x"49";  -- I
  constant C_J  : std_logic_vector(7 downto 0) := x"4A";  -- J
  constant C_K  : std_logic_vector(7 downto 0) := x"4B";  -- K
  constant C_L  : std_logic_vector(7 downto 0) := x"4C";  -- L
  constant C_M  : std_logic_vector(7 downto 0) := x"4D";  -- M
  constant C_N  : std_logic_vector(7 downto 0) := x"4E";  -- N
  constant C_O  : std_logic_vector(7 downto 0) := x"4F";  -- O
  constant C_P  : std_logic_vector(7 downto 0) := x"50";  -- P
  constant C_Q  : std_logic_vector(7 downto 0) := x"51";  -- Q
  constant C_R  : std_logic_vector(7 downto 0) := x"52";  -- R
  constant C_S  : std_logic_vector(7 downto 0) := x"53";  -- S
  constant C_T  : std_logic_vector(7 downto 0) := x"54";  -- T
  constant C_U  : std_logic_vector(7 downto 0) := x"55";  -- U
  constant C_V  : std_logic_vector(7 downto 0) := x"56";  -- V
  constant C_W  : std_logic_vector(7 downto 0) := x"57";  -- W
  constant C_X  : std_logic_vector(7 downto 0) := x"58";  -- X
  constant C_Y  : std_logic_vector(7 downto 0) := x"59";  -- Y
  constant C_Z  : std_logic_vector(7 downto 0) := x"5A";  -- Z
  constant C_SP : std_logic_vector(7 downto 0) := x"20";  -- Space
  constant C_EX : std_logic_vector(7 downto 0) := x"21";  -- !

  -------------
  -- SIGNALS --
  -------------

  signal s_keypad_data    : std_logic_vector(4 downto 0);   -- Data from keypress
  signal s_keypressed     : std_logic;                      -- Whether a key was pressed
  signal s_display_data   : t_lcd_display_data;             -- Data to be displayed on LCD
  signal s_lcd_busy       : std_logic;                      -- Busy signal from LCD
  signal s_reset_n        : std_logic;                      -- Active low reset signal

  signal s_ascii_new      : std_logic;
  signal s_ascii_code     : std_logic_vector(7 downto 0);
  signal s_ascii_cntr     : integer range 0 to 31;

begin

  -- User logic display driver for LCD
  DISPLAY_DRIVER_INST: lcd_display_driver
  generic map
  (
    C_CLK_FREQ_MHZ   => C_CLK_FREQ_MHZ,
    C_NUM_DISP_LINES => C_NUM_DISP_LINES,
    C_CHAR_FONT      => C_CHAR_FONT,
    C_DISP_EN        => C_DISP_EN,
    C_CURSOR_EN      => C_CURSOR_EN,
    C_BLINK_EN       => C_BLINK_EN,
    C_INC_DEC        => C_INC_DEC,
    C_SHIFT_EN       => C_SHIFT_EN
  )
  port map
  (
    I_CLK            => I_CLK,
    I_RESET_N        => s_reset_n,
    I_LCD_DATA       => s_display_data,
    O_LCD_BUSY       => s_lcd_busy,
    O_LCD_DATA       => O_LCD_DATA,
    O_LCD_ENABLE     => O_LCD_ENABLE,
    O_LCD_RS         => O_LCD_RS,
    O_LCD_RW         => O_LCD_RW
  );

 -- User logic display driver for PS2 keyboard
  PS2_KEYBOARD_INST: ps2_keyboard_to_ascii
  generic map
  (
    C_CLK_FREQ_MHZ => C_CLK_FREQ_MHZ
  )
  port map
  (
    I_CLK              => I_CLK,
    I_RESET_N        => s_reset_n,
    I_PS2_CLK          => I_PS2_CLK,
    I_PS2_DATA         => I_PS2_DATA,
    O_NEW_ASCII        => s_ascii_new,
    O_ASCII       => s_ascii_code
  );

  ---------------
  -- Processes --
  ---------------

  ------------------------------------------------------------------------------
  -- Process Name     : KEYPAD_LCD_DISPLAY_TEST
  -- Sensitivity List : I_CLK            : System clock
  --                    I_RESET_N        : System reset (active low logic)
  -- Useful Outputs   : s_display_data   : Data to display on LCD.
  -- Description      : A process to latch triggered inputs from a matrix
  --                    keypad to an LCD display for testing.
  ------------------------------------------------------------------------------
  KEYPAD_LCD_DISPLAY_TEST: process (I_CLK, s_reset_n)
  begin
    if (s_reset_n = '0') then
      s_display_data   <= (others=>(x"20"));
      s_ascii_cntr <= 0;

      elsif (rising_edge(I_CLK)) then

      -- CDL=> For testing:
      -- s_display_data <= (others => (x"41")); -- Ascii "A"

      -- "Hello World!"
--	    s_display_data <= (C_SP, C_SP, C_H , C_E , C_L , C_L , C_O , C_SP, C_W , C_O , C_R , C_L , C_D , C_EX, C_SP,
--                         C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP, C_SP,
--                         C_SP, C_SP);
        if (s_ascii_new = '1') then
            if (s_ascii_code = x"08") then -- Backspace
                if (s_ascii_cntr /= 0) then
                    s_display_data(31 - (s_ascii_cntr - 1))   <= x"20";
                    s_ascii_cntr <= s_ascii_cntr - 1;
                end if;
            else
                if (s_ascii_cntr /= 31) then
                    s_ascii_cntr <= s_ascii_cntr + 1;
                    s_display_data(31 - s_ascii_cntr)   <= s_ascii_code;
                end if;
            end if;
        else
            s_display_data <= s_display_data;
        end if;
      -- A-Z
      -- s_display_data <= (C_A, C_B, C_C, C_D, C_E, C_F, C_G, C_H, C_I, C_J, C_K, C_L, C_M, C_N, C_O, C_P,
      --                    C_Q, C_R, C_S, C_T, C_U, C_V, C_W, C_X, C_Y, C_Z, C_A, C_B, C_C, C_D, C_E, C_F);

      -- Only update key data when a key is pressed
      --if ((s_keypressed = '1') and s_lcd_busy = '0') then
       -- s_display_data <= (others=>CDL=> Here);
      --else
     --   s_display_data <= s_display_data;
   --   end if;
    end if;
  end process KEYPAD_LCD_DISPLAY_TEST;
  ------------------------------------------------------------------------------

  s_reset_n <= not I_RESET;

end architecture behavioral;
