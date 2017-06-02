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
		address_ps: out std_logic_vector(12 downto 0); -- 豌豆、阳光资源地址
		q_bg: in std_logic_vector(8 downto 0); -- 背景资源值
		q_obj, q_ps: in std_logic_vector(11 downto 0); -- 物体资源值，豌豆、阳光资源值
		req_x, req_y: in std_logic_vector(9 downto 0); -- 询问坐标输入
		res_r, res_g, res_b: out std_logic_vector(2 downto 0); -- 颜色输出
		plants: in plant_vector; -- 植物输入
		zombies: in zombie_vector; -- 僵尸输入
		mousex, mousey: in std_logic_vector(9 downto 0); -- 鼠标坐标输入
		state: in mouse_state; -- 鼠标状态输入
		win: in std_logic;
		lost: in std_logic
	);
end entity;

architecture bhv of Renderer is
	signal x, y: std_logic_vector(9 downto 0);
	signal r, g, b: std_logic_vector(2 downto 0);
	signal count: std_logic_vector(24 downto 0);
	signal fps: std_logic_vector(3 downto 0);
	signal tmp_r, tmp_r1, tmp_g, tmp_g1, tmp_b, tmp_b1: integer range 0 to 7;
begin
	x <= req_x;
	y <= req_y;
	res_r <= r;
	res_g <= g;
	res_b <= b;

	process(clock)
	begin
		if (rising_edge(clock)) then
			if (count = 10 * 1000000) then
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
		variable bg_r, bg_g, bg_b: integer range 0 to 7;
		variable p: plant;
	begin
		if (rising_edge(clock)) then
			-- TODO 使用 SRAM 存储背景
			--address_bg <= conv_std_logic_vector(conv_integer(x + 200) / 4 * 120 + conv_integer(y) / 4, 16);
			bg_r := 0; -- conv_integer(q_bg(8 downto 6));
			bg_g := 7; -- conv_integer(q_bg(5 downto 3));
			bg_b := 0; -- conv_integer(q_bg(2 downto 0));
			tmp_r <= bg_r;
			tmp_g <= bg_g;
			tmp_b <= bg_b;

			if (x < 10 and y < 10) then
				-- 鼠标状态提示
				case state is
				when NO =>
					r <= "111";
					g <= "111";
					b <= "111";
				when SUNFLOWER_DOWN =>
					r <= "111";
					g <= "000";
					b <= "000";
				when PEASHOOTER_DOWN =>
					r <= "000";
					g <= "111";
					b <= "000";
				when WALLNUT_DOWN =>
					r <= "000";
					g <= "000";
					b <= "111";
				when UP =>
					r <= "111";
					g <= "111";
					b <= "000";
				when others =>
					r <= "000";
					g <= "000";
					b <= "000";
				end case;
			elsif (10 <= x and x < 20 and 10 <= y and y < 20) then
				-- 输赢提示
				if lost='1' then
					r <= "111";
					g <= "000";
					b <= "000";
				elsif win='1' then
					r <= "000";
					g <= "111";
					b <= "000";
				end if;
			elsif (mousex - 4 <= x and x < mousex + 4 and mousey - 4 <= y and y < mousey + 4) then
				-- 鼠标指针
				r <= "000";
				g <= "000";
				b <= "000";
			elsif (100 <= x and x < 300 and y < 70) then
				-- 植物面板
				address_obj <= conv_std_logic_vector(conv_integer(x - 100) * 70 + conv_integer(y), 16);
				alpha := conv_integer(q_obj(2 downto 0));
				r <= conv_std_logic_vector(((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7, 3);
				g <= conv_std_logic_vector(((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7, 3);
				b <= conv_std_logic_vector(((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7, 3);
			elsif (x < 640 and y < 480) then

				tmp_r1 <= 0;
				tmp_g1 <= 0;
				tmp_b1 <= 0;

				-- 僵尸
				for i in 0 to N-1 loop
					if (zombies(i).hp > 0) then
						x1 := zombies(i).x * 16 * 4;
						y1 := i * 20 * 4 + 14 * 4;
						x2 := x1 + 12 * 4;
						y2 := y1 + 20 * 4;
						if (x1 <= x and x < x2 and y1 <= y and y < y2) then
							address_obj <= "01" & fps & conv_std_logic_vector(conv_integer(x - x1) / 2 * 40 + conv_integer(y - y1) / 2, 10);
							alpha := conv_integer(q_obj(2 downto 0));
							tmp_r <= ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
							tmp_g <= ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
							tmp_b <= ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
						end if;
					end if;
				end loop;

				-- 植物
				for i in 0 to N-1 loop
					for j in 0 to M-1 loop
						x1 := j * 16 * 4;
						y1 := i * 20 * 4 + 18 * 4;
						x2 := x1 + 16 * 4;
						y2 := y1 + 16 * 4;
						p := plants(i * M + j);

						-- 已有的植物
						if (p.hp > 0) then
							if (x1 <= x and x < x2 and y1 <= y and y < y2) then
								address_obj <= '1' & p.plant_type & fps(2 downto 0) & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
								alpha := conv_integer(q_obj(2 downto 0));
								tmp_r <= ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
								tmp_g <= ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
								tmp_b <= ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
							end if;

							-- 阳光
							if (p.with_sun='1') then
								if (x1 + 4 * 4 <= x and x < x2 + 4 * 4 and y1 + 10 * 4 <= y and y < y1 + 26 * 4) then
									address_ps <= "0" & conv_std_logic_vector(conv_integer(x - x1 - 4 * 4) * 64 + conv_integer(y - y1 - 10 * 4), 12);
									alpha := conv_integer(q_ps(2 downto 0));
									tmp_r1 <= ((7 - alpha) * tmp_r + alpha * conv_integer(q_ps(11 downto 9))) / 7;
									tmp_g1 <= ((7 - alpha) * tmp_g + alpha * conv_integer(q_ps(8 downto 6))) / 7;
									tmp_b1 <= ((7 - alpha) * tmp_b + alpha * conv_integer(q_ps(5 downto 3))) / 7;
								end if;
							end if;

							-- 豌豆
							if (p.pea < M) then
								x1 := p.pea * 16 * 4;
								y1 := i * 20 * 4 + 18 * 4;
								x2 := x1 + 16 * 4;
								y2 := y1 + 16 * 4;
								if (x1 + 6 * 4 <= x and x < x2 - 6 * 4 and y1 + 2 * 4 <= y and y < y1 + 6 * 4) then
									address_ps <= "1" & conv_std_logic_vector(conv_integer(x - x1 - 6 * 4) * 16 + conv_integer(y - y1 - 2 * 4), 12);
									alpha := conv_integer(q_ps(2 downto 0));
									tmp_r1 <= ((7 - alpha) * tmp_r + alpha * conv_integer(q_ps(11 downto 9))) / 7;
									tmp_g1 <= ((7 - alpha) * tmp_g + alpha * conv_integer(q_ps(8 downto 6))) / 7;
									tmp_b1 <= ((7 - alpha) * tmp_b + alpha * conv_integer(q_ps(5 downto 3))) / 7;
								end if;
							end if;

						-- 将要放置的植物
						elsif (x1 <= mousex and mousex < x2 and y1 <= mousey and mousey < y2 and
							(state = PEASHOOTER_DOWN or state = SUNFLOWER_DOWN or state = WALLNUT_DOWN)) then
							if (x1 <= x and x < x2 and y1 <= y and y < y2) then
								if (state = PEASHOOTER_DOWN) then
									address_obj <= '1' & "00000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
								elsif (state = SUNFLOWER_DOWN) then
									address_obj <= '1' & "01000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
								elsif (state = WALLNUT_DOWN) then
									address_obj <= '1' & "10000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
								end if;
								alpha := conv_integer(q_obj(2 downto 0));
								if (alpha > 1) then
									alpha := alpha - 2;
								elsif (alpha > 0) then
									alpha := alpha - 1;
								end if;
								tmp_r <= ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
								tmp_g <= ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
								tmp_b <= ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
							end if;
						end if;

					end loop;
				end loop;

				if (tmp_r1 = 0 and tmp_g1 = 0 and tmp_b1 = 0) then
					r <= conv_std_logic_vector(tmp_r, 3);
					g <= conv_std_logic_vector(tmp_g, 3);
					b <= conv_std_logic_vector(tmp_b, 3);
				else
					r <= conv_std_logic_vector(tmp_r1, 3);
					g <= conv_std_logic_vector(tmp_g1, 3);
					b <= conv_std_logic_vector(tmp_b1, 3);
				end if;
			else
				r <= "000";
				g <= "000";
				b <= "000";
			end if;

		end if;
	end process;

end architecture;
