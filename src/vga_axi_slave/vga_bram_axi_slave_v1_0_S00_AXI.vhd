library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_bram_axi_slave_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 32  -- CDL=> Should be 32 not 4?
	);
	port (
		-- Users to add ports here
    VGA_RED   : out std_logic_vector(3 downto 0);
    VGA_GREEN : out std_logic_vector(3 downto 0);
    VGA_BLUE  : out std_logic_vector(3 downto 0);
    VGA_H     : out std_logic;
    VGA_V     : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave)
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end vga_bram_axi_slave_v1_0_S00_AXI;

architecture arch_imp of vga_bram_axi_slave_v1_0_S00_AXI is

  component blk_mem_gen_0 is
  port (
    clka : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 31 downto 0 );
    clkb : in STD_LOGIC;
    addrb : in STD_LOGIC_VECTOR ( 15 downto 0 );
    doutb : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component blk_mem_gen_0;
  component clk_wiz_0 is
  port (
    clk_in1 : in STD_LOGIC;
    clk_out1 : out STD_LOGIC
  );
  end component clk_wiz_0;
  component vgatest_0 is
  port (
    clock : in STD_LOGIC;
    datain : in STD_LOGIC_VECTOR ( 31 downto 0 );
    addrout : out STD_LOGIC_VECTOR ( 15 downto 0 );
    R : out STD_LOGIC_VECTOR ( 3 downto 0 );
    G : out STD_LOGIC_VECTOR ( 3 downto 0 );
    B : out STD_LOGIC_VECTOR ( 3 downto 0 );
    H : out STD_LOGIC;
    V : out STD_LOGIC
  );
  end component vgatest_0;

--  component design_1_0 is
--    port (
--      B : out std_logic_vector ( 3 downto 0 );
--      G : out std_logic_vector ( 3 downto 0 );
--      H : out std_logic;
--      R : out std_logic_vector ( 3 downto 0 );
--      V : out std_logic;
--      bramaddr : in std_logic_vector ( 15 downto 0 );
--      bramdata : in std_logic_vector ( 31 downto 0 );
--      bramena : in std_logic;
--      clk : in std_logic
--    );
--  end component design_1_0;

  constant C_M_VIDEOMEM_BASE_ADDR	: std_logic_vector	:= x"80000000";
	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;
  signal bram_addr      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;
	
	signal VGA_addr : std_logic_vector(15 downto 0);
	signal VGA_data : std_logic_vector(31 downto 0);
	signal clock_out_25 : std_logic;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design
	        -- expects no outstanding transactions.
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both
	-- S_AXI_AWVALID and S_AXI_WVALID are valid.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design
	          -- expects no outstanding transactions.
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

-- 	process (S_AXI_ACLK)  -- CDL=> Here
-- --	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
-- 	begin
-- 	  if rising_edge(S_AXI_ACLK) then
-- 	    if S_AXI_ARESETN = '0' then
-- --	      slv_reg0 <= (others => '0');
-- --	      slv_reg1 <= (others => '0');
-- --	      slv_reg2 <= (others => '0');
-- --	      slv_reg3 <= (others => '0');
--             led <= (others => '0');
-- 	    else
-- --	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
-- 	       if (slv_reg_wren = '1') then
-- 	           led <= (5 downto 0);
-- 	      end if;
-- 	    end if;
-- 	  end if;
-- 	end process;

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	-- This marks the acceptance of address and indicates the status of
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00";
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;
	end process;

  -- S_AXI_WDATA
  -- S_AXI_WVALID

--  VGA_BRAM_INST: design_1_0
--  port map
--  (
--    R        => VGA_RED,
--    G        => VGA_GREEN,
--    B        => VGA_BLUE,
--    H        => VGA_H,
--    V        => VGA_V,
--    bramaddr => bram_addr(17 downto 2),
--    bramdata => S_AXI_WDATA,
--    bramena => S_AXI_WVALID,
--    clk      => S_AXI_ACLK
--  );

  BLOCK_RAM : blk_mem_gen_0
  port map
  (
    clka => S_AXI_ACLK,
    wea(0) => S_AXI_WVALID,
    addra => bram_addr(17 downto 2),
    dina => S_AXI_WDATA,
    clkb => S_AXI_ACLK,
    addrb => VGA_addr,
    doutb => VGA_data
  );
  
  CLOCK_WIZ : clk_wiz_0
  port map
  (
    clk_in1 => S_AXI_ACLK,
    clk_out1 => clock_out_25
  );
  
  VGA : vgatest_0
  port map
  (
    clock => clock_out_25,
    datain => VGA_data,
    addrout => VGA_addr,
    R => VGA_RED,
    G => VGA_GREEN,
    B => VGA_BLUE,
    H => VGA_H,
    V => VGA_V
  );

  bram_addr <= std_logic_vector(unsigned(S_AXI_AWADDR) - unsigned(C_M_VIDEOMEM_BASE_ADDR));
	-- Add user logic here
	-- User logic ends

end arch_imp;
