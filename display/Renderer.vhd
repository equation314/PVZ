library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Renderer is
	port(
		address_bg: out std_logic_vector(15 downto 0); -- 背景资源地址
		address_p: out std_logic_vector(7 downto 0); -- 植物资源地址
		q_bg: in std_logic_vector(8 downto 0); -- 背景资源值
		q_p: in std_logic_vector(11 downto 0); -- 植物资源值
		req_x, req_y: in std_logic_vector(9 downto 0); -- 询问坐标输入
		res_r, res_g, res_b: out std_logic_vector(2 downto 0) -- 颜色输出
	);
end entity;


architecture bhv of Renderer is
	signal x, y: std_logic_vector(9 downto 0);
	signal r, g, b: std_logic_vector(2 downto 0);
begin
	x <= req_x;
	y <= req_y;
	res_r <= r;
	res_g <= g;
	res_b <= b;

	process(x, y, q_p, q_bg)
		variable alpha: integer;
	begin
		if (x < 640 and y < 480) then
			address_bg <= conv_std_logic_vector(conv_integer(x + 200) / 4 * 120 + conv_integer(y) / 4, 16);
			if (x < 16 * 4 and 16 * 4 <= y and y < 32 * 4) then
				address_p <= conv_std_logic_vector(conv_integer(x) / 4 * 16 + conv_integer(y - 16 * 4) / 4, 8);
				alpha := conv_integer(q_p(2 downto 0));
				r <= conv_std_logic_vector(((7 - alpha) * conv_integer(q_bg(8 downto 6)) + alpha * conv_integer(q_p(11 downto 9))) / 7, 3);
				g <= conv_std_logic_vector(((7 - alpha) * conv_integer(q_bg(5 downto 3)) + alpha * conv_integer(q_p(8 downto 6))) / 7, 3);
				b <= conv_std_logic_vector(((7 - alpha) * conv_integer(q_bg(2 downto 0)) + alpha * conv_integer(q_p(5 downto 3))) / 7, 3);
			else
				r <= q_bg(8 downto 6);
				g <= q_bg(5 downto 3);
				b <= q_bg(2 downto 0);
			end if;
		else
			r <= "000";
			g <= "000";
			b <= "000";
		end if;
	end process;
end architecture;
