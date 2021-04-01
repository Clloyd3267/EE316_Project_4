Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use ieee.numeric_std.ALL;

entity vgatest is
  port(clock : in std_logic;
       datain : in std_logic_vector(31 downto 0);
       addrout : out std_logic_vector(15 downto 0);
       R : out std_logic_vector(3 downto 0);
       G : out std_logic_vector(3 downto 0);
       B : out std_logic_vector(3 downto 0);
       H : out std_logic;
       V : out std_logic
       );
end entity;

architecture test of vgatest is

  component VGAdrive2 is
  port(
		clock : in std_logic;
		red0 : in std_logic;
		red1 : in std_logic;
		green : in std_logic;
		blue : in std_logic;
		row : out std_logic_vector(9 downto 0);
		column : out std_logic_vector(9 downto 0);
		Rout : out std_logic_vector(3 downto 0);
		Gout : out std_logic_vector(3 downto 0);
		Bout : out std_logic_vector(3 downto 0);
		H, V : out std_logic
	);
  end component;
  
  signal row, column : std_logic_vector(9 downto 0);
  signal red0, red1, green, blue : std_logic;
  --signal clk_en : std_logic;
  --signal count : integer range 0 to 4:=0;
  signal counter1 : integer range 0 to 7 := 0;
  signal counter2 : integer range 0 to 79 := 0;
  signal addrcounter : std_logic_vector(15 downto 0) := "0000000000000000";
  signal temp : std_logic_vector(16 downto 0);
  signal eighty : std_logic_vector(6 downto 0) := "1010000";
--  signal rowint : integer range 0 to 480 := 0;
--  signal colint : integer range 0 to 640 := 0;

  

begin

  -- for debugging: to view the bit order
  VGA : component VGAdrive2
    port map(
        clock => clock,
		red0 => red0,
		red1 => red1,
		green => green,
		blue => blue,
		row => row,
		column => column,
		Rout => R,
		Gout => G,
		Bout => B,
		H => H,
		V => V
    );
    
--  	clock_divide : process(clock)
--		begin
--		if(rising_edge(clock)) then
--			     if(count = 4) then
--				    clk_en <= '1';
--				    count <= 0;
--			     else
--				    count <= count + 1;
--				    clk_en <= '0';
--			     end if;
--			end if;
--	end process;  
 
  RGB : process(clock)
  begin
      if(rising_edge(clock)) then
         if(row < 480 and column < 640) then
            if(counter1 = 0) then
                red0 <= datain(0);
                red1 <= datain(1);
                green <= datain(2);
                blue <= datain(3);
                counter1 <= counter1 + 1;
            elsif(counter1 = 1) then
                red0 <= datain(4);
                red1 <= datain(5);
                green <= datain(6);
                blue <= datain(7);
                counter1 <= counter1 + 1;
            elsif(counter1 = 2) then
                red0 <= datain(8);
                red1 <= datain(9);
                green <= datain(10);
                blue <= datain(11);
                counter1 <= counter1 + 1;
            elsif(counter1 = 3) then
                red0 <= datain(12);
                red1 <= datain(13);
                green <= datain(14);
                blue <= datain(15);
                counter1 <= counter1 + 1;
            elsif(counter1 = 4) then
                red0 <= datain(16);
                red1 <= datain(17);
                green <= datain(18);
                blue <= datain(19);
                counter1 <= counter1 + 1;
            elsif(counter1 = 5) then
                red0 <= datain(20);
                red1 <= datain(21);
                green <= datain(22);
                blue <= datain(23);
                counter1 <= counter1 + 1;
            elsif(counter1 = 6) then
                red0 <= datain(24);
                red1 <= datain(25);
                green <= datain(26);
                blue <= datain(27);
                counter1 <= counter1 + 1;
            elsif(counter1 = 7) then
                red0 <= datain(28);
                red1 <= datain(29);
                green <= datain(30);
                blue <= datain(31);
                counter1 <= 0;
                if(counter2 /= 79) then
                    counter2 <= counter2 + 1;
                else
                    counter2 <= 0;
                end if;
                
                            
                if(row = 479 and column = 639) then
                addrcounter <= "0000000000000000";
                else
                temp <= row * eighty + counter2;
                addrcounter <= temp(15 downto 0);
                end if;           
            end if;                                         
            else
            red0 <= '0';
            red1 <= '0';
            green <= '0';
            blue <= '0';
            end if;                
         end if; 

         addrout <= addrcounter;    
  end process;
  
end architecture;