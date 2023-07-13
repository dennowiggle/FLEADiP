-- ****************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- *
-- *    Copyright (C) 2023 Denno Wiggle
-- *
-- *    -- Synchronize a reset signal to the clock domain
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

entity wtm_resetSync is
    port (
        clock       : in  std_ulogic;
        rst_n       : in  std_ulogic;
        rst_out_n   : out std_ulogic 
    );
end wtm_resetSync;

architecture rtl of wtm_resetSync is
    -- Use a two flip-flop synchronizer
    signal reg : std_ulogic_vector(1 to 2); 
begin
    SYNC_PROC: process(rst_n, clock) is
    begin
        if rst_n = '0' then
            reg <= (others => '0');
        elsif rising_edge(clock) then
            reg <= '1' & reg(1 to reg'right-1);
        end if;
    end process;

    rst_out_n <= reg(reg'right);
end architecture;

