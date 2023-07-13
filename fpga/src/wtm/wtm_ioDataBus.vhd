-- ****************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- * 
-- *    Copyright (C) 2023 Denno Wiggle
-- *
-- *    Module to read the status of all three devices on the IO_DATA bus
-- *    and store the value in three registers. The devices are:
-- *    1. Config switch (Bit value OFF = 0, ON = 1)
-- *    2. Joystick 0    (Bit value OFF = 1, ON = 0)
-- *    2. Joystick 1    (Bit value OFF = 1, ON = 0)
-- * 
-- ****************************************************************************
-- * 
-- *    This library is free software; you can redistribute it and/or
-- *    modify it under the terms of the GNU Lesser General Public
-- *    License as published by the Free Software Foundation; either
-- *    version 2.1 of the License, or (at your option) any later version.
-- *
-- *    This library is distributed in the hope that it will be useful,
-- *    but WITHOUT ANY WARRANTY; without even the implied warranty of
-- *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- *    Lesser General Public License for more details.
-- *
-- *    You should have received a copy of the GNU Lesser General Public
-- *    License along with this library; if not, write to the Free Software
-- *    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
-- *    USA
-- *
-- ****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wtm_ioDataBus is
    generic(
        -- Determines the sampling interval between reading each device
        sampling_freq_hz    : integer := 10e3;
        clk_freq_hz         : integer := 10e6
    );
    port (
        clk                 : in std_logic;
        rst_n               : in std_logic;

        -- The data bus we use to read the devices
        io_data             : in  std_logic_vector(7 downto 0);

        -- Enable signals for each of the three device buffers.
        -- Only one cab be active at a time.
        config_sw_en_n      : out std_logic;
        iorq_read_a8_n      : out std_logic;
        iorq_read_a9_n      : out std_logic;

        -- Registers that are loaded with data we read from the device buffers
        joy0_register       : out std_logic_vector(7 downto 0);
        joy1_register       : out std_logic_vector(7 downto 0);
        config_register     : out std_logic_vector(7 downto 0)
    );
end wtm_ioDataBus;

architecture rtl of wtm_ioDataBus is

    -- For timing the reading of the io data ports
    constant tick_counter_max   : integer := clk_freq_hz / sampling_freq_hz - 1;
    signal   tick_counter       : integer range 0 to tick_counter_max;
    signal   tick               : std_logic;

    -- State machine that controls reading the devices
    type io_state_type is (WAIT_STATE, PRE_READ_DEVICE, READ_DEVICE);
    signal io_read_state        : io_state_type;

    signal joy0_register_in     : std_logic_vector(7 downto 0);
    signal joy1_register_in     : std_logic_vector(7 downto 0);

begin

    -- A tick counter that generates a tick pulse at a frequency
    -- specified in the sampling_freq_hz input parameter
    TICK_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                tick_counter <= 0;
                tick <= '0';
            else
                if tick_counter = tick_counter_max then
                    tick_counter <= 0;
                    tick <= '1';
                else
                    tick_counter <= tick_counter + 1;
                    tick <= '0';
                end if;
                
            end if;
        end if;
    end process;

    -- Process to read all three devices on the IO_DATA bus.
    -- Joystick 0, Jotstick 1, and the config switch.
    -- Reading occurs on a tick pulse (default frequency set by the input 
    --    parameter sampling_freq_hz)
    READING_PROC : process(clk)
        -- There are three devices to read on the bus
        constant max_device : integer := 3;
        variable device     : integer range 1 to max_device := 1;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                -- Assign default values
                joy0_register_in   <= (others => '1');
                joy1_register_in   <= (others => '1');
                config_register    <= (others => '0');

                -- Start in the wait state
                -- Change initial state to PRE_READ_DEVICE if using the config 
                -- switch immediately is required.
                io_read_state   <= WAIT_STATE;
                -- Change initial state to PRE_READ_DEVICE if using the config 
                -- switch immediately is required.
                -- io_read_state   <= PRE_READ_DEVICE;

                -- Set the cuffer control lines to tri-state
                iorq_read_a8_n  <= '1';
                iorq_read_a9_n  <= '1';
                config_sw_en_n  <= '1';

                -- Start with the config switch
                device := 1;
            else
                -- assign default values
                config_sw_en_n  <= '1';
                iorq_read_a8_n  <= '1';
                iorq_read_a9_n  <= '1';

                case io_read_state is 
                when WAIT_STATE =>
                    if tick = '1' then
                        io_read_state  <= PRE_READ_DEVICE;
                    end if;

                when PRE_READ_DEVICE =>
                    case device is
                        when 1 =>  config_sw_en_n <= '0';
                        when 2 =>  iorq_read_a8_n <= '0';
                        when 3 =>  iorq_read_a9_n <= '0';
                        when others =>
                    end case;
                    io_read_state  <= READ_DEVICE;

                when READ_DEVICE =>
                    case device is
                        when 1 =>  
                            config_sw_en_n   <= '0';
                            config_register  <= not io_data;
                        when 2 =>  
                            iorq_read_a8_n   <= '0';
                            joy0_register_in <= io_data;
                        when 3 =>  
                            iorq_read_a9_n   <= '0';
                            joy1_register_in <= io_data;
                        when others =>
                    end case;
                            
                    -- Loop back to the first device if we've read all three
                    -- otherwise advance to the next device
                    if device = max_device then
                        device := 1;
                    else
                        device := device + 1;
                    end if;

                    io_read_state <= WAIT_STATE;

                when others =>
                end case;
                
            end if;
        end if;
    end process;

    -- Swap joystick ports based on the config switch value.
    -- If Bit 0 = '1' => swap port.
    JOY_REGISTER_SWAP_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                joy0_register     <= (others => '1');
                joy1_register     <= (others => '1');
            else
                if config_register(0) = '0' then
                    joy0_register <= joy0_register_in;
                    joy1_register <= joy0_register_in;
                else 
                    joy0_register <= joy1_register_in;
                    joy1_register <= joy0_register_in;
                end if;
            end if;
        end if;
    end process;

end architecture;