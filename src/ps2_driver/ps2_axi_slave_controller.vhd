--------------------------------------------------------------------------------
-- Filename     : ps2_axi_slave_controller.vhd
-- Author(s)    : Chris Lloyd, James Alongi, Chandler Kent
-- Class        : EE316 (Project 4)
-- Due Date     : 2021-04-01
-- Target Board : Cora Z7 10
-- Entity       : ps2_axi_slave_controller
-- Description  : Scancode to Ascii decoder for a PS/2 keyboard.
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
entity ps2_axi_slave_controller is
generic
(
  C_CLK_FREQ_MHZ   : integer := 125  -- System clock frequency in MHz
);
port
(
  I_CLK            : in std_logic;   -- System clk frequency of (C_CLK_FREQ_MHZ)
  I_RESET_N        : in std_logic;   -- System reset (active low)

  I_IRQ_CLEAR      : in std_logic;   -- Signal to clear (O_ASCII_IRQ) flag

  -- Output Ascii. Only valid if (O_NEW_ASCII) triggered
  O_ASCII          : out std_logic_vector(7 downto 0);
  O_ASCII_IRQ      : out std_logic;   -- New ascii ready flag

  I_PS2_DATA       : in std_logic;   -- PS/2 Data pin
  I_PS2_CLK        : in std_logic    -- PS/2 Clk pin
);
end entity ps2_axi_slave_controller;

--------------------------------
--  Architecture Declaration  --
--------------------------------
architecture behavioral of ps2_axi_slave_controller is

  ----------------
  -- Components --
  ----------------
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
  -------------
  -- SIGNALS --
  -------------
  signal s_ascii_new     : std_logic;
  signal s_ascii_code    : std_logic_vector(7 downto 0);
  signal s_ascii_irq     : std_logic;
  signal s_ascii_latched : std_logic_vector(7 downto 0);

begin
  ------------------------------
  -- Component Instantiations --
  ------------------------------
  -- User logic driver for PS2 keyboard
  PS2_KEYBOARD_INST: ps2_keyboard_to_ascii
  generic map
  (
    C_CLK_FREQ_MHZ => C_CLK_FREQ_MHZ
  )
  port map
  (
    I_CLK              => I_CLK,
    I_RESET_N          => I_RESET_N,
    I_PS2_CLK          => I_PS2_CLK,
    I_PS2_DATA         => I_PS2_DATA,
    O_NEW_ASCII        => s_ascii_new,
    O_ASCII            => s_ascii_code
  );
  ------------------------------------------------------------------------------
  -- Process Name     : IRQ_CONTROL
  -- Sensitivity List : I_CLK           : System clock
  --                    I_RESET_N       : System reset (active low logic)
  -- Useful Outputs   : s_ascii_latched : Latched data from the PS/2 decoder.
  --                    s_ascii_irq     : Data interrupt (cleared by I_IRQ_CLEAR)
  -- Description      : A process to latch data and handle an AXI interrupt.
  ------------------------------------------------------------------------------
  IRQ_CONTROL: process (I_CLK, I_RESET_N)
  begin
    if (I_RESET_N = '0') then
      s_ascii_latched <= (others=>'0');
      s_ascii_irq     <= '0';

    elsif (rising_edge(I_CLK)) then

      -- IRQ control
      if    (I_IRQ_CLEAR = '1') then
        s_ascii_irq <= '0';
      elsif (s_ascii_new = '1' and s_ascii_irq = '0') then
        s_ascii_irq <= '1';
      else
        s_ascii_irq <= s_ascii_irq;
      end if;

      -- Latch data
      if (s_ascii_new = '1' and s_ascii_irq = '0') then
        s_ascii_latched <= s_ascii_code;
      else
        s_ascii_latched <= s_ascii_latched;
      end if;
    end if;
  end process IRQ_CONTROL;
  ------------------------------------------------------------------------------

  -- Bind local signals
  O_ASCII_IRQ <= s_ascii_irq;
  O_ASCII     <= s_ascii_latched;

end architecture behavioral;