library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- VGA 接口
entity VGA640x480 is
	port(
		reset: in std_logic;
		clk_0: in std_logic; --100m时钟输入
		clk50: out std_logic; --50m时钟输出
		hs, vs: out std_logic; --行同步、场同步信号
		r, g, b: out std_logic_vector(2 downto 0);
		req_x, req_y: out std_logic_vector(9 downto 0); -- 向渲染模块询问坐标
		res_r, res_g, res_b: in std_logic_vector(2 downto 0) -- 渲染模块输出的颜色
	);
end entity;

architecture behavior of vga640x480 is
	signal r1, g1, b1: std_logic_vector(2 downto 0);
	signal hs1, vs1: std_logic;
	signal vector_x, vector_y: std_logic_vector(9 downto 0); --x 坐标
	signal clk, clk_1: std_logic;
begin
	clk50 <= clk_1;

	---------------------------------------------------------------------
	process(clk_0) --对100m输入信号二分频
	begin
		if (clk_0'event and clk_0 = '1') then
			clk_1 <= not clk_1;
		end if;
	end process;

	process(clk_1) --对50m输入信号二分频
	begin
		if (clk_1'event and clk_1 = '1') then
			clk <= not clk;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --行区间像素数（含消隐区）
	begin
		if (reset = '0') then
			vector_x <= (others=>'0');
		elsif (clk'event and clk = '1') then
			if (vector_x = 799) then
				vector_x <= (others=>'0');
			else
				vector_x <= vector_x + 1;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --场区间行数（含消隐区）
	begin
		if (reset = '0') then
			vector_y <= (others=>'0');
		elsif (clk'event and clk = '1') then
			if (vector_x = 799) then
				if (vector_y = 524) then
					vector_y <= (others=>'0');
				else
					vector_y <= vector_y + 1;
				end if;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --行同步信号产生（同步宽度96，前沿16）
	begin
		if (reset = '0') then
			hs1 <= '1';
		elsif (clk'event and clk = '1') then
			if (vector_x >= 656 and vector_x < 752) then
				hs1 <= '0';
			else
				hs1 <= '1';
			end if;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --场同步信号产生（同步宽度2，前沿10）
	begin
		if (reset = '0') then
			vs1 <= '1';
		elsif (clk'event and clk = '1') then
			if (vector_y >= 490 and vector_y < 492) then
				vs1 <= '0';
			else
				vs1 <= '1';
			end if;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --行同步信号输出
	begin
		if (reset = '0') then
			hs <= '0';
		elsif (clk'event and clk = '1') then
			hs <= hs1;
		end if;
	end process;

	---------------------------------------------------------------------
	process(clk, reset) --场同步信号输出
	begin
		if (reset = '0') then
			vs <= '0';
		elsif (clk'event and clk = '1') then
			vs <= vs1;
		end if;
	end process;

	---------------------------------------------------------------------
	process(reset, clk, vector_x, vector_y) -- xy坐标定位控制
	begin
		if (reset = '0') then
			r1 <= "000";
			g1 <= "000";
			b1 <= "000";
		elsif (clk'event and clk = '1') then
			if (vector_x < 640 and vector_y < 480) then
				req_x <= vector_x;
				req_y <= vector_y;
				r1 <= res_r;
				g1 <= res_g;
				b1 <= res_b;
			else
				r1 <= "000";
				g1 <= "000";
				b1 <= "000";
			end if;
		end if;
	end process;

	---------------------------------------------------------------------
	process (hs1, vs1, r1, g1, b1) --色彩输出
	begin
		if (hs1 = '1' and vs1 = '1') then
			r <= r1;
			g <= g1;
			b <= b1;
		else
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '0');
		end if;
	end process;

end architecture;
