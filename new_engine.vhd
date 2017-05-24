library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library objects;
use objects.pvz_objects.all;

entity new_engine is
  port(
    enable: in std_logic;
    clk, game_clk: in std_logic
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

  type EngineState is (s_init, s_outer, s_read, s_inner, s_idle, s_write_inner
    , s_write_outer, s_append, s_append_done);
  signal state : EngineState;
  signal next_state : EngineState;
  signal i : integer range 0 to 255 := 0;
  signal j : integer range 0 to 255 := 0;
  signal addr: std_logic_vector(7 downto 0) := "00000000";
  signal data: std_logic_vector(26 downto 0);
  signal wren: std_logic := '0';
  signal q: std_logic_vector(26 downto 0);
  constant MAX_N : integer range 0 to 255 := 200;
begin
  c0 : internal_ram port map(addr, clk, data, wren, q);

  automata: process(clk, game_clk)
  begin
    if enable='1' then
      if rising_edge(clk) then
        state <= next_state;
      end if;
    else
      state <= s_idle;
    end if;
  end process;

  com: process(state, data)
    variable outer_object, inner_object, append_object, tmp_object : object;
    variable outer_updated : std_logic := '0';
  begin
    case state is
      when s_init =>
        i <= 0;
        j <= 0;
        wren <= '0';
        next_state <= s_outer;
      when s_outer =>
        if i < MAX_N then
          addr <= std_logic_vector(unsigned(addr) + i);
          wren <= '0';
          next_state <= s_read;
        else
          wren <= '0';
          next_state <= s_idle;
        end if;
      when s_read =>
        outer_object := bitvec_to_obj(q);
        if outer_object.invalid = '1' then
          i <= i+1;
          next_state <= s_idle;
        elsif outer_object.hp = 0 then
          i <= i+1;
          next_state <= s_outer;
        else
          if outer_object.state = 31 then
            outer_object.state := 0;
          else
            outer_object.state := outer_object.state + 1;
          end if;
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
                    addr <= std_logic_vector(unsigned(addr) + j);
                    wren <= '0';
                    next_state <= s_append;
                  end if;
                when plant_sunflower =>
                if outer_object.state = 16 then
                  append_object.obj_type := sun;
                  append_object.sub_type := sun_norm;
                  append_object.pos_x := outer_object.pos_x;
                  append_object.pos_y := outer_object.pos_y;
                  append_object.invalid := '0';

                  j <= 0;
                  addr <= std_logic_vector(unsigned(addr) + j);
                  wren <= '0';
                  next_state <= s_append;
                end if;
                when plant_nut =>
                when others =>
              end case;
            when zombie =>
              case outer_object.sub_type is
                when zombie_norm =>
                  --outer_object.
                when others =>
              end case;
            when pea =>
              if outer_object.pos_x = 127 then --出地图
                outer_object.hp := 0;
              else
                j <= 0;
                wren <= '0';
                addr <= std_logic_vector(unsigned(addr) + j);
                next_state <= s_inner;
              end if;
            when sun =>
              outer_object.hp := outer_object.hp - 1;
            when others =>
          end case;
          if not(next_state = s_append or next_state = s_inner or next_state=s_idle) then
            addr <= std_logic_vector(unsigned(addr) + i);
            wren <= '1';
            data <= obj_to_bitvec(outer_object);
            next_state <= s_write_outer;
            i <= i+1;
          end if;
        end if;
      when s_write_outer =>
        wren <= '0';
        next_state <= s_outer;
        i <= i+1;
        addr <= std_logic_vector(unsigned(addr) + i);
      when s_append =>
        tmp_object := bitvec_to_obj(q);
        if tmp_object.invalid='1' or tmp_object.hp = 0 then
          addr <= std_logic_vector(unsigned(addr) + j);
          wren <= '1';
          data <= obj_to_bitvec(append_object);
          next_state <= s_append_done;
        else
          j <= j+1;
          addr <= std_logic_vector(unsigned(addr) + j);
          wren <= '0';
          next_state <= s_append;
        end if;
      when s_append_done =>
        wren <= '1';
        addr <= std_logic_vector(unsigned(addr) + i);
        data <= obj_to_bitvec(outer_object);
        next_state <= s_write_outer;
        i <= i+1;
      when s_inner =>
        inner_object <= bitvec_to_obj(q);
        if inner_object.invalid='1' then
          next_state <= s_outer;
        elsif inner_object.hp = 0 then
          j <= j+1;
          addr <= std_logic_vector(unsigned(addr) + j);
          next_state <= s_inner;
        else
          case outer_object.sub_type is
            when pea_norm =>
            when zombie_norm =>
            others =>
          end case;
          j <= j+1;
          addr <= std_logic_vector(unsigned(addr) + j);
          next_state <= s_inner;
        end if;
      when s_idle =>
        next_state <= s_idle;
      when others =>
        next_state <= s_idle;
    end case;
  end process;
end bhv;
