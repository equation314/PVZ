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
  constant OBJ_MAX : integer := 16;

  type obj_pool is array(0 to OBJ_MAX) of object;
  signal objects : obj_pool;

  signal k : integer := 0;
begin

  update: process(clk, enable)
    variable tmp_obj : object;
    variable current_object, obj : object;
    variable zombie_step : boolean := true;
  begin
    if clear='1' then
      for k in 0 to 0 loop
        tmp_obj.obj_type := sun;
        tmp_obj.sub_type := plant_shooter;
        tmp_obj.pos_x := 10;
        tmp_obj.pos_y := 1;
        tmp_obj.state := 31;
        tmp_obj.hp := 31;
        tmp_obj.invalid := '0';
        objects(k) <= tmp_obj;
      end loop;
    elsif enable='1' and rising_edge(clk) then
      for i in 0 to OBJ_MAX loop
        i_out <= std_logic_vector(to_unsigned(i, 8));
        current_object := objects(i);
        mem_out <= obj_to_bitvec(objects(0));
        next when current_object.invalid='1';
        next when current_object.hp = 0;

        if current_object.state = 31 then
          current_object.state := 0;
        else
          current_object.state := current_object.state+1;
        end if;

        case current_object.obj_type is
          when plant =>
            case current_object.sub_type is
              when plant_shooter =>
                if current_object.state = 16 then -- 发射豌豆
                  tmp_obj.obj_type := pea;
                  tmp_obj.sub_type := pea_norm;
                  tmp_obj.pos_x := current_object.pos_x;
                  tmp_obj.pos_y := current_object.pos_y;
                  tmp_obj.hp := 31;
                  tmp_obj.invalid := '0';
                  for j in 0 to OBJ_MAX loop
                    obj := objects(j);
                    if obj.invalid='1' or obj.hp = 0 then -- 是空位或已死亡
                      objects(j) <= tmp_obj;
                    end if;
                    exit when obj.invalid='1' or obj.hp = 0;
                  end loop;
                end if;
              when plant_sunflower =>
                if current_object.state = 16 then -- 产生阳光
                  tmp_obj.obj_type := sun;
                  tmp_obj.sub_type := sun_norm;
                  tmp_obj.pos_x := current_object.pos_x;
                  tmp_obj.pos_y := current_object.pos_y;
                  tmp_obj.hp := 31;
                  tmp_obj.invalid := '0';
                  for j in 0 to OBJ_MAX loop
                    obj := objects(j);
                    if obj.invalid='1' or obj.hp = 0 then -- 是空位或已死亡
                      objects(j) <= tmp_obj;
                    end if;
                    exit when obj.invalid='1' or obj.hp = 0;
                  end loop;
                end if;
              when others => -- Do nothing.
            end case;
          when zombie =>
            zombie_step := true;
            for j in 0 to OBJ_MAX loop
              tmp_obj := objects(j);

              next when tmp_obj.hp = 0 or tmp_obj.invalid = '1'; -- 跳过空位或死亡的物体
              exit when zombie_step=false;
              if tmp_obj.obj_type = plant and tmp_obj.pos_x = current_object.pos_x and tmp_obj.pos_y = current_object.pos_y then
                case tmp_obj.sub_type is
                  when plant_nut => -- 防御力强
                    tmp_obj.hp := tmp_obj.hp-1;
                  when others =>
                    if tmp_obj.hp < 3 then
                      tmp_obj.hp := 0;
                    else
                      tmp_obj.hp := tmp_obj.hp-3;
                    end if;
                end case;
                objects(j) <= tmp_obj;
                zombie_step := false;
              end if;
            end loop;

            if zombie_step then
              current_object.pos_x := current_object.pos_x-1;
            end if;

          when pea =>
            if current_object.pos_x = 127 then -- 走出地图
              current_object.hp := 0;
            end if;
            current_object.pos_x := current_object.pos_x + 1; -- 前进
            for j in 0 to OBJ_MAX loop -- 是否打到僵尸
              tmp_obj := objects(j);

              next when tmp_obj.hp = 0 or tmp_obj.invalid = '1';

              if tmp_obj.obj_type = zombie and tmp_obj.pos_y = current_object.pos_y and tmp_obj.pos_x = current_object.pos_x then
                if tmp_obj.pos_x - current_object.pos_x <= 2 then
                  if tmp_obj.hp < 2 then
                    tmp_obj.hp := 0;
                  else
                    tmp_obj.hp := tmp_obj.hp - 2; -- 体力减少
                  end if;
                  objects(j) <= tmp_obj;
                  current_object.hp := 0;
                  objects(i) <= current_object;
                end if;
              end if;
              exit when tmp_obj.obj_type = zombie and tmp_obj.pos_y = current_object.pos_y and tmp_obj.pos_x = current_object.pos_x;
            end loop;
          when sun =>
            current_object.hp := current_object.hp - 1;
          when others =>
        end case;

        objects(i) <= current_object;
      end loop;
    elsif rising_edge(clk) then
      if k > OBJ_MAX then
        k <= 0;
      end if;
      i_out <= std_logic_vector(to_unsigned(k, 8));
      mem_out <= obj_to_bitvec(objects(0));
      k <= k+1;
    end if;
  end process;

end bhv;
