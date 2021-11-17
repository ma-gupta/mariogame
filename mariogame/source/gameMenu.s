.section .text
//-----------------------------------------------------------
// GameMenuControl(): gets game menu input
// No arguments:
// Returns:
// r0: 0 (restart game) or 1 (exit game) or 2 (continue game)
//-----------------------------------------------------------
.globl GameMenuControl
GameMenuControl:
	push		{r4-r9, lr}

	bl		SetPauseOn	// sets pause flag

	mov		r4, #0		// Initialize prev button state 
	mov		r8, #0		// Initialize curr state (restart)
	ldr		r9, =0xFFF7	// Start pressed
	ldr		r5, =0xFEFF	// 'A'
	ldr		r6, =0xFFDF	// down arrow
	ldr		r7, =0xFFEF	// up arrow

	ldr		r0, =mushSel
	mov		r1, #7
	mov		r2, #8
	bl		DrawGrid	// draw menu selector on restart

getGameMenuInput:
	ldr		r0, =50000	// Arg: .1 second (long delay)
	bl		Wait

	bl		ReadSNES	// returns r0(button pressed)

	cmp		r4, r0		// else, if prev state == curr (so we dont print button being held down more than once)
	beq		getGameMenuInput		
	mov		r4, r0		// set curr button to prev

	cmp		r0, r9		// if start pressed
	beq		restoreGame	

	cmp		r0, r5		// if A was pressed
	beq		exitGameMenu
	
	cmp		r0, r6		// if down arrow was pressed
	bne		checkArrow
	cmp		r8, #0		// and prev state was restart
	moveq		r0, r8	
	bleq		GameSelector	// draw menu selector
	moveq		r8, #1		// save menu option
	b		getGameMenuInput

checkArrow:	
	cmp		r0, r7		// else if up arrow was pressed
	bne		getGameMenuInput
	cmp		r8, #1		// and prev state was quit
	moveq		r0, r8		
	bleq		GameSelector	// draw menu selector
	moveq		r8, #0		// save menu option
	b		getGameMenuInput 

restoreGame:	
	mov		r0, #1		
	ldr		r1, =0x5CBF
	bl		ClearBox	// erase menu screen 

	ldr		r0, =marioPos
	ldrb		r1, [r0] 	// get mario x value
	ldrb		r2, [r0, #1] 	// get mario y value

	ldr		r0, =marioR
	mov		r1, r4		// x coord
	mov		r2, r5		// y coord
	bl		DrawGrid	// redraw mario 
	
	moveq		r8, #2		// save menu option
	
exitGameMenu:
	bl		SetPauseOff	// set pause flag off
	mov 		r0, r8		// return option selected
	pop		{r4-r9, pc}

//-----------------------------------------------------------
// GameSelector(): moves the selector in game menu
// Arguments:
// r0: 0 (start prev selected) or 1 (quit prev selected)
// Returns nothing
//-----------------------------------------------------------
GameSelector:
	push 		{r4-r5, lr}
	cmp		r0, #0		// if start game selected set xy coord
	moveq		r4, #8		
	moveq		r5, #10		
	movne		r4, #10		// else is quit selected, swap
	movne		r5, #8		

	ldr		r0, =black	
	mov		r1, #7
	mov		r2, r4
	bl		DrawGrid	// draw a black box to old menu option
	ldr		r0, =mushSel
	mov		r1, #7
	mov		r2, r5
	bl		DrawGrid	// draw menu selector to new menu option

	pop    		{r4-r5, pc}

//-----------------------------------------------------------
// DrawGameMenu(): Draws the Game Menu Screen
// No Arguments
// No Returns
//-----------------------------------------------------------
.globl DrawGameMenu
DrawGameMenu:
	push 		{r4-r5, lr}

	bl		DrawBorderedBox	// draw menu box with border

	ldr		r0, =startString 
	mov		r1, #8
	mov		r2, #8
	bl		DrawString	// draw restart string

	ldr		r0, =quitString
	mov		r1, #8
	mov		r2, #10
	bl		DrawString	// draw quit string

	pop		{r4-r5, pc}

//-----------------------------------------------------------
// DrawBorderedBox(): draws black box with red border
// No Args
// Returns nothing
//-----------------------------------------------------------
DrawBorderedBox:
	push 		{r4-r9, lr}

	mov		r4, #352	// init x value 
	mov		r5, #256	// init y value
	ldr		r7, =672	// init width of screen
	ldr		r8, =480	// init height of the screen

boxLoop:
	mov		r0, r4		// Set x 
	mov		r1, r5		// Set y

	mov		r2, #0		// set black as default color
					// set to red if within 10 pixels of edge of box 
	ldr		r9, =362
	cmp		r4, r9		
	movle		r2, #0xF800	
	ldr		r9, =662
	cmp		r4, r9
	movge		r2, #0xF800
	ldr		r9, =266
	cmp		r5, r9
	movle		r2, #0xF800
	ldr		r9, =470
	cmp		r5, r9
	movge		r2, #0xF800

	bl		DrawPixel
	add		r4, #1		// increment x by 1
	cmp		r4, r7		// compare with width
	blt		boxLoop
	mov		r4, #352	// reset x
	add		r5, #1		// increment Y by 1
	cmp		r5, r8		// compare with height
	blt		boxLoop
	pop 		{r4-r9, pc}	


.section .data
.align 2
.globl startString
startString:
.asciz "RESTART GAME"
.globl quitString
quitString:
.asciz "QUIT GAME"
