-- PVZ
library ieee;
use ieee.std_logic_1164.all;

library objects;
use objects.pvz_objects.all;

entity PVZ is
	port(
	clk: in std_logic;
	state: out std_logic
	);
end PVZ;

architecture bhv of PVZ is
begin
	state <= '1';
	
	process(clk)
		variable plant1 : object;
	begin
		plant1.obj_type := plant;
		plant1.sub_type := plant_shooter;
		plant1.pos_x := 600;
		plant1.pos_y := 380;
		plant1.hp := 100;
	end process;
end bhv;