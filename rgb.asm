; Simple test for the NeoPixel peripheral

ORG 0
Loop:
    IN     Switches
	AND	   Mask1
	JPOS   Switch1
	LOADI 3
	OUT		PXL_A
	LOAD  Zero
    OUT    PXL_D
Con1:
	IN     Switches
	AND	   Mask2
	JPOS   Switch2
	LOADI 4
	OUT		PXL_A
	LOAD  Zero
    OUT    PXL_D
Con2:
	IN     Switches
	AND	   Mask3
	JPOS   Switch3
	LOADI 5
	OUT		PXL_A
	LOAD  Zero
    OUT    PXL_D

Switch1:
	LOADI 3
	OUT		PXL_A
	LOAD  Red
    OUT    PXL_D
	JUMP   Con1
Switch2:
	LOADI 4
	OUT		PXL_A
	LOAD  Green
    OUT    PXL_D
	JUMP   Con2
Switch3:
	LOADI 5
	OUT		PXL_A
	LOAD  Blue
    OUT    PXL_D
	JUMP   Loop


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