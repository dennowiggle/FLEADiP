# FLEADiP
FLEADiP is a compatiable add-on board for the Z80 Retro! project

## Description
This project is an FPGA Logic Engine And Display Processor add-on board that fits the form factor of the [Z80 Retro! project by John Winans](https://github.com/Z80-Retro).

It has VGA, HDMI, two Atari 2600 compatible joystick ports, and user I/O expansion pin headers. 

![FLEADiP Board Image](kicad/output/FLEADip_V0_3d_Angle.jpg "FPGA Logic Engine And Video Processor Board")

## Board design 
The board design is based around a Efinix Trion T20 FPGA in a QFP144 package. The HDMI output is driven by a PTN3366 IC that converts the LVDS from the FPGA into a true TMDS.

The VGA, HDMI, input header, and joystick ports are completely buffered to protect the FPGA. The user I/O port is unbuffered to give plenty of options for add-on creations.

The HDMI socket is on the back side of the board and allowance must be made for the type of board that is underneath. If there is not a good fit, a spacer board can be added.

## FPGA logic
The FPGA logic uses [Matthew Haggerty's F18A core](https://github.com/dnotq/f18a) so that code is compatible with the Z80 Retro! [2068-Z80-TMS9118 project board](https://github.com/Z80-Retro/2068-Z80-TMS9118). 

The HDMI logic uses the DVI code design from {Randi Rossi's VicII-Kawari project}(https://github.com/randyrossi/vicii-kawari).

The FPGA image is stored on a 4MByte W25Q32JVSS Flash memory. There is both a SPI and JTAG programming header on the right side of the board. The board may be programmed using an FT232H module with Efinity tools, or using another Z80 Retro! add on board, the - ESP32 Interface and Programmer with WiFi (link coming) which was designed to fit below this one (no HDMI connector fit concerns).

# Z80 I/O Port Addresses
0x50 FPGA adress register address
0x51 FPGA data registers (not all are writable) 
0x80 Video Display Processor
0x81 Video Display Processor
0xA8 Read Joystick 0 (Z80 Retro! legacy address)

# FPGA Registers
Full details listed [in the VHDL code](fpga/src/wtm/wtm_z80Interface.vhd)
Reg 0 - Version (R)
Reg 1 - Test Register (RW)
Reg 2 - PLL Lock      (R)
Reg 3 - Config switch (R)
Reg 4 - Joystick 0    (R)
Reg 5 - Joystick 1    (R)
Reg 6 - HDMI control  (RW)
Reg 7 - Interrupt 




