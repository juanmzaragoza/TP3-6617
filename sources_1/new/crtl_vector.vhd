----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/07/2019 11:53:43 AM
-- Design Name: 
-- Module Name: crtl_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ctrl_vector is

    port(
        -- inputs
		clk_pin:        in std_logic;
		
		cordic_pixel_x:  in signed;   --salida del cordic
        cordic_pixel_y : in signed;  --salida del cordic
		
		-- outputs
		hsync_pin:  out std_logic; 
		vsync_pin:  out std_logic; 
		
		red_o: out std_logic;
		grn_o: out std_logic;
        blu_o: out std_logic
	);
end ctrl_vector;

architecture Behavioral of ctrl_vector is

 component vector_calculator is
    generic(
		AW: integer := 100 -- para un vector de norma 100
	);
    port ( clk : in std_logic;
	
           pixel_x: in std_logic_vector(9 downto 0);  --contador de pixeles de la VGA
           pixel_y : in std_logic_vector(9 downto 0); --contador de pixeles de la VGA
		   
		   cordic_pixel_x: in signed;   --salida del cordic
           cordic_pixel_y : in signed;  --salida del cordic
		   
		   pixel_on: out std_logic := '0'
		   
           );
	end component;
	
	
	
	
	component vga_ctrl is
        generic(
            N: integer := 5
        );
        port (
            mclk: in std_logic; 
			pixel_on: in std_logic;		
			
            hs: out std_logic;
            vs: out std_logic;
            red_o: out std_logic;
            grn_o: out std_logic;
            blu_o: out std_logic;
            pixel_row: out std_logic_vector(9 downto 0); --devuelven en el sistema la posicion del barrido
            pixel_col: out std_logic_vector(9 downto 0)
        );
    
    end component;
	
	
	
	
	-- Signals between vector_calculator and vga
	
	signal pixel_on:  std_logic;
	signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	--signal cordic_pixel_x:  signed;   
    --ignal cordic_pixel_y : signed;  
	
	
begin

    vga: vga_ctrl
        generic map(
			N 	=> 5 -- 125 Mhz / 5
		)
		port map(
			mclk        => clk_pin,
			pixel_on    => pixel_on,
			hs          => hsync_pin,
            vs          => vsync_pin,
            red_o       => open,
            grn_o       => open,
            blu_o       => open,
            pixel_row   => pixel_y,
            pixel_col   => pixel_x
		);
		
		
	vector_calc: 	
		vector_calculator 
     generic map(
		AW => 100 -- para un vector de norma 100
	)
    port map( 
			clk => clk_pin,
           pixel_x => pixel_x,
           pixel_y => pixel_y,
		   
		   cordic_pixel_x => cordic_pixel_x,  --salida del cordic
           cordic_pixel_y => cordic_pixel_x,  --salida del cordic
		   
		   pixel_on =>pixel_on
		   
           );
		
		
		
	
	-- prendo toda la pantalla
	-- rgb <= (others => '1');
            
	-- process(clk_pin)
	-- begin
		-- if rising_edge(clk_pin) then
			-- if rst_clk_rx = '1' then
			    -- enable_write_ram <= '0';
				-- old_rx_data_rdy <= '0';
				-- char_data       <= "00000000";
			-- else
			--	Capture the value of rx_data_rdy for edge detection
				-- old_rx_data_rdy <= rx_data_rdy;
			--	If rising edge of rx_data_rdy, capture rx_data
				-- if (rx_data_rdy = '1' and old_rx_data_rdy = '0') then
				    -- enable_write_ram <= '1';
					-- char_data <= rx_data;
				-- else
				    -- enable_write_ram <= '0';
				-- end if;
			-- end if;	-- if !rst
		-- end if;
	-- end process;

end Behavioral;
