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
--		Input 	-	i_enable: Module Enable ('0': Disable, '1': Enable)
--		Input 	-	i_last_read: Indicates the Last Read Operation ('0': Continue Read Cycle, '1': Last Read Cycle)
--		Output 	-	o_led: ACD Value
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
    i_enable: IN STD_LOGIC;
    i_last_read: IN STD_LOGIC;
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
-- Pmod AD2 Configuration Init
signal pmodad2_init_end: STD_LOGIC := '0';

-- Pmod AD2 Ready Handler
signal pmodad2_ready: STD_LOGIC := '0';
signal pmodad2_ready_reg: STD_LOGIC := '0';
signal pmodad2_ready_rising: STD_LOGIC := '0';

-- Pmode AD2 Input Register
signal mode_reg: STD_LOGIC := '0';

-- Pmod AD2 Output Register
signal adc_valid_reg: STD_LOGIC := '0';
signal adc_value_reg: UNSIGNED(15 downto 0) := (others => '0');

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

    ----------------------------
	-- Pmod ADZ Ready Handler --
	----------------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then
            pmodad2_ready_reg <= pmodad2_ready;
        end if;
    end process;
    pmodad2_ready_rising <= pmodad2_ready and not(pmodad2_ready_reg);

    -------------------
	-- Pmod AD2 Mode --
	-------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then

            -- Reset
            if (i_reset = '1') then
                pmodad2_init_end <= '0';

            -- Config Mode
            elsif (pmodad2_ready_rising = '1') then
                pmodad2_init_end <= '1';
            end if;
        end if;
    end process;

	----------------------------
	-- Pmod AD2 Configuration --
	----------------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then

            -- Reset Digital Value
            if (i_reset = '1') then
                mode_reg <= '0';
            
            -- Config Mode
            elsif (pmodad2_init_end = '0') then
                mode_reg <= '0';

            -- Signal Mode
            else
                mode_reg <= '1';
            end if;

        end if;
    end process;

    ----------------------------
	-- Pmod AD2 Digital Value --
	----------------------------
	process(i_sys_clock)
	begin

		if rising_edge(i_sys_clock) then

            -- Reset
            if (i_reset = '1') then
                o_led <= (others => '0');

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
        i_enable => i_enable,
        i_mode => mode_reg,
        i_addr => "0101000",
        i_config_byte => "00010000",
        i_last_read => i_last_read,
        o_adc_valid => adc_valid_reg,
        o_adc_value => adc_value_reg,
        o_ready => pmodad2_ready,
        io_scl => io_scl,
        io_sda => io_sda);

end Behavioral;