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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ctrl_rotation is
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
end ctrl_rotation;

-- IDEA: recibo un char en char_data y lo voy guardando en memoria
-- Si se forma ROT C A o ROT C H se generara rotation_enable=1 y la cantidad de grados se modifica de manera continua cada un tiempo visualizable (1seg)
-- Si se forma ROT A angulo se genera rotation_enable=1 y la cantidad de grados de manera fija
-- Mientras se ingrese algo distinto se genera rotation_enable=0 y deshabilita la rotacion
architecture Behavioral of ctrl_rotation is
    
    type buffer_type is array (0 to BUFFER_CHARS_SIZE-1) of std_logic_vector(CHAR_SIZE-1 downto 0);
    
    function word_to_int(word: std_logic_vector(7 downto 0)) return integer is
        begin
            return to_integer(unsigned(word));
        end;

    -- 48=>[0], 57=>[9], 32=>[espacio], 67=>[C], 99=>[c], 84=>[T], 116=>[t], 79=>[O], 111=>[o], 82=>[R], 114=>[r], 65=>[A], 97=>[a], 72=>[H], 104=>[h],
    -- ROT A [0-3][0-9][0-9] 
    function is_fixed_rotation_command(buffer_chars: buffer_type) return boolean is
            variable last_is_digit: boolean := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) >= 48 and word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) <= 57;
            variable before_last_is_digit: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-2)) >= 48 and word_to_int(buffer_chars(BUFFER_CHARS_SIZE-2)) <= 57);
            variable is_digit_123: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-3)) >= 48 and word_to_int(buffer_chars(BUFFER_CHARS_SIZE-3)) <= 51);
            variable is_last_space: boolean := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-4)) = 32;
            variable is_a_Aa: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-5)) = 65 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-5)) = 97);
            variable is_first_space: boolean := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-6)) = 32;
            variable is_a_Tt: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-7)) = 84 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-7)) = 116);
            variable is_a_Oo: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-8)) = 79 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-8)) = 111);
            variable is_a_Rr: boolean := (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-9)) = 82 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-9)) = 114);
        begin
            return last_is_digit and before_last_is_digit and is_digit_123 and is_last_space and is_a_Aa and is_first_space and is_a_Tt and is_a_Oo and is_a_Rr;
        end;
    
    function is_counterclockwise_rotation(buffer_chars: buffer_type) return boolean is
        begin
            return (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) = 65 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) = 97);
        end;
        
    function is_hourly_rotation(buffer_chars: buffer_type) return boolean is
        begin
            return (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) = 72 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1)) = 104);
        end;
        
    -- tiene que ser una H o A => ROT C [A,H]
    -- espero un espacio, una C, un espacio y TOR => ROT C 000
    function is_continuos_rotation_command(buffer_chars: buffer_type) return boolean is
        begin
            return (is_counterclockwise_rotation(buffer_chars) or is_hourly_rotation(buffer_chars)) and word_to_int(buffer_chars(BUFFER_CHARS_SIZE-2)) = 32 and (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-3)) = 67 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-3)) = 99)  and word_to_int(buffer_chars(BUFFER_CHARS_SIZE-4)) = 32 and (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-5)) = 84 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-5)) = 116) and (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-6)) = 79 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-6)) = 111) and (word_to_int(buffer_chars(BUFFER_CHARS_SIZE-7)) = 82 or word_to_int(buffer_chars(BUFFER_CHARS_SIZE-7)) = 114);
        end;
    

    function get_degrees_from_buffer(buffer_chars: buffer_type) return integer is
            variable unidad: integer;
            variable decena: integer;
            variable centena: integer;
            variable resultado: integer;
        begin
            unidad := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-1))-48;
            decena := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-2))-48;
            centena := word_to_int(buffer_chars(BUFFER_CHARS_SIZE-3))-48;

            resultado := unidad + decena*10 + centena*100;

            if resultado >= 0 and resultado <= 360 then
                return resultado;
            else
                return 0;
            end if;

        end;
    
    signal buffer_chars: buffer_type := (others=>(others=>'0'));
    
    signal acc_degrees :integer := 0;
    signal rotation_enable_aux, fixed_rotation_enabled, continuos_rotation_enabled: std_logic := '0';
    
begin
    
    bufferWrite: process(clk)
            variable aux: buffer_type;
        begin
            if rising_edge(clk) then
            
                -- 1) llega un nuevo dato => reescribo (desplazando)
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
    
    -- 2) valido lo que hay en buffer
    readCommand: process(clk, rst)
        begin
            
            if rising_edge(clk) then
                -- (ROTACION FIJA) si es un numero => ROT A [0-3][0-9][0-9] 
                if is_fixed_rotation_command(buffer_chars) then
                    
                    fixed_rotation_enabled <= '1';
                    continuos_rotation_enabled <= '0';
                    
                    acc_degrees <= get_degrees_from_buffer(buffer_chars);
    
                -- (ROTACION CONTINUA) tiene que ser una H o A => ROT C [A,H]
                elsif is_continuos_rotation_command(buffer_chars) then 
                
                    continuos_rotation_enabled <= '1';
                    fixed_rotation_enabled <= '0';
                    
                    if rotation_enable_aux = '1' then
                        if is_counterclockwise_rotation(buffer_chars) then -- si la rotacion es anti-horario
                            -- cuento hasta 360
                            if (acc_degrees + 1) <= 360 then
                                acc_degrees <= acc_degrees + 1;
                            else
                                acc_degrees <= 0;
                            end if;
                            
                        else -- la rotacion es horaria
                            -- y cuento hasta 0
                            if (acc_degrees - 1) >= 0 then
                                acc_degrees <= acc_degrees - 1;
                            else
                                acc_degrees <= 360;
                            end if;
                        end if;
                    end if;
    
                -- no es un comando y dejo de enviar la rotacion
                else 
                    continuos_rotation_enabled <= '0';
                    fixed_rotation_enabled <= '0';
                    -- decidir que se hace con el angulo
                end if;
            end if;
        end process;

    -- Division de la frecuencia del reloj para obtener señal de 1 seg
    prescaler: entity work.prescaler
        port map(
           clk_in => clk,
           rst => rst,
           N1 =>  N,
            -- N1 : in std_logic_vector(3 downto 0);
           clk_1 => rotation_enable_aux
        );
        
    rotation_enable <= (rotation_enable_aux and (continuos_rotation_enabled xor fixed_rotation_enabled));
    degrees <= acc_degrees;

end Behavioral;
