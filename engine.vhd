-- 游戏引擎，用来更新游戏中各物体的状态
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

library objects;
use objects.pvz_objects.all;

entity engine is
  port(
    clk: in std_logic;
    storage_enable: out std_logic;
    storage_func: out std_logic;
    storage_adder: out std_logic_vector(5 downto 0);
    obj_node: inout object_node
  );
end engine;

architecture bhv of engine is
  constant ADDR_FIRST := 
begin
  process(clk)
  begin
    if rising_edge(clk) then
    end if;
  end process;
end bhv;
