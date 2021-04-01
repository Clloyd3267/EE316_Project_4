library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity VGAdrive2 is
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
end VGAdrive2;

architecture Behavior of VGAdrive2 is

constant h_va : integer := 640;
constant h_fp : integer := 16;
constant h_pulse : integer := 96;
constant h_bp : integer := 48;
constant h_tot : integer := 800;

constant v_va : integer := 480;
constant v_fp : integer := 10;
constant v_pulse : integer := 2;
constant v_bp : integer := 33;
constant v_tot : integer := 525;

--signal clk_en : std_logic;
--signal count : integer range 0 to 4:=0;
signal vertical : std_logic_vector(9 downto 0) := "0000000000";
signal horizontal : std_logic_vector(9 downto 0) := "0000000000";

signal Rout_sig : std_logic_vector(3 downto 0);
signal Gout_sig : std_logic_vector(3 downto 0);
signal Bout_sig : std_logic_vector(3 downto 0);

begin
--	clock_divide : process(clock)
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
	
	timing : process(clock)
		begin
			if(rising_edge(clock)) then
				if(horizontal < h_tot - 1) then
					horizontal <= horizontal + "0000000001";
				else
					horizontal <= (others => '0');
					if(vertical < v_tot - 1) then
						vertical <= vertical + "0000000001";
					else
						vertical <= (others => '0');
					end if;
				end if;
				
			if(horizontal >= (h_va + h_fp) and horizontal < (h_va + h_fp + h_pulse)) then
				H <= '0';
			else
				H <= '1';
			end if;
			
			if(vertical >= (v_va + v_fp) and vertical < (v_va + v_fp + v_pulse)) then
				V <= '0';
			else
				V <= '1';
			end if;
			
			row <= vertical;
			column <= horizontal;
			end if;
	end process;
	
	colors : process
		begin
			if(red0 = '0' and red1 = '0') then
				Rout_sig <= "0000";
			elsif(red0 = '1' and red1 = '0') then
				Rout_sig <= "0110";
			elsif(red0 = '0' and red1 = '1') then
				Rout_sig <= "1010";
			else
				Rout_sig <= "1111";
			end if;
			
			if(green = '1') then
				Gout_sig <= "1111";
			else
				Gout_sig <= "0000";
			end if;
        
			if(blue = '1') then
				Bout_sig <= "1111";
			else
				Bout_sig <= "0000";
			end if;
        
		Rout <= Rout_sig;
		Gout <= Gout_sig;
        Bout <= Bout_sig;
	end process;
	
end Behavior;