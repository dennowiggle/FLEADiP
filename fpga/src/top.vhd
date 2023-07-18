-- *************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- * 
-- *    Copyright (C) 2023
-- *
-- *    License for modules not f18a or DVI (f18a, DVI)
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
-- * 
-- *    Uses f18a module for video processor -- https://dnotq.io
-- *    Copyright 2011-2018 Matthew Hagerty (matthew <at> dnotq <dot> io)
-- *    f18a module released under the 3-Clause BSD License:
-- *       - See f18a module for full terms
-- * 
-- ****************************************************************************
-- * 
-- *    Uses dvi/hdmi module from C64 Vic replacement project vicii-kawari
-- *    (https://github.com/randyrossi/vicii-kawari)
-- *    Copyright (c) 2022 Randy Rossi and Sameer Puri
-- *    Module released under the terms of the GNU General Public License as 
-- *    published by the Free Software Foundation, version 3. 
-- *       - See dvi module for full terms
-- ****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        -- Fpga signals
        -- Crystal Oscillator - ECS-2333-500-BN-TR
        clk_in_50           : in std_logic;

        -- PLL to generate a ~100MHz intermediate clock from clock input.
        -- Actual frequency target is 100.714285MHz
        -- Only used for PLL's
        pll_100_rst_n       : out std_logic;
        clk_100             : in  std_logic;
        clk_100_lock        : in  std_logic;

        -- Generate three clocks from 100.714285MHz intermediate clock
        -- 25MHz pixel clock = 25.178571MHz (Target pixel clock 640 x 48 = 25.175MHz)
        -- https:--github.com/hdl-util/hdmi
        -- LVDS requires a specific PLL - BR0 for T20 device.
        pll_vdp_rst_n       : out std_logic;
        clk_250             : in  std_logic;
        clk_50              : in  std_logic;
        clk_25              : in  std_logic;
        clk_vdp_lock        : in  std_logic;

        -- Generate a pseudo GROM clock just because we can
        -- Ti9918 = 447,443khz. FPGA = 447,393khz
        pll_grom_rst_n      : out std_logic;
        clk_grom            : in std_logic;
        clk_grom_lock       : in std_logic;
        
        -- PLL Placeholder in case we need to use the Z80 clock
        pll_z80_50_rst_n    : out std_logic;
        clk_z80_50          : in  std_logic;
        clk_z80_50_lock     : in  std_logic;

        -- Placeholder to output a clock or other signal
        gromclk             : out std_logic;

        -- Z80 Interface
        z80_address         : in  std_logic_vector(15 downto 0);
        z80_data_in         : in  std_logic_vector(7 downto 0);
        z80_data_out        : out std_logic_vector(7 downto 0);
        z80_data_oe         : out std_logic_vector(7 downto 0);
        clk_in_z80_10       : in  std_logic;
        z80_read_n          : in  std_logic;
        z80_write_n         : in  std_logic;
        z80_mem_req_n       : in  std_logic;
        z80_io_req_n        : in  std_logic;
        z80_bus_req_n       : out std_logic;
        z80_bus_ack_n       : in  std_logic;
        z80_m1_n            : in  std_logic;
        z80_wait_n          : out std_logic;
        z80_reset_n         : in  std_logic;
        z80_int             : out std_logic;
        
        -- Control lines for the 245 bus transceivers
        iorq_read_a8_n      : out std_logic;
        iorq_read_a9_n      : out std_logic;
        config_sw_en_n      : out std_logic;
        z80_dbuf_enable_n   : out std_logic;
        z80_dbuf_read_n     : out std_logic;

        io_data : in  std_logic_vector(7 downto 0);

        -- I/O user port
        -- Currently configured for a two digit 7 segment timer display 
        io_user_in          : in  std_logic_vector(7 downto 0);
        io_user_out         : out std_logic_vector(7 downto 0);
        io_user_oe          : out std_logic_vector(7 downto 0);

        -- status LED
        led_status          : out std_logic;

        -- VGA port
        rgb_hsync           : out std_logic;
        rgb_vsync           : out std_logic;
        rgb_blank           : out std_logic;
        rgb_red             : out std_logic_vector(3 downto 0);
        rgb_green           : out std_logic_vector(3 downto 0);
        rgb_blue            : out std_logic_vector(3 downto 0);

        -- SPI ports
        -- SPI master config = talk to ram
        spi_mosi_out        : out std_logic;
        spi_miso_in         : in  std_logic;
        spi_clk_out         : out std_logic;
        -- Spi slave config = talk to CPU
        spi_mosi_in         : in  std_logic;
        spi_miso_out        : out std_logic;
        spi_clk_in          : in  std_logic;
        spi_mouse_cs        : in  std_logic;
        -- SPI common
        spi_mosi_oe         : out std_logic;
        spi_miso_oe         : out std_logic;
        spi_clk_oe          : out std_logic;

        -- hdmi SIGNALS
        hdmi_hot_plug_det   : in  std_logic;
        hdmi_oe_n           : out std_logic;
        tmds_eq0            : out std_logic;
        tmds_eq1            : out std_logic;

        lvds_data_0         : out std_logic;
        lvds_data_1         : out std_logic;
        lvds_data_2         : out std_logic;
        lvds_clock          : out std_logic
    );

