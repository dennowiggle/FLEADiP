-- ****************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- *
-- *    Copyright (C) 2023 Denno Wiggle
-- *
-- *    -- Syncrhonize a reset signal to the clock domain and add a delay 
-- *       specified by the user as a parameter.
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

entity wtm_resetSyncDelay is
    generic(
        delay_in_us  : integer := 1250;
        clk_freq_hz  : integer := 10e6
    );
    port (
        clock       : in  std_ulogic;
        rst_n       : in  std_ulogic;
        rst_out_n   : out std_ulogic 
    );
end wtm_resetSyncDelay;

architecture rtl of wtm_resetSyncDelay is

    -- We must have a minium of 2 clock cyles to synchronize
    constant counter_max   : integer := MAXIMUM(2, delay_in_us * (clk_freq_hz / 1e6) );
    signal   counter       : integer range 0 to counter_max := 0;

begin

    SYNC_DELAY_PROC: process (rst_n, clock)
    begin
        if rst_n = '0' then
            rst_out_n <= '0';
            counter   <= 0;
        elsif rising_edge(clock) then
            if (counter < counter_max) then
                counter <= counter + 1;
            else
                rst_out_n <= '1';
            end if;
        end if;
    end process;


end architecture;
