;****************************************************************************
;
;	 Copyright (C) 2021 John Winans
;
;	 This library is free software; you can redistribute it and/or
;	 modify it under the terms of the GNU Lesser General Public
;	 License as published by the Free Software Foundation; either
;	 version 2.1 of the License, or (at your option) any later version.
;
;	 This library is distributed in the hope that it will be useful,
;	 but WITHOUT ANY WARRANTY; without even the implied warranty of
;	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;	 Lesser General Public License for more details.
;
;	 You should have received a copy of the GNU Lesser General Public
;	 License along with this library; if not, write to the Free Software
;	 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
;	 USA
;
; https://github.com/johnwinans/2063-Z80-cpm
;
;****************************************************************************

;#############################################################################
; Dump BC bytes of memory from address in HL.
; if E is zero, no fancy formatting
; Does not clobber any registers
;#############################################################################
; BDOS:		equ	0x0005		; BDOS entry address (for system calls)
; CON_OUT:	equ	0x02		; Output a character to the console
; CON_STR:	equ	0x09		; Output a character to the console

BDOS:		equ	5		; BDOS entry address (for system calls)

CON_IN:		equ	1		; read character into A
CON_OUT:	equ	2		; Output a character to the console
CON_STR:	equ	9		; Output a string to the console

esp_reg:    equ 0xA4    ; IO Address of ESP32 WiFi & Programmer Board.
fdip_reg0:  equ 0x50    ; IO Address of the FLEADiP FPGA register 0.
fdip_reg1:  equ 0x51    ; IO Address of the FLEADiP FPGA register 1.
joy0_reg:   equ 0xA8    ; IO Address of the Legacy Joytick 0.
joy1_reg:   equ 0xA9    ; IO Address of the Legacy Joytick 1.
