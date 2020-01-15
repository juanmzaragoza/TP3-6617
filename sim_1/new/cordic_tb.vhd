----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/08/2019 08:39:44 PM
-- Design Name: 
-- Module Name: cordic_tb - Behavioral
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
use work.cordic.all;

entity cordic_tb is
--  Port ( );
end cordic_tb;

architecture Behavioral of cordic_tb is

    component cordic_sequential is
        generic (
          SIZE               : positive; --# Width of operands
          ITERATIONS         : positive; --# Number of iterations for CORDIC algorithm
          RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
        );
        port (
          --# {{clocks|}}
          Clock : in std_ulogic; --# System clock
          Reset : in std_ulogic; --# Asynchronous reset
    
          --# {{control|}}
          Mode  : in cordic_mode; --# Rotation or vector mode selection
    
          --# {{data|}}
          X : in signed(SIZE-1 downto 0); --# X coordinate
          Y : in signed(SIZE-1 downto 0); --# Y coordinate
          Z : in signed(SIZE-1 downto 0); --# Z coordinate (angle in brads)
    
          X_result : out signed(SIZE-1 downto 0); --# X result
          Y_result : out signed(SIZE-1 downto 0); --# Y result
          Z_result : out signed(SIZE-1 downto 0)  --# Z result
        );
    end component;
    
    constant TCK: time:= 20 ns; 
    constant SIZE: positive := 20;
    constant ITERATIONS: positive := 20;
    
    signal clk, rot_ena, new_data: std_logic:= '0';
    signal X, Y, Z, Xa, Ya, Za,result_x, result_y: signed(SIZE-1 downto 0) := (others => '0');
    signal Zaux: signed(8 downto 0) := (others => '0');
    signal acc: integer := 0;
    signal FRAC_BITS: positive := 2;

begin

    clk <= not(clk) after TCK/ 2; -- reloj
    
    
    -- Vector unitario y conversion a brads
    FRAC_BITS <= SIZE-11; --11-1 = bits parte entera
    X <= to_signed(integer(200.0/cordic_gain(ITERATIONS) * 2.0 ** FRAC_BITS), result_y'length);
    Y <= (others => '0');
    
    Zaux <= to_signed(45 * 512 / 360, Zaux'length);
    -- 2 PI RAD = 2 ^ SIZE => 00=0grados, 01=90grados, 10=180grados, 11=270grados
    --Z <= "00100000000000000000";
    
    -- Paso angular 0.703125 grados = 0.5 brads
    -- 360 grados = 512 0.5 brads
    -- Entonces x_grados = x * 512 / 360 o bien y_brads = 45 grados * 512 / 360    
    Z <= Zaux&Z(SIZE-Zaux'length-1 downto 0);
    
    proc: process(clk) is
    begin
        acc <= acc + 1;
        if acc > 3 and acc < 5 then
            new_data <= '1';
        else
            new_data <= '0';
        end if;
        -- ajusto el angulo dependiendo en que cuadrante este
        adjust_angle(X, Y, Z, Xa, Ya, Za); 
    end process;
    
    DUT: cordic_sequential
	   generic map(
        SIZE                    => SIZE,
        ITERATIONS              => ITERATIONS,
        RESET_ACTIVE_LEVEL      => '1'
	   )
	   port map (
        Clock       => clk,
        Reset       => '0',
        
        Mode        => cordic_rotate,     
    
        X           => Xa,
        Y           => Ya,
        Z           => Za, 
    
        X_result    => result_x,
        Y_result    => result_y,
        Z_result    => open
      );

end Behavioral;