end top;

architecture rtl of top is

    component dvi is 
        port(
            clk_pixel       : in  std_logic;
            clk_pixel_x10   : in  std_logic;
            reset           : in  std_logic;
            rgb             : in  std_logic_vector(23 downto 0);
            hsync           : in  std_logic;
            vsync           : in  std_logic;
            de              : in  std_logic;
            tmds            : out std_logic_vector(2 downto 0);
            tmds_clock      : in  std_logic
        );
    end component;

    -- Synchronized reset signals
    -- Synchronized to clk_in_50 with 1250us required delay added
    signal rst_n                : std_logic;
    -- Synchronized to clk_in_z80_10
    signal rst_z80_10_n         : std_logic;
    signal rst_vdp_n            : std_logic;
    -- Sychronized to clk_250
    signal rst_250              : std_logic;

    -- HW register used to help successfully compile in Efinity tool.
    signal hw_register          : std_logic_vector(7 downto 0);
    
    -- Internal registers
    signal pll_lock_register    : std_logic_vector(7 downto 0);
    signal joy0_register        : std_logic_vector(7 downto 0);
    signal joy1_register        : std_logic_vector(7 downto 0);
    signal config_register      : std_logic_vector(7 downto 0);

    -- Something to play with on the IO_USER port
    signal segments             : std_logic_vector(6 downto 0);
    signal digit_sel            : std_logic;

    -- Video Display Processor signals
    signal vdp_data_in          : std_logic_vector(7 downto 0);
    signal vdp_data_out         : std_logic_vector(7 downto 0);
    signal vdp_mode             : std_logic;
    signal vdp_read_n           : std_logic;
    signal vdp_write_n          : std_logic;
    signal vdp_int_n            : std_logic;

    signal rgb_8bit_red         : std_logic_vector(7 downto 0);
    signal rgb_8bit_green       : std_logic_vector(7 downto 0);
    signal rgb_8bit_blue        : std_logic_vector(7 downto 0);
    signal lvds_data            : std_logic_vector(2 downto 0);

