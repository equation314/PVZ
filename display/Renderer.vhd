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
		address_sram: out std_logic_vector(19 downto 0); -- SRAM 资源地址
		address_obj: out std_logic_vector(15 downto 0); -- 物体资源地址
		address_ps: out std_logic_vector(12 downto 0); -- 豌豆、阳光资源地址
		q_sram: in std_logic_vector(31 downto 0); -- SRAM 资源值
		q_obj, q_ps: in std_logic_vector(11 downto 0); -- 物体资源值，豌豆、阳光资源值
		req_x, req_y: in std_logic_vector(9 downto 0); -- 询问坐标输入
		res_r, res_g, res_b: out std_logic_vector(2 downto 0); -- 颜色输出
		plants: in plant_matrix; -- 植物输入
		zombies: in zombie_vector; -- 僵尸输入
		mousex, mousey: in std_logic_vector(9 downto 0); -- 鼠标坐标输入
		state: in mouse_state; -- 鼠标状态输入
		game_state: in game_state
	);
end entity;

architecture bhv of Renderer is
	signal x, y: std_logic_vector(9 downto 0);
	signal r, g, b: std_logic_vector(2 downto 0);
	signal count: std_logic_vector(24 downto 0);
	signal fps: std_logic_vector(3 downto 0);
	signal tmp_r, tmp_r1, tmp_g, tmp_g1, tmp_b, tmp_b1, bg_r, bg_g, bg_b: integer range 0 to 7;
