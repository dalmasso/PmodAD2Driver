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
--		Input 	-	i_mode_op: Module Mode Operation ('0': ADC Configuration, '1': ADC Conversion)
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
        i_mode_op: IN STD_LOGIC;
        o_led: OUT UNSIGNED(15 downto 0);
        io_scl: INOUT STD_LOGIC;
        io_sda: INOUT STD_LOGIC
    );

END COMPONENT;

signal sys_clock: STD_LOGIC := '0';
signal reset: STD_LOGIC := '0';
signal mode_op: STD_LOGIC := '0';
signal led: UNSIGNED(15 downto 0) := (others => '0');
signal scl: STD_LOGIC := '0';
signal sda: STD_LOGIC := '0';

begin

-- Clock 100 MHz
sys_clock <= not(sys_clock) after 5 ns;

-- Reset
reset <= '1', '0' after 5 us, '1' after 300 us, '0' after 310 us;

-- Operation Mode
mode_op <= '0', '1' after 300 us;

-- SDA
sda <= 	'Z',
        -- Write Slave Address ACK
        '0' after 105.025 us,
        'Z' after 115.025 us,

        -- Write Config ACK
        '0' after 195.025 us,
        'Z' after 205.025 us,

        -- Write Slave Address ACK
        '0' after 410.025 us,

        -- Read Byte 1.1
        '1' after 420.025 us,
        '1' after 430.025 us,
        '0' after 440.025 us,
        '1' after 450.025 us,
        '0' after 460.025 us,
        '1' after 470.025 us,
        '1' after 480.025 us,
        '1' after 490.025 us,
        'Z' after 500.025 us,

        -- Read Byte 2.1
        '0' after 510.025 us,
        '0' after 520.025 us,
        '0' after 530.025 us,
        '1' after 540.025 us,
        '0' after 550.025 us,
        '1' after 560.025 us,
        '0' after 570.025 us,
        '1' after 580.025 us,
        'Z' after 590.025 us;

uut: Top_PmodAD2Driver
    
    PORT map(
        i_sys_clock => sys_clock,
        i_reset => reset,
        i_mode_op => mode_op,
        o_led => led,
        io_scl => scl,
        io_sda => sda);

end Behavioral;