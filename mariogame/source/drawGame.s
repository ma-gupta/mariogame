.section .text
//-----------------------------------------------------------
// DrawStage(): draws game map
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl DrawStage
DrawStage:
	push 		{r4-r7, lr}
	bl		SetPauseOn		//set pause flag on
	mov		r0, #0			//arg: 0 (clear whole screen)
	mov		r1, #0			//arg: 0 (black)
	bl		ClearBox			
	mov		r4, #0			//initialize registers
	mov 		r5, #0
	mov 		r6, #0
	mov		r7, #0

loadBg:
	ldr		r0, =currState		//load curr map state pointer
	ldr		r0, [r0]
	ldrb		r1, [r0, r7]		//load value from arrray
	add		r7, #1			//increment array offset by 1

	cmp		r1, #1			//if array pos==1
	ldreq		r0, =ground		//set arg: ground image
	beq		print

	cmp		r1, #2			//if array pos==2
	ldreq		r0, =coinBlock		//set arg: coin block image
	beq		print
	
	cmp		r1, #3			//if array pos==3
	ldreq		r0, =block		//set arg: block image
	beq		print

	cmp		r1, #4			//if array pos==4
	ldreq		r0, =brick		//set arg: brick image
	beq		print

	cmp		r1, #5			//if array pos==5
	beq		printPipe			

	cmp		r1, #6			//if array pos==6
	beq		printFlag			

	ldr		r0, =sky		//else load arg: sky image
	b		print

printPipe:
	ldr		r0, =pipe		//load arg: pipe image
	add		r4, r1				
	cmp		r4, #5				
	bgt		skipPrint			
	b		print			//only print pipe once
printFlag:
	ldr		r0, =flag		//load arg: flag image
	add		r4, r1
	cmp		r4, #6
	bgt		skipPrint		//only print flag once
print:
	mov		r1, r5			//set x coord
	mov		r2, r6			//set y coord
	bl		DrawGrid
skipPrint:
	add		r5, #1			//increment x pos
	cmp		r5, #20			//if x=20
	moveq		r5, #0			//reset x=0
	addeq		r6, #1			//and increment y by 1
	cmp		r7, #400		//if array offset<400 continue
	blt		loadBg

	ldr		r0, =scoreLabel		//arg: score label image
	mov		r1, #2			//arg: x coord
	mov		r2, #0			//arg: y coord
	bl		DrawGrid

	ldr		r0, =score
	ldr 		r0, [r0]		//arg: current point score 
	mov		r1, #2			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		ToAscii

	ldr		r0, =coinLabel		//arg: coin label image
	mov		r1, #6			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		DrawGrid

	ldr		r0, =coins
	ldrb 		r0, [r0]		//arg: current coin count
	mov		r1, #7			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		ToAscii

	ldr		r0, =lifeLabel		//arg: life label image
	mov		r1, #13			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		DrawGrid

	ldr		r0, =lives
	ldrb 		r0, [r0]		//arg: current life count
	mov		r1, #17			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		ToAscii

	ldr		r0, =cloud		//arg: cloud image
	mov		r1, #5			//arg: x coord
	mov		r2, #4			//arg: y coord
	bl		DrawGrid
	
	ldr		r0, =cloud		//arg: cloud image
	mov		r1, #15			//arg: x coord
	mov		r2, #3			//arg: y coord
	bl		DrawGrid	
	bl		SetPauseOff

	pop		{r4-r7, pc}

