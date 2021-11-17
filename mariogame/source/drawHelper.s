.section .text

//-----------------------------------------------------------
// DrawPixel(): draws a pixel on given coord **TA code
// Arguments:
// r0: x (in pixels)
// r1: y (in pixels)
// r2: color
// Returns nothing
//-----------------------------------------------------------
.globl DrawPixel
DrawPixel:
	push		{lr}

	offset	.req	r3

	// offset = (y * 1024) + x = x + (y << 10)
	add		offset,	r0, r1, lsl #10
	// offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)
	lsl		offset, #1

	// store the colour (half word) at framebuffer pointer + offset

	ldr		r0, =FrameBufferPointer
	ldr		r0, [r0]
	strh		r2, [r0, offset]

	pop		{pc}


//-----------------------------------------------------------
// DrawGrid(): draws image to screen **based off TA code
// Arguments:
// r0: addr of pic 
// r1: x coord (in grid 0-19)
// r2: y coord (in grid 0-19)
// Returns nothing
//-----------------------------------------------------------
.globl DrawGrid
DrawGrid:
	push 		{r4-r9,lr}
	lsl		r1, #5		//x grid coord * 32
	add		r4, r1, #192	//Start X position of your picture
	mov		r9, r4		//hold x value
	lsl		r2, #5		//y grid coord * 32
	add		r5, r2, #64	//Start Y position of your picture
	add		r6, r0, #8	//to get addr of picture
	ldr		r1, [r0]
	add		r7, r4, r1	//Width of your picture
	ldr		r1, [r0, #4]
	add		r8, r5, r1	//Height of your picture
drawGridLoop:
	mov		r0, r4		//passing x for ro which is used by the Draw pixel function 
	mov		r1, r5		//passing y for r1 which is used by the Draw pixel formula 
	
	ldrh		r2, [r6], #2	//setting pixel color by loading it from the data section. We load half word
	bl		DrawPixel
	add		r4, #1		//increment x position
	cmp		r4, r7		//compare with image width
	blt		drawGridLoop
	mov		r4, r9		//reset x
	add		r5, #1		//increment Y
	cmp		r5, r8		//compare y with image height
	blt		drawGridLoop
	pop    		{r4-r9, pc}

//-----------------------------------------------------------
// ClearBox(): draws colored box  **TA code
// Args:
// r0 (0=clear whole screen or 1=clear a smallbox)
// r1: color to be printed
// Returns nothing
//-----------------------------------------------------------
.globl ClearBox
ClearBox:
	push 		{r4-r9, lr}
	mov		r6, r1 		//save color
	cmp		r0, #0		//IF clearing small box
	beq		clrScrn
	ldr		r4, =352	//init x value
	ldr		r5, =256	//init y value
	ldr		r7, =672	//init width of screen
	ldr		r8, =480	//init height of the screen
	mov		r9, r4
	b		looping
clrScrn:				//ELSE
	mov		r4, #0		//init x value
	mov		r5, #0		//init y value
	ldr		r7, =1024	//init width of screen
	ldr		r8, =768	//init height of the screen
	mov		r9, r4
looping:
	mov		r0, r4		//Set x 
	mov		r1, r5		//Set y
	mov		r2, r6		//set pixel color 
	bl		DrawPixel
	add		r4, #1		//increment x by 1
	cmp		r4, r7		//compare with width
	blt		looping
	mov		r4, r9		//reset x
	add		r5, #1		//increment Y by 1
	cmp		r5, r8		//compare with height
	blt		looping
	
	pop 		{r4-r9, pc}	


//-----------------------------------------------------------
// DrawChar(): draws char to given (x,y) **Tutorial code
// Arguments:
// r0: character to write
// r1: x coord (in pixels)
// r2: y coord (in pixels)
// Returns nothing
//-----------------------------------------------------------
.globl DrawChar
DrawChar:
	push		{r4-r9, lr}

	chAdr	.req	r4
	px	.req	r5
	py	.req	r6
	row	.req	r7
	mask 	.req	r8

	ldr		chAdr,=font	// load the address of the font map
	add		chAdr,r0, lsl #4 // char address = font base + (char * 16)
	mov		py, r2		// init the Y coordinate (pixel coordinate)
	mov		r9 ,r1
charLoop$:
	mov		px,r9		// init the X coordinate
	mov		mask,#0x01	// set the bitmask to 1 in the LSB	
	ldrb		row,[chAdr], #1	// load the row byte, post increment chAdr

rowLoop$:
	tst		row,mask	// test row byte against the bitmask
	beq		noPixel$

	mov		r0,px
	mov		r1,py
	ldr		r2,=0xFFFF	// white
	bl		DrawPixel	// draw white pixel at (px, py)

noPixel$:
	add		px, #1		// increment x coordinate by 1
	lsl		mask, #1	// shift bitmask left by 1

	tst		mask,	#0x100	// test if the bitmask has shifted 8 times (test 9th bit)
	beq		rowLoop$

	add		py, #1		// increment y coordinate by 1

	tst		chAdr,	#0xF
	bne		charLoop$	// loop back to charLoop$, unless address evenly divisibly by 16 (ie: at the next char)

	.unreq	chAdr
	.unreq	px
	.unreq	py
	.unreq	row
	.unreq	mask

	pop		{r4-r9, pc}

//-----------------------------------------------------------
// DrawString(): draws r0 string to given (x,y) coord
// Arguments:
// r0: string address
// r1: x coord (in grid 0-19) 
// r2: y coord (in grid 0-19)
// Returns nothing
//-----------------------------------------------------------
.globl DrawString
DrawString:
	push		{r4-r6, lr}
	lsl		r1, #5		//x grid coord * 32
	add		r4, r1, #192	//Start X position 
	lsl		r2, #5		//y grid coord * 32
	add		r5, r2, #70	//Start Y position 
	mov		r6, r0
writeLoop:
	ldrb 		r0, [r6], #1	//ascii char to print
	cmp		r0, #0		//check if end of string
	beq		exitDrawString
	mov		r1, r4		//x pixel position
	mov		r2, r5		//y pixel position
	bl		DrawChar
	add		r4, #15		//increment space between letters
	b		writeLoop
exitDrawString:
	pop		{r4-r6, pc}

//-----------------------------------------------------------
// ToAscii(): Draws out the r0 number to (x,y) coord
// Arguments:	
// r0: decimal value 
// r1: x coord (in grid 0-19)
// r2: y coord (in grid 0-19)
// Returns nothing 
//-----------------------------------------------------------
.globl ToAscii
ToAscii:
	push		{r4-r8, lr}	//save registers
	mov		r4, r0		//value to print

	lsl		r1, #5		//x grid coord * 32
	add		r6, r1, #185	//Start X position 177
	lsl		r2, #5		//y grid coord * 32
	add		r7, r2, #70	//Start Y position 

	cmp		r4, #1000	//if >=1000
	movge		r5, #1000	//set placeholder as 1000
	movge		r8, #4		//set counter as 4
	bge		divLoop		//and jump to divLoop

	cmp		r4, #100	//if >=100
	movge		r5, #100	//set placeholder as 100
	movge		r8, #3		//set counter as 3
	bge		divLoop		//jump to divLoop

	cmp		r4, #10		//if >=10
	movge		r5, #10		//set placeholder as 10
	movge		r8, #2		//set counter as 2

	movlt		r5, #1		//else set placeholder as 1
	movlt		r8, #1		//set counter as 1

divLoop:
	udiv		r0, r4, r5	//r0=r4/r5
	mul		r1, r0, r5	//r1=r0 * r5
	sub		r4, r1		//r4=r4-r1
	
	add		r0, #48		//convert digit to ascii
	add		r6, #15 	
	mov		r1, r6		//set x coord
	mov		r2, r7		//set y coord
	bl		DrawChar
	
	sub		r8, r8, #1	//decrement counter
	mov		r0, #10	
	udiv		r5, r5, r0	//divide placeholder by 10
	cmp		r8, #0		//if counter != 0
	bne		divLoop
exitToAscii:
	pop		{r4-r8, pc}	//restore registers


.section .data
.align 2
font:		.incbin	"font.bin"
