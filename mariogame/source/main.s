// ==============================================================
// Assignment 4 - CPSC359-T06
// By Choeney Nardechen (5008866) & Manisha Gupta (10170550) & Simone Mendonca (30006108)
//  
// This program implements a simple super mario game.
// ==============================================================

.section    .init
.globl     _start

_start:
    b       main
    
.section .text

main:	
	bl		InstallIntTable		//install interrupt table
	bl		EnableJTAG		//enable jtag
	bl		InitFrameBuffer		//initialize frame buffer
	bl		InitGPIO		//initialize GPIO lines
	bl		Enable			//enable irq lines
.globl FirstMenu
FirstMenu:
	bl		ResetCounts		//reset scores
	bl		DrawMainMenu		//draw main menu
	bl		MainMenuControl		//handle main menu input
	cmp		r0, #1			//if quit selected, exit
	beq		exit
.globl Restart
Restart:
	bl		ResetCounts		//reset scores
.globl Died
Died:
	bl		InitGame		//initialize and draw game map
	bl		SetPauseOff		//turn game pause off
	bl		PlayControl		//handle player input
	cmp		r0, #0			//if player selects restart game
	beq		Restart
	bne		FirstMenu		//else go back to first menu
exit:
	bl		SetPauseOn		//set pause flag on
	mov		r0, #0			//arg: whole screen
	mov		r1, #0			//arg: black color
	bl		ClearBox		//clear screen
.globl	haltLoop$
haltLoop$:
	b		haltLoop$

//-----------------------------------------------------------
// InstallsIntTable(): installs interrupt table  **tutorial code
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl InstallIntTable
InstallIntTable:
        push            {r0-r12, lr}   
	ldr		r0, =IntTable
	mov		r1, #0x00000000

	// load the first 8 words and store at the 0 address
	ldmia		r0!, {r2-r9}
	stmia		r1!, {r2-r9}

	// load the second 8 words and store at the next address
	ldmia		r0!, {r2-r9}
	stmia		r1!, {r2-r9}

	// switch to IRQ mode and set stack pointer
	mov		r0, #0xD2
	msr		cpsr_c, r0
	mov		sp, #0x8000

	// switch back to Supervisor mode, set the stack pointer
	mov		r0, #0xD3
	msr		cpsr_c, r0
	mov		sp, #0x8000000

	bx		lr	

//-----------------------------------------------------------
// Enable(): enables irq line n cpsr register and irq table **based off TA notes
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl	Enable
Enable:

        push            {r0-r12, lr}

	ldr		r0, =0x3F003004		
	ldr		r1, [r0]		//load current clock
	ldr		r2, =30000000		//load 30sec
	add		r1, r2			//add clock time and delay
	ldr		r0, =0x3F003010		
	str		r1, [r0]		//update clock timer compare 1

        ldr             r0, =0x3F00B210		
        mov             r1, #10
        str             r1, [r0]		//enable irq line 1&3

        ldr             r0, =0x3F00B214		
        mov             r1, #0
        str             r1, [r0]		//disable all other interrupts

        mrs		r0, cpsr		//get cpsr
	bic		r0, #0x80		//clear bit 3
	msr		cpsr_c, r0		//store result back

       pop            	{r0-r12, pc}

//-----------------------------------------------------------
// irq(): Handles irq interrupt **based off TA notes
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl irq
irq:    
        push            {r0-r12, lr}
        ldr		r0, =0x3F00B204		
	ldr		r1, [r0]		//check for interrupt
	tst		r1, #0x2		//if bit 1 not set
	beq		irqUpdate       	

	ldr		r0, =pause		
	ldrb		r1, [r0]		
	cmp		r1, #1			//and if game not paused
	blne		DrawValuePack		//draw value pack

	ldr             r0, =0x3F003000 	
	ldr		r2, =0x2
	str		r2, [r0]		//enable CS timer control		
        
irqUpdate: 
	ldr		r0, =0x3F00B204		
	ldr		r1, [r0]		//load interrupt
	mov		r2, #0x2
	bic		r1, r2			//clear bit 1
	str		r1, [r0]		//store cleared result
        bl	        Enable

irqEnd:
	pop		{r0-r12, lr}
	subs	        pc, lr, #4

//-----------------------------------------------------------
// RandomGenerator(): Generates a random number between 0-11
// ** based off wiki xorshift
// No Arguments
// Returns the random number
//-----------------------------------------------------------
RandomGenerator:
	push            {lr}
	ldr		r0, =0x3F003004		
	ldr		r1, [r0]		//load from clock

	lsl		r2, r1, #13		//r2 = r1 << 13
	eor		r3, r2, r1		//r3 = r2 eor r1

	lsr		r1, r3, #17		//r1 = r3 << 17
	eor		r3, r1			//r3 = r3 eor r1

	lsl		r1, r3, #5		//r1 = r3 << 5
	eor		r3, r1			//r3 = r3 eor r1

	mov		r0,#11			
	udiv		r2, r3, r0		//r2 = r3 / 11
	mul		r1, r2, r0		//r1= r2*11
	sub		r3, r1			//r3=r3-r1
	mov		r0, r3			//return r3 mod 11

	pop		{pc}

//-----------------------------------------------------------
// DrawValuePack(): draws the mushroom in a random x coord (0-11) 
// and static y coord 15
// No Arguments
// Returns nothing
//-----------------------------------------------------------
DrawValuePack:
	push            {lr}

	ldr 		r0, =mushroom		
	ldrb		r1, [r0]		//load x coord of mushroom
	cmp		r1, #21			//if ==21 (mushroom not on map)
	beq		drawNewValuePack

	ldr		r0, =sky		//else load arg: sky image
	mov		r2, #15			//arg: y coord
	bl		DrawGrid
	bl		ClearValuePack		//remove old value pack

drawNewValuePack:
	
	bl		RandomGenerator		
	mov		r1, r0			//save random number

	ldr		r0, =currState		
	ldr		r0, [r0]		//get curr map state pointer
	add		r3, r1, #300		//get array offset
	mov		r2, #10		
	strb		r2, [r0, r3]		//store '10' in array position 

	ldr		r0, =mushroom		
	strb		r1, [r0]		//store random x to mushroom x coord

        ldr		r0, =oneUp		//arg: value pack image
	mov		r2, #15			//y coord (always static)
	bl		DrawGrid		

	pop		{pc}


.section .data

.globl IntTable
IntTable:
	// Interrupt Vector Table (16 words)
	ldr		pc, reset_handler
	ldr		pc, undefined_handler
	ldr		pc, swi_handler
	ldr		pc, prefetch_handler
	ldr		pc, data_handler
	ldr		pc, unused_handler
	ldr		pc, irq_handler
	ldr		pc, fiq_handler

reset_handler:		.word InstallIntTable
undefined_handler:	.word haltLoop$
swi_handler:		.word haltLoop$
prefetch_handler:	.word haltLoop$
data_handler:		.word haltLoop$
unused_handler:		.word haltLoop$
irq_handler:		.word irq
fiq_handler:		.word haltLoop$
