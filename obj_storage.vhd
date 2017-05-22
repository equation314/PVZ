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
    obj: inout object;
    --- memory 	to CFPGA
    BASERAMWE           : out std_logic;   --write
    BASERAMOE           : out std_logic;    --read
    BASERAMCE           : out std_logic;		--cs
    BASERAMADDR         : out std_logic_vector(19 downto 0);
    BASERAMDATA         : inout std_logic_vector(31 downto 0)
  );
end obj_storage;

architecture bhv of obj_storage is
  constant ADDR_PREFIX : std_logic_vector(13 downto 0) := "00000000000000";

begin
  process(enable)
  begin
    if enable='1' then
      case func is
        when OSF_read =>
          BASERAMCE<='0';
          BASERAMOE<='0';
          BASERAMWE<='1';
          BASERAMADDR <= ADDR_PREFIX & addr;
        when OSF_write =>
          BASERAMCE<='0';
          BASERAMOE<='1';
          BASERAMWE<='0';
          BASERAMADDR <= ADDR_PREFIX & addr;
          BASERAMDATA <= obj_to_bitvec(obj);
      end case;
    end if;
  end process;
end bhv;

-- 编码、解码测试模块
library ieee;
use ieee.std_logic_1164.all;
library objects;
use objects.pvz_objects.all;
entity node_encoder is
  port(
    -- node: in object_node;
    enable: in std_logic;
    bits: out std_logic_vector(31 downto 0);
    bits_decode_encode: out std_logic_vector(31 downto 0)
  );
end node_encoder;
architecture bhv of node_encoder is
begin
  process(enable)
    variable obj : object;
    variable decode_node : object;
    variable vec: std_logic_vector(31 downto 0);
    variable b: std_logic;
  begin
    obj.obj_type := pea;
    obj.sub_type := plant_shooter;
    obj.pos_x := 50;
    obj.pos_y := 3;
    obj.hp := 15;
    obj.state := 0;
    vec := obj_to_bitvec(obj);
    bits <= vec;
    decode_node := bitvec_to_obj(vec);
    bits_decode_encode <= obj_to_bitvec(decode_node);
  end process;
end bhv;
-- 备忘
-- 存储器锁，如何实现？
