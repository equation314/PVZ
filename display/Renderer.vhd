library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Renderer is
	port(
		clock: in std_logic;
		address_bg: out std_logic_vector(15 downto 0); -- 背景资源地址
		address_obj: out std_logic_vector(15 downto 0); -- 物体资源地址
		q_bg: in std_logic_vector(8 downto 0); -- 背景资源值
		q_obj: in std_logic_vector(11 downto 0); -- 物体资源值
		req_x, req_y: in std_logic_vector(9 downto 0); -- 询问坐标输入
		res_r, res_g, res_b: out std_logic_vector(2 downto 0) -- 颜色输出
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

	process(x, y, fps)
		variable t: std_logic_vector(1 downto 0);
		variable alpha: integer range 0 to 7;
		variable x1, x2, y1, y2: integer range 0 to 1023;
		variable tmp_r, tmp_g, tmp_b: integer range 0 to 7;
		variable bg_r, bg_g, bg_b: integer range 0 to 7;
	begin
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
				for i in 0 to 8 loop
					for j in 0 to 4 loop
						x1 := i * 16 * 4;
						y1 := j * 20 * 4 + 18 * 4;
						x2 := x1 + 16 * 4;
						y2 := y1 + 16 * 4;
						t := conv_std_logic_vector((i + j) mod 3, 2);

						if (x1 <= x and x < x2 and y1 <= y and y < y2) then
							address_obj <= '1' & t & fps & conv_std_logic_vector(conv_integer(x - x1) / 2 * 32 + conv_integer(y - y1) / 2, 10);
							alpha := conv_integer(q_obj(2 downto 0));
							tmp_r := ((7 - alpha) * bg_r + alpha * conv_integer(q_obj(11 downto 9))) / 7;
							tmp_g := ((7 - alpha) * bg_g + alpha * conv_integer(q_obj(8 downto 6))) / 7;
							tmp_b := ((7 - alpha) * bg_b + alpha * conv_integer(q_obj(5 downto 3))) / 7;
						end if;
					end loop;
				end loop;
			end if;

			r <= conv_std_logic_vector(tmp_r, 3);
			g <= conv_std_logic_vector(tmp_g, 3);
			b <= conv_std_logic_vector(tmp_b, 3);
		else
			r <= "000";
			g <= "000";
			b <= "000";
		end if;
	end process;
end architecture;
