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

ENTITY PmodAD2Driver is

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

END PmodAD2Driver;

ARCHITECTURE Behavioral of PmodAD2Driver is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
COMPONENT I2CBusAnalyzer is
	PORT(
		i_clock: IN STD_LOGIC;
		i_scl_master: IN STD_LOGIC;
		i_scl_line: IN STD_LOGIC;
		i_sda_master: IN STD_LOGIC;
		i_sda_line: IN STD_LOGIC;
		o_bus_busy: OUT STD_LOGIC;
		o_bus_arbitration: OUT STD_LOGIC;
		o_scl_stretching: OUT STD_LOGIC
	);
END COMPONENT;

------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------------
-- I2C Clock Dividers
constant CLOCK_DIV: INTEGER := sys_clock / i2c_clock;
constant CLOCK_DIV_X2_1_4: INTEGER := CLOCK_DIV /4;
constant CLOCK_DIV_X2_3_4: INTEGER := CLOCK_DIV - CLOCK_DIV_X2_1_4;

-- I2C IDLE ('Z' with Pull-Up)
constant TRANSMISSION_IDLE: STD_LOGIC := 'Z';

-- I2C Transmission Don't Care Bit
constant TRANSMISSION_DONT_CARE_BIT: STD_LOGIC := '1';

-- I2C Transmission Start Bit
constant TRANSMISSION_START_BIT: STD_LOGIC := '0';

-- I2C Transmission ACK Bit
constant TRANSMISSION_ACK_BIT: STD_LOGIC := '0';

-- I2C Transmission NACK Bit
constant TRANSMISSION_NACK_BIT: STD_LOGIC := '1';

-- I2C Modes ('0': Write, '1': Read)
constant I2C_WRITE_MODE: STD_LOGIC := '0';

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- Pmod A2 Registers
signal enable_reg: STD_LOGIC := '0';
signal mode_reg: STD_LOGIC := '0';
signal data_write_reg: UNSIGNED(15 downto 0) := (others => '0');
signal data_read_reg: UNSIGNED(15 downto 0) := (others => '0');
signal data_read_reg_valid: STD_LOGIC := '0';

-- I2C Master States
TYPE i2cState is (	IDLE, START_TX,
					WRITE_SLAVE_ADDR, SLAVE_ADDR_ACK,
					WRITE_BYTE, WRITE_BYTE_ACK,
					READ_BYTE_1, READ_BYTE_1_ACK, READ_BYTE_2, READ_BYTE_2_ACK,
					READ_BYTE_2_NO_ACK, STOP_TX);
signal state: i2cState := IDLE;
signal next_state: i2cState;

-- I2C Clock Divider
signal i2c_clock_divider: INTEGER range 0 to CLOCK_DIV-1 := 0;
signal i2c_clock_enable: STD_LOGIC := '0';
signal i2c_clock_enable_rising: STD_LOGIC := '0';
signal i2c_clock_enable_falling: STD_LOGIC := '0';

-- I2C Transmission Bit Counter (8 bits per cycle)
signal bit_counter: UNSIGNED(2 downto 0) := (others => '0');
signal bit_counter_end: STD_LOGIC := '0';

-- I2C SCL
signal scl_reg_out: STD_LOGIC := '1';

