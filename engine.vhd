-- 游戏引擎，用来更新游戏中各物体的状态
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library objects;
use objects.pvz_objects.all;

entity engine is
  port(
    clk: in std_logic
  );
end engine;

architecture bhv of engine is
  constant ADDR_FIRST : std_logic_vector(5 downto 0) := "000000";
  constant OBJ_SIZE : integer := 27;

  signal tmp_mem, current_mem : std_logic_vector(OBJ_SIZE-1 downto 0);
  signal current_object, tmp_object, obj : object;
  signal addr : std_logic_vector(5 downto 0);
  signal nearby_center: integer range 0 to 127;
  signal facing_plant: boolean := false;
  signal storage : std_logic_vector(1560 downto 0);

begin
  process(clk, storage)
  begin
      for i in 0 to 1 loop
        -- 读取物体
        current_mem <= storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE);
        current_object <= bitvec_to_obj(current_mem);
        ---- // 读取物体
        exit when current_object.invalid = '1'; -- 到头，停止
        next when current_object.hp = 0; -- 物体已死亡，跳过

        -- 更新物体计数器
        if current_object.state = 31 then
          current_object.state <= 0;
        else
          current_object.state <= current_object.state + 1;
        end if;
        ---- // 更新物体计数器

        storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE) <= obj_to_bitvec(current_object);

        case current_object.obj_type is
          when plant =>
            case current_object.sub_type is
              when plant_shooter =>
                if current_object.state = 16 then -- 发射豌豆
                  tmp_object.obj_type <= pea;
                  tmp_object.sub_type <= pea_norm;
                  tmp_object.pos_x <= current_object.pos_x;
                  tmp_object.pos_y <= current_object.pos_y;
                  tmp_object.invalid <= '0';
                  for j in 0 to 1 loop
                    tmp_mem <= storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE);
                    obj <= bitvec_to_obj(tmp_mem);
                    if obj.invalid='1' then -- 没有空位，append
                      storage((j+2)*OBJ_SIZE-1 downto (j+1)*OBJ_SIZE) <= obj_to_bitvec(tmp_object);
                    elsif obj.hp = 0 then -- 某物体已死亡，替换。
                      storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE) <= obj_to_bitvec(tmp_object);
                    end if;
                  end loop;
                end if;
              when plant_sunflower =>
                if current_object.state = 16 then -- 产生阳光
                  tmp_object.obj_type <= sun;
                  tmp_object.sub_type <= sun_norm;
                  tmp_object.pos_x <= current_object.pos_x;
                  tmp_object.pos_y <= current_object.pos_y;
                  tmp_object.invalid <= '0';
                  for j in 0 to 1 loop
                    tmp_mem <= storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE);
                    obj <= bitvec_to_obj(tmp_mem);
                    if obj.invalid='1' then -- 没有空位，append
                      storage((j+2)*OBJ_SIZE-1 downto (j+1)*OBJ_SIZE) <= obj_to_bitvec(tmp_object);
                    elsif obj.hp = 0 then -- 某物体已死亡，替换
                      storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE) <= obj_to_bitvec(tmp_object);
                    end if;
                  end loop;
                end if;
              when others => -- Do nothing.
            end case;
          when pea =>
            if current_object.pos_x = 127 then -- 走出地图
              current_object.hp <= 0;
              storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE) <= obj_to_bitvec(current_object);
            end if;
            for j in 0 to 1 loop -- 是否打到僵尸
              tmp_mem <= storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE);
              tmp_object <= bitvec_to_obj(tmp_mem);

              exit when tmp_object.invalid = '1';
              next when tmp_object.hp = 0;

              if tmp_object.obj_type = zombie and tmp_object.pos_y = current_object.pos_y then
                if tmp_object.pos_x - current_object.pos_x <= 2 then
                  if tmp_object.hp < 2 then
                    tmp_object.hp <= 0;
                  else
                    tmp_object.hp <= tmp_object.hp - 2; -- 体力减少
                  end if;
                  storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE) <= obj_to_bitvec(tmp_object);

                  current_object.hp <= 0;
                  storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE) <= obj_to_bitvec(current_object);
                end if;
              end if;
            end loop;
          when zombie =>
              if current_object.pos_y >= 10 and current_object.pos_y < 13 then
                nearby_center <= 10;
              elsif current_object.pos_y >= 20 and current_object.pos_y < 23 then
                nearby_center <= 20;
              elsif current_object.pos_y >= 30 and current_object.pos_y < 33 then
                nearby_center <= 30;
              elsif current_object.pos_y >= 40 and current_object.pos_y < 43 then
                nearby_center <= 40;
              elsif current_object.pos_y >= 1 and current_object.pos_y < 53 then
                nearby_center <= 1;
              elsif current_object.pos_y >= 60 and current_object.pos_y < 2 then
                nearby_center <= 60;
              elsif current_object.pos_y >= 70 and current_object.pos_y < 73 then
                nearby_center <= 70;
              elsif current_object.pos_y >= 80 and current_object.pos_y < 83 then
                nearby_center <= 80;
              else
                nearby_center <= 100;
              end if;

            facing_plant <= false;
            for j in 0 to 1 loop
              tmp_mem <= storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE);
              tmp_object <= bitvec_to_obj(tmp_mem);

              exit when tmp_object.invalid = '1';
              next when tmp_object.hp = 0;

              if tmp_object.obj_type=plant and tmp_object.pos_x = nearby_center then
                tmp_object.hp <= tmp_object.hp-1; -- 吃植物
                storage((j+1)*OBJ_SIZE-1 downto j*OBJ_SIZE) <= obj_to_bitvec(tmp_object);
              end if;
              exit when facing_plant;
            end loop;

            if not facing_plant then
              current_object.pos_x <= current_object.pos_x - 1; -- 前进
              storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE) <= obj_to_bitvec(current_object);
            end if;
          when sun => -- 减少寿命
            current_object.hp <= current_object.hp - 1;
            storage((i+1)*OBJ_SIZE-1 downto i*OBJ_SIZE) <= obj_to_bitvec(current_object);
          when others =>
        end case;
      end loop;
  end process;
end bhv;
