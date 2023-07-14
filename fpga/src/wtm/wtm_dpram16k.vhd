-- ****************************************************************************
-- * 
-- *    Code by Denno Wiggle aka WTM for the FLEADiP Board, which is an 
-- *    add-on card for the Z80 Retro!
-- * 
-- *    Copyright (C) 2023 Denno Wiggle
-- *
-- *    This is an inferred 16kByte dual port ram for the f18a FPGA logic.
-- *    It has the capability to initialise the Ram from a text file that has
-- *    a one byte hex value per line.
-- * 
-- *    The Effinity tool has a bug that it will only infer 8Kx8 of memory 
-- *    otherwise it fails to synthesize with :
-- *    [EFX-0680 WARNING] .... has incompatible control signal RE ('vcc') 
-- *                            should also control WE.
-- *    [EFX-0683 WARNING] .... has incompatible control or address signals.
-- *
-- *    Splitting code into two 8K blocks on address bit 13 gives us 16K  
-- *    without the tool reporting an error.
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
use std.textio.all;

entity wtm_dpram16k is
    generic(
        data_width      : natural := 8;
        address_width   : natural := 14;
        ram_depth       : natural := 2**address_width;
        ram_file_name   : string := "init/16KRamZero.txt"
    );
    port (
        clock       : in  std_logic;
        write_en    : in  std_logic;
        address1    : in  std_logic_vector(address_width - 1 downto 0);
        address2    : in  std_logic_vector(address_width - 1 downto 0);
        data_in     : in  std_logic_vector(data_width - 1 downto 0);
        data1_out   : out std_logic_vector(data_width - 1 downto 0);
        data2_out   : out std_logic_vector(data_width - 1 downto 0)
    );

end wtm_dpram16k;

architecture rtl of wtm_dpram16k is
  
    type ram_type is array (ram_depth - 1 downto 0) of std_logic_vector(data_width - 1 downto 0);
  
    -- Function to initialise the Ram with hex values from a text file.
    -- Reguires one byte hex value per line in the text file.
    impure function init_ram_hex return ram_type is
        file text_file : text open read_mode is ram_file_name;
        variable text_line : line;
        variable ram_content : ram_type;
    begin
        for i in 0 to ram_depth - 1 loop
            if ram_file_name = "" then
                ram_content(i) := (others => '0');
            else 
                readline(text_file, text_line);
                hread(text_line, ram_content(i));
            end if;
        end loop;
  
        return ram_content;
    end function;
  
    -- Initialize RAM from hex values in ASCII file
    signal ram_memory : ram_type := init_ram_hex;
  
begin

    MEMORY_PROC : process(clock)
    begin
        if rising_edge(clock) then
            -- Splitting code into two 8K blocks on address bit 13  
            -- Ram interface 1
            if address1(13) = '0' then
                data1_out <= ram_memory(to_integer(unsigned(address1)));
                if write_en = '1' then
                    ram_memory(to_integer(unsigned(address1))) <= data_in;
                end if;
            else 
                data1_out <= ram_memory(to_integer(unsigned(address1)));
                if write_en = '1' then
                    ram_memory(to_integer(unsigned(address1))) <= data_in;
                end if;
            end if;

            -- Ram interface 2
            if address2(13) = '0' then
                data2_out <= ram_memory(to_integer(unsigned(address2)));
            else 
                data2_out <= ram_memory(to_integer(unsigned(address2)));
            end if;
                
        end if;
        
    end process;


end architecture;