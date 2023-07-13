# FLEADiP
FLEADiP is a compatiable add-on board for the Z80 Retro! project

## Description
This project is an FPGA Logic Engine And Display Processor add-on board that fits the form factor of the [Z80 Retro! project by John Winans](https://github.com/Z80-Retro).

## Top View

## Bottom View


## FLEADiP Board Rev 0.0 Releaae Notes

1. The 'info' directory contains the BOM, netlist, and PDF schematic.

2. Board design used KiCad 7.0.2

3. The HDMI connector is on the bottom of the board so that there is no P/N signal swap, at least for rev 0 PCB. This means 
   the card doesn't fit right above the Z80 Retro! CPU board unless a spacer board is added. The board was designed with the 
   intent to use the ESP32 programmer board underneath FLEADiP which does have space for the connector.
   
   A future spin could move it to the top, with swapping all P/N traces. This may work right away with no hdl code change, 
   but if it does not the logic should be inverted in the HDL code to address this.
   
4. The silkscreen circle pin 1 marker for SW301 16pin config switch is in the wrong position. The copper layout is fine, 
   - pin 1 is in the oppostite corner to that marked - top right as viewed from the front board edge.

5. J503 2x5 right-angle programming connector should be installed on the top side of the board (silkscreen on back side).

6. To program an image to the FPGA FLASH you can use a FT232H module with the Efinity FPGA SW tool programmer. 
   - I tested a $12 one from Amazon  https://www.amazon.com/dp/B09XTF7C1P:
   Pin connections are as follows:
   
              FT232H     PLEADiP J503
  SPI_CLK       AD0         J503.8
  SPI_MOSI      AD1         J503.2
  SPI_MISO      AD2         J503.10
  SPI_CS_N      AD3         J503.4
  MOUSE_RESET_N AD4         J503.6
  MOUSE_CDONE   AD5         J503.5
  GND     Board Specific    J503.9
  
  - Efinity Programmer tool settings
    - With FT232H USB target should be USB <-> Serial Convertor
    - Active mode
    - Starting address 0x0
    - check erase before programming
    - Check verify after programming
    - Uses a hex file image
  
7. The board can also be programmed with the ESP32 Programmer and WiFi Z80 Retro! add on board.

8. 1x2 pin headers that supply 5V if a jumper is installed on the joystick ports should be no stuff for normal operation.
   - If you want to supply 5V on DB9 pin 5 then soldering a wire is preferred as clearances of 1x2 to 2x5 are tight for 
     DB9 cables made with IDC headers and 2 pin headers with jumpers installed.
     
   - To use a 2x5 cable with 1x2 jumpers installed use a 2x5 to DB9 cable with a narrow 2x5 receptacle. 
   - J301, J305 = no stuff for normal use.

9. The second Joystick port uses a 10 pin header J303 and is designed for a 10pin header to female DB9 cable with a gender 
   changer added. That way it's just using another Z80 Retro! console cable with addition of DB9 gender changer rather than 
   a totally new cable.
   - To use a 2x5 header to male DB9 cable the wires on the header need to swap pin columns.
     This method was tested with cable https://www.amazon.com/dp/B0BGQ96LX5

10. Joystick fire/button 2 and 5V options are wired per MSX joystick. 
     - Do not plug another type of 2 button joystick such as for C64 or Atari 
       especially if 5V is expected on a pin other than pin 5.
     - One button Atari 2600 compatible joysticks are supported.


