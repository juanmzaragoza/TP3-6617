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
            
            Data_valid   : in std_ulogic;  --# Load new input data
            Busy         : out std_ulogic; --# Generating new result
            Result_valid : out std_ulogic; --# Flag when result is valid
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
    signal Busy, Data_valid, Result_valid: std_logic := '0';
    signal x_integer, y_integer: integer := 0;
    signal rotation_enable_old: std_logic := '0';
    
begin

    process(mclk)
    begin
        if rising_edge(mclk) then
        
            
            if cordic_reset = '1' and Data_valid = '1' then
            
                cordic_reset <= '0';
                
            -- Calculo de cada punto del vector (200,0)
            elsif rotation_enable_old = '0' and rotation_enable = '1' then -- 1) cuando se habilita la rotacion, arranco a calculalar desde 1
            
                mag <= 1; -- habilito a contar las magnitudes
                RAM <= (others=>(others=>'0')); --limpio la RAM
                cordic_reset <= '0'; -- me aseguro que no se encuentre reseteado
                Data_valid <= '1'; -- habilito la nueva entrada para que comience el calculo
            
            elsif Result_valid = '1' and Busy = '0' then -- si termino de calcular
            
                x_integer <= to_integer(unsigned(result_x(SIZE-2 downto SIZE-INTEGER_BITS)))+480; --col
                y_integer <= to_integer(unsigned(result_y(SIZE-2 downto SIZE-INTEGER_BITS)))+240; --row
                RAM(y_integer)(x_integer) <= '1'; -- prendo el bit en la RAM
                
                mag <= mag + 1; -- aumento en 1 la magintud
                Data_valid <= '1'; -- lo pongo en 1 para indicar nuevo dato
                cordic_reset <= '1'; -- reseteo el cordic porque termine
                
            elsif mag >= 200 then -- si termino de calcular todas las magnitudes
            
                cordic_reset <= '1'; -- reseteo el cordic porque termine
                Data_valid <= '0'; -- lo pongo en cero para que cuenta las ITERATIONS del cordic
                
            else -- en cualquier otro caso
            
                Data_valid <= '0'; -- lo pongo en cero para que cuenta las ITERATIONS del cordic
                
            end if;
            
            -- me guardo el anterior para ver flanco ASC
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
        
        Data_valid      => Data_valid,  --# Load new input data
        Busy            => Busy, --# Generating new result
        Result_valid    => Result_valid, --# Flag when result is valid
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
