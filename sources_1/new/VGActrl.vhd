--------------------------------------------------------------------------
-- Modulo: Controlador VGA
-- Descripci�n: 
-- Autor: Sistemas Digitales (66.17)
--        Universidad de Buenos Aires - Facultad de Ingenier�a
--        www.campus.fi.uba.ar
-- Fecha: 16/04/13
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity vga_ctrl is
    generic(
        N: integer := 5;
		SIZE: positive
    );
    port (
		mclk: in std_logic;
      -- encendido: in std_logic := '0';
	  -- X : in signed(SIZE-1 downto 0); --# X coordinate
      -- Y : in signed(SIZE-1 downto 0); --# Y coordinate		
		
		pixel_on: in std_logic := '0';
		
		--red_i: in std_logic:= '0';

		--grn_i: in std_logic := '0';
		--blu_i: in std_logic := '0';
		-- ------------------------------
		hs: out std_logic;
		vs: out std_logic;
		red_o: out std_logic;
		grn_o: out std_logic;
		blu_o: out std_logic;
		pixel_row: out std_logic_vector(9 downto 0); --devuelve el nmero de Fila
		pixel_col: out std_logic_vector(9 downto 0)  -- devulve el nmero de columna
	);

end vga_ctrl;

architecture vga_ctrl_arq of vga_ctrl is



	-- Numero de pixeles en una linea horizontal (800)
	constant hpixels: unsigned(9 downto 0) := "1100100000";
	
	
	-- Numero de lineas horizontales en el display (521)

	constant vlines: unsigned(9 downto 0) := "1000001001";
	
	-- Se trata de 640 x 480
	
	constant hbp: unsigned(9 downto 0) := "0010010000";	 -- Back porch horizontal (144)
	constant hfp: unsigned(9 downto 0) := "1100010000";	 -- Front porch horizontal (784)
	constant vbp: unsigned(9 downto 0) := "0000011111";	 -- Back porch vertical (31)
	constant vfp: unsigned(9 downto 0) := "0111111111";	 -- Front porch vertical (511)
	
	

	-- Contadores (horizontal y vertical)
	signal hc, vc: unsigned(9 downto 0);
	
	-- Flag para obtener una habilitacion cada dos ciclos de clock
	signal clkdiv_flag: std_logic;
	
	-- Senal para habilitar la visualizacion de datos (estoy en la parte visible)
	signal vidon: std_logic;
	
	-- Senal para habilitar el contador vertical (el contador horizontal tiene que hacer avanzar al controlador vertical cuando llega al final)
	signal vsenable: std_logic;
	
	-- Senal para encender el recorte de pantalla
	
	signal encendido: std_logic := '0';
	
	
	

