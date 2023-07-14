;****************************************************************************
;
;    Test app to read and write from and to the FLEADiP board FPGA.
;
;    Copyright (C) 2023 Denno Wiggle
;
;    This library is free software; you can redistribute it and/or
;    modify it under the terms of the GNU Lesser General Public
;    License as published by the Free Software Foundation; either
;    version 2.1 of the License, or (at your option) any later version.
;
;    This library is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;    Lesser General Public License for more details.
;
;    You should have received a copy of the GNU Lesser General Public
;    License along with this library; if not, write to the Free Software
;    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
;    USA
;
;
;****************************************************************************

; Read the message byte from the ESP32 one time.

include 'memory.asm'

    org 0x100

    ld de,  .msg_buf          ; Print a WTM Welcome banner
    call .print_str

    ld de,  .msg_test         ; Print the test description
    call .print_str

    ; Read the Version Register status
    ld de,  .msg_buf_version     ; Print description of action
    call .print_str
    ld  a,  0                 ; Reg address to read = 1
    call .read_fpga_register

    call    .print_crlf

    ; Read FLEADiP Test Register
    ld de,  .msg_buf_testread  ; Print description of action
    call .print_str
    ld  a,  1                 ; Reg address to read = 1
    call .read_fpga_register

    ; Write FLEADiP register 1
    ld de,  .msg_buf_testwrite  ; Print description of action
    call .print_str
    ld  a,  (.dataByte)       ; Read the data to write from memory
    out (fdip_reg1), a        ; Output the message byte value to then ESP32 board
    call    .print_val_crlf   ; Write the hex value to the console

    ; Read FLEADiP register 0
    ld de,  .msg_buf_read0    ; Print description of action
    call .print_str
    in  a,  (fdip_reg0)       ; Read the data byte from register 0 on the the FLEADiP board
    call    .print_val_crlf   ; Write the hex value to the console

    ; Read FLEADiP Test Register
    ld de,  .msg_buf_testread  ; Print description of action
    call .print_str
    ld  a,  1                 ; Reg address to read = 1
    call .read_fpga_register

    call    .print_crlf

    ; Read the PLL Register status
    ld de,  .msg_buf_pll      ; Print description of action
    call .print_str
    ld  a,  2                 ; Reg address to write = 2
    call .read_fpga_register

    call    .print_crlf

    ; Read the Config Switch register
    ld de,  .msg_buf_config    ; Print description of action
    call .print_str
    ; Write FLEADiP register 0 with 03
    ld  a,  3                 ; Reg address to write = 3
    call .read_fpga_register

    call    .print_crlf

    ; Read joystick 0 register
    ld de,  .msg_buf_joy0     ; Print description of action
    call .print_str
    call    .print_crlf
    ld  a,  4                 ; Reg address to read = 4
    call .read_fpga_register

    call    .print_crlf

    ; Read joystick 1 register
    ld de,  .msg_buf_joy1     ; Print description of action
    call .print_str
    call    .print_crlf
    ld  a,  5                 ; Reg address to read = 5
    call .read_fpga_register

    call    .print_crlf

    ; Read the HDMI status
    ld de,  .msg_buf_hdmi     ; Print description of action
    call .print_str
    ld a,   6                 ; Reg address to read = 6
    call .read_fpga_register

    call    .print_crlf

    ; Read the Interrupt status
    ld de,  .msg_buf_int      ; Print description of action
    call .print_str
    ld a,   7                 ; Reg address to read = 6
    call .read_fpga_register

    call    .print_crlf

    ; Read Legacy joystick 0
    ld de,  .msg_buf_ljoy0    ; Print description of action
    call .print_str
    in  a,  (joy0_reg)        ; Read the data byte from register 0 on the the FLEADiP board
    call    .print_val_crlf   ; Write the hex value to the console

    ; Read Legacy joystick 1
    ld de,  .msg_buf_ljoy1    ; Print description of action
    call .print_str
    in  a,  (joy1_reg)        ; Read the data byte from register 0 on the the FLEADiP board
    call    .print_val_crlf   ; Write the hex value to the console

    ; Exit the program
    ret

.read_fpga_register:
    push    af                ; store the a value
    ld de,  .msg_buf_write0   ; Print description of action
    call .print_str
    pop     af                ; Retrieve the value from the a register
    out (fdip_reg0), a        ; Output the message byte value to then ESP32 board
    call    .print_val_crlf   ; Write the hex value to the console

    ; Read FLEADiP register 1
    ld de,  .msg_buf_read1    ; Print description of action
    call .print_str
    in  a,  (fdip_reg1)       ; Read the data byte from register 0 on the the FLEADiP board
    call    .print_val_crlf   ; Write the hex value to the console
    ret
    
.print_str:
    ld  c,  CON_STR
    call    BDOS
    ret
    
.print_val_crlf:
    call    hexdump_a       ; Write the hex value to the console
    call    .print_crlf     ; Print a new line
    ret

.print_crlf:
    ld  c, CON_OUT          ; Output LF to the console
    ld  e, 13
    call   BDOS
    ld  c, CON_OUT          ; Output CR to the console
    ld  e, 10
    call   BDOS
    ret

.dataByte:              ; store the value to write to the ESP message byte here
    db  0x55
.msg_buf:
    db  "#######################################\r\n"
    db  "  FLEADiP FPGA Test program by Wiggle\r\n"
    db  "#######################################\r\n\n$"
.msg_buf_read0:
    db  "Read Addr Register  50 : $"
.msg_buf_read1:
    db  "Read Data Register  51 : $"
.msg_buf_write0:
    db  "Write Addr Register 50 : $"
.msg_buf_write1:
    db  "Write Data Register 51 : $"
.msg_buf_joy0:
    db  "Read Joystick 0        : $"
.msg_buf_joy1:
    db  "Read Joystick 1        : $"
.msg_buf_ljoy0:
    db  "Read Legacy Joystick 0 : $"
.msg_buf_ljoy1:
    db  "Read Legacy Joystick 1 : $"
.msg_buf_pll:
    db  "Read PLL status        : \r\n$"
.msg_buf_config:
    db  "Read Config Switch     : \r\n$"
.msg_buf_version:
    db  "Read Version           : \r\n$"
.msg_buf_testread:
    db  "Read Test Reg          : \r\n$"
.msg_buf_testwrite:
    db  "Write Test Reg         : $"
.msg_buf_hdmi:
    db  "Read HDMI status       : \r\n$"
.msg_buf_int:
    db  "Read interrupt status  : \r\n$"
.msg_test:
    db  "Test read and write from and to FLEADiP : \r\n"
    db  "    IO address 0x50 = FLEADiP data address register\r\n"
    db  "    IO address 0x51 = FLEADiP data registers\r\n"
    db  "    IO address 0xA8 = FLEADiP legacy joystick 0\r\n"
    db  "    IO address 0xA9 = FLEADiP legacy joystick 1\r\n\n$"

include 'hexdump.asm'
