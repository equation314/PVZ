library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library objects;
use objects.pvz_objects.all;

entity obj_storage is -- 读写物体信息
  port(
    -- 对外 IO
    enable: in std_logic; -- 使能，信号为0的时候不工作
    func: in obj_storage_funcion; -- 工作模式 读，写
    addr: in std_logic_vector(5 downto 0); -- 内存地址
    obj: inout object
  );
end obj_storage;
