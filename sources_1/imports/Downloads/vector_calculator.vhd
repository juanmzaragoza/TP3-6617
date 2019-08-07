----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/20/2019 04:52:45 PM
-- Design Name: 
-- Module Name: tile_number_calculator - Behavioral
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

entity vector_calculator is
    generic(
		AW: integer := 14 -- para un vector de norma 100
	);
    port ( clk : in std_logic;
	
           pixel_x: in std_logic_vector(9 downto 0);  --contador de pixeles de la VGA
           pixel_y : in std_logic_vector(9 downto 0); --contador de pixeles de la VGA
		   
		   --cordic_pixel_x: in signed := (others => '0');   --salida del cordic
           --cordic_pixel_y : in signed := (others => '0');  --salida del cordic
		   
		   pixel_on: out std_logic := '0'
		   
    );
end vector_calculator;

architecture Behavioral of vector_calculator is

    type vector_number_x is array (0 to AW-1) of std_logic_vector(9 downto 0);
    type vector_number_y is array (0 to AW-1) of std_logic_vector(9 downto 0);

	signal vector_x: vector_number_x;
	signal vector_y: vector_number_y;
	
	signal r : integer := vector_number_x'length;

begin

    process(clk)
	
		--variable r: integer;

		begin
		   if rising_edge(clk) then
		
			for i in vector_number_x'range loop
                
				--if  r = AW then	
				--    r <= 1;  -- El cont vert se resetea cuando alcanza la cantidad maxima de lineas
				--else
				
		        	vector_x(i)  <= std_logic_vector (to_unsigned(100*(i/r)+ 320,vector_x(i)'length)); 

					vector_y(i) <=  std_logic_vector (to_unsigned(100*(i/r)+ 240,vector_x(i)'length)); 
	
					--r <= r + 1; 
	
				--end if;
	        
			end loop;
		  end if;
	end process;
	
		
--	pixel_on <= '1' when ((vector_x(1) = pixel_x) and (vector_y(1) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(2) = pixel_x) and (vector_y(2) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(3) = pixel_x) and (vector_y(3) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(4) = pixel_x) and (vector_y(4) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(5) = pixel_x) and (vector_y(5) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(6) = pixel_x) and (vector_y(6) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(7) = pixel_x) and (vector_y(7) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(8) = pixel_x) and (vector_y(8) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(9) = pixel_x) and (vector_y(9) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(10) = pixel_x) and (vector_y(10) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(11) = pixel_x) and (vector_y(11) = pixel_y)) else '0';
--	pixel_on <= '1' when ((vector_x(12) = pixel_x) and (vector_y(12) = pixel_y)) else '0';
	pixel_on <= '1' when ((vector_x(13) = pixel_x) and (vector_y(13) = pixel_y)) else '0';

	
	
	-- std_logic_vector(to_unsigned(tile_number_aux, tile_number'length));

	-- Dibujo el vector ingresado, la amplitud del vecto es de 100 

    -- red_o <= '1' when ((hc = unsigned(std_logic_vector (X_aux)+ 464) and (vc = unsigned(std_logic_vector (Y_aux)+ 271)) and encendido = '1' and vidon ='1') else '0';

	
	
end Behavioral;
