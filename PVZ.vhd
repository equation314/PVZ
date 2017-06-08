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
		ps2_clk: inout std_logic;
		ps2_data: inout std_logic;

		BASERAMWE: out std_logic; --write
		BASERAMOE: out std_logic; --read
		BASERAMCE: out std_logic; --cs
		BASERAMADDR: out std_logic_vector(19 downto 0);
		BASERAMDATA: in std_logic_vector(31 downto 0);
		digit: out std_logic_vector(3 downto 0);
		state_out: out std_logic_vector(2 downto 0)
	);
end entity;

architecture bhv of PVZ is
	component Logic is
		port(
			reset: in std_logic;
			clock: in std_logic;
			out_plants: out plant_matrix;
			out_zombies: out zombie_vector;
			new_plant: in std_logic;
			new_plant_type: in std_logic_vector(1 downto 0);
			new_plant_x, new_plant_y: in integer range 0 to M-1;
			out_lost: out std_logic;
			out_round: out std_logic_vector(3 downto 0)
		);
	end component;
	component Objects is
		port (
			address: in std_logic_vector (15 downto 0);
			clock: in std_logic;
			q: out std_logic_vector (11 downto 0)
		);
	end component;
	component PeaSun is
		port (
			address: in std_logic_vector (12 downto 0);
			clock: in std_logic;
			q: out std_logic_vector (11 downto 0)
		);
	end component;
	component Input is
		port(
			clock, reset: in std_logic;
			ps2_clk: inout std_logic;
			ps2_data: inout std_logic;
			mousex, mousey: out std_logic_vector(9 downto 0);
			state: out mouse_state;
			plants: in plant_matrix;
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
	component Renderer is
		port(
			clock: in std_logic;
			address_sram: out std_logic_vector(19 downto 0);
			address_obj: out std_logic_vector(15 downto 0);
			address_ps: out std_logic_vector(12 downto 0);
			q_sram: in std_logic_vector(31 downto 0);
			q_obj, q_ps: in std_logic_vector(11 downto 0);
			req_x, req_y: in std_logic_vector(9 downto 0);
			res_r, res_g, res_b: out std_logic_vector(2 downto 0);
			plants: in plant_matrix;
			zombies: in zombie_vector;
			mousex, mousey: in std_logic_vector(9 downto 0);
			state: in mouse_state;
			game_state: in game_state
		);
	end component;

	component Encoder is
	  port(
	    in_digit: in std_logic_vector(3 downto 0);
	    out_digit: out std_logic_vector(6 downto 0)
	  );
	end component;


	signal game_clk: std_logic;
	signal clk50, clk25: std_logic;
	signal address_obj: std_logic_vector(15 downto 0);
	signal address_ps: std_logic_vector(12 downto 0);
	signal q_obj, q_ps: std_logic_vector(11 downto 0);
	signal req_x, req_y: std_logic_vector(9 downto 0);
	signal res_r, res_g, res_b: std_logic_vector(2 downto 0);
	signal plants: plant_matrix;
	signal zombies: zombie_vector;
	signal mousex, mousey: std_logic_vector(9 downto 0);
	signal state: mouse_state;
	signal new_plant: std_logic;
	signal new_plant_type: std_logic_vector(1 downto 0);
	signal new_plant_x, new_plant_y: integer range 0 to M-1;
	signal win: std_logic := '0'; -- 赢
	signal lost: std_logic := '0'; -- 输
	signal restart: std_logic := '0'; -- 重置游戏
	signal rnd : std_logic_vector(3 downto 0);

	signal current_state : game_state := S_START;
	signal next_state : game_state := S_START;

	constant WIN_CONDITION : std_logic_vector(3 downto 0) := "1000"; -- 需要过8轮才能赢

begin
	BASERAMCE <= '0';
	BASERAMOE <= '0';
	BASERAMWE <= '1';

	process(clk50)
	begin
		if (rising_edge(clk50)) then
			clk25 <= not clk25;
		end if;
	end process;

	-- logic
	l: Logic port map (
		reset => restart,
		clock => game_clk,
		out_plants => plants,
		out_zombies => zombies,
		new_plant => new_plant,
		new_plant_type => new_plant_type,
		new_plant_x => new_plant_x, new_plant_y => new_plant_y,
		out_lost => lost,
		out_round => rnd
	);

	-- rom
	obj: Objects port map (
		address => address_obj,
		clock => clk50,
		q => q_obj
	);
	ps: PeaSun port map (
		address => address_ps,
		clock => clk50,
		q => q_ps
	);

	-- input
	i: Input port map (
		clock => clk_0,
		reset => reset,
		ps2_clk => ps2_clk,
		ps2_data => ps2_data,
		mousex => mousex, mousey => mousey,
		state => state,
		plants => plants,
		new_plant => new_plant,
		new_plant_type => new_plant_type,
		new_plant_x => new_plant_x, new_plant_y => new_plant_y
	);

	-- display
	vga: VGA640x480 port map (
		reset => reset,
		clk50 => clk50,
		clk_0 => clk_0,
		hs => hs, vs => vs,
		r => red, g => green, b => blue,
		req_x => req_x, req_y => req_y,
		res_r => res_r, res_g => res_g, res_b => res_b
	);
	ren: Renderer port map (
		clock => clk50,
		address_sram => BASERAMADDR,
		address_obj => address_obj,
		address_ps => address_ps,
		q_sram => BASERAMDATA,
		q_obj => q_obj,
		q_ps => q_ps,
		req_x => req_x, req_y => req_y,
		res_r => res_r, res_g => res_g, res_b => res_b,
		plants => plants,
		zombies => zombies,
		mousex => mousex, mousey => mousey,
		state => state,
		game_state => current_state
	);

	gc: process(clk50, current_state)
	begin
		if (current_state=S_PLAYING) then
			game_clk <= clk50;
		else
			game_clk <= '0';
		end if;
	end process;

	fsm: process(clk50)
	begin
		if reset='0' then
			current_state <= S_START;
			--next_state <= S_START;
		elsif rising_edge(clk50) then
			current_state <= next_state;
		end if;
	end process;

	com: process(current_state)
	begin
		case current_state is
			when S_START =>
				state_out <= "000";
				restart <= '0';
				next_state <= S_PLAYING;
			when S_PLAYING =>
				state_out <= "001";
				if lost = '1' then
					next_state <= S_LOST;
				elsif rnd = WIN_CONDITION then
					next_state <= S_WIN;
				else
					next_state <= S_PLAYING;
					restart <= '0';
				end if;
			when S_LOST =>
				state_out <= "010";
				restart <= '1';
				next_state <= S_LOST;
			when S_WIN =>
				state_out <= "100";
				restart <= '1';
				next_state <= S_WIN;
		end case;
	end process;

	process(rnd)
	begin
		digit <= rnd;
	end process;
end architecture;
