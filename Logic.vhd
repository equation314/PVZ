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
		out_plants: out plant_vector;
		out_zombies: out zombie_vector;
		new_plant: in std_logic;  -- 新植物信号
		new_plant_type: in std_logic_vector(1 downto 0);  -- 新植物类型
		new_plant_x, new_plant_y: in integer range 0 to M-1;  -- 新植物坐标
		out_win, out_lost : out std_logic -- 输赢
	);
end entity;

architecture bhv of Logic is
	signal count: std_logic_vector(30 downto 0);
	signal pea_clk_count : std_logic_vector(10 downto 0);
	signal zombie_count : std_logic_vector(5 downto 0);
	signal pea_clk: std_logic;
	signal plants: plant_vector := (("10", "1010", M, '0', "0000"), ("01", "1010", M, '0', "0000"), others => ("10", "1010", M, '0', "0000"));
	signal zombies: zombie_vector := (("1010", 15), others => ("0000", 0));
	signal passed_round : integer := 0; -- 过去了多少轮

	constant ROUND_CLK : integer := 20;
	constant ZOMBIE_MOVE_COUNT : integer := 2;
	constant WIN_CONDITION : integer := 10; -- 需要过10轮才能赢
	constant NEW_ZOMBIE_Y : y_vector := (1, 3, 0, 4, 2, 3, 2, 0, 1, 4, 2, 4, 3, 1, 0, 1, 0, 3, 2, 4);

begin
	out_zombies <= zombies;
	out_plants <= plants;

	process(clock)
	begin
		if (rising_edge(clock)) then
			if (count = 30 * 1000000) then
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
		variable has_win : std_logic := '0';
		variable new_y: integer range 0 to N-1;
	begin
		if (rising_edge(pea_clk)) then
			-- 放置植物
			if (new_plant = '1' and reset='0') then
				if (not(zombies(new_plant_y).x = new_plant_x and zombies(new_plant_y).hp > 0)) then
					x := new_plant_x;
					y := new_plant_y;
					plants(y*M + x).pea <= M;
					plants(y*M + x).with_sun <= '0';
					plants(y*M + x).cd <= "0000";
					plants(new_plant_y*M + new_plant_x).hp <= "1010";
					plants(new_plant_y*M + new_plant_x).plant_type <= new_plant_type;
				end if;
			end if;

			-- 更新植物
			if (reset='1') then
				for i in 0 to N-1 loop
					for j in 0 to M-1 loop
						plants(i*M + j).pea <= M;
						plants(i*M + j).with_sun <= '0';
						plants(i*M + j).cd <= "0000";
						--plants(i*M + j).hp <= "0000";
					end loop;
				end loop;
			else
				for i in 0 to N-1 loop
					for j in 0 to M-1 loop
						p := plants(i * M + j);
						if (p.hp > 0 and p.plant_type = "00") then
							if (zombies(i).hp > 0 and zombies(i).x >= j) then
								if (p.pea = zombies(i).x or p.pea = zombies(i).x-1) then
									p.pea := M;
									zombies(i).hp <= zombies(i).hp - 2;
								elsif (p.pea < M) then
									p.pea := p.pea + 1;
								elsif (p.cd = 0) then
									p.pea := j;
									p.cd := "1010";
								end if;
							elsif (p.pea < M) then
								p.pea := p.pea + 1;
							end if;
							if (p.cd > 0) then
								p.cd := p.cd - 1;
							end if;
							plants(i * M + j) <= p;
						elsif (p.hp > 0 and p.plant_type = "01") then -- 向日葵产生阳光
							if (p.cd = 0) then
								if (p.with_sun = '1') then
									p.with_sun := '0';
								elsif (p.with_sun = '0') then
									p.with_sun := '1';
								end if;
								p.cd := "1010";
							else
								p.cd := p.cd - 1;
							end if;
							plants(i * M + j) <= p;
						end if;
					end loop;
				end loop;
			end if;

			-- 更新僵尸
			if reset='1' then -- 重置僵尸
				for i in 0 to N-1 loop
					zombies(i).hp <= "0000";
				end loop;
				has_lost := '0';
				out_win <= '0';
				out_lost <= '0';
				passed_round <= 0;
			else
				if pea_clk_count=ROUND_CLK then
					pea_clk_count <= (others => '0');
					if passed_round = WIN_CONDITION then
						has_win := '0';
					else -- 新增僵尸
						new_y := NEW_ZOMBIE_Y(passed_round);
						passed_round <= passed_round + 1;
						zombies(new_y).x <= M;
						zombies(new_y).hp <= "0101";
						has_win := '0';
					end if;
				else
					has_win := '0';
					pea_clk_count <= pea_clk_count + 1;
				end if;
				has_win := '0';

				if (zombie_count=ZOMBIE_MOVE_COUNT) then
					for i in 0 to N-1 loop
						if (zombies(i).hp > 0) then
							if (plants(i * M + zombies(i).x-1).hp > 0) then
								if (plants(i * M + zombies(i).x-1).plant_type="10") then -- 坚果墙的防御力较高，特殊处理
									--plants(i * M + zombies(i).x-1).hp <= plants(i * M + zombies(i).x-1).hp - NUT_HARM;
								else
									--plants(i * M + zombies(i).x-1).hp <= plants(i * M + zombies(i).x-1).hp - NORM_HARM;
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
					if (zombies(i).hp > 0 and zombies(i).x = 0 and plants(i * M + zombies(i).x).hp = 0) then
						has_lost := '1';
					end if;
				end loop;
				out_lost <= has_lost;
			end if;
			out_win <= has_win;
		end if;
	end process;

end architecture;
