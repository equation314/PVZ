library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library objects;
use objects.pvz_objects.all;

entity obj_storage is -- 读写物体信息
  port(
    enable: in std_logic; -- 使能，信号为0的时候不工作
    func: in obj_storage_funcion; -- 工作模式 读，写
    addr: in std_logic_vector(5 downto 0); -- 内存地址
    obj_node: inout object;
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

      end case;
    end if;
  end process;
end bhv;

-- 备忘
-- 链表 存储起始位置和结束位置等信息
