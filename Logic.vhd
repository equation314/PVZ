library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library pvz;
use pvz.pvz_objects.all;

-- 逻辑部分
entity Logic is
	port(
		reset: in std_logic;
		clock: in std_logic;
		out_plants: out plant_matrix;
		out_zombies: out zombie_vector;
		new_plant: in std_logic;  -- 新植物信号
		new_plant_type: in std_logic_vector(1 downto 0);  -- 新植物类型
		new_plant_x, new_plant_y: in integer range 0 to M-1;  -- 新植物坐标
		out_lost : out std_logic; -- 输赢
		out_round : out std_logic_vector(3 downto 0)
	);
end entity;

architecture bhv of Logic is
	signal count: std_logic_vector(30 downto 0);
	signal pea_clk_count : std_logic_vector(10 downto 0);
	signal zombie_count : std_logic_vector(5 downto 0);
	signal pea_clk: std_logic;
	signal plants: plant_matrix := (others => (others => ("01", "0000", M, '0', "0000")));
	signal zombies: zombie_vector := (others => ("0000", 0));
	signal passed_round : std_logic_vector(3 downto 0) := (others => '0'); -- 过去了多少轮

	signal restart : std_logic := '0';

	constant ROUND_CLK : integer := 20;
	constant ZOMBIE_MOVE_COUNT : integer := 3;
	constant NEW_ZOMBIE_Y : y_vector := (1, 3, 0, 4, 2, 3, 2, 0, 1, 4, 2, 4, 3, 1, 0, 1, 0, 3, 2, 4);

begin
	out_zombies <= zombies;
	out_plants <= plants;

	process(clock)
	begin
		if (rising_edge(clock)) then
			restart <= reset;
			if (count = 32000000) then
				count <= (others => '0');
				pea_clk <= '1';
			else
				count <= count + 1;
				pea_clk <= '0';
			end if;
		end if;
	end process;

	-- 处理豌豆
	process(pea_clk, new_plant, reset)
		variable p: plant;
		variable x, y: integer range 0 to M-1;
		constant NUT_HARM : integer := 1;
		constant NORM_HARM : integer := 2;
		variable has_lost : std_logic := '0';
		variable new_y: integer range 0 to N-1;
	begin

		if (rising_edge(pea_clk)) then
			if (restart='1') then
				for i in 0 to N-1 loop
					for j in 0 to M-1 loop
						plants(i)(j).hp <= (others=>'0');
					end loop;
				end loop;

				for i in 0 to N-1 loop
					zombies(i).hp <= "0000";
				end loop;
				has_lost := '0';
				out_lost <= '0';
				passed_round <= (others => '0');

			else
				if (new_plant = '1') then
					if (plants(new_plant_y)(new_plant_x).hp > 0 and new_plant_type = "10") then
						plants(new_plant_y)(new_plant_x).with_sun <= '0';
						plants(new_plant_y)(new_plant_x).cd <= "0000";
						plants(new_plant_y)(new_plant_x).plant_type <= "10";
					elsif (not(zombies(new_plant_y).x = new_plant_x and zombies(new_plant_y).hp > 0)) then
						plants(new_plant_y)(new_plant_x).pea <= M;
						plants(new_plant_y)(new_plant_x).with_sun <= '0';
						plants(new_plant_y)(new_plant_x).cd <= "0000";
						plants(new_plant_y)(new_plant_x).hp <= "1010";
						plants(new_plant_y)(new_plant_x).plant_type <= new_plant_type;
					end if;
				end if;

				-- 更新植物
				if (reset='1') then
					for i in 0 to N-1 loop
						for j in 0 to M-1 loop
							plants(i)(j).pea <= M;
							plants(i)(j).with_sun <= '0';
							plants(i)(j).cd <= "0000";
							--plants(i*M + j).hp <= "0000";
						end loop;
					end loop;
				else
					for i in 0 to N-1 loop
						for j in 0 to M-1 loop
							p := plants(i)(j);
							if (p.hp > 0 and p.plant_type = "00") then
								if (zombies(i).hp > 0 and zombies(i).x >= j) then
									if (p.pea = zombies(i).x or p.pea = zombies(i).x-1) then
										plants(i)(j).pea <= M;
										zombies(i).hp <= zombies(i).hp - 1;
									elsif (plants(i)(j).pea < M) then
										plants(i)(j).pea <= p.pea + 1;
									elsif (p.cd = 0) then
										plants(i)(j).pea <= j;
										plants(i)(j).cd <= "1010";
									end if;
								elsif (p.pea < M) then
									plants(i)(j).pea <= p.pea + 1;
								end if;
								if (p.cd > 0) then
									plants(i)(j).cd <= p.cd - 1;
								end if;
							elsif (p.hp > 0 and p.plant_type = "10") then -- 向日葵产生阳光
								if (p.cd = 0) then
									if (p.with_sun = '1') then
										plants(i)(j).with_sun <= '0';
									elsif (p.with_sun = '0') then
										plants(i)(j).with_sun <= '1';
									end if;
									plants(i)(j).cd <= "1010";
								else
									plants(i)(j).cd <= p.cd - 1;
								end if;
							end if;
						end loop;
					end loop;
				end if;

				-- 更新僵尸

				if pea_clk_count=ROUND_CLK then
					pea_clk_count <= (others => '0');
					new_y := NEW_ZOMBIE_Y(conv_integer(unsigned(passed_round)));
					passed_round <= passed_round + 1;
					zombies(new_y).x <= M;
					zombies(new_y).hp <= "0101";
				else
					pea_clk_count <= pea_clk_count + 1;
				end if;

				if (zombie_count=ZOMBIE_MOVE_COUNT) then
					for i in 0 to N-1 loop
						if (zombies(i).hp > 0) then
							if (plants(i)(zombies(i).x-1).hp > 0) then
								if (plants(i)(zombies(i).x-1).plant_type="01") then -- 坚果墙的防御力较高特殊处理
									plants(i)(zombies(i).x-1).hp <= plants(i)(zombies(i).x-1).hp - NUT_HARM;
								else
									plants(i)(zombies(i).x-1).hp <= plants(i)(zombies(i).x-1).hp - NORM_HARM;
								end if;
							else
								zombies(i).x <= zombies(i).x - 1;
							end if;
						end if;
					end loop;
					zombie_count <= (others=>'0');
				else
					zombie_count <= zombie_count + 1;
				end if;

					-- 判断是否输了
				for i in 0 to N-1 loop
					if (zombies(i).hp > 0 and zombies(i).x = 0 and plants(i)(zombies(i).x).hp = 0) then
						has_lost := '1';
					end if;
				end loop;
				out_lost <= has_lost;
			end if;
		end if;
	end process;

	process(passed_round)
	begin
		out_round <= passed_round;
	end process;

end architecture;
