----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2019 07:35:07 PM
-- Design Name: 
-- Module Name: ctrl_rotation_tb - Behavioral
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
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ctrl_rotation_tb is
--  Port ( );
end ctrl_rotation_tb;

architecture Behavioral of ctrl_rotation_tb is
    
    component ctrl_rotation is
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
    end component;

    constant TCK: time:= 20 ns; 		-- periodo de reloj
    constant DELAY: natural:= 5;
    constant WORD_SIZE_T: natural:= 8;
    
    file datos: text open read_mode is "//home/juanzaragoza/sisdig6617/TP3_6617/TP3_6617.srcs/ctrl_rotation_data_tb.txt";
    
    signal clk, rot_ena: std_logic:= '0';
    signal input_char: std_logic_vector(7 downto 0) := (others => '0');
	signal expected_result: integer := 0;
    signal ciclos: integer := 0;
	signal degrees: integer := 0;
begin

    -- Generacion del clock del sistema
	clk <= not(clk) after TCK/ 2; -- reloj

	Test_Sequence: process
		variable l: line;
		variable ch: character:= ' '; -- para capturar blancos entre operandos
		variable aux: integer;
	begin
		while not(endfile(datos)) loop 		-- si se quiere leer de stdin se pone "input"
			wait until rising_edge(clk);
			ciclos <= ciclos + 1;			-- solo para debugging
			readline(datos, l); 			-- se lee una linea del archivo de valores de prueba
			read(l, ch); 					-- se extrae el primer caracter)
			input_char <= std_logic_vector(to_unsigned(character'pos(ch), 8));
			read(l, ch); 					-- se lee un caracter (es el espacio)
			read(l, aux); 					-- se lee otro entero de la linea
			expected_result <= to_integer(to_unsigned(aux, WORD_SIZE_T)); 	-- se carga el valor del operando B
		end loop;
		
		file_close(datos);		-- se cierra del archivo
		wait for TCK*(DELAY+1);
		assert false report		-- se aborta la simulacion (fin del archivo)
			"Fin de la simulacion" severity failure;
	end process Test_Sequence;
	
	DUT: ctrl_rotation
        generic map(
            BUFFER_CHARS_SIZE => 9,
            CHAR_SIZE => 8
        )
        port map(
            -- inputs
            clk => clk, 
            rst => '0',
            new_data => clk, -- si new_data=1 => hay un nuevo dato en char_data
            char_data => input_char,
            -- outputs
            rotation_enable => rot_ena,
            degrees => degrees
        );

	-- Verificacion de la condicion
	verificacion: process(clk)
	begin
		if rising_edge(clk) then
--			report integer'image(to_integer(a_file)) & " " & integer'image(to_integer(b_file)) & " " & integer'image(to_integer(z_file));
			assert degrees = expected_result report
				"Error: Salida del DUT no coincide con referencia (salida del dut = " & 
				integer'image(degrees) &
				", salida del archivo = " &
				integer'image(expected_result) & ")"
				severity warning;
		end if;
	end process;
	
end Behavioral;
