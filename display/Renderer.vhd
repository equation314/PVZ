library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library pvz;
use pvz.pvz_objects.all;

-- 渲染一个像素
entity Renderer is
	port(
		clock: in std_logic;
		address_bg: out std_logic_vector(15 downto 0); -- 背景资源地址
		address_obj: out std_logic_vector(15 downto 0); -- 物体资源地址
		q_bg: in std_logic_vector(8 downto 0); -- 背景资源值
		q_obj: in std_logic_vector(11 downto 0); -- 物体资源值
		req_x, req_y: in std_logic_vector(9 downto 0); -- 询问坐标输入
		res_r, res_g, res_b: out std_logic_vector(2 downto 0); -- 颜色输出
		plants: plant_vector; -- 植物输入
		zombies: zombie_vector; -- 僵尸输入
		win, lost: std_logic -- 输赢
	);
end entity;

architecture bhv of Renderer is
	signal x, y: std_logic_vector(9 downto 0);
	signal r, g, b: std_logic_vector(2 downto 0);
	signal count: std_logic_vector(24 downto 0);
	signal fps: std_logic_vector(2 downto 0);

begin
	x <= req_x;
	y <= req_y;
	res_r <= r;
	res_g <= g;
	res_b <= b;

	process(clock)
	begin
		if (clock'event and clock = '1') then
			if (count = 5 * 1000000) then
				count <= (others => '0');
				fps <= fps + 1;
			else
				count <= count + 1;
			end if;
		end if;
	end process;

	process(x, y, clock)
		variable alpha: integer range 0 to 7;
		variable x1, x2, y1, y2: integer range 0 to 1023;
		variable tmp_r, tmp_g, tmp_b: integer range 0 to 7;
		variable bg_r, bg_g, bg_b: integer range 0 to 7;
		variable p: plant;
	begin
		if rising_edge(clock) then
			address_bg <= conv_std_logic_vector(conv_integer(x + 200) / 4 * 120 + conv_integer(y) / 4, 16);
			bg_r := conv_integer(q_bg(8 downto 6));
			bg_g := conv_integer(q_bg(5 downto 3));
			bg_b := conv_integer(q_bg(2 downto 0));
			tmp_r := bg_r;
			tmp_g := bg_g;
			tmp_b := bg_b;

			if (x < 640 and y < 480) then

				if (100 <= x and x < 300 and y < 70) then
					-- 植物面板
					address_obj <= conv_std_logic_vector(conv_integer(x - 100) * 70 + conv_integer(y), 16);
					alpha := conv_integer(q_obj(2 downto 0));
					tmp_r := ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
					tmp_g := ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
					tmp_b := ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
				else
					-- 植物
					for i in 0 to N-1 loop
						for j in 0 to M-1 loop
							p := plants(i * M + j);
							if (p.hp > 0) then
								x1 := j * 16 * 4;
								y1 := i * 20 * 4 + 18 * 4;
								x2 := x1 + 16 * 4;
								y2 := y1 + 16 * 4;

								if (x1 <= x and x < x2 and y1 <= y and y < y2) then
									address_obj <= '1' & p.plant_type & fps & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
									alpha := conv_integer(q_obj(2 downto 0));
									tmp_r := ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
									tmp_g := ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
									tmp_b := ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
								end if;

								-- 阳光
								if (p.with_sun='1') then
									if (x1 + 6 * 4 <= x and x < x2 - 6 * 4 and y1 + 6 * 4 <= y and y < y2 - 6 * 4) then
										tmp_r := 7;
										tmp_g := 7;
										tmp_b := 0;
									end if;
								end if;

								-- 豌豆
								if (p.pea < M) then
									x1 := p.pea * 16 * 4;
									y1 := i * 20 * 4 + 18 * 4;
									x2 := x1 + 16 * 4;
									y2 := y1 + 16 * 4;
									if (x1 + 6 * 4 <= x and x < x2 - 6 * 4 and y1 + 6 * 4 <= y and y < y2 - 6 * 4) then
										tmp_r := 0;
										tmp_g := 7;
										tmp_b := 0;
									end if;
								end if;

							end if;
						end loop;
					end loop;

					-- 僵尸
					for i in 0 to N-1 loop
						if (zombies(i).hp > 0) then
							x1 := zombies(i).x * 16 * 4 + 8 * 4;
							y1 := i * 20 * 4 + 18 * 4;
							x2 := x1 + 8 * 4;
							y2 := y1 + 16 * 4;
							if (x1 <= x and x < x2 and y1 <= y and y < y2) then
								tmp_r := 7;
								tmp_g := 0;
								tmp_b := 0;
							end if;
						end if;
					end loop;

				end if;

				-- 输赢指示
				if (10 <= x and x < 20 and 10 <= y and y < 20) then
					if lost='1' then
						tmp_r := 7;
						tmp_g := 0;
						tmp_b := 0;
					elsif win='1' then
						tmp_r := 0;
						tmp_g := 0;
						tmp_b := 7;
					end if;
				end if;

				r <= conv_std_logic_vector(tmp_r, 3);
				g <= conv_std_logic_vector(tmp_g, 3);
				b <= conv_std_logic_vector(tmp_b, 3);
			else
				r <= "000";
				g <= "000";
				b <= "000";
			end if;
		end if;
	end process;

end architecture;
