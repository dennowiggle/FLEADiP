
# Files to initialiase the 16K video ram

1. 16KRamInitF18aScreen.txt is a text file with 16,384 hex byte values extracted from the original [f18a 16k ram source file](../src/f18a/f18a_single_port_ram.vhd).
   - to use this file the VHDL source code should be changed so that the default background is white, and text is black. This is set by VDP register 7.

2. 16KRamZero.txt is a text file with 16,384 hex byte values all set to zero.