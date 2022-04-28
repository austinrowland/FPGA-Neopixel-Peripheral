ORG 0
	
;******************************************************************************************************************************************************
; Body: This is the main assembly loop that allows you to specify mode based on DE-10 switch input.
; This loop will reset all MODE_NAME_EN constants and then check switch input to jump to each mode.
; Only one switch at a time can be high, otherwise, priority is given to different modes in their sequential order of jump statements.
;******************************************************************************************************************************************************

Body: 
	;LOADI	0
	;OUT		MODE_16_EN
	;OUT		MODE_24_EN
	;OUT		MODE_ALL_EN
	;OUT		MODE_AUTO_EN
	
	IN     	Switches
    AND    	Mask1
    JPOS   	Test16
	
	IN     	Switches
    AND    	Mask2
    JPOS   	Test24
	
	IN     	Switches
    AND    	Mask3
    JPOS   	TestAll
	
	IN     	Switches
    AND    	Mask4
    JPOS   	TestAuto
	
	IN     	Switches
    AND    	Mask5
    JPOS   	TestFade
	
	IN		Switches
	AND		Mask6
	JPOS	TestGrad
	
	IN		Switches
	AND		Mask7
	JPOS	TestFlow
	
	JUMP   	Body
	
;******************************************************************************************************************************************************
; ClearAll: Clears all pixels on the Neopixel strip by setting color to black.
;******************************************************************************************************************************************************
ClearAll: 
	LOADI   1
	OUT     MODE_ALL_EN
	LOAD    Zero
	OUT     PXL_D
	LOADI   0
	OUT     MODE_ALL_EN
	JUMP    Body
	
;******************************************************************************************************************************************************
; Test24: Tests the 24-bit color feature for setting any single pixel to a 24-bit color.
; Verifies functionality by setting 3 different pixels to 3 different colors
; Colors are set by sending 3 8-bit color vectors (R, G, B) to PXL_D, and the color is displayed when 3 color vectors are given.
;******************************************************************************************************************************************************
	
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
	LOADI   4
    OUT     PXL_A
	LOAD	Red1
	OUT 	PXL_D
	LOAD	Blue1
    OUT     PXL_D
	LOAD	Green1
	OUT 	PXL_D
	LOADI   6
    OUT     PXL_A
	LOAD	Red1
	OUT 	PXL_D
	LOAD	Blue1
    OUT     PXL_D
	LOAD	Green1
	OUT 	PXL_D
	
	IN     	Switches
    AND    	Mask2
	JZERO   ClearAll
	JUMP    Test24

;******************************************************************************************************************************************************
; TestAll: Tests the 16-bit all color feature for setting all pixel to a 16-bit color.
; Verifies all pixel functionality because no pixel address (PXL_A) is set, but a 16-bit color is set to all pixels with PXL_D.
;******************************************************************************************************************************************************

TestAll:
	LOADI   1
	OUT     MODE_ALL_EN
	
	LOAD	Red
	OUT 	PXL_D
	
	;IN     	Switches
    ;AND    	Mask3
    ;JPOS    TestAll
	;CALL    ClearAll
	;JUMP    Body
TurnOnAll:
	IN     	Switches
    AND    	Mask3
	JZERO   ClearAll
	JUMP    TurnOnAll
	
;******************************************************************************************************************************************************
; TestFade: Tests the 16-bit all color feature for setting all pixel to a 16-bit color.
; Verifies all pixel functionality because no pixel address (PXL_A) is set, but a 16-bit color is set to all pixels with PXL_D.
;******************************************************************************************************************************************************

TestFade:
    LOADI   1
    OUT     MODE_FADE_EN
	
    LOAD    Red
    OUT     PXL_D
	
TurnOnFade:
	IN     	Switches
    AND    	Mask5
	JZERO   ClearAll
	JUMP    TurnOnFade
	
;******************************************************************************************************************************************************
; Test16: Tests the 16-bit color feature for setting any single pixel to a 16-bit color.
; Verifies functionality by selecting different pixels with PXL_A, and setting them to different colors with PXL_D.
;******************************************************************************************************************************************************
	
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
	
	IN     	Switches
    AND    	Mask1
	JZERO   ClearAll
	JUMP    Test16

;******************************************************************************************************************************************************
; TestAuto: Tests the auto-increment features for pixel address incrementation
; Verfies auto-increment functionality works because a pixel address (PXL_A) is never set but the pixels increment anyways
; Will light up all the pixels on the Neopixel one-by-one.
;******************************************************************************************************************************************************

TestAuto:
	LOADI   1
	OUT     MODE_AUTO_EN

    LOAD	Red
	OUT 	PXL_D
	LOADI   3
	CALL 	DelayAC
	OUT 	PXL_D
	
	IN     	Switches
    AND    	Mask4
	JZERO   ClearAll
	JUMP    TestAuto

;******************************************************************************************************************************************************
; TestGrad: Each pixel’s RGB vector increments or decrements from the color in the assembly code
; Sets current pixel address’ data as updated color vector
; Sent to RAM write buffer to update the LED strips on each clock cycle
;******************************************************************************************************************************************************
	
TestGrad: 

	LOADI   1
	OUT 	MODE_GRAD_EN
	
	LOAD    Red
	OUT     PXL_D
	
	
Grady:
	IN     	Switches
    AND    	Mask6
	JZERO   ClearAll
	JUMP    TestGrad

;******************************************************************************************************************************************************
; TestFlow: RGB color vectors updated by current 16 bit color vector
; Color incremented/decremented based on current color
; Sent to RAM write buffer to update the LED strips on each clock cycle
;******************************************************************************************************************************************************
	
TestFlow:

	LOADI   1
	OUT 	MODE_FLOW_EN
	
	LOAD    Red1
	OUT     PXL_D
	
Flowy:
	IN     	Switches
    AND    	Mask7
	JZERO   ClearAll
	JUMP    TestFlow

	
	
;******************************************************************************************************************************************************
; DelayAC: Pause for some multiple of 0.1 seconds.
; Call this with the desired delay in AC.
; E.g. if AC is 10, this will delay for 10*0.1 = 1 second
;******************************************************************************************************************************************************

DelayAC:
	STORE  DelayTime   ; Save the desired delay
	OUT    Timer       ; Reset the timer
WaitingLoop:
	IN     Timer       ; Get the current timer value
	SUB    DelayTime
	JNEG   WaitingLoop ; Repeat until timer = delay value
	RETURN
DelayTime: DW 5

; Constant Values
Mask1:     DW &B0000000001
Mask2:     DW &B0000000010
Mask3:     DW &B0000000100
Mask4:     DW &B0000001000
Mask5:     DW &B0000010000
Mask6:     DW &B0000100000
Mask7:     DW &B0001000000

Red:       DW &B1000000000000000
Green:     DW &B1000000000
Blue:       DW &B0000010000
Red1:       DW &B00011101
Green1:     DW &B11001111
Blue1:      DW &B11101011
Zero:       DW &B0000000000

Pret1:		DW &B01010001
Pret2:		DW &B11010100
Pret3:		DW &B101001111011101111111101

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

PXL_A:        EQU &H0B0
PXL_D:        EQU &H0B1
MODE_16_EN:   EQU &H0B5
MODE_24_EN:   EQU &H0B6
MODE_ALL_EN:  EQU &H0B7
MODE_AUTO_EN: EQU &H0B8
MODE_FADE_EN: EQU &H0BC
MODE_FLOW_EN: EQU &H0BB
MODE_GRAD_EN: EQU &H0B9