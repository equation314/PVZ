-- 游戏中的各种物体，植物、僵尸和豌豆
package pvz_objects is
  type obj_types is (plant, zombie, pea, sun); -- 物体大类：植物，僵尸，豌豆，阳光
  type sub_obj_types is (plant_shooter, plant_sunflower, plant_nut
    , zombie_norm, pea_norm, sun_norm); -- 物体小类：植物（豌豆射手，向日葵，坚果） 僵尸（普通）
    -- 豌豆（普通）阳光（普通）
  type object is
    record
      obj_type: obj_types; -- 物体大类
      sub_type: sub_obj_types; -- 物体小类
      pos_x: integer range 0 to 640; -- x坐标
      pos_y: integer range 0 to 400; -- y坐标
      hp: integer range 0 to 100; -- 体力
    end record;
end package pvz_objects;

package body pvz_objects is
end package body pvz_objects;
