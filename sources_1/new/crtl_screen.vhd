----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/06/2019 08:04:00 PM
-- Design Name: 
-- Module Name: crtl_screen - Behavioral
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

entity crtl_screen is
    port(
        -- inputs
		mclk: in std_logic;
		pixel_row: in std_logic_vector(9 downto 0); --devuelven en el sistema la posicion del barrido
		pixel_col: in std_logic_vector(9 downto 0);
		-- outputs
		pixel_on: out std_logic
	);
end crtl_screen;

architecture Behavioral of crtl_screen is

    function draw_axis(pixel_row: std_logic_vector(9 downto 0); pixel_col: std_logic_vector(9 downto 0)) return boolean is
        begin
            return ((to_integer(unsigned(pixel_row)) <= 241 and to_integer(unsigned(pixel_row)) >= 240) or (to_integer(unsigned(pixel_col)) <= 321 and to_integer(unsigned(pixel_col)) >= 320));
        end;
        
    component vector_calculator is
        generic(
            AW: integer := 100 -- para un vector de norma 100
        );
        port ( clk : in std_logic;
        
               pixel_x: in std_logic_vector(9 downto 0);  --contador de pixeles de la VGA
               pixel_y : in std_logic_vector(9 downto 0); --contador de pixeles de la VGA
               
               --cordic_pixel_x: in signed := (others => '0');   --salida del cordic
               --cordic_pixel_y : in signed := (others => '0');  --salida del cordic
               
               pixel_on: out std_logic := '0'
               
        );
    end component;
    
    signal vector_on: std_logic := '0';
begin
    
    vectorCalculator: vector_calculator
        port map(
            clk             => mclk,
            pixel_x         => pixel_col,
            pixel_y         => pixel_row,
            --cordic_pixel_x  => 10,
            --cordic_pixel_y  => 10,
            pixel_on        => vector_on
        );
        
    pixel_on <= '1' when draw_axis(pixel_row, pixel_col) or vector_on = '1'
                    else '0';

end Behavioral;
