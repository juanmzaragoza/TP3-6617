library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cordic is

  --# Rotation or vector mode selection.
  type cordic_mode is (cordic_rotate, cordic_vector);
  
    --## Correct angle so that it lies in quadrant 1 or 4.
  --# Args:
  --#  X : X coordinate
  --#  Y : Y coordinate
  --#  Z : Z coordinate (angle)
  --#  Xa : Adjusted X coordinate
  --#  Ya : Adjusted Y coordinate
  --#  Za : Adjusted Z coordinate (angle)
  procedure adjust_angle(X, Y, Z : in signed; signal Xa, Ya, Za : out signed);
  
end package;

package body cordic is

  --## Adjust points in the left half of the X-Y plane so that they will
  --#  lie within the +/-99.7 degree convergence zone of CORDIC on the right
  --#  half of the plane. Input vector and angle in x,y,z. Adjusted result
  --#  in xa,ya,za.
  procedure adjust_angle(x, y, z : in signed; signal xa, ya, za : out signed) is
    variable quad : unsigned(1 downto 0);  
    variable zp : signed(z'length-1 downto 0) := z;
    variable yp : signed(y'length-1 downto 0) := y;
    variable xp : signed(x'length-1 downto 0) := x;
  begin

    -- 0-based quadrant number of angle
    quad := unsigned(zp(zp'high downto zp'high-1));

    if quad = 1 or quad = 2 then -- Rotate into quadrant 0 and 3 (right half of plane)
      xp := -xp;
      yp := -yp;
      -- Add 180 degrees (flip the sign bit)
      zp := (not zp(zp'left)) & zp(zp'left-1 downto 0);
    end if;

    xa <= xp;
    ya <= yp;
    za <= zp;
  end procedure;
  
end package body;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.cordic.all;

entity cordic_sequential is
  generic (
    SIZE       : positive;
    ITERATIONS : positive;
    RESET_ACTIVE_LEVEL : std_ulogic := '1'
  );
  port (
    Clock : in std_ulogic;
    Reset : in std_ulogic;

    Data_valid   : in std_ulogic;  --# Load new input data
    Busy         : out std_ulogic; --# Generating new result
    Result_valid : out std_ulogic; --# Flag when result is valid
    Mode         : in cordic_mode; --# Rotation or vector mode selection

    X : in signed(SIZE-1 downto 0);
    Y : in signed(SIZE-1 downto 0);
    Z : in signed(SIZE-1 downto 0);

    X_result : out signed(SIZE-1 downto 0);
    Y_result : out signed(SIZE-1 downto 0);
    Z_result : out signed(SIZE-1 downto 0)
  );
end entity;

architecture rtl of cordic_sequential is
  type signed_array is array (natural range <>) of signed(SIZE-1 downto 0);

  function gen_atan_table(size : positive; iterations : positive) return signed_array is
    variable table : signed_array(0 to ITERATIONS-1);
  begin

      table(0) := to_signed(integer(45.0 * 2.0**size / 6.28318), size);
      table(1) := to_signed(integer(26.5650512 * 2.0**size / 6.28318), size);
      table(2) := to_signed(integer(14.0362435 * 2.0**size / 6.28318), size);
      table(3) := to_signed(integer(7.12501635 * 2.0**size / 6.28318), size);
      table(4) := to_signed(integer(3.57633437 * 2.0**size / 6.28318), size);
      table(5) := to_signed(integer(1.78991061 * 2.0**size / 6.28318), size);
      table(6) := to_signed(integer(0.89517371 * 2.0**size / 6.28318), size);
      table(7) := to_signed(integer(0.44761417 * 2.0**size / 6.28318), size);
      table(8) := to_signed(integer(0.2238105 * 2.0**size / 6.28318), size);
      table(9) := to_signed(integer(0.11190568 * 2.0**size / 6.28318), size);
      table(10) := to_signed(integer(0.05595289 * 2.0**size / 6.28318), size);
      table(11) := to_signed(integer(0.02797645 * 2.0**size / 6.28318), size);
      table(12) := to_signed(integer(0.01398823 * 2.0**size / 6.28318), size);
      table(13) := to_signed(integer(0.00699411 * 2.0**size / 6.28318), size);
      table(14) := to_signed(integer(0.00349706 * 2.0**size / 6.28318), size);
      table(15) := to_signed(integer(0.000174853 * 2.0**size / 6.28318), size);

	  

    return table;
  end function;

  constant ATAN_TABLE : signed_array(0 to ITERATIONS-1) := gen_atan_table(SIZE, ITERATIONS);

  signal xr : signed(X'range);
  signal yr : signed(Y'range);
  signal zr : signed(Z'range);

  signal x_shift : signed(X'range);
  signal y_shift : signed(Y'range);

  subtype iter_count is integer range 0 to ITERATIONS;

  signal cur_iter : iter_count;
begin

  cordic: process(Clock, Reset) is
    variable negative : boolean;
  begin
    if Reset = RESET_ACTIVE_LEVEL then
      xr <= (others => '0');
      yr <= (others => '0');
      zr <= (others => '0');
      cur_iter <= 0;
      Result_valid <= '0';
      Busy <= '0';
    elsif rising_edge(Clock) then
      if Data_valid = '1' then
        xr <= X;
        yr <= Y;
        zr <= Z;
        cur_iter <= 0;
        Result_valid <= '0';
        Busy <= '1';
      else
        if cur_iter /= ITERATIONS then
        --if cur_iter(ITERATIONS) /= '1' then
          if Mode = cordic_rotate then
            negative := zr(z'high) = '1';
          else
            negative := yr(y'high) = '0';
          end if;

          --if zr(z'high) = '1' then -- z or y is negative
          if negative then
            xr <= xr + y_shift; --(yr / 2**(cur_iter));
            yr <= yr - x_shift; --(xr / 2**(cur_iter));
            zr <= zr + ATAN_TABLE(cur_iter);
          else -- z or y is positive
            xr <= xr - y_shift; --(yr / 2**(cur_iter));
            yr <= yr + x_shift; --(xr / 2**(cur_iter));
            zr <= zr - ATAN_TABLE(cur_iter);
          end if;

          cur_iter <= cur_iter + 1;
          --cur_iter <= '0' & cur_iter(0 to ITERATIONS-1);
        end if;

        if cur_iter = ITERATIONS-1 then
          Result_valid <= '1';
          Busy <= '0';
        end if;
      end if;

    end if;
  end process;

  x_shift <= shift_right(xr, cur_iter);
  y_shift <= shift_right(yr, cur_iter);


  X_result <= xr;
  Y_result <= yr;
  Z_result <= zr;

end architecture;