-- I2C SDA
signal sda_in_reg: STD_LOGIC := '1';
signal sda_out: STD_LOGIC := '1';

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin
	
	--------------------------------------
	-- Pmod AD2 Enable & Mode Registers --
	--------------------------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then

            -- Load Inputs
            if (state = IDLE) then
				enable_reg <= i_enable;
				mode_reg <= i_mode;
            end if;

        end if;
    end process;

	-----------------------
	-- I2C Clock Divider --
	-----------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Reset I2C Clock Divider
			if (enable_reg = '0') or (i2c_clock_divider = CLOCK_DIV-1) then
				i2c_clock_divider <= 0;

			-- Increment I2C Clock Divider
			else
				i2c_clock_divider <= i2c_clock_divider +1;
			end if;
		end if;
	end process;

	-----------------------
	-- I2C Clock Enables --
	-----------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then
			
			-- I2C Clock Enable
			if (i2c_clock_divider = CLOCK_DIV-1) then
				i2c_clock_enable <= '1';
			else
				i2c_clock_enable <= '0';
			end if;

			-- I2C Clock Rising
			if (i2c_clock_divider = CLOCK_DIV_X2_1_4-1) then
				i2c_clock_enable_rising <= '1';
			else
				i2c_clock_enable_rising <= '0';
			end if;

			-- I2C Clock Falling
			if (i2c_clock_divider = CLOCK_DIV_X2_3_4-1) then
				i2c_clock_enable_falling <= '1';
			else
				i2c_clock_enable_falling <= '0';
			end if;

		end if;
	end process;

	-----------------------
	-- I2C State Machine --
	-----------------------
    -- I2C State
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Next State (When I2C Clock Enable)
			if (i2c_clock_enable = '1') then
				state <= next_state;
			end if;
			
		end if;
	end process;

	-- I2C Next State
	process(state, enable_reg, bit_counter_end, sda_in_reg, mode_reg, i_last_read)
	begin
		case state is
			when IDLE =>    if (enable_reg = '1') then
                                next_state <= START_TX;
                            else
                                next_state <= IDLE;
							end if;

			-- Start Transmission
			when START_TX => next_state <= WRITE_SLAVE_ADDR;

			-- Write Slave Address
			when WRITE_SLAVE_ADDR =>
							-- End of Write Slave Address Cycle
							if (bit_counter_end = '1') then
								next_state <= SLAVE_ADDR_ACK;

							else
								next_state <= WRITE_SLAVE_ADDR;
							end if;

			-- Slave Address ACK
			when SLAVE_ADDR_ACK =>
							-- Slave ACK Error or Stop Command
							if (sda_in_reg /= TRANSMISSION_ACK_BIT) then
								next_state <= STOP_TX;

							-- Write Mode
							elsif (mode_reg = I2C_WRITE_MODE) then
								next_state <= WRITE_BYTE;

							-- Read Mode
							else
								next_state <= READ_BYTE_1;
							end if;

			-- Write Byte
			when WRITE_BYTE =>
							-- End of Write Byte Cycle
							if (bit_counter_end = '1') then
								next_state <= WRITE_BYTE_ACK;

							else
								next_state <= WRITE_BYTE;
							end if;

			-- Write Byte ACK (Independ of Slave ACK/No ACK)
			when WRITE_BYTE_ACK => next_state <= STOP_TX;

			-- Read Byte 1
			when READ_BYTE_1 =>
							-- End of Read Byte 1 Cycle
							if (bit_counter_end = '1') then
								next_state <= READ_BYTE_1_ACK;
							else
								next_state <= READ_BYTE_1;
							end if;

			-- Read Byte 1 ACK
			when READ_BYTE_1_ACK => next_state <= READ_BYTE_2;

			-- Read Byte 2
			when READ_BYTE_2 =>
							-- End of Read Byte 2 Cycle
							if (bit_counter_end = '1') then

								-- End of Read Cycles (NO ACK)
								if (i_last_read = '1') then
									next_state <= READ_BYTE_2_NO_ACK;
							
								-- New Read Cycles (ACK)
								else
									next_state <= READ_BYTE_2_ACK;
								end if;

							else
								next_state <= READ_BYTE_2;
							end if;
			
			-- Read Byte 2 ACK
			when READ_BYTE_2_ACK => next_state <= READ_BYTE_1;

			-- End of Read Cycles
			when READ_BYTE_2_NO_ACK => next_state <= STOP_TX;

			-- End of Transmission
			when others => next_state <= IDLE;
		end case;
	end process;
			
	---------------------
	-- I2C Bit Counter --
	---------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- I2C Clock Enable
			if (i2c_clock_enable = '1') then

				-- Increment I2C Bit Counter
				if (state = WRITE_SLAVE_ADDR) or (state = WRITE_BYTE) or (state = READ_BYTE_1) or (state = READ_BYTE_2) then
					bit_counter <= bit_counter +1;
				
				-- Reset I2C Bit Counter
				else
					bit_counter <= (others => '0');
				end if;
			end if;
		end if;
    end process;

	-- I2C Bit Counter End
	bit_counter_end <= bit_counter(2) and bit_counter(1) and bit_counter(0);

	--------------------
	-- Pmod AD2 Ready --
	--------------------
    o_ready <= '1' when (state = IDLE) else '0';

	-----------------------------
	-- I2C SCL Output Register --
	-----------------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- SCL High ('Z')
			if (i2c_clock_enable_rising = '1') or (state = IDLE) then
				scl_reg_out <= '1';
			
			-- SCL Low ('0')
			elsif (i2c_clock_enable_falling = '1') and (state /= STOP_TX) then
				scl_reg_out <= '0';
			end if;
		end if;
	end process;

	--------------------
	-- I2C SCL Output --
	--------------------
	-- ('0' or 'Z' values)
	io_scl <= '0' when scl_reg_out = '0' else TRANSMISSION_IDLE;

	-----------------------------
	-- I2C Data Write Register --
	-----------------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- Load Inputs
            if (state = IDLE) then
				data_write_reg <= i_addr & i_mode & i_config_byte;
            
			-- I2C Clock Enable
			elsif (i2c_clock_enable = '1') then
				
				-- Left-Shift (when Write Slave Address or Write Byte)
				if (state = WRITE_SLAVE_ADDR) or (state = WRITE_BYTE) then
					data_write_reg <= data_write_reg(14 downto 0) & data_write_reg(15);
				end if;
			end if;
		end if;
	end process;

	--------------------------
	-- I2C SDA Output Value --
	--------------------------
	process(state, i_last_read, data_write_reg)
	begin
		-- Start & Stop Transmission
		if (state = START_TX) or (state = STOP_TX) then
			sda_out <= TRANSMISSION_START_BIT;
		
		-- Read Cycles ACK
		elsif (state = READ_BYTE_1_ACK) or (state = READ_BYTE_2_ACK) then
			sda_out <= TRANSMISSION_ACK_BIT;
		
		-- Read Cycle NO ACK
		elsif (state = READ_BYTE_2_NO_ACK) then
			sda_out <= TRANSMISSION_NACK_BIT;

		-- Write Slave Address or Write Byte Cycles
		elsif (state = WRITE_SLAVE_ADDR) or (state = WRITE_BYTE) then
			sda_out <= data_write_reg(15);

		-- IDLE, Slave Address ACK, Write Byte ACK, Read Byte 1/2
		else
			sda_out <= TRANSMISSION_DONT_CARE_BIT;
		end if;
	end process;

	--------------------
	-- I2C SDA Output --
	--------------------
	-- ('0' or 'Z' values)
	io_sda <= '0' when sda_out = '0' else TRANSMISSION_IDLE;

	-------------------
	-- I2C SDA Input --
	-------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- I2C Clock Enable Rising Edge
			if (i2c_clock_enable_rising = '1') then
				sda_in_reg <= io_sda;
			end if;
			
		end if;
	end process;

	--------------------
	-- Pmod AD2 Value --
	--------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- I2C Clock Enable
			if (i2c_clock_enable = '1') then
				
				-- Read SDA Input
				if (state = READ_BYTE_1) or (state = READ_BYTE_2) then
					data_read_reg <= data_read_reg(14 downto 0) & sda_in_reg;
				end if;

			end if;
		end if;
	end process;
	o_adc_value <= data_read_reg;

	--------------------------
	-- Pmod AD2 Valid Value --
	--------------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

			-- I2C Clock Enable
			if (i2c_clock_enable = '1') then

				-- Disable ADC Value Valid (New 2-byte Read Cycle)
				if (state = START_TX) or (state = READ_BYTE_1) then
					data_read_reg_valid <= '0';
				
				-- Enable ADC Value Valid Data (End of 2-byte Read Cycle)
				elsif (state = READ_BYTE_2_ACK) or (state = READ_BYTE_2_NO_ACK) then
					data_read_reg_valid <= '1';
				end if;
			end if;
		end if;
	end process;
	o_adc_valid <= data_read_reg_valid;

end Behavioral;