begin
    -- Division de la frecuencia del reloj
    prescaler: entity work.prescaler
    port map(
       clk_in => mclk,
       rst => '0',
       N1 =>  N,
--           N1 : in std_logic_vector(3 downto 0);
       clk_1 => clkdiv_flag
    
    );																			

    -- Contador horizontal
    process(mclk)
    begin
        if rising_edge(mclk) then
            if clkdiv_flag = '1' then
                if hc = hpixels then														
                    hc <= (others => '0');	-- El cont horiz se resetea cuando alcanza la cuenta m�xima de pixeles
                    vsenable <= '1';		-- Habilitaci�n del cont vert
                else
                    hc <= hc + 1;			-- Incremento del cont horiz
                    vsenable <= '0';		-- El cont vert se mantiene deshabilitado
                end if;
            end if;
        end if;
    end process;

    -- Contador vertical
    process(mclk)
    begin
        if rising_edge(mclk) then			 
            if clkdiv_flag = '1' then           -- Flag que habilita la operaci�n una vez cada dos ciclos (25 MHz)
                if vsenable = '1' then          -- Cuando el cont horiz llega al m�ximo de su cuenta habilita al cont vert
                    if vc = vlines then															 
                        vc <= (others => '0');  -- El cont vert se resetea cuando alcanza la cantidad maxima de lineas
                    else
                        vc <= vc + 1;           -- Incremento del cont vert
                    end if;
                end if;
            end if;
        end if;
    end process;

	-- hs <= '1' when (hc(9 downto 7) = "000") else '0';
	-- vs <= '1' when (vc(9 downto 1) = "000000000") else '0';
    hs <= '1' when (hc < "0001100001") else '0';   -- Generaci�n de la senal de sincronismo horizontal (96 menor al front porch)
    vs <= '1' when (vc < "0000000011") else '0';   -- Generaci�n de la senal de sincronismo vertical

    pixel_col <= std_logic_vector(hc - 144) when (vidon = '1') else std_logic_vector(hc);    
    pixel_row <= std_logic_vector(vc - 31) when (vidon = '1') else std_logic_vector(vc);
	
	-- Habilitaci�n de la salida de datos por el display cuando se encuentra entre los porches
    vidon <= '1' when (((hc < hfp) and (hc > hbp)) and ((vc < vfp) and (vc > vbp))) else '0';

	-- Ejemplos
	------------------------------------------------------------------------------------------------
	
	-- Los colores estan comandados por los switches de entrada del kit

	-- Dibuja un cuadrado rojo
 --   red_o <= '1' when ((hc(9 downto 6) = "0111") and vc(9 downto 6) = "0100" and red_i = '1' and vidon ='1') else '0';

	-- Dibuja una linea roja (valor espec�fico del contador horizontal
	-- red_o <= '1' when (hc = "1010101100" and red_i = '1' and vidon ='1') else '0';
	
	-- Dibuja una linea verde (valor espec�fico del contador horizontal)
   -- grn_o <= '1' when (hc = "0100000100" and grn_i = '1' and vidon ='1') else '0';	
	
	-- Dibuja una linea azul (valor espec�fico del contador vertical)
   -- blu_o <= '1' when (vc = "0100100001" and blu_i = '1' and vidon ='1') else '0';	

	-- Pinta la pantalla del color formado por la combinaci�n de las entradas red_i, grn_i y blu_i (switches)
	-- (Descomentar esto para pintar directamente desde afuera)
	-- red_o <= '1' when (red_i = '1' and vidon = '1') else '0';
	-- grn_o <= '1' when (grn_i = '1' and vidon = '1') else '0';
	-- blu_o <= '1' when (blu_i = '1' and vidon = '1') else '0';
	
---------------------------------------------------------------------------------------------------------


   -- Opción sin Memoria Ram, direcamente sobre la pantalla, sin calcular el número de tile, pero todo se representa con un pixel


   -- Determino el espcio de pantalla que van a ocupar nuestros ejes, la pantalla queda de 320x320
   
   encendido <= '1' when (((hc < "1001110000") and (hc > "0100110000")) and ((vc < "0110101111") and (vc > "0001101111"))) else '0';


   -- Dibujo el eje de las y en la posición x=464, recoedemos que hc cuenta todos los pixeles, incluso los que nos se ven
   red_o <= '1' when (hc = "0111010000" and encendido = '1' and vidon ='1') else '0';
   
   -- Dibujo el eje de las X en la posición y=271, recoedemos que vc cuenta todos los pixeles, incluso los que nos se ven

   red_o <= '1' when (vc = "0100001111" and encendido = '1' and vidon ='1') else '0';
   
   -- Dibujo las flechas de los ejes
   --Puntos eje x
   
   red_o <= '1' when (hc = "0100001110"  and vc = "1001101111" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0100010000"  and vc = "1001101111" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0100001101"  and vc = "1001101110" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0100010001"  and vc = "1001101110" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0100001100"  and vc = "1001101101" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0100010010"  and vc = "1001101101" and encendido = '1' and vidon ='1') else '0';
   
   
   -- Dibujo las flechas de los ejes
   --Puntos eje y
   red_o <= '1' when (hc = "0000011110"  and vc = "0111010001" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0000011110"  and vc = "0111001111" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0000011101"  and vc = "0111010010" and encendido = '1' and vidon ='1') else '0';

   red_o <= '1' when (hc = "0000011101"  and vc = "0111001110" and encendido = '1' and vidon ='1') else '0';
     
   red_o <= '1' when (hc = "0000011100"  and vc = "0111001101" and encendido = '1' and vidon ='1') else '0';
	
   red_o <= '1' when (hc = "0000011100"  and vc = "0111010011" and encendido = '1' and vidon ='1') else '0';

  
  -- Dibujo el pixel sobre el que esta barriendo  

   red_o <= '1' when (pixel_on = '1' and encendido = '1' and vidon ='1') else '0';


end vga_ctrl_arq;
