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
		new_plant: in std_logic;  -- 新植物信号
		new_plant_type: in std_logic_vector(1 downto 0);  -- 新植物类型
		new_plant_x, new_plant_y: in integer range 0 to M-1  -- 新植物坐标
	);
end entity;

architecture bhv of Logic is
	signal count: std_logic_vector(24 downto 0);
	signal pea_clk, zombie_clk: std_logic;
	signal plants: plant_vector := (("00", "1010", M, "0000"), ("00", "1010", M, "0000"), others => ("00", "0000", M, "0000"));
	signal zombies: zombie_vector := (("1010", 15), ("1010", M-1), others => ("0000", 0));
begin
	out_zombies <= zombies;
	out_plants <= plants;

	process(clock)
	begin
		if (rising_edge(clock)) then
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
		if (rising_edge(pea_clk)) then
			zombie_clk <= not zombie_clk;
		end if;
	end process;

	-- 处理豌豆
	process(pea_clk, new_plant)
		variable p: plant;
	begin
		if (rising_edge(pea_clk)) then
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
							elsif (p.pea_cd = 0) then
								p.pea := j;
								p.pea_cd := "1010";
							end if;
						elsif (p.pea < M) then
							p.pea := p.pea + 1;
						end if;
						if (p.pea_cd > 0) then
							p.pea_cd := p.pea_cd - 1;
						end if;
						plants(i * M + j) <= p;
					end if;
				end loop;
			end loop;

		end if;
	end process;

	-- 处理僵尸
	process(zombie_clk)
	begin
		if (rising_edge(zombie_clk)) then
			for i in 0 to N-1 loop
				if (zombies(i).hp > 0) then
					if (plants(i * M + zombies(i).x).hp > 0) then
						plants(i * M + zombies(i).x).hp <= plants(i * M + zombies(i).x).hp - 2;
					else
						zombies(i).x <= zombies(i).x - 1;
					end if;
				end if;
			end loop;
		end if;
	end process;

end architecture;
