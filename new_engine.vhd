library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library objects;
use objects.pvz_objects.all;

entity new_engine is
  port(
    clear: in std_logic;
    enable: in std_logic;
    clk, game_clk: in std_logic;
    state_out: out std_logic_vector(6 downto 0);
    mem_out: out std_logic_vector(26 downto 0);
    addr_out : out std_logic_vector(7 downto 0);
    i_out : out std_logic_vector(7 downto 0);
    j_out : out std_logic_vector(7 downto 0)
  );
end new_engine;
architecture bhv of new_engine is
  component internal_ram
  	PORT
  	(
  		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
  		clock		: IN STD_LOGIC  := '1';
  		data		: IN STD_LOGIC_VECTOR (26 DOWNTO 0);
  		wren		: IN STD_LOGIC ;
  		q		: OUT STD_LOGIC_VECTOR (26 DOWNTO 0)
  	);
  end component;

  type EngineState is (s_init, s_outer, s_inner, s_idle
    , s_write_outer, s_write_inner, s_append, s_append_done, s_append_append , s_clear_0, s_clear_1);
  signal prev_state : EngineState;
  signal state : EngineState;
  signal next_state : EngineState;

  signal addr: std_logic_vector(7 downto 0);
  signal data: std_logic_vector(26 downto 0);
  signal wren: std_logic := '0';
  signal q: std_logic_vector(26 downto 0);
  constant MAX_N : integer range 0 to 255 := 200;
  constant ADDR_INIT : std_logic_vector(7 downto 0) := "00000000";


  signal i : integer range 0 to 255 := 0;
  signal j : integer range 0 to 255 := 0;
