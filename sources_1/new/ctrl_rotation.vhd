----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/07/2019 01:10:35 PM
-- Design Name: 
-- Module Name: ctrl_rotation - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ctrl_rotation is
    generic(
		BUFFER_CHARS_SIZE: integer := 9;
		CHAR_SIZE: integer := 8
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
end ctrl_rotation;

-- IDEA: recibo un char en char_data y lo voy guardando en memoria
-- Si se forma ROT C A o ROT C H se generara rotation_enable=1 y la cantidad de grados se modifica de manera continua cada un tiempo visualizable (1seg)
-- Si se forma ROT A angulo se genera rotation_enable=1 y la cantidad de grados de manera fija
-- Mientras se ingrese algo distinto se genera rotation_enable=0 y deshabilita la rotacion
architecture Behavioral of ctrl_rotation is

    type buffer_type is array (0 to BUFFER_CHARS_SIZE-1) of std_logic_vector(CHAR_SIZE-1 downto 0);
    
    signal buffer_chars: buffer_type := (others=>(others=>'0'));
    
    signal acc_degrees :integer := 0;
    signal rotation_enable_aux: std_logic := '0';
    
begin
    
    bufferWrite: process(clk)
        variable aux: buffer_type;
        begin
            if rising_edge(clk) then
                if new_data = '1' then
                    for i in 0 to buffer_chars'length-1 loop
                        if i > 0 then
                            buffer_chars(i-1) <= buffer_chars(i);
                        end if;
                    end loop;
                    buffer_chars(BUFFER_CHARS_SIZE-1) <= char_data;
                end if;
            end if;
        end process;
        
    readCommand: process(clk)
        begin
            if rotation_enable_aux = '1' then -- para que el rotation enable sea solo un pulso
                rotation_enable_aux <= '0';
            else
                if buffer_chars(BUFFER_CHARS_SIZE-1) and buffer_chars(BUFFER_CHARS_SIZE-2) and buffer_chars(BUFFER_CHARS_SIZE-3) then -- si es un numero => ROT A 000
                    
                    if buffer_chars(BUFFER_CHARS_SIZE-4) and buffer_chars(BUFFER_CHARS_SIZE-5) and buffer_chars(BUFFER_CHARS_SIZE-6) and buffer_chars(BUFFER_CHARS_SIZE-7) and buffer_chars(BUFFER_CHARS_SIZE-8) and buffer_chars(BUFFER_CHARS_SIZE-9) then -- espero un espacio, una A, un espacio y TOR => ROT C 000
                        rotation_enable_aux <= '1';
                        degrees <= 100; --TODO: transformar los grados del buffer
                    end if;
                    
                elsif buffer_chars(BUFFER_CHARS_SIZE-1) then -- tiene que ser una H o A
                
                    if buffer_chars(BUFFER_CHARS_SIZE-2) and buffer_chars(BUFFER_CHARS_SIZE-3) and buffer_chars(BUFFER_CHARS_SIZE-4) and buffer_chars(BUFFER_CHARS_SIZE-5) and buffer_chars(BUFFER_CHARS_SIZE-6) and buffer_chars(BUFFER_CHARS_SIZE-7) then -- espero un espacio, una C, un espacio y TOR => ROT C 000
                        rotation_enable_aux <= '1';
                        degrees <= acc_degrees + 1;
                        acc_degrees <= acc_degrees + 1;
                    end if;
                    
                else -- no es un comando y dejo de enviar la rotacion
                    rotation_enable_aux <= '0';
                    -- decidir que se hace con el angulo
                end if;
            end if;
        end process;
        
    rotation_enable <= rotation_enable_aux;

end Behavioral;
