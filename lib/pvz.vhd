library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package pvz_objects is
	constant N: integer := 5;
	constant M: integer := 9;

	type plant is record
		plant_type: std_logic_vector(1 downto 0); -- 00: peashooter; 01: sunflower; 10: wallnut
		hp: std_logic_vector(3 downto 0); -- 植物血量
		pea: integer range 0 to M; -- 豌豆横坐标
		pea_cd: std_logic_vector(3 downto 0); -- 发射豌豆的 CD
	end record;

	type zombie is record
		hp: std_logic_vector(3 downto 0); -- 僵尸血量
		x: integer range 0 to M-1; -- 僵尸横坐标
	end record;

	type plant_vector is array(0 to N*M-1) of plant;
	type zombie_vector is array(0 to N-1) of zombie;

	type mouse_state is (NO, SUNFLOWER_DOWN, PEASHOOTER_DOWN, WALLNUT_DOWN);

end package;