begin
  c0 : internal_ram port map(addr, clk, data, wren, q);

  debug_out: process(q, state, i, j)
  begin
    mem_out <= q;
    state_out <= std_logic_vector(to_unsigned(EngineState'pos(state), state_out'length));
    i_out <= std_logic_vector(to_unsigned(i, 8));
    j_out <= std_logic_vector(to_unsigned(j, 8));
  end process;

  automata: process(clk, game_clk)

  begin
    if enable='1' then
      if rising_edge(clk) then
        if clear='1' then
          state <= s_clear_0;
        else
          state <= next_state;
        end if;
      end if;
    else
      state <= s_idle;
    end if;
  end process;

  com: process(state)
    variable outer_object, inner_object, append_object, tmp_object : object;
    variable resumed_outer : std_logic := '0';
    variable stop_inner : std_logic := '0';

  begin
    case state is
      when s_clear_0=>
        addr <= "00000000";
        tmp_object.obj_type := plant;
        tmp_object.sub_type := plant_shooter;
        tmp_object.pos_x := 10;
        tmp_object.pos_y := 1;
        tmp_object.hp := 31;
        tmp_object.state := 31;
        tmp_object.invalid := '0';
        data <= obj_to_bitvec(tmp_object);
        wren <= '1';
        next_state <= s_clear_1;
      when s_clear_1 =>
        addr <= "00000001";
        tmp_object.invalid := '1';
        data <= obj_to_bitvec(tmp_object);
        wren <= '1';
        next_state <= s_init;
      when s_init =>
        i <= 0;
        j <= 0;
        wren <= '0';
        addr <= std_logic_vector(unsigned(ADDR_INIT) + i);
        addr_out <= addr;
        next_state <= s_outer;
      when s_outer =>
        outer_object := bitvec_to_obj(q);
        if outer_object.invalid = '1' then -- tail
          next_state <= s_idle;
        elsif outer_object.hp = 0 then
          -- skip
        elsif resumed_outer = '0' then
          if outer_object.state = 31 then
            outer_object.state := 0;
          else
            outer_object.state := outer_object.state + 1;
          end if; -- update object state
          case outer_object.obj_type is
            when plant =>
              case outer_object.sub_type is
                when plant_shooter =>
                  if outer_object.state = 16 then
                    append_object.obj_type := pea;
                    append_object.sub_type := pea_norm;
                    append_object.pos_x := outer_object.pos_x;
                    append_object.pos_y := outer_object.pos_y;
                    append_object.invalid := '0';

                    j <= 0;
                    addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
                    wren <= '0';
                    next_state <= s_append; -- 从0开始遍历，寻找空位
                  end if;
                when plant_sunflower =>
                  if outer_object.state = 16 then
                    append_object.obj_type := sun;
                    append_object.sub_type := sun_norm;
                    append_object.pos_x := outer_object.pos_x;
                    append_object.pos_y := outer_object.pos_y;
                    append_object.invalid := '0';

                    j <= 0;
                    addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
                    wren <= '0';
                    next_state <= s_append; -- 从0开始遍历，寻找空位
                  end if;
                when plant_nut =>
                when others =>
              end case;
            when zombie =>
              case outer_object.sub_type is
                when zombie_norm =>
                  j <= 0;
                  addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
                  wren <= '0';
                  next_state <= s_inner;
                when others =>
              end case;
            when pea =>
              if outer_object.pos_x = 127 then --出地图
                outer_object.hp := 0;
              else
                j <= 0;
                wren <= '0';
                addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
                next_state <= s_inner;
              end if;
            when sun =>
              outer_object.hp := outer_object.hp - 1;
            when others =>
          end case;
        end if;
        if not(next_state = s_append or next_state = s_inner or next_state=s_idle) then
          addr <= std_logic_vector(unsigned(ADDR_INIT) + i);
          addr_out <= addr;
          wren <= '1';
          data <= obj_to_bitvec(outer_object);
          next_state <= s_write_outer;
          resumed_outer := '0';
        end if;
      when s_write_outer =>
        wren <= '0';
        next_state <= s_outer;
        i <= i+1;
        --addr <= std_logic_vector(unsigned(ADDR_INIT) + i);
        --addr_out <= std_logic_vector(unsigned(ADDR_INIT) + i);
      when s_append =>
        tmp_object := bitvec_to_obj(q);
        if tmp_object.invalid='1' then
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          wren <= '1';
          data <= obj_to_bitvec(append_object);
          next_state <= s_append_append;
        elsif tmp_object.hp = 0 then
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          wren <= '1';
          data <= obj_to_bitvec(append_object);
          next_state <= s_append_done;
        else
          j <= j+1;
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          wren <= '0';
          next_state <= s_append;
        end if;
      when s_append_append => -- set tail
        wren <= '1';
        addr <= std_logic_vector(unsigned(ADDR_INIT) + j + 1);
        tmp_object.invalid := '1';
        data <= obj_to_bitvec(tmp_object);
        next_state <= s_append_done;
      when s_append_done => -- return to outer loop
        wren <= '0';
        addr <= std_logic_vector(unsigned(ADDR_INIT) + i);
        resumed_outer := '1';
        next_state <= s_outer;
      when s_inner =>
        inner_object := bitvec_to_obj(q);
        resumed_outer := '1';
        stop_inner := '0';
        wren <= '0';
        if inner_object.invalid='1' then
          if outer_object.obj_type=zombie then --面前没有植物
            outer_object.pos_x := outer_object.pos_x - 1;
          end if;
          next_state <= s_outer;
        elsif inner_object.hp = 0 then
          j <= j+1;
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          next_state <= s_inner;
        else
          case outer_object.sub_type is
            when pea_norm =>
              if inner_object.obj_type = zombie and inner_object.pos_x = outer_object.pos_x and inner_object.pos_y = outer_object.pos_y then
                outer_object.hp := 0;
                if inner_object.hp < 5 then -- 豌豆攻击僵尸
                  inner_object.hp := 0;
                else
                  inner_object.hp := inner_object.hp - 5;
                end if;
                stop_inner := '1';
              end if;
            when zombie_norm =>
              if inner_object.obj_type = plant and inner_object.pos_x = outer_object.pos_x and inner_object.pos_y = outer_object.pos_y then -- 僵尸攻击植物
                if outer_object.hp < 3 then
                  outer_object.hp := 0;
                else
                  outer_object.hp := outer_object.hp - 3;
                end if;
                stop_inner := '1';
              end if;
            when others =>
          end case;
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          wren <= '1';
          next_state <= s_write_inner;
        end if;
      when s_write_inner =>
        if stop_inner = '0' then
          j <= j+1;
          addr <= std_logic_vector(unsigned(ADDR_INIT) + j);
          wren <= '0';
          next_state <= s_inner;
        else
          wren <= '0';
          addr <= std_logic_vector(unsigned(ADDR_INIT) + i);
          next_state <= s_outer;
        end if;
      when s_idle =>
        next_state <= s_idle;
      when others =>
        next_state <= s_idle;
    end case;
  end process;
end bhv;
