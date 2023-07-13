-- ****************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- * 
-- *    Copyright (C) 2023 Denno Wiggle
-- *
-- *    Module for the Z80 bus. The main function is to provide access for 
-- *    the Z80 Retro! cpu to read and write internal registers.
-- *
-- *    IO Address Map
-- *    0x50 R/W FPGA adress register address
-- *    0x51 R/W FPGA data registers (not all are writable) 
-- *
-- *                                   Bits   7   6   5   4   3   2   1   0
-- *        Reg 0 - Version       (R)  Bits   (7 - 4) Major   (3 - 0) Minor
-- *        Reg 1 - Test Register (RW)       User defined to test FPGA access
-- *        Reg 2 - PLL Lock      (R ) Bits : 1   1   1   1  L3  L2  L1  L0
-- *        Reg 3 - Config switch (R ) Bits : 8   7   6   5   4   3   2   1 
-- *                Switch 1 = 1 swaps the joystick ports. 
-- *        Reg 4 - Joystick 0    (R ) Bits : U   D   R  B2   1   L VdpI B0
-- *        Reg 5 - Joystick 1    (R ) Bits : U   D   R  B2   1   L   1  B0
--*                 U = Up, D = Down, R = Right, L = Left, B1,2 = Buttons
-- *        Reg 6 - HDMI control  (RW) Bits : 1   1   1 EnS HpS  En Eq1 Eq0 
-- *                EnS = Enable signal, HpS = Hot plug detect signal
-- *                En = User enable setting, Eq1,0 = HDMI Equaliser Setting
-- *        Reg 7 - Interrupt     (R ) Bits : 1   1   1   1   1   1   1  VDP
-- *                VDP = 0 = VDP Interrupt present. Clear by reading VDP status
-- *
-- *    0x80 R/W  Video Display Processor
-- *    0x81 R/W  Video Display Processor
-- *    0xA8 Read Joystick 0 (Z80 Retro! legacy address)
-- *    0xA9 Read Joystick 1 (Z80 Retro! legacy address)
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

entity wtm_z80Interface is
    generic(
        majorVersion        : integer range 0 to 15 := 15;
        minorVersion        : integer range 0 to 15 := 15
    );
    port (
        clk                 : in std_logic; -- not used
        rst_n               : in std_logic;

        -- Z80 CPU Signal connections
        z80_address         : in  std_logic_vector(15 downto 0);
        z80_data_in         : in  std_logic_vector(7 downto 0);
        z80_data_out        : out std_logic_vector(7 downto 0);
        z80_data_oe         : out std_logic_vector(7 downto 0);
        z80_read_n          : in  std_logic;
        z80_write_n         : in  std_logic;
        z80_mem_req_n       : in  std_logic;
        z80_io_req_n        : in  std_logic;
        z80_bus_req_n       : out std_logic := '1';
        z80_bus_ack_n       : in  std_logic;
        z80_m1_n            : in  std_logic;
        z80_wait_n          : out std_logic := '1';
        z80_reset_n         : in  std_logic;
        z80_int             : out std_logic := '0';

        -- Z80 CPU data bus buffer enable and direction signals
        z80_dbuf_enable_n   : out std_logic;
        z80_dbuf_read_n     : out std_logic;

        -- FPGA Registers whose value used externally to this module
        pll_lock_register   : in  std_logic_vector(7 downto 0);
        joy0_register       : in  std_logic_vector(7 downto 0);
        joy1_register       : in  std_logic_vector(7 downto 0);
        config_register     : in  std_logic_vector(7 downto 0);
        hw_register         : in  std_logic_vector(7 downto 0);

        -- VDP bus interface signals
        vdp_data_in         : out std_logic_vector(7 downto 0);
        vdp_data_out        : in  std_logic_vector(7 downto 0);
        vdp_read_n          : out std_logic;
        vdp_write_n         : out std_logic;
        vdp_int_n           : in  std_logic;
        
        -- hdmi SIGNALS
        hdmi_hot_plug_det   : in  std_logic;
        hdmi_oe_n           : out std_logic;
        tmds_eq0            : out std_logic;
        tmds_eq1            : out std_logic
    );
end wtm_z80Interface;

architecture rtl of wtm_z80Interface is
    
    -- FPGA Registers internal to this module
    signal cpu_reg_addr     : std_logic_vector(7 downto 0);
    signal version_register : std_logic_vector(7 downto 0);
    signal test_register    : std_logic_vector(7 downto 0) := x"55";

    -- CPU bus control signals
    signal cpu_iorq_r       : std_logic;
    signal cpu_iorq_w       : std_logic;
    signal cpu_cs_r         : std_logic;
    signal cpu_iorq_addr    : std_logic_vector(7 downto 0);

    -- User setting for enabling HDMI
    signal hdmi_enable      : std_logic;


