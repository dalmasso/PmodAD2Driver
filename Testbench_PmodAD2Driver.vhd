------------------------------------------------------------------------
-- Engineer:    Dalmasso Loic
-- Create Date: 07/02/2025
-- Module Name: PmodAD2Driver
-- Description:
--      Pmod AD2 Driver for the 4 Channels of 12-bit Analog-to-Digital Converter AD7991. The communication with the ADC uses the I2C protocol.
--      User can specifies the I2C Clock Frequency (up to 400 kHz with the Fast Mode).
--
-- WARNING: /!\ Require Pull-Up on SCL and SDA pins /!\
--
-- Usage:
--		User specifies inputs: I2C mode (i_mode), ADC Slave Address (i_addr), Configuration Byte (i_config_byte, write mode only) and the Last Read Cycle trigger (i_last_read, read mode only)
--		The transmission begin when the i_enable signal is set to '1'.
--		When started, the PmodAD2Driver executes the complete operation cycle (configurations or ADC conversions) independently of the new i_enable signal value (the i_enable signal can be reset).
--		At the end of the operation cycle, if the i_enable signal is still set to '1', the PmodAD2Driver executes the operation again with the current inputs.
--		The o_ready signal (set to '1') indicates the PmodAD2Driver is ready to process new operation. The o_ready signal is set to '0' to acknowledge the receipt.
--		The o_ready signal is set to '0' to acknowledge the receipt.
--		In Write mode, the PmodAD2Driver writes the Configuration byte into the ADC register and stop the transmission.
--		In Read mode, the PmodAD2Driver always reads 2-byte ADC conversion values channel-by-channel (according to ADC configuration).
--		The ADC value (o_adc_value) is available when its validity signal (o_adc_valid) is asserted.
--		In Read mode, while the i_last_read is NOT set to '1', the PmodAD2Driver execute the 2-byte ADC conversion value.
--		When the i_last_read is set to '1', the PmodAD2Driver ends the 2-byte ADC conversion value and return to IDLE state, and waits for the i_enable signal is set to '1'.
--
--		ADC AD7991 has 2 I2C Addresses:
--		AD7991-0: 010 1000
--		AD7991-1: 010 1001
--
--		Configuration Register (8-bit Write Only)
--		| D7  | D6  | D5  | D4  |   D3    |  D2	 |       D1   	   |      D0 	  | Bit
--		| CH3 | CH2 | CH1 | CH0 | REF_SEL | FLTR | Bit Trial delay | Sample delay | Description
--		|  1  |  1	|  1  |  1	|    0	  |  0   | 		 0 		   | 	  0 	  | Default Value
--
--		Configuration Register MSB Description
--		| D7 | D6 | D5 | D4 | Analog Input Channel
--		| 0  | 0  | 0  | 0  | No channel selected
--		| 0  | 0  | 0  | 1  | Convert on VIN0
--		| 0  | 0  | 1  | 0  | Convert on VIN1
--		| 0  | 0  | 1  | 1  | Sequence between VIN0 and VIN1
--		| 0  | 1  | 0  | 0  | Convert on VIN2
--		| 0  | 1  | 0  | 1  | Sequence between VIN0 and VIN2
--		| 0  | 1  | 1  | 0  | Sequence between VIN1 and VIN2
--		| 0  | 1  | 1  | 1  | Sequence among VIN0, VIN1, and VIN2
--		| 1  | 0  | 0  | 0  | Convert on VIN3
--		| 1  | 0  | 0  | 1  | Sequence between VIN0 and VIN3
--		| 1  | 0  | 1  | 0  | Sequence between VIN1 and VIN3
--		| 1  | 0  | 1  | 1  | Sequence among VIN0, VIN1, and VIN3
--		| 1  | 1  | 0  | 0  | Sequence between VIN2 and VIN3
--		| 1  | 1  | 0  | 1  | Sequence among VIN0, VIN2, and VIN3
--		| 1  | 1  | 1  | 0  | Sequence among VIN1, VIN2, and VIN3
--		| 1  | 1  | 1  | 1  | Sequence among VIN0, VIN1, VIN2, and VIN3
--
--		Conversion Result Register (16-bit Read Only)
--		| D15 | D14 |  D13  |  D12  | D11 | D10 | D9 | D8 | D7 | D6 | D5 | D4 | D3 | D2 | D1 | D0 |
--		|  0  |  0  | CHID1 | CHID0 | MSB | B10 | B9 | B8 | B7 | B6 | B5 | B4 | B3 | B2 | B1 | B0 |
--
-- Generics
--		sys_clock: System Input Clock Frequency (Hz)
--      i2c_clock: I2C Serial Clock Frequency (Standard Mode: 100 kHz, Fast Mode: 400 kHz)
-- Ports
--		Input 	-	i_sys_clock: System Input Clock
--		Input 	-	i_enable: Module Enable ('0': Disable, '1': Enable)
--		Input 	-	i_mode: Read or Write Mode ('0': Write, '1': Read)
--		Input 	-	i_addr: ADC Address (7 bits)
--		Input 	-	i_config_byte: ADC Configuration Byte (8 bits)
--		Input 	-	i_last_read: Indicates the Last Read Operation ('0': Continue Read Cycle, '1': Last Read Cycle)
--		Output 	-	o_adc_valid: ADC Read Value Valid ('0': Not Valid, '1': Valid)
--		Output 	-	o_adc_value: ADC Read Value
--		Output 	-	o_ready: ADC Ready Status ('0': NOT Ready, '1': Ready)
--		In/Out 	-	io_scl: I2C Serial Clock ('0'-'Z'(as '1') values, working with Pull-Up)
--		In/Out 	-	io_sda: I2C Serial Data ('0'-'Z'(as '1') values, working with Pull-Up)
------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Testbench_PmodAD2Driver is
--  Port ( );
END Testbench_PmodAD2Driver;

