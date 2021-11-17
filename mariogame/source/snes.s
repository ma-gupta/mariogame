.section .text

//-----------------------------------------------------------
// InitGPIO():Initializes SNES controller GPIO pins 9/10/11
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl InitGPIO
InitGPIO:
	push		{lr}	
setLine10:
	ldr 		r0, =0x3F200004 // addr for GPFSEL1
	ldr 		r1, [r0]	// r1= GPFSEL1 
	mov 		r2, #7 		// r2 = bitmask (b0111)
	bic 		r1, r2		//clear pin10 bits (input func)
	str 		r1, [r0] 	//write back to GPFSEL1

setLine11:
	ldr 		r1, [r0]	// r1= GPFSEL1 
	lsl 		r2, #3 		// shift bitmask to pin11
	bic 		r1, r2 		// clear pin11 bits
	mov		r3, #1		// output function
	lsl 		r3, #3 		// shift func code to pin11
	orr 		r1, r3 		// set pin function in r1
	str 		r1, [r0] 	// write back to GPFSEL1

setLine9:
	ldr 		r0, =0x3F200000 // addr for GPFSEL0
	ldr 		r1, [r0]	// r1 = GPFSEL0
	mov 		r2, #7 		// r2 = bitmask (b0111)
	lsl 		r2, #27 	// shift bitmask to pin9
	bic 		r1, r2 		// clear pin9 bits
	mov		r3, #1		// output function 
	lsl 		r3, #27 	// shift func code to pin9
	orr 		r1, r3 		// set pin function in r1
	str 		r1, [r0] 	// write back to GPFSEL0

	pop		{pc}

//-----------------------------------------------------------
// WriteLatch(): Writes a 1/0 to latch
// Arguments
// r0: bit to write (1 or 0)
// Returns nothing
//-----------------------------------------------------------
WriteLatch:
	push		{lr}		
        mov 		r1, #1		// bit mask
	ldr		r2, =0x3F200000	// base GPIO addr
        lsl		r1, #9		// 1 << 9 (latch line)
        teq             r0, #0		// if r0 == 0

	streq		r1, [r2, #40]	// write 1 GPCLR0
	strne		r1, [r2, #28]	// else, write 1 GPSET0
	pop		{pc}

//-----------------------------------------------------------
// ReadData(): Reads from data line 
// No arguments
// Returns: bit read from GPIO data line (1 or 0)
//-----------------------------------------------------------
ReadData:
	push		{lr}		
        mov 		r0, #1		// bit mask
	ldr		r2, =0x3F200000	// base GPIO address
        ldr		r1, [r2, #52]	// r1 = GPLEV0
	lsl		r0, #10		// 1 << 10 (data line)
	and		r1, r0		// r1=GPLEV0 AND bitmask
	teq		r1, #0		// if r1 == 0

	moveq		r0, #0		// return 0
	movne		r0, #1		// else, return 1
	pop		{pc}

//-----------------------------------------------------------
// WriteClock(): Writes a 1/0 on clock line
// Arguments
// r0: bit to write (1 or 0)
// Returns nothing
//-----------------------------------------------------------
WriteClock:
	push		{lr}		
        mov 		r1, #1		// bitmask
	ldr		r2, =0x3F200000	// base GPIO addr		
	lsl		r1, #11		// 1 << 11 (clock line)
        teq             r0, #0		// if r0 == 0

	streq		r1, [r2, #40]	// write 1 GPCLR0
	strne		r1, [r2, #28]	// else write 1 GPSET0
	pop		{pc}

//-----------------------------------------------------------
// Wait(): Waits the given time interval
// Arguments
// r0: time interval (in microseconds)
// Returns nothing
//-----------------------------------------------------------
.globl Wait
Wait:
	push		{lr}		
	ldr		r1, =0x3F003004 // CLO addr
	ldr		r2, [r1]	// read CLO
	add		r2, r0		// add time interval
waitLoop:
	ldr		r3, [r1]	// read CLO
	cmp		r2, r3		// if timeinterval > read
	bhi		waitLoop
	
	pop		{pc}

//-----------------------------------------------------------
// ReadSNES(): Reads buttons presses from SNES controller 
// No Arguments
// Returns:
// r0: 16 bit (button presses from SNES controller)
//-----------------------------------------------------------
.globl ReadSNES
ReadSNES:
	push		{r4, r5, lr}	// save registers
	mov		r4, #0		// set r4=0 (buttons)
	mov		r0, #1		// Arg: bit 1 to output
	bl		WriteClock	
	mov		r0, #1		// Arg: bit 1 to output
	bl		WriteLatch	
	mov		r0, #12		// Arg: 12 microseconds
	bl		Wait		
	mov		r0, #0		// Arg: bit 0 to output
	bl		WriteLatch	
	mov		r5, #0		// set r5=0 (i)
pulseLoop:
	mov		r0, #6		// Arg: 6 microseconds
	bl		Wait
	mov		r0, #0		// Arg: bit 0 to output
	bl		WriteClock
	mov		r0, #6		// Arg: 6 microseconds
	bl		Wait
	bl		ReadData	// returns r0 (a single button at bit i)	
	lsl		r0, r5		// shift single button to position i
	orr		r4, r0		// update buttons to incl button just read
	mov		r0, #1		// Arg: 1 microsecond
	bl		WriteClock

	add		r5, #1		// r5++ (increment i by 1)
	cmp		r5, #16		// if r5 < 16
	blt		pulseLoop	
	
	mov		r0, r4		// return 16 bit button presses
	pop		{r4,r5,pc}


.section .data 
