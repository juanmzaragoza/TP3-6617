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

entity ctrl_top is
    generic(
        BAUD_RATE: integer := 115200;   
        CLOCK_RATE: integer := 125E6
    );
    port(
        -- inputs
		clk_pin, rst_pin:         in std_logic;
		rxd_pin:                  in std_logic; 		-- Uart input
		-- outputs
		txd_pin:                  out std_logic; 		-- Uart output
		hsync_pin , vsync_pin :   out std_logic; 
		rgb :                     out std_logic_vector(2 downto 0)
	);
end ctrl_top;

architecture Behavioral of ctrl_top is

    component meta_harden is
		port(
			clk_dst: 	in std_logic;	-- Destination clock
			rst_dst: 	in std_logic;	-- Reset - synchronous to destination clock
			signal_src: in std_logic;	-- Asynchronous signal to be synchronized
			signal_dst: out std_logic	-- Synchronized signal
		);
	end component;
	
	component uart_rx is
		generic(
			BAUD_RATE: integer := 115200; 	-- Baud rate
			CLOCK_RATE: integer := 50E6
		);

		port(
			-- Write side inputs
			clk_rx: in std_logic;       				-- Clock input
			rst_clk_rx: in std_logic;   				-- Active HIGH reset - synchronous to clk_rx
							
			rxd_i: in std_logic;        				-- RS232 RXD pin - Directly from pad
			rxd_clk_rx: out std_logic;					-- RXD pin after synchronization to clk_rx
		
			rx_data: out std_logic_vector(7 downto 0);	-- 8 bit data output
														--  - valid when rx_data_rdy is asserted
			rx_data_rdy: out std_logic;  				-- Ready signal for rx_data
			frm_err: out std_logic       				-- The STOP bit was not detected	
		);
	end component;
	
	component vga_ctrl is
        generic(
            N: integer := 5
        );
        port (
            mclk: in std_logic;
            red_i: in std_logic := '0';
            grn_i: in std_logic := '0';
            blu_i: in std_logic := '0';
            hs: out std_logic;
            vs: out std_logic;
            red_o: out std_logic;
            grn_o: out std_logic;
            blu_o: out std_logic;
            pixel_row: out std_logic_vector(9 downto 0); --devuelven en el sistema la posicion del barrido
            pixel_col: out std_logic_vector(9 downto 0)
        );
    
    end component;
    
    component ctrl_rotation is
        generic(
            BUFFER_CHARS_SIZE: integer := 9;
            CHAR_SIZE: integer := 8;
            N: integer := 125000000
        );
        port(
            -- inputs
            clk, rst:                 in std_logic;
            new_data:                 in std_logic; -- si new_data=1 => hay un nuevo dato en char_data
            char_data:                in std_logic_vector(7 downto 0);
            -- outputs
            rotation_enable:          out std_logic;
            degrees:                  out integer
        );
    end component;
	
	signal rst_clk_rx: std_logic;
	
	-- Signals between uart_rx and vga
	signal rx_data, char_data: std_logic_vector(7 downto 0);           -- Data output of uart_rx
	signal rx_data_rdy, old_rx_data_rdy, enable_write_ram, enable_rot: std_logic;  -- Data ready output of uart_rx
	signal rotation_degress : integer := 0;
	
	-- VGA
	signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
	
begin
    meta_harden_rst_i0: meta_harden
		port map(
			clk_dst 	=> clk_pin,
			rst_dst 	=> '0',    		-- No reset on the hardener for reset!
			signal_src 	=> rst_pin,
			signal_dst 	=> rst_clk_rx
		);
	
	-- (1) se genera el dato de UART
	uart_rx_i0: uart_rx
		generic map(
			CLOCK_RATE 	=> CLOCK_RATE,
			BAUD_RATE  	=> BAUD_RATE
		)
		port map(
			clk_rx     	=> clk_pin,
			rst_clk_rx 	=> rst_clk_rx,
	
			rxd_i      	=> rxd_pin,
			rxd_clk_rx 	=> open,
	
			rx_data_rdy	=> rx_data_rdy,
			rx_data    	=> rx_data,
			frm_err    	=> open
		);
		
    vga: vga_ctrl
        generic map(
			N 	=> 5 -- 125 Mhz / 5
		)
		port map(
			mclk        => clk_pin,
			hs          => hsync_pin,
            vs          => vsync_pin,
            red_o       => open,
            grn_o       => open,
            blu_o       => open,
            pixel_row   => pixel_y,
            pixel_col   => pixel_x
		);
		
	ctrl_rot: ctrl_rotation
	   port map(
	       -- inputs
            clk             => clk_pin,
            rst             => rst_clk_rx,
            new_data        => enable_write_ram,
            char_data       => char_data,
            -- outputs
            rotation_enable => enable_rot, -- salida que habilita la rotacion cada 1 seg
            degrees         => rotation_degress -- cantidad de grados a rotar
       );
	
	-- prendo toda la pantalla
	rgb <= (others => '1');
            
	process(clk_pin)
	begin
		if rising_edge(clk_pin) then
			if rst_clk_rx = '1' then
			    enable_write_ram <= '0';
				old_rx_data_rdy <= '0';
				char_data       <= "00000000";
			else
				-- Capture the value of rx_data_rdy for edge detection
				old_rx_data_rdy <= rx_data_rdy;
				-- If rising edge of rx_data_rdy, capture rx_data
				if (rx_data_rdy = '1' and old_rx_data_rdy = '0') then
				    enable_write_ram <= '1';
					char_data <= rx_data;
				else
				    enable_write_ram <= '0';
				end if;
			end if;	-- if !rst
		end if;
	end process;

end Behavioral;