begin

    -- Logic to turn on the PLL's
    pll_100_rst_n  <= '1';
    pll_vdp_rst_n  <= clk_100_lock;
    pll_grom_rst_n <= clk_100_lock;
    pll_z80_50_rst_n <= '1';

    -- Assign the PLL lock status register
    pll_lock_register <= "1111" & clk_grom_lock & clk_vdp_lock & clk_100_lock & clk_z80_50_lock;

    -- Light up the STATUS led to a condition showing the combined PLL lock status
    -- led_status <= clk_100_lock and clk_vdp_lock and clk_grom_lock and clk_z80_50_lock;
    led_status <= clk_100_lock and clk_vdp_lock and clk_grom_lock and clk_z80_50_lock;

    -- Disable SPI signal output for now
    spi_mosi_oe <= '0';
    spi_miso_oe <= '0';

    -- Setup the I/O user port as an ouput
    io_user_oe <= (others => '1');

    -- Assign to IO_USER pins
    -- Good to use for debug or developing new features.
    io_user_out(6 downto 0) <= segments;
    io_user_out(7)          <= digit_sel;
    -- io_user_out(7) <= clk_50;
    -- io_user_out(5 downto 0) <= (others => '0');

    -- Need this for compile to work if we want to output clk_z80_50 for test purposes
    -- A clock needs to drive at least one flip-flop clock for the Efinity tool to compile
    CLK_Z80_50_OUT_PROC : process(clk_z80_50)
    begin
        if rising_edge(clk_z80_50) then
            hw_register(6) <= not hw_register(6);
        end if;
    end process;
    
    -- Need this for compile to work if we want to output clk_grom for test purposes
    -- A clock needs to drive at least one flip-flop clock for the Efinity tool to compile.
    CLK_GROM_OUT_PROC : process(clk_grom)
    begin
        if rising_edge(clk_grom) then
            hw_register(7) <= not hw_register(7);
        end if;
    end process;

    -- Output 50MHz clk on GROMCLK pin to measure using a frequency counter
    -- gromclk <= clk_in_50;
    -- Output 447,393khz on gromclk
    gromclk <= clk_grom;


    -- synchronise global reset signal to the FPGA 50MHz input clock domain
    -- and add in a 1250 us delay as required by T20 FPGA 
    SYNC_DELAY_RESET_TO_CLK_IN_50 : entity work.wtm_resetSyncDelay(rtl)
    generic map(
        delay_in_us  => 1250,
        clk_freq_hz  => 50e6
    )
    port map(
       clock       => clk_in_50, 
       rst_n       => z80_reset_n, -- from the input pin
       rst_out_n   => rst_n
    );

    -- Synchronize the Z80 cpu logic reset to the Z80 10Mhz clock
    SYNC_RESET_TO_CLK_IN_Z80_10 : entity work.wtm_resetSync(rtl)
    port map(
       clock       => clk_in_z80_10, 
       rst_n       => rst_n,
       rst_out_n   => rst_z80_10_n
    );

    -- Synchronize the VDP logic reset to pixel clock
    SYNC_VDP_RESET_TO_CLK_25 : entity work.wtm_resetSync(rtl)
    port map(
       clock       => clk_25, 
       rst_n       => rst_z80_10_n and clk_vdp_lock,
       rst_out_n   => rst_vdp_n
    );

    -- Synchronize the DVI logic reset to the pixel x10 clock
    SYNC_DVI_RESET_TO_CLK_250 : entity work.wtm_resetSync(rtl)
    port map(
       clock       => clk_250, 
       rst_n       => not (rst_z80_10_n and clk_vdp_lock),
       rst_out_n   => rst_250
    );

    -- Z80_CPU_Interface
    Z80_CPU : entity work.wtm_z80Interface(rtl)
    generic map(
        majorVersion => 0,
        minorVersion => 1
    )
    port map(
        clk               => clk_in_z80_10, 
        rst_n             => rst_z80_10_n,

        -- Z80 signals
        z80_address       => z80_address,
        z80_data_in       => z80_data_in,
        z80_data_out      => z80_data_out,
        z80_data_oe       => z80_data_oe,
        z80_read_n        => z80_read_n,
        z80_write_n       => z80_write_n,
        z80_mem_req_n     => z80_mem_req_n,
        z80_io_req_n      => z80_io_req_n,
        z80_bus_req_n     => z80_bus_req_n,
        z80_bus_ack_n     => z80_bus_ack_n,
        z80_m1_n          => z80_m1_n,
        z80_wait_n        => z80_wait_n,
        z80_reset_n       => z80_reset_n,
        z80_int           => z80_int,
        z80_dbuf_enable_n => z80_dbuf_enable_n,
        z80_dbuf_read_n   => z80_dbuf_read_n,

        -- FPGA Registers external to module
        pll_lock_register => pll_lock_register,
        joy0_register     => joy0_register,
        joy1_register     => joy1_register,
        config_register   => config_register,
        hw_register       => hw_register,

        -- VDP signals
        vdp_data_in       => vdp_data_in,
        vdp_data_out      => vdp_data_out,
        vdp_read_n        => vdp_read_n,
        vdp_write_n       => vdp_write_n,
        vdp_int_n         => vdp_int_n,
        tmds_eq0          => tmds_eq0,
        tmds_eq1          => tmds_eq1,
        hdmi_oe_n         => hdmi_oe_n,
        hdmi_hot_plug_det => hdmi_hot_plug_det

    );

    -- IO Bus with the config switch and two joystick ports
    IO_DATA_BUS : entity work.wtm_ioDataBus(rtl)
    generic map(
        sampling_freq_hz => 50e3,
        clk_freq_hz      => 10e6
    )
    port map(
        clk               => clk_in_z80_10, 
        rst_n             => rst_z80_10_n,
        io_data           => io_data,
        config_sw_en_n    => config_sw_en_n,
        iorq_read_a8_n    => iorq_read_a8_n,
        iorq_read_a9_n    => iorq_read_a9_n,
        joy0_register     => joy0_register,
        joy1_register     => joy1_register,
        config_register   => config_register
   );

    -- Seven Segment Timer (Digilent ssd pmod)
    -- Something to play with on the IO_USER bus 
    -- (also helps test out pin functionality)
    SevenSegTimer_Inst : entity work.sevenSegTimer(rtl)
    generic map(
        clk_hz => 50e6,
        alt_counter_len => 16
    )
    port map(
        -- entity sig => local sig
        clk       => clk_in_50,
        rst_n     => rst_n,
        segments  => segments,
        digit_sel => digit_sel
    );
    
    -- VDP signals
    vdp_mode   <= z80_address(0);

    -- VDP core which is the f18a - Copyright 2011-2018 Matthew Hagerty
    -- https://dnotq.io
    -- f18a internal PLL's have been removed and placed in top.
    VideoDisplayProcessor_Inst : entity work.f18a_top(rtl)
    port map(
        -- 50Mhz pll input no longer needed in this module
        -- clk_50m0_net   : in  std_logic;
        -- Feed with 25MHz pixel clock and 50Mhz clock = 2 x pixel clock
        clk_100m0_s    => clk_50,
        clk_25m0_s     => clk_25,
  
        -- 9918A to Host interface
        reset_n_net    => rst_vdp_n,
        mode_net       => vdp_mode,
        csw_n_net      => vdp_write_n,
        csr_n_net      => vdp_read_n,
        int_n_net      => vdp_int_n,
        -- clk_grom_net   =>
        -- clk_cpu_net    =>
        cd_net         => vdp_data_in,
        cd_out_s       => vdp_data_out,

        -- Video generation
        hsync_net      => rgb_hsync,
        vsync_net      => rgb_vsync,
        red_net        => rgb_red,
        grn_net        => rgb_green,
        blu_net        => rgb_blue,
        blank_net      => rgb_blank,

        -- User header for feature selection
        -- Not used in this application
        usr1_net       => '0',
        usr2_net       => '0',
        usr3_net       => '0',
        usr4_net       => '0',
  
        -- No need to use the SPI feature in this application
        -- spi_cs_net     =>
        -- spi_mosi_net   =>
        spi_miso_net   => '1'
        -- spi_clk_net    =>
    );

    -- Set up the signals required by the hdmi module
    rgb_8bit_red   <= rgb_red   & "0000";
    rgb_8bit_green <= rgb_green & "0000";
    rgb_8bit_blue  <= rgb_blue  & "0000";

    lvds_data_0 <= lvds_data(0);
    lvds_data_1 <= lvds_data(1);
    lvds_data_2 <= lvds_data(2);


    -- DVI/HDMI module from C64 Vic replacement project vicii-kawari
    -- (https://github.com/randyrossi/vicii-kawari)
    -- Copyright (c) 2022 Randy Rossi and Sameer Puri.
    -- Code modified so TMDS order matches R-G-B for this applicaction
    DVI_Module : dvi
    port map(
        clk_pixel       => clk_25,
        clk_pixel_x10   => clk_250,
        reset           => rst_250,
        rgb             => rgb_8bit_red & rgb_8bit_green & rgb_8bit_blue,
        hsync           => rgb_hsync,
        vsync           => rgb_vsync,
        de              => not rgb_blank,
        tmds            => lvds_data,
        tmds_clock      => lvds_clock
    );

end architecture;