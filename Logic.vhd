library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library pvz;
use pvz.pvz_objects.all;

-- 逻辑部分
entity Logic is
	port(
		clock: in std_logic;
		out_plants: out plant_vector;
		out_zombies: out zombie_vector;
		out_win, out_lost : out std_logic -- 输赢
	);
end entity;

architecture bhv of Logic is
	signal count: std_logic_vector(24 downto 0);
	signal pea_clk_count : std_logic_vector(10 downto 0);
	signal pea_clk, zombie_clk: std_logic;
	signal plants: plant_vector := (("01", "1010", M, '0', "0000"), ("00", "1010", M, '0', "0000"), others => ("00", "0000", M, '0', "0000"));
	signal zombies: zombie_vector := (("1010", 15), others => ("0000", 0));
	signal passed_round : integer := 0; -- 过去了多少轮

	signal zombies_to_update : std_logic_vector(0 to N-1); -- 需要更新x的僵尸
	constant ROUND_CLK : integer := 20;
	constant WIN_CONDITION : integer := 10; -- 需要过10轮才能赢
begin
	out_zombies <= zombies;
	out_plants <= plants;

	process(clock)
	begin
		if (clock'event and clock = '1') then
			if (count = 20 * 1000000) then
				count <= (others => '0');
				pea_clk <= '1';
			else
				count <= count + 1;
				pea_clk <= '0';
			end if;
		end if;
	end process;

	process(pea_clk)
	begin
		if (pea_clk'event and pea_clk = '1') then
			zombie_clk <= not zombie_clk;
		end if;
	end process;

	-- 处理豌豆
	-- 僵尸的hp只能在这个process里更新
	process(pea_clk)
		variable p: plant;
		variable has_win : std_logic := '0';
	begin
		if (pea_clk'event and pea_clk = '1') then
			for i in 0 to N-1 loop
				for j in 0 to M-1 loop
					p := plants(i * M + j);
					if (p.hp > 0 and p.plant_type = "00") then
						if (zombies(i).hp > 0) then
							if (p.pea = zombies(i).x) then
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

			-- 更新新产生僵尸的hp
			for i in 0 to N-1 loop
				if zombies(i).hp = 0 and zombies_to_update(i)='1' then
					zombies(i).hp <= "0010";
				end if;
			end loop;

		end if;
	end process;

	-- 处理僵尸
	-- 僵尸的x只能在这里更新
	process(zombie_clk)
		constant NUT_HARM : integer := 1;
		constant NORM_HARM : integer := 2;
		variable has_lost : std_logic := '0';
		variable has_win : std_logic := '0';
	begin
		if (zombie_clk'event and zombie_clk = '1') then
			-- 新产生僵尸
			-- 同时判断是否获胜
			if pea_clk_count=ROUND_CLK then
				pea_clk_count <= (others => '0');
				if passed_round = WIN_CONDITION then
					has_win := '1';
				else
					passed_round <= passed_round + 1;
					for i in 0 to N-1 loop
						if zombies(i).hp = 0 then
							--zombies(i).x <= M-1;
							--zombies_to_update(i) <= '1';
						end if;
					end loop;
					has_win := '0';
				end if;
			else
				pea_clk_count <= pea_clk_count + 1;
				zombies_to_update <= (others => '0');
			end if;
			out_win <= has_win;

			for i in 0 to N-1 loop
				if (zombies(i).hp > 0) then
					if (plants(i * M + zombies(i).x).hp > 0) then
						if (plants(i * M + zombies(i).x).plant_type="10") then -- 坚果墙的防御力较高，特殊处理
							plants(i * M + zombies(i).x).hp <= plants(i * M + zombies(i).x).hp - NUT_HARM;
						else
							plants(i * M + zombies(i).x).hp <= plants(i * M + zombies(i).x).hp - NORM_HARM;
						end if;
					else
						zombies(i).x <= zombies(i).x - 1;
					end if;
				end if;
			end loop;

			-- 判断是否输了
			for i in 0 to N-1 loop
				if (zombies(i).hp > 0 and zombies(i).x = 0 and plants(i * M + zombies(i).x).hp = 0) then
					has_lost := '1';
				end if;
			end loop;
			out_lost <= has_lost;
		end if;

	end process;

end architecture;
