------------------------------------------------------------------------
-- Engineer:    Dalmasso Loic
-- Create Date: 05/02/2025
-- Module Name: Top_PmodAD2Driver
-- Description:
--      Top Module including Pmod AD2 Driver for the 4 Channels of 12-bit Analog-to-Digital Converter AD7991.
--
-- Ports
--		Input 	-	i_sys_clock: System Input Clock
--		Input 	-	i_reset: Module Reset ('0': No Reset, '1': Reset)
--		Input 	-	i_enable: Module Enable ('0': Disable, '1': Enable)
--		Input 	-	i_last_read: Indicates the Last Read Operation ('0': Continue Read Cycle, '1': Last Read Cycle)
--		Output 	-	o_led: ACD Value
--		In/Out 	-	io_scl: I2C Serial Clock ('0'-'Z'(as '1') values, working with Pull-Up)
--		In/Out 	-	io_sda: I2C Serial Data ('0'-'Z'(as '1') values, working with Pull-Up)
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Testbench_Top_PmodAD2Driver is
--  Port ( );
END Testbench_Top_PmodAD2Driver;

ARCHITECTURE Behavioral of Testbench_Top_PmodAD2Driver is

COMPONENT Top_PmodAD2Driver is

    PORT(
        i_sys_clock: IN STD_LOGIC;
        i_reset: IN STD_LOGIC;
        i_enable: IN STD_LOGIC;
        i_last_read: IN STD_LOGIC;
        o_led: OUT UNSIGNED(15 downto 0);
        io_scl: INOUT STD_LOGIC;
        io_sda: INOUT STD_LOGIC
    );

END COMPONENT;

signal sys_clock: STD_LOGIC := '0';
signal reset: STD_LOGIC := '0';
signal enable: STD_LOGIC := '0';
signal last_read: STD_LOGIC := '0';
signal led: UNSIGNED(15 downto 0) := (others => '0');
signal scl: STD_LOGIC := '0';
signal sda: STD_LOGIC := '0';

begin

-- Clock 100 MHz
sys_clock <= not(sys_clock) after 5 ns;

-- Reset
reset <= '1', '0' after 5 us;

-- Enable
enable <= '0', '1' after 11 us, '0' after 100 us, '1' after 530 us, '0' after 630 us;

-- Last Read
last_read <= '0', '1' after 915 us;

-- SDA
sda <= 	'Z',
        -- Write Slave Address ACK
        '0' after 111.015 us,
        'Z' after 121.015 us,

        -- Write Config ACK
        '0' after 201.015 us,
        'Z' after 211.015 us,

        -- Write Slave Address ACK
        '0' after 630.015 us,

        -- Read Byte 1.1
        '1' after 640.015 us,
        '1' after 650.015 us,
        '0' after 660.015 us,
        '1' after 670.015 us,
        '0' after 680.015 us,
        '1' after 690.015 us,
        '1' after 700.015 us,
        '1' after 710.015 us,
        'Z' after 720.015 us,

        -- Read Byte 2.1
        '0' after 730.015 us,
        '0' after 740.015 us,
        '0' after 750.015 us,
        '1' after 760.015 us,
        '0' after 770.015 us,
        '1' after 780.015 us,
        '0' after 790.015 us,
        '1' after 800.015 us,
        'Z' after 810.015 us,

        -- Read Byte 1.2
        '1' after 820.015 us,
        '1' after 830.015 us,
        '0' after 840.015 us,
        '1' after 850.015 us,
        '0' after 860.015 us,
        '0' after 870.015 us,
        '0' after 880.015 us,
        '0' after 890.015 us,
        'Z' after 900.015 us,

        -- Read Byte 2.2
        '0' after 910.015 us,
        '1' after 920.015 us,
        '0' after 930.015 us,
        '1' after 940.015 us,
        '0' after 950.015 us,
        '0' after 960.015 us,
        '0' after 970.015 us,
        '0' after 980.015 us,
        'Z' after 990.015 us;

uut: Top_PmodAD2Driver
    
    PORT map(
        i_sys_clock => sys_clock,
        i_reset => reset,
        i_enable => enable,
        i_last_read => last_read,
        o_led => led,
        io_scl => scl,
        io_sda => sda);

end Behavioral;