.section .text

//-----------------------------------------------------------
// MainMenuControl(): gets main menu input
// No arguments:
// Returns:
// r0: 0 (start game) or 1 (quits)
//-----------------------------------------------------------
.globl MainMenuControl
MainMenuControl:
	push		{r4-r8, lr}
	bl		SetPauseOn	// sets pause flag
	mov		r4, #0		// Initialize prev button state 
	mov		r8, #0		// curr state (start/quit)
	ldr		r5, =0xFEFF	// 'A'
	ldr		r6, =0xFFDF	// down arrow
	ldr		r7, =0xFFEF	// up arrow

	ldr		r0, =bullet	
	mov		r1, #5		// x coord
	mov		r2, #11		// y coord
	bl		DrawGrid	// draws menu selctor on start

getMainInput:
	ldr		r0, =50000	// Arg: .1 second (long delay)
	bl		Wait

	bl		ReadSNES	// returns r0(button pressed)

	cmp		r4, r0		// else, if prev state == curr (so we dont print button being held down more than once)
	beq		getMainInput		
	mov		r4, r0		// set curr button to prev

	cmp		r0, r5		// if A was pressed
	beq		exit
	
	cmp		r0, r6		// if down arrow was pressed
	bne		checkUp
	cmp		r8, #0		// and if curr state was start
	moveq		r0, r8
	bleq		MainSelector	// then draw change of menu selector
	moveq		r8, #1		// and save quit game as curr choice
	b		getMainInput

checkUp:	
	cmp		r0, r7		// if up arrow was pressed
	bne		getMainInput	
	cmp		r8, #1		// and if prev state was quit
	moveq		r0, r8		
	bleq		MainSelector	// then draw change of menu selector
	moveq		r8, #0		// and save start game as curr choice
	b		getMainInput
		
exit:
	mov 		r0, r8		// return menu option selected
	pop		{r4-r8, pc}

//-----------------------------------------------------------
// MainSelector(): moves the selector in main menu
// Arguments:
// r0: 0 (start prev selected) or 1 (quit prev selected)
// Returns nothing
//-----------------------------------------------------------
MainSelector:
	push 		{r4-r5, lr}
	cmp		r0, #0		// if start game selected, set xy coord
	moveq		r4, #11		
	moveq		r5, #13		
	movne		r4, #13		// else if quit sellected swap
	movne		r5, #11

	ldr		r0, =sky	
	mov		r1, #5		
	mov		r2, r4		
	bl		DrawGrid	// draw a black box to old menu option
	ldr		r0, =bullet	
	mov		r1, #5		
	mov		r2, r5		
	bl		DrawGrid	// draw menu selector to new menu option

	pop    		{r4-r5, pc}

//-----------------------------------------------------------
// DrawMainMenu(): Draws the Main Menu Screen
// No Arguments
// No Returns
//-----------------------------------------------------------
.globl DrawMainMenu
DrawMainMenu:
	push 		{lr}

	bl		DrawStage	

	ldr		r0, =creators	// string to write
	mov		r1, #2		// x coord
	mov		r2, #20		// y coord
	bl		DrawString

	ldr		r0, =title	// game title to print
	mov		r1, #2		// xcoord
	mov		r2, #2		// ycoord
	bl		DrawGrid

	ldr		r0, =label1	// start label to print
	mov		r1, #6		// xcoord
	mov		r2, #11		// ycoord
	bl		DrawGrid

	ldr		r0, =label2	// quit label to print
	mov		r1, #6		// xcoord
	mov		r2, #13		// ycoord
	bl		DrawGrid

	ldr		r0, =koopa	// koopa to print
	mov		r1, #2		// xcoord
	mov		r2, #17		// ycoord
	bl		DrawGrid

	ldr		r0, =marioR	// mario to print
	mov		r1, #5		// xcoord
	mov		r2, #17		// ycoord
	bl		DrawGrid

	ldr		r0, =goomba	// goomba to print
	mov		r1, #14		// xcoord
	mov		r2, #17		// ycoord
	bl		DrawGrid

	pop    		{pc}


.section .data
.align 2
.globl creators				// string to print
creators:
.asciz "BY: CHOENEY N, SIMONE M & MANISHA G"