//-----------------------------------------------------------
// InitGame(): initializes game variables and draws to screen
// No Arguments
// Returns nothing
//-----------------------------------------------------------
.globl InitGame
InitGame:
	push 		{lr}

	ldr		r0, =gameMap1		// reset coin/wood blocks in gamemap1
	mov		r1, #2
	strb		r1, [r0, #288]!
	strb		r1, [r0, #4]!
	mov		r2, #4
	strb		r2, [r0, #1]!
	strb		r1, [r0, #1]!
	strb		r2, [r0, #1]!

	ldr		r0, =gameMap2		//reset coin/wood blocks in gamemap2
	mov		r1, #2
	strb		r1, [r0, #258]
	mov		r1, #4
	strb		r1, [r0, #296]
	strb		r1, [r0, #297]

	ldr		r0, =gameMap3		//reset coin/wood blocks in gamemap3
	mov		r1, #2
	strb		r1, [r0, #182]
	strb		r1, [r0, #217]
	mov		r1, #4
	strb		r1, [r0, #262]

	mov		r2, #0			//reset array (if enemy exists)
	mov		r3, #0
	ldr		r0, =gameMap1
clearArray:
	ldrb		r1, [r0, r2]		//read whats stored in array pos
	cmp		r1, #7			//if value <7 ignore
	blt		skipStore
	strb		r3, [r0, r2]		//else store a 0 in the array pos
skipStore:
	add		r2, #1			//increment array index
	cmp		r2, #1600		//if index<=1600 continue
	bne		clearArray

	ldr		r0, =marioPos		
	mov 		r1, #0			
	strb		r1, [r0], #1		//reset mario x 
	mov 		r1, #17
	strb		r1, [r0], #1		//reset mario y 

	mov 		r1, #8
	strb		r1, [r0], #1		//reset goomba x
	mov 		r1, #17
	strb		r1, [r0], #1		//reset goomba y
	mov 		r1, #1
	strb		r1, [r0], #1		//reset goomba direction

	mov 		r1, #11
	strb		r1, [r0], #1		//reset koopa x
	mov 		r1, #17
	strb		r1, [r0], #1		//reset koopa y
	mov 		r1, #1
	strb		r1, [r0], #1		//reset koopa  direction

	mov 		r1, #21
	ldr		r0, =mushroom
	strb		r1, [r0]		//reset value pack mushroom

	ldr		r0, =currState		
	ldr		r1, =gameMap1
	str		r1, [r0]		//update screen to level 1	
	bl		DrawStage

	ldr		r0, =marioR
	ldr		r2, =marioPos
	ldrb		r1, [r2] 		// curr x value
	ldrb		r2, [r2, #1] 		// curr y value
	bl		DrawGrid		// draws mario 

	pop		{pc}



//-----------------------------------------------------------
// ResetCounts(): resets scores/lives/coins/ win/lose condition
// No Arg
// No Return
//-----------------------------------------------------------
.globl ResetCounts
ResetCounts:
	push		{lr}
	ldr		r0, =winCond
	
	mov 		r1, #0
	strb		r1, [r0], #1		//reset win condition to 0

	strb		r1, [r0], #1		//reset lose condition to 0

	mov		r1, #3
	strb		r1, [r0], #1 		//reset lives to 3

	mov		r1, #0
	strb		r1, [r0], #1 		//reset coins to 0

	str		r1, [r0]		//reset score to 0
	pop		{pc}


//-----------------------------------------------------------
// DrawMario(): draws mario and updates coord
// Arg: r0 (image address), r1 (new x coord), r2 ( new y coord)
// No Return
//-----------------------------------------------------------
.globl DrawMario
DrawMario:
	push		{r4-r7, lr}
	mov		r7, r0
	mov		r4, r1
	mov		r5, r2
	
	ldr		r6, =marioPos

	ldr		r0, =50000
	bl		Wait

	ldr		r0, =sky		//arg: sky image
	ldrb		r1, [r6]		//arg: old mario x coord
	ldrb		r2, [r6, #1]		//arg: old mario y coord
	bl		DrawGrid		

	mov		r0, r7			//arg: image passed in
	mov		r1, r4			//arg: new mario x coord
	mov		r2, r5			//arg: new mario y coord
	bl		DrawGrid

	strb		r4, [r6]		//store new x coord
	strb		r5, [r6, #1]		//store new y coord
	pop		{r4-r7, pc}

//-----------------------------------------------------------
// MarioDead(): draws mario dying
// Arg: r0 (x), r1 (y)
// No Return
//-----------------------------------------------------------
.globl MarioDead
MarioDead:
	push		{r4-r6,lr}
	mov 		r4, r0			//x coord
	mov		r5, r1			//y coord

	ldr		r0, =marioD		//arg: image
	mov		r1, r4			//arg: x coord
	sub		r2, r5, #1		//arg: y coord
	bl		DrawGrid		

	ldr		r0, =100000
	bl		Wait			//long delay

	ldr		r0, =sky		//arg: image
	mov		r1, r4			//arg: x coord
	sub		r2, r5, #1		//arg: y coord (lower 1 grid)
	bl		DrawGrid

	ldr		r6, =currState		//load curr map state pointer
	ldr		r6, [r6]

marioDeadDown:
	ldr		r0, =marioD		//arg: image
	mov		r1, r4			//arg: x coord
	mov		r2, r5			//arg: y coord
	bl		DrawGrid

	ldr		r0, =100000
	bl		Wait			//long delay

	add		r3, r4, r5, lsl #4	//calc offset	
	add		r3, r5, lsl #2		//for array position
	ldrb		r1, [r6, r3]		//load from array

	ldr		r0, =sky		//arg: sky iamge
	cmp		r1, #1			//but if array pos had 1
	ldreq		r0, =ground		//load image arg as ground
	mov		r1, r4			//arg: x coord
	mov		r2, r5			//arg: y coord
	bl		DrawGrid

	add		r5, #1			//increment y coord
	cmp		r5, #19			//if y<=19 (edge of game map)
	ble		marioDeadDown		

	pop		{r4-r6,pc}


//-----------------------------------------------------------
// GameOver(): draws win/lose screen - waits for input to exit
// No Arg
// No Return
//-----------------------------------------------------------
.globl GameOver
GameOver:
	push		{lr}
	ldr		r0, =winCond		//load win condition flag
	ldrb		r1, [r0]
	cmp		r1, #1			//if win flag was set
	ldreq		r0, =winLabel		//load arg as win screen

	ldrne		r0, =loseLabel		//else load arg as lose screen

	mov		r1, #3			//arg: x coord (in grid)
	mov		r2, #4			//arg: y coord (in grid)
	bl		DrawGrid		

continueWait:
	ldr		r0, =50000
	bl		Wait			//long delay
	bl		ReadSNES		//returns r0(button pressed)
	ldr		r1, =0xFFFF
	cmp		r0, r1			//if any button pressed
	beq		continueWait
	b		FirstMenu		//go to the FirstMenu	
	pop		{pc}

//-----------------------------------------------------------
// DrawUpdate(): draws update for either score/coins/life
// Arg:
// r0: value to print
// r1: x grid coord (0-19)
// r2: y grid coord (0-19)
// No Return
//-----------------------------------------------------------
.globl DrawUpdate
DrawUpdate:
	push		{r4-r7,lr}

	mov		r4, r0			//value to print
	mov		r5, r1			//x coord
	add		r7, r5, #1		//increment x coord
	mov		r6, r2			//y coord

	ldr		r0, =sky		//arg: image
	mov		r1, r5			//arg: x
	mov		r2, r6			//arg: y
	bl		DrawGrid		//redraw old score with sky

	ldr		r0, =sky		//arg: image
	mov		r1, r7			//arg: x
	mov		r2, r6			//arg: y
	bl		DrawGrid		//redraw old score with sky

	mov		r0, r4			//arg: value
	mov		r1, r5			//arg: x
	mov		r2, r6			//arg: y
	bl		ToAscii			//draw new value

	pop		{r4-r7,pc}

.section .data
.align 4
//below are the game map representations
// 0=sky, 1=ground, 2=coinblock, 3=block, 4=woodblock, 5=pipe, 6=flag, 7=mario, 8=goomba, 9=koopa
.globl gameMap1
gameMap1:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,2,0,0,0,2,4,2,4,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 
.globl gameMap2
gameMap2:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0,0,0,0,0
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 

.globl gameMap3
gameMap3:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,4,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,5,0,0
.byte 1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1 

.globl gameMap4
gameMap4:
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 

.globl currState	//game map pointer
currState:
.int gameMap1

.globl marioPos
marioPos:
.byte 0, 0 		//mario x pos, y pos (for 20x20 array)

.globl goombaPos
goombaPos:
.byte 0, 0, 0		//goomba x,y,direction(0 or 1)

.globl koopaPos		//koopa x,y,direction(0 or 1)
koopaPos:
.byte 0, 0, 0

.globl winCond		//win flag
winCond:
.byte 0

.globl loseCond		//lose flag
loseCond:
.byte 0

.globl lives		//life counter
lives:
.byte 0

.globl coins		//coin counter
coins:
.byte 0

.globl score		//point score counter
score: 
.int 0

.globl mushroom		//value pack x coord
mushroom:
.byte 21 

.globl pause		//game pause flag 
pause: 
.byte 0
