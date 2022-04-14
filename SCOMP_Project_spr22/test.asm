	ORG 0

	OUT MODE_AUTO_EN

Loop:
	LOADI 0
	OUT		PXL_A
	LOAD  Red
    OUT    PXL_D
	LOAD  Green
    OUT    PXL_D
	LOAD  Blue
    OUT    PXL_D


	
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mask1:     DW &B0000000001
Mask2:     DW &B0000000010
Mask3:     DW &B0000000100
Red:	   DW &B1000000000000000
Green:     DW &B1000000000
Blue:       DW &B0000010000
Zero:	   DW &B0000000000



PXL_A:     EQU &H0B0
PXL_D:     EQU &H0B1
MODE_16_EN: EQU &H0B5
MODE_AUTO_EN: EQU &H0B8