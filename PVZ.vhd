library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library pvz;
use pvz.pvz_objects.all;

-- 顶层模块
entity PVZ is
	port (
		clk_0, reset: in std_logic; --100m 时钟输入
		hs, vs: out std_logic;
		red, green, blue: out std_logic_vector(2 downto 0);
		ps2_clk : inout std_logic;
		ps2_data : inout std_logic
	);
end entity;

architecture bhv of PVZ is
	component Logic is
		port(
			clock: in std_logic;
			out_plants: out plant_vector;
			out_zombies: out zombie_vector;
			new_plant: in std_logic;
			new_plant_type: in std_logic_vector(1 downto 0);
			new_plant_x, new_plant_y: in integer range 0 to M-1
		);
	end component;
	component Input is
		port(
			clock, reset: in std_logic;
			ps2_clk : inout std_logic;
			ps2_data : inout std_logic;
			mousex, mousey: out std_logic_vector(9 downto 0);
			state: out mouse_state;
			new_plant: out std_logic;
			new_plant_type: out std_logic_vector(1 downto 0);
			new_plant_x, new_plant_y: out integer range 0 to M-1
		);
	end component;
	component VGA640x480 is
		port(
			reset: in std_logic;
			clk_0: in std_logic;
			clk50: out std_logic;
			hs, vs: out std_logic;
			r, g, b: out std_logic_vector(2 downto 0);
			req_x, req_y: out std_logic_vector(9 downto 0);
			res_r, res_g, res_b: in std_logic_vector(2 downto 0)
		);
	end component;
	component Background is
		port (
			address: in std_logic_vector (15 downto 0);
			clock: in std_logic;
			q : out std_logic_vector (8 downto 0)
		);
	end component;
	component Objects is
		port (
			address: in std_logic_vector (15 downto 0);
			clock: in std_logic;
			q: out std_logic_vector (11 downto 0)
		);
	end component;
	component Renderer is
		port(
			clock: in std_logic;
			address_bg: out std_logic_vector(15 downto 0);
			address_obj: out std_logic_vector(15 downto 0);
			q_bg: in std_logic_vector(8 downto 0);
			q_obj: in std_logic_vector(11 downto 0);
			req_x, req_y: in std_logic_vector(9 downto 0);
			res_r, res_g, res_b: out std_logic_vector(2 downto 0);
			plants: plant_vector;
			zombies: zombie_vector;
			mousex, mousey: in std_logic_vector(9 downto 0);
			state: in mouse_state
		);
	end component;

	signal clk50: std_logic;
	signal address_bg: std_logic_vector(15 downto 0);
	signal address_obj: std_logic_vector(15 downto 0);
	signal q_bg: std_logic_vector(8 downto 0);
	signal q_obj: std_logic_vector(11 downto 0);
	signal req_x, req_y: std_logic_vector(9 downto 0);
	signal res_r, res_g, res_b: std_logic_vector(2 downto 0);
	signal plants: plant_vector;
	signal zombies: zombie_vector;
	signal mousex, mousey: std_logic_vector(9 downto 0);
	signal state: mouse_state;
	signal new_plant: std_logic;
	signal new_plant_type: std_logic_vector(1 downto 0);
	signal new_plant_x, new_plant_y: integer range 0 to M-1;
begin
	l: Logic port map (
		clock => clk50,
		out_plants => plants,
		out_zombies => zombies,
		new_plant => new_plant,
		new_plant_type => new_plant_type,
		new_plant_x => new_plant_x, new_plant_y => new_plant_y
	);
	i: Input port map (
		clock => clk50,
		reset => reset,
		ps2_clk => ps2_clk,
		ps2_data => ps2_data,
		mousex => mousex, mousey => mousey,
		state => state,
		new_plant => new_plant,
		new_plant_type => new_plant_type,
		new_plant_x => new_plant_x, new_plant_y => new_plant_y
	);
	vga: VGA640x480 port map (
		reset => reset,
		clk50 => clk50,
		clk_0 => clk_0,
		hs => hs, vs => vs,
		r => red, g => green, b => blue,
		req_x => req_x, req_y => req_y,
		res_r => res_r, res_g => res_g, res_b => res_b
	);
	bg: Background port map (
		address => address_bg,
		clock => clk50,
		q => q_bg
	);
	obj: Objects port map (
		address => address_obj,
		clock => clk50,
		q => q_obj
	);
	ren: Renderer port map (
		clock => clk50,
		address_bg => address_bg,
		address_obj => address_obj,
		q_bg => q_bg,
		q_obj => q_obj,
		req_x => req_x, req_y => req_y,
		res_r => res_r, res_g => res_g, res_b => res_b,
		plants => plants,
		zombies => zombies,
		mousex => mousex, mousey => mousey,
		state => state
	);
end architecture;
