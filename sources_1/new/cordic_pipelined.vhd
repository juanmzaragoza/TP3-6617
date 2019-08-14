----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2019 08:25:51 PM
-- Design Name: 
-- Module Name: cordic_pipelined - Behavioral
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

entity cordic_pipelined_in_degress is
    generic (
        INTEGER_BITS       : positive := 11; --# INTEGER_BITS - 1 number integer part
        SIZE               : positive; --# Width of operands (Always greather than 9)
        ITERATIONS         : positive; --# Number of iterations for CORDIC algorithm
        RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
    );
    port (
        --# {{clocks|}}
        clk   : in std_ulogic; --# System clock
        Reset : in std_ulogic; --# Asynchronous reset
        Mode  : in cordic_mode := cordic_rotate; --# Rotation or vector mode selection

        --# {{data|}}
        degrees : in integer; --# degress from 0 to 360
        
        MAGNITUDE  : in real := 200.0; --# Scale factor for vector length

        X_result : out signed(SIZE-1 downto 0); --# X result
        Y_result : out signed(SIZE-1 downto 0); --# Y result
        Z_result : out signed(SIZE-1 downto 0)  --# Z result
    );
end cordic_pipelined_in_degress;

architecture Behavioral of cordic_pipelined_in_degress is
    
    signal Xin, Yin, Zin, Xa, Ya, Za, complete_vector: signed(SIZE-1 downto 0) := (others => '0');
    signal Zaux: signed(8 downto 0) := (others => '0');
    signal FRAC_BITS: positive := INTEGER_BITS;
    
begin

    proc: process(clk) is
        begin
            -- ajusto el angulo dependiendo en que cuadrante este
            adjust_angle(Xin, Yin, Zin, Xa, Ya, Za); 
        end process;
        
    FRAC_BITS <= SIZE - INTEGER_BITS;
    
    Xin <= to_signed(integer(MAGNITUDE/cordic_gain(ITERATIONS) * 2.0 ** FRAC_BITS), X_result'length);
    Yin <= (others => '0');
    -- 2 PI RAD = 2 ^ SIZE => 00=0grados, 01=90grados, 10=180grados, 11=270grados
    --Z <= "00100000000000000000";
    
    -- Paso angular 0.703125 grados = 0.5 brads
    -- 360 grados = 512 0.5 brads
    -- Entonces x_grados = x * 512 / 360 o bien y_brads = 45 grados * 512 / 360
    Zaux <= to_signed(degrees * 512 / 360, Zaux'length); 
    Zin <= Zaux&complete_vector(SIZE-Zaux'length-1 downto 0);
    
    DUT: cordic_pipelined
	   generic map(
        SIZE                    => SIZE,
        ITERATIONS              => ITERATIONS,
        RESET_ACTIVE_LEVEL      => '1'
	   )
	   port map (
        Clock       => clk,
        Reset       => Reset,
        
        Mode        => cordic_rotate,     
    
        X           => Xa,
        Y           => Ya,
        Z           => Za, 
    
        X_result    => X_result,
        Y_result    => Y_result,
        Z_result    => Z_result
      );
    
end Behavioral;