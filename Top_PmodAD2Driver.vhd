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

ENTITY Top_PmodAD2Driver is

PORT(
	i_sys_clock: IN STD_LOGIC;
    i_reset: IN STD_LOGIC;
    o_led: OUT UNSIGNED(15 downto 0);
	io_scl: INOUT STD_LOGIC;
    io_sda: INOUT STD_LOGIC
);

END Top_PmodAD2Driver;

ARCHITECTURE Behavioral of Top_PmodAD2Driver is

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- Pmod States
TYPE pmodState is (IDLE, CONFIG, END_CONFIG, WAITING_READ, READ_ADC, END_READ);
signal state: pmodState := IDLE;
signal next_state: pmodState;

-- Read Timer (1 read every second)
constant CLOCK_DIV: INTEGER := 100_000_000;
signal read_timer: INTEGER range 0 to CLOCK_DIV-1 := 0;
signal read_enable: STD_LOGIC := '0';

-- Pmod AD2 Enable
signal pmodad2_enable: STD_LOGIC := '0';

-- Pmod AD2 Ready
signal pmodad2_ready: STD_LOGIC := '0';

-- Pmode AD2 Input Register
signal mode_reg: STD_LOGIC := '0';

-- Pmod AD2 Output Register
signal adc_valid_reg: STD_LOGIC := '0';
signal adc_value_reg: UNSIGNED(15 downto 0) := (others => '0');

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

	-----------------------
	-- Reset Read Timer --
	-----------------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

            -- Reset Read Timer
            if (i_reset = '1') or (read_timer = CLOCK_DIV-1) or (state = END_READ) then
                read_timer <= 0;

			-- Increment Read Timer
			elsif (state = WAITING_READ) then
                read_timer <= read_timer +1;
			end if;
		end if;
	end process;

	-----------------
	-- Read Enable --
	-----------------
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then
			
			-- Read Enable
			if (read_timer = CLOCK_DIV-1) then
				read_enable <= '1';
			else
                read_enable <= '0';
			end if;

		end if;
	end process;

	------------------------
	-- Pmod State Machine --
	------------------------
    -- Pmod State
	process(i_sys_clock)
	begin
		if rising_edge(i_sys_clock) then

            -- Reset
            if (i_reset = '1') then
                state <= IDLE;

            -- Next State
			else
				state <= next_state;
			end if;
			
		end if;
	end process;

    -- Pmod Next State
    process(state, pmodad2_ready, read_enable)
	begin
		case state is
			when IDLE =>    if (pmodad2_ready = '1') then
                                next_state <= CONFIG;
                            else
                                next_state <= IDLE;
							end if;

			-- Configure ADC
			when CONFIG =>  if (pmodad2_ready = '0') then
                                next_state <= END_CONFIG;
                            else
                                next_state <= CONFIG;
							end if;

            -- End of Configuration
            when END_CONFIG =>
                            if (pmodad2_ready = '1') then
                                next_state <= WAITING_READ;
                            else
                                next_state <= END_CONFIG;
                            end if;
            
            -- Waiting Read ADC
            when WAITING_READ =>
                            if (read_enable = '1') then
                                next_state <= READ_ADC;
                            else
                                next_state <= WAITING_READ;
                            end if;

            -- Read ADC
            when READ_ADC =>
                            if (pmodad2_ready = '0') then
                                next_state <= END_READ;
                            else
                                next_state <= READ_ADC;
                            end if;
            
            -- End Read ADC
            when END_READ =>
                            if (pmodad2_ready = '1') then
                                next_state <= WAITING_READ;
                            else
                                next_state <= END_READ;
                            end if;

            when others => next_state <= IDLE;
        end case;
    end process;

	---------------------
	-- Pmod AD2 Enable --
	---------------------
    pmodad2_enable <= '0' when state = IDLE or state = WAITING_READ else '1';

	-------------------
	-- Pmod AD2 Mode --
	-------------------
    mode_reg <= '0' when state = CONFIG or state = END_CONFIG else '1';

    ----------------------------
	-- Pmod AD2 Digital Value --
	----------------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then

            -- Config
            if (state = IDLE) then
                o_led <= "1010101010101010";

            -- ADC Value
            elsif (adc_valid_reg = '1') then
                o_led <= adc_value_reg;
            end if;

        end if;
    end process;

    ---------------------
	-- Pmod AD2 Driver --
	---------------------
    inst_PmodAD2Driver: PmodAD2Driver
    generic map (
        sys_clock => 100_000_000,
        i2c_clock => 100_000)
    
    port map (
        i_sys_clock => i_sys_clock,
        i_enable => pmodad2_enable,
        i_mode => mode_reg,
        i_addr => "0101000",
        i_config_byte => "00010000",
        i_last_read => '1',
        o_adc_valid => adc_valid_reg,
        o_adc_value => adc_value_reg,
        o_ready => pmodad2_ready,
        io_scl => io_scl,
        io_sda => io_sda);

end Behavioral;