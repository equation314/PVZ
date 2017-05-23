-- 游戏引擎，用来更新游戏中各物体的状态
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library objects;
use objects.pvz_objects.all;

entity engine is
  port(
    clk: in std_logic;
    storage_enable: out std_logic;
    storage_func: out obj_storage_funcion;
    storage_addr: out std_logic_vector(5 downto 0);
    obj: inout object
  );
end engine;

architecture bhv of engine is
  constant ADDR_FIRST : std_logic_vector(5 downto 0) := "000000";
begin
  process(clk)
    variable current_object, tmp_object : object;
    variable addr : std_logic_vector(5 downto 0);
    variable nearby_center: integer range 0 to 127;
    variable facing_plant: boolean := false;
  begin
    current_object.invalid := '1';
    if rising_edge(clk) then
      for i in 0 to 63 loop
        -- 读取物体
        storage_func <= OSF_read;
        storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + i);
        storage_enable <= '1';
        current_object := obj;
        storage_enable <= '0';
        ---- // 读取物体
        exit when current_object.invalid = '1'; -- 到头，停止
        next when current_object.hp = 0; -- 物体已死亡，跳过

        -- 更新物体计数器
        if current_object.state = 31 then
          current_object.state := 0;
        else
          current_object.state := current_object.state + 1;
        end if;
        ---- // 更新物体计数器

        storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + i);
        storage_func <= OSF_write;
        obj <= current_object;
        storage_enable <= '1';
        storage_enable <= '0';

        case current_object.obj_type is
          when plant =>
            case current_object.sub_type is
              when plant_shooter =>
                if current_object.state = 16 then -- 发射豌豆
                  tmp_object.obj_type := pea;
                  tmp_object.sub_type := pea_norm;
                  tmp_object.pos_x := current_object.pos_x;
                  tmp_object.pos_y := current_object.pos_y;
                  tmp_object.invalid := '0';
                  for j in 0 to 63 loop
                    storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
                    storage_func <= OSF_read;
                    storage_enable <= '1';
                    if obj.invalid='1' then -- 没有空位，append
                      obj <= tmp_object;
                      storage_func <= OSF_write;
                      storage_enable <= '0';
                      tmp_object.invalid := '1';
                      storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j + 1);
                      obj <= tmp_object;
                      storage_enable <= '1';
                      storage_enable <= '0';
                    elsif obj.hp = 0 then -- 某物体已死亡，替换。
                      obj <= tmp_object;
                      storage_func <= OSF_write;
                      storage_enable <= '1';
                      storage_enable <= '0';
                    end if;
                  end loop;
                end if;
              when plant_sunflower =>
                if current_object.state = 16 then -- 产生阳光
                  tmp_object.obj_type := sun;
                  tmp_object.sub_type := sun_norm;
                  tmp_object.pos_x := current_object.pos_x;
                  tmp_object.pos_y := current_object.pos_y;
                  tmp_object.invalid := '0';
                  for j in 0 to 63 loop
                    storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
                    storage_func <= OSF_read;
                    storage_enable <= '1';
                    if obj.invalid='1' then -- 没有空位，append
                      obj <= tmp_object;
                      storage_func <= OSF_write;
                      storage_enable <= '0';
                      tmp_object.invalid := '1';
                      storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j + 1);
                      obj <= tmp_object;
                      storage_enable <= '1';
                      storage_enable <= '0';
                    elsif obj.hp = 0 then -- 某物体已死亡，替换
                      obj <= tmp_object;
                      storage_func <= OSF_write;
                      storage_enable <= '1';
                      storage_enable <= '0';
                    end if;
                  end loop;
                end if;
              when others => -- Do nothing.
            end case;
          when pea =>
            if current_object.pos_x = 127 then -- 走出地图
              current_object.hp := 0;
              storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + i);
              storage_func <= OSF_write;
              obj <= current_object;
              storage_enable <= '1';
              storage_enable <= '0';
            end if;
            for j in 0 to 63 loop -- 是否打到僵尸
              storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
              storage_func <= OSF_read;
              storage_enable <= '1';
              tmp_object := obj;
              storage_enable <= '0';

              exit when tmp_object.invalid = '1';
              next when tmp_object.hp = 0;

              if tmp_object.obj_type = zombie and tmp_object.pos_y = current_object.pos_y then
                if tmp_object.pos_x - current_object.pos_x <= 2 then
                  if tmp_object.hp < 2 then
                    tmp_object.hp := 0;
                  else
                    tmp_object.hp := tmp_object.hp - 2; -- 体力减少
                  end if;
                  storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
                  obj <= tmp_object;
                  storage_func <= OSF_write;
                  storage_enable <= '1';
                  storage_enable <= '0';

                  current_object.hp := 0;
                  storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
                  obj <= current_object;
                  storage_enable <= '1';
                  storage_enable <= '0';
                end if;
              end if;
            end loop;
          when zombie =>
              if current_object.pos_y >= 10 and current_object.pos_y < 13 then
                nearby_center := 10;
              elsif current_object.pos_y >= 20 and current_object.pos_y < 23 then
                nearby_center := 20;
              elsif current_object.pos_y >= 30 and current_object.pos_y < 33 then
                nearby_center := 30;
              elsif current_object.pos_y >= 40 and current_object.pos_y < 43 then
                nearby_center := 40;
              elsif current_object.pos_y >= 50 and current_object.pos_y < 53 then
                nearby_center := 50;
              elsif current_object.pos_y >= 60 and current_object.pos_y < 63 then
                nearby_center := 60;
              elsif current_object.pos_y >= 70 and current_object.pos_y < 73 then
                nearby_center := 70;
              elsif current_object.pos_y >= 80 and current_object.pos_y < 83 then
                nearby_center := 80;
              else
                nearby_center := 100;
              end if;

            facing_plant := false;
            for j in 0 to 63 loop
              storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + j);
              storage_func <= OSF_read;
              storage_enable <= '1';
              tmp_object := obj;
              storage_enable <= '0';

              exit when tmp_object.invalid = '1';
              next when tmp_object.hp = 0;

              if tmp_object.obj_type=plant and tmp_object.pos_x = nearby_center then
                tmp_object.hp := tmp_object.hp-1; -- 吃植物
                storage_func <= OSF_write;
                storage_enable <= '1';
                storage_enable <= '0';
                facing_plant := true;
              end if;
              exit when facing_plant;
            end loop;

            if not facing_plant then
              current_object.pos_x := current_object.pos_x - 1; -- 前进
              storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + i);
              storage_func <= OSF_write;
              storage_enable <= '1';
              storage_enable <= '0';
            end if;
          when sun => -- 减少寿命
            current_object.hp := current_object.hp - 1;
            storage_addr <= std_logic_vector(unsigned(ADDR_FIRST) + i);
            storage_func <= OSF_write;
            obj <= current_object;
            storage_enable <= '1';
            storage_enable <= '0';
          when others =>
        end case;

      end loop;
    end if;
  end process;
end bhv;
