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
use work.cordic.all;

entity crtl_screen is
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
end crtl_screen;

architecture Behavioral of crtl_screen is

    function draw_axis(pixel_row: std_logic_vector(9 downto 0); pixel_col: std_logic_vector(9 downto 0)) return boolean is
        begin
            return ((to_integer(unsigned(pixel_row)) <= 241 and to_integer(unsigned(pixel_row)) >= 240) or (to_integer(unsigned(pixel_col)) <= 321 and to_integer(unsigned(pixel_col)) >= 320));
        end;
        
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
            degrees : in integer; --# degress from 0 to 360
            
            MAGNITUDE  : in integer := 200; --# Scale factor for vector length
    
            X_result : out signed(SIZE-1 downto 0); --# X result
            Y_result : out signed(SIZE-1 downto 0); --# Y result
            Z_result : out signed(SIZE-1 downto 0)  --# Z result
        );
    end component;
    
    -- screen
    constant WIDTH_SCREEN: integer := 640;
    constant HEIGHT_SCREEN: integer := 480;
    -- cordic
    constant INTEGER_BITS: positive := 11;
    constant SIZE: positive := 20;
    constant ITERATIONS: positive := 20;
    
    --ram
    type ram_type is array (0 to HEIGHT_SCREEN-1) of std_logic_vector(WIDTH_SCREEN-1 downto 0);
    signal RAM: ram_type := (others=>(others=>'0'));
    --cordic
    signal result_x, result_y: signed(SIZE-1 downto 0) := (others => '0');
    signal mag: integer := 1;
    signal cordic_reset: std_logic := '0';
    --auxiliares
    signal busy: std_logic := '0';
    signal x_integer, y_integer, acc: integer := 0;
    signal aux1, aux2: boolean := false;
    signal rotation_enable_old: std_logic := '0';
    
begin

    process(mclk)
    begin
        if rising_edge(mclk) then
            
            -- Calculo de cada punto del vector (200,0)
            aux1 <= busy = '1';
            aux2 <= mag < 200;
            if aux1 and aux2 then -- 2) cada vez que esta busy, aumento la maginutd para obtener un nuevo result
            
                mag <= mag + 1;
                cordic_reset <= '0';
                acc <= acc + 1; -- aumento el acumulador para saber a partir de que momento tengo que empezar a leer el dato
                
            elsif rotation_enable_old = '0' and rotation_enable = '1' then -- 1) cuando se habilita la rotacion, arranco a calculalar desde 1
            
                busy <= '1';
                mag <= 1;
                RAM <= (others=>(others=>'0')); --limpio la RAM
                cordic_reset <= '1'; -- arranco los calculos del cordic nuevamente
                acc <= 0;
                
            else -- 3) si la magnitud es mayor a 200, dejo de estar busy porque termine de calcular la nueva posicion del vector
            
                busy <= '0';
                cordic_reset <= '0';
                
            end if;
            
            -- por cada result, tengo que ver si su parte entera es un numero entre 0 y 200
            -- porque el resultado no puede exceder ese valor
            --#1 valido que no sea 'X' ni 'U'
            --#2 convierto la parte entera
            if acc >= ITERATIONS then -- podriamos validar tambien que acc <= 200 + ITERATIONS
                x_integer <= to_integer(unsigned(result_x(SIZE-2 downto SIZE-INTEGER_BITS)))+480; --col
                y_integer <= to_integer(unsigned(result_y(SIZE-2 downto SIZE-INTEGER_BITS)))+240; --row
                RAM(y_integer)(x_integer) <= '1';
            end if;
            
            rotation_enable_old <= rotation_enable;
            
        end if;
    end process;
    
    cordic: cordic_pipelined_in_degress
	   generic map(
        SIZE                    => SIZE,
        ITERATIONS              => ITERATIONS,
        RESET_ACTIVE_LEVEL      => '1'
	   )
	   port map (
        clk         => mclk,
        Reset       => cordic_reset,
        
        Mode        => cordic_rotate,     
        MAGNITUDE   => mag,
        
        degrees     => degrees, 
    
        X_result    => result_x,
        Y_result    => result_y,
        Z_result    => open
      );
        
    pixel_on <= '1' when draw_axis(pixel_row, pixel_col) or RAM(to_integer(unsigned(pixel_row)))(to_integer(unsigned((pixel_col)))) = '1'
                    else '0';

end Behavioral;
