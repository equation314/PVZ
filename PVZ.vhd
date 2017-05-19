library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PVZ is
	port (
		clk_0, reset: in std_logic;
		hs, vs: out std_logic;
		red, green, blue: out std_logic_vector(2 downto 0)
	);
end entity;

architecture bhv of PVZ is
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
	component Plants is
		port (
			address: in std_logic_vector (7 downto 0);
			clock: in std_logic;
			q: out std_logic_vector (11 downto 0)
		);
	end component;
	component Renderer is
		port(
			address_bg: out std_logic_vector(15 downto 0);
			address_p: out std_logic_vector(7 downto 0);
			q_bg: in std_logic_vector(8 downto 0);
			q_p: in std_logic_vector(11 downto 0);
			req_x, req_y: in std_logic_vector(9 downto 0);
			res_r, res_g, res_b: out std_logic_vector(2 downto 0)
		);
	end component;

	signal clk50: std_logic;
	signal address_bg: std_logic_vector(15 downto 0);
	signal address_p: std_logic_vector(7 downto 0);
	signal q_bg: std_logic_vector(8 downto 0);
	signal q_p: std_logic_vector(11 downto 0);
	signal req_x, req_y: std_logic_vector(9 downto 0);
	signal res_r, res_g, res_b: std_logic_vector(2 downto 0);
begin
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
	p: Plants port map (
		address => address_p,
		clock => clk50,
		q => q_p
	);
	ren: Renderer port map (
		address_bg => address_bg,
		address_p => address_p,
		q_bg => q_bg,
		q_p => q_p,
		req_x => req_x, req_y => req_y,
		res_r => res_r, res_g => res_g, res_b => res_b
	);
end architecture;