begin
    -- Always enable the data buffer
    z80_dbuf_enable_n <= '0';

    -- Always disable wait, bus request signals for now
    z80_bus_req_n <= '1';
    z80_wait_n    <= '1';
   
    -- For I/O access the Z80 only uses the lower 8 address bits
    cpu_iorq_addr <= z80_address(7 downto 0);

    -- Set up the version register based on parameters supplied to this module
    version_register <= std_logic_vector(to_unsigned(majorVersion, 4)) & std_logic_vector(to_unsigned(minorVersion, 4));

    -- Assign the Z80 interrupt to the VDP
    z80_int <= vdp_int_n;
    
    -- Enable hdmi out when the HPD dignal is high and user setting is enabled
    hdmi_oe_n <= not (hdmi_hot_plug_det and hdmi_enable);

    -- Process to Detect a Z80 I/O request
    IORQ_PROC : process(rst_n, z80_m1_n, z80_io_req_n)
    begin
        if rst_n = '0' then
            cpu_iorq_r <= '0';
            cpu_iorq_w <= '0';
        else
            cpu_iorq_r <= not z80_io_req_n and z80_m1_n and not z80_read_n;  
            cpu_iorq_w <= not z80_io_req_n and z80_m1_n and not z80_write_n;  
        end if;
    end process;

    -- Provide access for the Z80 to read the internal registers
    CPU_READ_PROC : process(cpu_iorq_r, cpu_iorq_addr, version_register, test_register)
    begin
        -- assign a default value that can be over-ridden
        cpu_cs_r    <= '0';
        vdp_read_n  <= '1';

        if cpu_iorq_r = '1' then
            case cpu_iorq_addr is

                -- Register address register
                when x"50" => 
                    z80_data_out <= cpu_reg_addr;
                    cpu_cs_r <= '1';

                -- Data registers
                when x"51" => 
                    case cpu_reg_addr is

                        -- 00 = Version register
                        when x"00"  => 
                            z80_data_out <= version_register;
                            cpu_cs_r <= '1';

                        -- 01 = Test R/W register
                        when x"01"  => 
                            z80_data_out <= test_register;
                            cpu_cs_r <= '1';

                        -- 02 = PLL Lock status register
                        when x"02"  => 
                            z80_data_out <= pll_lock_register;
                            cpu_cs_r <= '1';

                        -- 03 = Board config switch setting
                        when x"03"  => 
                            z80_data_out <= config_register;
                            cpu_cs_r <= '1';

                        -- 04 = Joystick 0 register
                        when x"04" =>
                            z80_data_out <= joy0_register;
                            cpu_cs_r <= '1';

                        -- 05 = Joystick 1 register
                        when x"05" =>
                            z80_data_out <= joy1_register;
                            cpu_cs_r <= '1';

                        -- 06 - HDMI control signal register
                        when x"06" =>
                            z80_data_out <= "111" & not hdmi_oe_n & hdmi_hot_plug_det & hdmi_enable & tmds_eq1 & tmds_eq0;
                            cpu_cs_r <= '1';
                    
                        -- 07 - Interrupt register
                        when x"07" =>
                            z80_data_out <= "1111111" & vdp_int_n;
                            cpu_cs_r <= '1';

                        -- Invisible register to help compilation with Efinity SW tool.
                        when x"99" =>
                            z80_data_out <= hw_register;
                    
                        -- Catch all - output 0xFF
                        when others => 
                            z80_data_out <= x"FF";
                            cpu_cs_r <= '1';

                    end case;

                -- Video Display Processor at address 80 and 81
                when x"80" | x"81" =>
                    -- z80_data_out <= reverse_any_vector(vdp_data_out);
                    z80_data_out <= vdp_data_out;
                    vdp_read_n   <= '0';
                    cpu_cs_r     <= '1';
                -- Legacy  Z80 Retro! joystick 0 register
                -- Bit position 1 contains the VDP interrupt
                when x"A8" =>
                    z80_data_out <= joy0_register(7 downto 2) & vdp_int_n & joy0_register(0);
                    cpu_cs_r     <= '1';
                -- Legacy Z80 Retro! joystick 1 register
                when x"A9" =>
                    z80_data_out <= joy1_register;
                    cpu_cs_r     <= '1';

                -- Do nothing with adresses that don't match our board
                when others => 

            end case;

        else 
            z80_data_out <= (others => '0');
        end if;
    end process;

    -- Provide access for the Z80 to write some of the internal registers
    CPU_WRITE_PROC : process(rst_n, cpu_iorq_w, cpu_iorq_addr, cpu_reg_addr, z80_data_in)
    begin
        if rst_n = '0' then
            cpu_reg_addr <= x"00";
            vdp_write_n  <= '1';
            hdmi_enable  <= '1';
            -- set the TMDS equaliser to the lowest setting as most use case have a short cable.
            tmds_eq0     <= '0';
            tmds_eq1     <= '0';

        elsif cpu_iorq_w = '1' then

            vdp_write_n  <= '1';

            case cpu_iorq_addr is
                -- Register address register
                when x"50" => 
                    cpu_reg_addr <= z80_data_in;

                -- Data registers
                when x"51" => 

                    case cpu_reg_addr is
                        -- 01 - Test R/W register
                        when x"01"  => 
                            test_register <= z80_data_in;

                        -- 06 - HDMI control signal register
                        when x"06" =>
                            hdmi_enable <= z80_data_in(2);
                            tmds_eq1    <= z80_data_in(1);
                            tmds_eq0    <= z80_data_in(0);

                        -- Catch all
                        when others =>

                    end case;

                -- Video Display Processor at address 80 and 81
                when x"80" | x"81" => 
                    -- vdp_data_in <= reverse_any_vector(z80_data_in);
                    vdp_data_in <= z80_data_in;
                    vdp_write_n  <= '0';

                --  catch all other values
                when others => 
            end case;
        else
            vdp_write_n  <= '1';
        end if;
    end process;

    -- Control the CPU data bus pin direction on this FPGA
    -- and the direction of the external data bus register
    CPU_READ_SELECT_PROC : process(rst_n, cpu_cs_r)
    begin
        if rst_n = '0' then
            z80_data_oe <= (others => '0');
            z80_dbuf_read_n   <= '0';
        else
            z80_data_oe <= (others => cpu_cs_r);
            z80_dbuf_read_n   <= cpu_cs_r;
        end if;
    end process;
end architecture;