begin
	x <= req_x;
	y <= req_y;
	res_r <= r;
	res_g <= g;
	res_b <= b;

	process(clock)
	begin
		if (rising_edge(clock)) then
			if (count = 8000000) then
				count <= (others => '0');
				fps <= fps + 1;
			else
				count <= count + 1;
			end if;
		end if;
	end process;

	process(x, y, clock)
		variable p: plant;
		variable x1, x2, y1, y2: integer range 0 to 1023;
		variable alpha: integer range 0 to 7;
	begin
		if (rising_edge(clock)) then

			-- if (x < 10 and y < 10) then
			-- 	-- 鼠标状态提示
			-- 	case state is
			-- 	when NO =>
			-- 		r <= "111";
			-- 		g <= "111";
			-- 		b <= "111";
			-- 	when SUNFLOWER_DOWN =>
			-- 		r <= "111";
			-- 		g <= "000";
			-- 		b <= "000";
			-- 	when PEASHOOTER_DOWN =>
			-- 		r <= "000";
			-- 		g <= "111";
			-- 		b <= "000";
			-- 	when WALLNUT_DOWN =>
			-- 		r <= "000";
			-- 		g <= "000";
			-- 		b <= "111";
			-- 	when UP =>
			-- 		r <= "111";
			-- 		g <= "111";
			-- 		b <= "000";
			-- 	when others =>
			-- 		r <= "000";
			-- 		g <= "000";
			-- 		b <= "000";
			-- 	end case;
			-- elsif (10 <= x and x < 20 and 10 <= y and y < 20) then
			-- 	-- 输赢提示
			-- 	if game_state=S_LOST then
			-- 		r <= "111";
			-- 		g <= "000";
			-- 		b <= "000";
			-- 	elsif game_state=S_WIN then
			-- 		r <= "000";
			-- 		g <= "111";
			-- 		b <= "000";
			-- 	elsif game_state=S_PLAYING then
			-- 		r <= "111";
			-- 		g <= "111";
			-- 		b <= "111";
			-- 	else
			-- 		r <= "000";
			-- 		g <= "000";
			-- 		b <= "000";
			-- 	end if;
			if (mousex - 4 <= x and x < mousex + 4 and mousey - 4 <= y and y < mousey + 4) then
				-- 鼠标指针
				r <= "000";
				g <= "000";
				b <= "000";
			elsif (game_state=S_LOST) then
				address_sram <= conv_std_logic_vector(conv_integer(x) * 480 + conv_integer(y), 20);
				r <= q_sram(17 downto 15);
				g <= q_sram(14 downto 12);
				b <= q_sram(11 downto 9);
			elsif (game_state=S_WIN) then
				address_sram <= conv_std_logic_vector(conv_integer(x) * 480 + conv_integer(y), 20);
				r <= q_sram(26 downto 24);
				g <= q_sram(23 downto 21);
				b <= q_sram(20 downto 18);
			else

				address_sram <= conv_std_logic_vector(conv_integer(x) * 480 + conv_integer(y), 20);
				bg_r <= conv_integer(q_sram(8 downto 6));
				bg_g <= conv_integer(q_sram(5 downto 3));
				bg_b <= conv_integer(q_sram(2 downto 0));
				tmp_r <= bg_r;
				tmp_g <= bg_g;
				tmp_b <= bg_b;

				if (x < 640 and y < 480) then

					tmp_r1 <= 0;
					tmp_g1 <= 0;
					tmp_b1 <= 0;

					-- 僵尸
					for i in 0 to N-1 loop
						if (zombies(i).hp > 0) then
							x1 := zombies(i).x * 64;
							y1 := i * 80 + 56;
							x2 := x1 + 48;
							y2 := y1 + 80;
							if (x1 <= x and x < x2 and y1 <= y and y < y2) then
								address_obj <= "10" & fps & conv_std_logic_vector(conv_integer(x - x1) / 2 * 40 + conv_integer(y - y1) / 2, 10);
								alpha := conv_integer(q_obj(2 downto 0));
								tmp_r <= ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
								tmp_g <= ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
								tmp_b <= ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
							end if;
						end if;
					end loop;

					-- 植物
					for i in 0 to N-1 loop
						for j in M-1 downto 0 loop
							x1 := j * 64;
							y1 := i * 80 + 72;
							x2 := x1 + 64;
							y2 := y1 + 64;
							p := plants(i)(j);

							-- 已有的植物
							if (p.hp > 0) then
								if (x1 <= x and x < x2 and y1 <= y and y < y2) then
									address_obj <= '0' & p.plant_type & fps(2 downto 0) & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
									alpha := conv_integer(q_obj(2 downto 0));
									tmp_r <= ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
									tmp_g <= ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
									tmp_b <= ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
								end if;

								-- 阳光
								if (p.with_sun='1') then
									if (x1 + 16 <= x and x < x2 + 16 and y1 + 40 <= y and y < y1 + 104) then
										address_ps <= "0" & conv_std_logic_vector(conv_integer(x - x1 - 16) * 64 + conv_integer(y - y1 - 40), 12);
										alpha := conv_integer(q_ps(2 downto 0));
										tmp_r1 <= ((7 - alpha) * tmp_r + alpha * conv_integer(q_ps(11 downto 9))) / 7;
										tmp_g1 <= ((7 - alpha) * tmp_g + alpha * conv_integer(q_ps(8 downto 6))) / 7;
										tmp_b1 <= ((7 - alpha) * tmp_b + alpha * conv_integer(q_ps(5 downto 3))) / 7;
									end if;
								end if;

								-- 豌豆
								if (p.pea < M) then
									if (zombies(i).hp > 0 and zombies(i).x = p.pea + 1) then
										x1 := p.pea * 64 + 64;
										y1 := i * 80 + 80;
										x2 := x1 + 16;
										y2 := y1 + 16;
										if (x1 <= x and x < x2 and y1 <= y and y < y2) then
											address_ps <= "10001" & conv_std_logic_vector(conv_integer(x - x1) * 16 + conv_integer(y - y1), 8);
											alpha := conv_integer(q_ps(2 downto 0));
											tmp_r1 <= ((7 - alpha) * tmp_r + alpha * conv_integer(q_ps(11 downto 9))) / 7;
											tmp_g1 <= ((7 - alpha) * tmp_g + alpha * conv_integer(q_ps(8 downto 6))) / 7;
											tmp_b1 <= ((7 - alpha) * tmp_b + alpha * conv_integer(q_ps(5 downto 3))) / 7;
										end if;
									else
										x1 := p.pea * 64 + 48 + conv_integer(fps(1 downto 0) & "0000");
										y1 := i * 80 + 80;
										x2 := x1 + 16;
										y2 := y1 + 16;
										if (x1 <= x and x < x2 and y1 <= y and y < y2) then
											address_ps <= "10000" & conv_std_logic_vector(conv_integer(x - x1) * 16 + conv_integer(y - y1), 8);
											alpha := conv_integer(q_ps(2 downto 0));
											tmp_r1 <= ((7 - alpha) * tmp_r + alpha * conv_integer(q_ps(11 downto 9))) / 7;
											tmp_g1 <= ((7 - alpha) * tmp_g + alpha * conv_integer(q_ps(8 downto 6))) / 7;
											tmp_b1 <= ((7 - alpha) * tmp_b + alpha * conv_integer(q_ps(5 downto 3))) / 7;
										end if;
									end if;
								end if;

							-- 将要放置的植物
							elsif (x1 <= mousex and mousex < x2 and y1 <= mousey and mousey < y2 and
								(state = PEASHOOTER_DOWN or state = SUNFLOWER_DOWN or state = WALLNUT_DOWN) and zombies(i).x /= j) then
								if (x1 <= x and x < x2 and y1 <= y and y < y2) then
									if (state = PEASHOOTER_DOWN) then
										address_obj <= '0' & "00000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
									elsif (state = SUNFLOWER_DOWN) then
										address_obj <= '0' & "10000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
									elsif (state = WALLNUT_DOWN) then
										address_obj <= '0' & "01000" & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
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

		end if;
	end process;

end architecture;
