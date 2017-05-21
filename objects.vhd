-- 游戏中的各种物体，植物、僵尸和豌豆
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package pvz_objects is
  type obj_types is (plant, zombie, pea, sun); -- 物体大类：植物，僵尸，豌豆，阳光
  type sub_obj_types is (plant_shooter, plant_sunflower, plant_nut
    , zombie_norm, pea_norm, sun_norm); -- 物体小类：植物（豌豆射手，向日葵，坚果） 僵尸（普通）
    -- 豌豆（普通）阳光（普通）

  -- 使用二进制顺序编码两个枚举类型
  attribute enum_encoding: string;
  attribute enum_encoding of obj_types : type is "sequential";
  attribute enum_encoding of sub_obj_types : type is "sequential";

  type object is record
    obj_type: obj_types; -- 物体大类
    sub_type: sub_obj_types; -- 物体小类
    pos_x: integer range 0 to 640; -- x坐标
    pos_y: integer range 0 to 4; -- y坐标 共5行
    hp: integer range 0 to 127; -- 体力
  end record;

  -- 将各物体信息存储在链表中。下面定义的是链表的节点。
  type object_node is record
    obj: object; -- 存储的物体
    next_addr: std_logic_vector(5 downto 0); -- 下一个物体的地址，后6位（前14位固定）
  end record;

  type obj_storage_funcion is (OSF_read, OSF_write); -- 读，写

  function obj_to_bitvec(obj: object) return std_logic_vector;
  function obj_node_to_bitvec(node: object_node) return std_logic_vector;

end package pvz_objects;

package body pvz_objects is
  function obj_to_bitvec(obj: object) return std_logic_vector is
    variable obj_type_vec : std_logic_vector(1 downto 0) := obj.obj_type'enum_encoding;
    variable vec : std_logic_vector(25 downto 0) := (others => '0');
  begin
    return vec;
  end obj_to_bitvec;

  function obj_node_to_bitvec(node: object_node) return std_logic_vector is
      variable vec : std_logic_vector(31 downto 0) := (others => '0');
  begin
    return vec;
  end obj_node_to_bitvec;
end package body pvz_objects;

-- 备忘：
-- SRAM: 地址20位，数据32位
-- object 的二进制表示 共26位
--   obj_type: 2位
--   sub_type: 4位 目前不到8种，前面补0
--   pos_x: 10位
--   pos_y: 3位
--   hp: 7位
-- object_node 的二进制表示，共32位
--   obj: 26位
--   next_adder: 6位
