ORG 0
Start:
	;OUT     MODE_16_EN
	
	IN     Switches ; in switches again to check for second switch
    AND    Mask4
	;JZERO  ClearAll
    JPOS   Test24 ; jumps to 24-bit color test
	
	IN     Switches ; in switches again to check for second switch
    AND    Mask3
	;JZERO  ClearAll
    JPOS   TestAuto ; jumps to auto increment test
	
	IN     Switches ; in switches again to check for second switch
    AND    Mask2
	;JZERO  ClearAll
    JPOS   Test16 ; jumps to 16-bit color test
	
	IN     Switches ; in switches again to check for second switch
    AND    Mask1
    JPOS   TestAll ; jumps to all pixel test
	
	;JZERO  ClearAll
ClearAll:
	LOADI   1
	OUT     MODE_ALL_EN
	LOAD	Zero
	OUT 	PXL_D
	JUMP 	Start

TestAll:
	LOADI   1
	OUT     MODE_ALL_EN
	
	LOAD	Red
	OUT 	PXL_D
	IN      Switches
	JZERO	ClearAll
	JUMP 	Start

Test16:
	LOADI   1
	OUT     MODE_16_EN
	
	LOADI   1
	OUT 	PXL_A
	LOAD	Red1
	OUT 	PXL_D
	LOADI   4
	OUT 	PXL_A
	LOAD	Green1
	OUT		PXL_D
	LOADI   7
	OUT 	PXL_A
	LOAD	Red
	OUT		PXL_D
	
	IN      Switches
	JZERO	ClearAll
	JUMP 	Start

TestAuto:
	LOADI   1
	OUT     MODE_AUTO_EN

    LOAD	Red1
	OUT 	PXL_D
	LOADI 	5
	CALL 	DelayAC
	IN      Switches
	JZERO	ClearAll
	JUMP 	Start

Test24:
	LOADI   1
	OUT     MODE_24_EN
	
    LOADI   3
    OUT     PXL_A
    LOAD	Red
	OUT 	PXL_D
	LOAD	Blue
    OUT     PXL_D
	LOAD	Green
	OUT 	PXL_D
;	LOADI   4
;    OUT     PXL_A
;	LOAD	Red1
;	OUT 	PXL_D
;	LOAD	Blue1
;   OUT     PXL_D
;	LOAD	Green1
;	OUT 	PXL_D
;	LOADI   6
;    OUT     PXL_A
;	LOAD	Red1
;	OUT 	PXL_D
;	LOAD	Blue1
;    OUT     PXL_D
;	LOAD	Green1
;	OUT 	PXL_D
    IN      Switches
	JZERO	ClearAll
	JUMP    Start

DelayAC:
	STORE  DelayTime   ; Save the desired delay
	OUT    Timer       ; Reset the timer
WaitingLoop:
	IN     Timer       ; Get the current timer value
	SUB    DelayTime
	JNEG   WaitingLoop ; Repeat until timer = delay value
	RETURN
DelayTime: DW 5



; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Mask1:     DW &B0000000001
Mask2:     DW &B0000000010
Mask3:     DW &B0000000100
Mask4:     DW &B0000001000
Red:       DW &B1000000000000000
Green:     DW &B1000000000
Blue:       DW &B0000010000
Red1:       DW &B00011101
Green1:     DW &B11001111
Blue1:      DW &B11101011
Zero:       DW &B0000000000



PXL_A:    		EQU &H0B0
PXL_D:     		EQU &H0B1
MODE_16_EN: 	EQU &H0B5
MODE_24_EN: 	EQU &H0B6
MODE_ALL_EN: 	EQU &H0B7
MODE_AUTO_EN:	EQU &H0B8