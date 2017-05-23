-- 游戏中的各种物体，植物、僵尸和豌豆
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package pvz_objects is
  type obj_types is (plant, zombie, pea, sun); -- 物体大类：植物，僵尸，豌豆，阳光
  type sub_obj_types is (plant_shooter, plant_sunflower, plant_nut
    , zombie_norm, pea_norm, sun_norm); -- 物体小类：植物（豌豆射手，向日葵，坚果） 僵尸（普通）
    -- 豌豆（普通）阳光（普通）

  type object is record
    obj_type: obj_types; -- 物体大类
    sub_type: sub_obj_types; -- 物体小类
    pos_x: integer range 0 to 127; -- x坐标 10, 20, ... , 80对应地图上8列的中点
    pos_y: integer range 0 to 4; -- y坐标 共5行
    hp: integer range 0 to 31; -- 体力
    state: integer range 0 to 31; -- 可用来控制节奏（实现动画、定间隔发射豌豆等）
    invalid: std_logic; -- 是否合法，用于判断结束
  end record;

  type obj_storage_funcion is (OSF_read, OSF_write); -- 读，写

  function obj_to_bitvec(obj: object) return std_logic_vector;
  function bitvec_to_obj(vec: std_logic_vector) return object;
  function decode_obj_type(vec: std_logic_vector) return obj_types;
  function decode_sub_type(vec: std_logic_vector) return sub_obj_types;

end package pvz_objects;

package body pvz_objects is
  function obj_to_bitvec(obj: object) return std_logic_vector is
    variable obj_type_vec : std_logic_vector(1 downto 0);
    variable obj_subtype_vec : std_logic_vector(3 downto 0);
    variable pos_x_vec: std_logic_vector(6 downto 0);
    variable pos_y_vec: std_logic_vector(2 downto 0);
    variable hp_vec: std_logic_vector(4 downto 0);
    variable state_vec: std_logic_vector(4 downto 0);
    variable vec: std_logic_vector(31 downto 0);
  begin
    obj_type_vec := std_logic_vector(to_unsigned(obj_types'pos(obj.obj_type), obj_type_vec'length));
    obj_subtype_vec := std_logic_vector(to_unsigned(sub_obj_types'pos(obj.sub_type), obj_subtype_vec'length));
    pos_x_vec := std_logic_vector(to_unsigned(obj.pos_x, pos_x_vec'length));
    pos_y_vec := std_logic_vector(to_unsigned(obj.pos_y, pos_y_vec'length));
    hp_vec := std_logic_vector(to_unsigned(obj.hp, hp_vec'length));
    state_vec := std_logic_vector(to_unsigned(obj.state, state_vec'length));
    vec := obj_type_vec & obj_subtype_vec & pos_x_vec & pos_y_vec & hp_vec & state_vec & "000000";
    return vec;
  end obj_to_bitvec;

  function decode_obj_type(vec: std_logic_vector) return obj_types is
  begin
    case vec is
      when "00" => return plant;
      when "01" => return zombie;
      when "10" => return pea;
      when "11" => return sun;
    end case;
  end decode_obj_type;

  function decode_sub_type(vec: std_logic_vector) return sub_obj_types is
  begin
    case vec is
      when "0000" => return plant_shooter;
      when "0001" => return plant_sunflower;
      when "0010" => return plant_nut;
      when "0011" => return zombie_norm;
      when "0100" => return pea_norm;
      when "0101" => return sun_norm;
      when others => return plant_shooter;
    end case;
  end decode_sub_type;

  function bitvec_to_obj(vec: std_logic_vector) return object is
    variable obj: object;
  begin
    obj.obj_type := decode_obj_type(vec(31 downto 30));
    obj.sub_type := decode_sub_type(vec(29 downto 26));
    obj.pos_x := to_integer(unsigned(vec(25 downto 19)));
    obj.pos_y := to_integer(unsigned(vec(18 downto 16)));
    obj.hp := to_integer(unsigned(vec(15 downto 11)));
    obj.state := to_integer(unsigned(vec(10 downto 6)));
    obj.invalid := vec(5);
    return obj;
  end bitvec_to_obj;

end package body pvz_objects;

-- 备忘：
-- SRAM: 地址20位，数据32位

-- object 的二进制表示 共26位
--   obj_type: 2位
--   sub_type: 4位 目前不到8种，前面补0
--   pos_x: 7位
--   pos_y: 3位
--   hp: 5位
--   state: 5位
--   invalid: 是否非法
--   后5位为0

-- 末尾元素，invalid = 1
