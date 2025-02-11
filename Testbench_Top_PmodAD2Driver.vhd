------------------------------------------------------------------------
-- Engineer:    Dalmasso Loic
-- Create Date: 05/02/2025
-- Module Name: Top_PmodAD2Driver
-- Description:
--      Top Module including Pmod AD2 Driver for the 4 Channels of 12-bit Analog-to-Digital Converter AD7991.
--
-- WARNING: /!\ Require Pull-Up on SCL and SDA pins /!\
--
-- Ports
--		Input 	-	i_sys_clock: System Input Clock
--		Input 	-	i_reset: Module Reset ('0': No Reset, '1': Reset)
--		Output 	-	o_led: ADC Value
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
        o_led: OUT UNSIGNED(15 downto 0);
        io_scl: INOUT STD_LOGIC;
        io_sda: INOUT STD_LOGIC
    );

END COMPONENT;

signal sys_clock: STD_LOGIC := '0';
signal reset: STD_LOGIC := '0';
signal led: UNSIGNED(15 downto 0) := (others => '0');
signal scl: STD_LOGIC := '0';
signal sda: STD_LOGIC := '0';

begin

-- Clock 100 MHz
sys_clock <= not(sys_clock) after 5 ns;

-- Reset
reset <= '1', '0' after 5 us;

-- SDA
sda <= 	'Z',
        -- Write Slave Address ACK
        '0' after 105.025 us,
        'Z' after 115.025 us,

        -- Write Config ACK
        '0' after 195.025 us,
        'Z' after 215.025 us,

        -- Write Slave Address ACK
        '0' after 316.065 us,

        -- Read Byte 1.1 (0xD7)
        '1' after 326.065 us,
        '1' after 336.065 us,
        '0' after 346.065 us,
        '1' after 356.065 us,
        '0' after 366.065 us,
        '1' after 376.065 us,
        '1' after 386.065 us,
        '1' after 396.065 us,
        'Z' after 406.065 us,

        -- Read Byte 2.1 (0x15)
        '0' after 416.065 us,
        '0' after 426.065 us,
        '0' after 436.065 us,
        '1' after 446.065 us,
        '0' after 456.065 us,
        '1' after 466.065 us,
        '0' after 476.065 us,
        '1' after 486.065 us,
        'Z' after 496.065 us;

uut: Top_PmodAD2Driver
    
    PORT map(
        i_sys_clock => sys_clock,
        i_reset => reset,
        o_led => led,
        io_scl => scl,
        io_sda => sda);

end Behavioral;