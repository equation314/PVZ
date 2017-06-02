library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library pvz;
use pvz.pvz_objects.all;

entity Input is
	port(
		clock, reset: in std_logic;
		ps2_clk: inout std_logic;
		ps2_data: inout std_logic;
		mousex, mousey: out std_logic_vector(9 downto 0); -- 鼠标坐标输出
		state: out mouse_state := NO; -- 鼠标状态输出
		plants: in plant_vector; -- 输入输入
		new_plant: out std_logic; -- 新植物信号
		new_plant_type: out std_logic_vector(1 downto 0); -- 新植物类型
		new_plant_x, new_plant_y: out integer range 0 to M-1 -- 新植物坐标
	);
end entity;

architecture bhv of Input is
	component ps2_mouse is
		port(
			clk_in : in std_logic;
			reset_in : in std_logic;
			ps2_clk : inout std_logic;
			ps2_data : inout std_logic;
			left_button : out std_logic;
			right_button : out std_logic;
			middle_button : out std_logic;
			mousex: buffer std_logic_vector(9 downto 0);
			mousey: buffer std_logic_vector(9 downto 0);
			error_no_ack : out std_logic
		);
	end component;

	signal left_button: std_logic;
	signal s1, s2: mouse_state;
	signal x, y: std_logic_vector(9 downto 0);
begin
	mousex <= x;
	mousey <= y;

	mouse: ps2_mouse port map (
		clk_in => clock,
		reset_in => reset,
		ps2_clk => ps2_clk,
		ps2_data => ps2_data,
		left_button => left_button,
		mousex => x, mousey => y
	);

	process(left_button)
		variable px, py: integer range 0 to M-1;
	begin
		if (rising_edge(left_button)) then
			if (6 <= y and y <= 62) then
				if (164 <= x and x <= 202) then
					s1 <= SUNFLOWER_DOWN;
				elsif (207 <= x and x <= 245) then
					s1 <= PEASHOOTER_DOWN;
				elsif (250 <= x and x <= 288) then
					s1 <= WALLNUT_DOWN;
				else
					s1 <= NO;
				end if;
			else
				s1 <= NO;
			end if;
		elsif (falling_edge(left_button)) then

			if (x < 9 * 64 and 18 * 4 <= y and y < 18 * 4 + 5 * 80) then
				s2 <= UP;
				px := conv_integer(x(9 downto 6));
				py := conv_integer(y - 18 * 4) / 80;
				new_plant_x <= px;
				new_plant_y <= py;
				if (plants(py * M + px).hp = 0) then
					new_plant <= '1';
					if (s1 = PEASHOOTER_DOWN) then
						new_plant_type <= "00";
					elsif (s1 = SUNFLOWER_DOWN) then
						new_plant_type <= "01";
					elsif (s1 = WALLNUT_DOWN) then
						new_plant_type <= "10";
					end if;
				end if;
			else
				new_plant <= '0';
				s2 <= NO;
			end if;
		end if;
		if (left_button = '1') then
			state <= s1;
		else
			state <= s2;
		end if;
	end process;

end architecture;
