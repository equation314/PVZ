
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Encoder is
  port(
    in_digit: in std_logic_vector(3 downto 0);
    out_digit: out std_logic_vector(6 downto 0)
  );
end Encoder;

architecture bhv of Encoder is
begin
  process(in_digit)
  begin
    case in_digit is
      when "0000" => out_digit <= "1111110"; -- 0
      when "0001" => out_digit <= "0110000"; -- 1
      when "0010" => out_digit <= "1101101"; -- 2
      when "0011" => out_digit <= "1111001"; -- 3
      when "0100" => out_digit <= "0110011"; -- 4
      when "0101" => out_digit <= "1011011"; -- 5
      when "0110" => out_digit <= "0011111"; -- 6
      when "0111" => out_digit <= "1110000"; -- 7
      when "1000" => out_digit <= "1111111"; -- 8
      when "1001" => out_digit <= "1110011"; -- 9
      when "1010" => out_digit <= "1110111"; -- a
      when "1011" => out_digit <= "0011111"; -- b
      when "1100" => out_digit <= "1001110"; -- c
      when "1101" => out_digit <= "0111101"; -- d
      when "1110" => out_digit <= "1001111"; -- e
      when "1111" => out_digit <= "1000111"; -- f
      when others => out_digit <= "0000000";
    end case;
  end process;
end bhv;
