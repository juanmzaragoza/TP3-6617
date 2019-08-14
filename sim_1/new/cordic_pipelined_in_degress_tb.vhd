----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2019 08:50:14 PM
-- Design Name: 
-- Module Name: cordic_pipelined_in_degress_tb - Behavioral
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

entity cordic_pipelined_in_degress_tb is
--  Port ( );
end cordic_pipelined_in_degress_tb;

architecture Behavioral of cordic_pipelined_in_degress_tb is
    component cordic_pipelined_in_degress is
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
            degress : in integer; --# degress from 0 to 360
            
            MAGNITUDE  : in real := 200.0; --# Scale factor for vector length
    
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
    
    signal mag: real := 200.0;
    
begin
    
    clk <= not(clk) after TCK/ 2; -- reloj
    
    proc: process(clk)
    begin
        if rising_edge(clk) then
            mag <= mag + 1.0;
        end if;
    end process;
    
    DUT: cordic_pipelined_in_degress
	   generic map(
        SIZE                    => SIZE,
        ITERATIONS              => ITERATIONS,
        RESET_ACTIVE_LEVEL      => '1'
	   )
	   port map (
        clk       => clk,
        Reset       => '0',
        
        Mode        => cordic_rotate,     
        MAGNITUDE   => mag,
        
        degress     => 45, 
    
        X_result    => result_x,
        Y_result    => result_y,
        Z_result    => open
      );

end Behavioral;
