----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/14/2019 07:54:32 PM
-- Design Name: 
-- Module Name: crtl_screen_tb - Behavioral
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

entity crtl_screen_tb is
--  Port ( );
end crtl_screen_tb;

architecture Behavioral of crtl_screen_tb is

    component crtl_screen is
        port(
            -- inputs
            mclk: in std_logic;
            pixel_row: in std_logic_vector(9 downto 0); --devuelven en el sistema la posicion del barrido
            pixel_col: in std_logic_vector(9 downto 0);
            rotation_enable: in std_logic; -- habilita la rotacion...
            degrees: in integer; -- esta cantidad de grados
            -- outputs
            pixel_on: out std_logic
        );
    end component;
    
    constant TCK: time:= 20 ns; 
    
    signal clk, new_data, pixel: std_logic:= '0';
    signal pixel_y, pixel_x: std_logic_vector(9 downto 0) := (others => '0');
    signal y_acc, x_acc: integer := 0;
    
begin

    clk <= not(clk) after TCK/ 2; -- reloj
    
    DUT: crtl_screen
        port map(
            mclk            => clk,
            pixel_row       => pixel_x,
            pixel_col       => pixel_y,
            rotation_enable => new_data,
            degrees         => 45,
            pixel_on        => pixel
        );
        
    process(clk)
    begin
        if rising_edge(clk) then
            
            if x_acc = 0 and y_acc >= 1 and y_acc <= 3  then
                new_data <= '1';
            else
                new_data <= '0';
            end if;
            
            pixel_x <= std_logic_vector(to_unsigned(x_acc, pixel_x'length));
            pixel_y <= std_logic_vector(to_unsigned(y_acc, pixel_y'length));
            
            if y_acc < 639 then
                y_acc <= y_acc + 1;
            else
                y_acc <= 0;
                if x_acc < 479 then
                    x_acc <= x_acc + 1;
                else
                    x_acc <= 0;
                end if;
            end if;
            
            
        end if;
    end process;
        
end Behavioral;