ARCHITECTURE Behavioral of Testbench_PmodAD2Driver is

COMPONENT PmodAD2Driver is

GENERIC(
	sys_clock: INTEGER := 100_000_000;
	i2c_clock: INTEGER range 1 to 400_000 := 100_000
);

PORT(
	i_sys_clock: IN STD_LOGIC;
    i_enable: IN STD_LOGIC;
	i_mode: IN STD_LOGIC;
	i_addr: IN UNSIGNED(6 downto 0);
    i_config_byte: IN UNSIGNED(7 downto 0);
	i_last_read: IN STD_LOGIC;
    o_adc_valid: OUT STD_LOGIC;
	o_adc_value: OUT UNSIGNED(15 downto 0);
    o_ready: OUT STD_LOGIC;
	io_scl: INOUT STD_LOGIC;
	io_sda: INOUT STD_LOGIC
);

END COMPONENT;

signal sys_clock: STD_LOGIC := '0';
signal enable: STD_LOGIC := '0';
signal mode: STD_LOGIC := '0';
signal addr: UNSIGNED(6 downto 0):= (others => '0');
signal config_byte: UNSIGNED(7 downto 0):= (others => '0');
signal last_read: STD_LOGIC := '0';
signal adc_valid: STD_LOGIC := '0';
signal adc_value: UNSIGNED(15 downto 0):= (others => '0');
signal ready: STD_LOGIC := '0';
signal scl: STD_LOGIC := '0';
signal sda: STD_LOGIC := '0';

begin

-- Clock 100 MHz
sys_clock <= not(sys_clock) after 5 ns;

-- Enable
enable <= '0', '1' after 11 us, '0' after 100 us, '1' after 530 us, '0' after 630 us;

-- Mode
mode <= '1', -- Read
        '0' after 509 us; -- Write

-- Address
addr <= "0101000", "0101001" after 300 us;

-- Config Byte
config_byte <= x"10";

-- Last Read
last_read <= '0', '1' after 351.5 us;

-- SCL
scl <= '1' when ready = '1' else 'Z';

-- SDA
sda <= 	'Z',
        -- Write Slave Address ACK
        '0' after 111.015 us,

        -- Read Byte 1.1 (0xD7)
        '1' after 121.015 us,
        '1' after 131.015 us,
        '0' after 141.015 us,
        '1' after 151.015 us,
        '0' after 161.015 us,
        '1' after 171.015 us,
        '1' after 181.015 us,
        '1' after 191.015 us,
        'Z' after 201.015 us,

        -- Read Byte 2.1 (0x15)
        '0' after 211.015 us,
        '0' after 221.015 us,
        '0' after 231.015 us,
        '1' after 241.015 us,
        '0' after 251.015 us,
        '1' after 261.015 us,
        '0' after 271.015 us,
        '1' after 281.015 us,
        'Z' after 291.015 us,

        -- Read Byte 1.2 (0xD0)
        '1' after 301.015 us,
        '1' after 311.015 us,
        '0' after 321.015 us,
        '1' after 331.015 us,
        '0' after 341.015 us,
        '0' after 351.015 us,
        '0' after 361.015 us,
        '0' after 371.015 us,
        'Z' after 381.015 us,

        -- Read Byte 2.2 (0x50)
        '0' after 391.015 us,
        '1' after 401.015 us,
        '0' after 411.015 us,
        '1' after 421.015 us,
        '0' after 431.015 us,
        '0' after 441.015 us,
        '0' after 451.015 us,
        '0' after 461.015 us,
        'Z' after 471.015 us,

        -- Write Slave Address ACK
        '0' after 630.015 us,
        'Z' after 640.015 us,

        -- Write Config ACK
        '0' after 720.015 us,
        'Z' after 730.015 us;

uut: PmodAD2Driver
    GENERIC map(
        sys_clock => 100_000_000,
        i2c_clock => 100_000
    )
    
    PORT map(
        i_sys_clock => sys_clock,
        i_enable => enable,
        i_mode => mode,
        i_addr => addr,
        i_config_byte => config_byte,
        i_last_read => last_read,
        o_adc_valid => adc_valid,
        o_adc_value => adc_value,
        o_ready => ready,
        io_scl => scl,
        io_sda => sda);

end Behavioral;