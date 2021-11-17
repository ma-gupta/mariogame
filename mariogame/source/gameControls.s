.section .text
//-----------------------------------------------------------
// PlayControl(): handles player input in game
// No arguments
// No Return
//-----------------------------------------------------------
.globl PlayControl
PlayControl:
	push		{r4-r8, lr}
	mov		r4, #0			// Initialize enemy counter
	ldr		r5, =0xFFF7		// Start pressed
	ldr		r6, =0xFF7F		// right arrow
	ldr		r7, =0xFFBF		// left arrow
	ldr		r8, =0xFFEF		// up arrow

getInput:
	add		r4, #1
	cmp		r4, #3
	blge		MoveEnemy		//move enemy every 3rd time loop occurs
	movge		r4, #0

	ldr		r0, =50000		// Arg: (long delay)
	bl		Wait

	bl		ReadSNES		// returns r0(button pressed)

	cmp		r0, r5			// if Start was pressed	
	bne		continueCheck
	bl		DrawGameMenu
	bl		GameMenuControl
	cmp		r0, #1
	ble		exitPlay

continueCheck:
	cmp		r0, r6			// if right arrow pressed
	bleq		MoveRight	

	cmp		r0, r7			// if left arrow pressed
	bleq		MoveLeft	

	cmp		r0, r8			// if up arrow was pressed
	bleq		MoveUp
	
	b		getInput	
exitPlay:
	pop		{r4-r8, pc}

//-----------------------------------------------------------
// MoveRight(): moves mario to the right if possible
// No arguments
// No Return
//-----------------------------------------------------------
.globl MoveRight
MoveRight:
	push		{r4-r7, lr}
	ldr		r2, =marioPos
	ldrb		r6, [r2] 		// curr x coord
	ldrb		r7, [r2, #1] 		// curr y coord
	add		r4, r6, #1		// new x coord
	mov		r5, r7			// new y coord

	cmp 		r4, #20			//IF new x ==20 (edge of screen)
	bne		skipReload
	mov		r0, r6			//arg: curr x coord
	mov		r1, r7			//arg: curr y coord
	bleq		UpdateState		//update game map
	ldr		r2, =marioPos		
	ldrb		r4, [r2]		//get new x coord
	ldrb		r5, [r2, #1]		//get new y coord		
skipReload:					
	mov 		r0, r4			//arg: new x
	mov		r1, r5			//arg: new y
	bl		ScanSide		//scan new xy coord for obstacles
	cmp		r0, #0			//if 0 not returned
	bne		exitRight		//cant move to new position, exit

	ldr		r0, =marioR		//arg: image addr
	mov		r1, r4			//arg: new x
	mov 		r2, r5			//arg: new y
	bl		DrawMario

	bl		Fall
	
exitRight:
	pop		{r4-r7, pc}


//-----------------------------------------------------------
// ScanSide(): checks if possible to move mario right
// Args: r0 (new x) r1: (new y)
// Returns: r0: 0(good move) or 1(not allowed)
//-----------------------------------------------------------
.globl ScanSide
ScanSide:
	push		{r4-r6, lr}
	mov		r4, r0			//new x coord
	mov		r5, r1			//new y coord
	ldr		r2, =currState
	ldr		r2, [r2]		//get curr game map pointer
	add		r3, r0, r5, lsl #4	
	add		r3, r5, lsl #2		//calc game array offset
	ldrb		r6, [r2, r3]		//access array at xy
	
	cmp		r6, #0			//if that xy coord is sky 
	moveq		r0, #0			//exit function and return 0 (good move)
	beq		exitScanSide
	
	cmp		r6, #10 		//if that xy coord is value pack
	bleq		IncreaseLives		//increment lives
	moveq		r0, #0			//exit function and return 0 (good move)
	beq		exitScanSide		

	cmp		r6, #6			//if xy coord is 6 (flag)
	bleq		UpdateWin		//update win flag

	cmp		r6, #8			//if xy coord <=8 
	movlt		r0, #1			//exit and return 1 bad move (either pipe/block)
	blt		exitScanSide
	mov		r0, r4			//else, must be enemy so arg: new x
	mov		r1, r5			//arg: new y
	bl		MarioDead		//animate mario death
	bl		RemoveLives		//decrement lives
	mov		r0, #1 			//return 1 (bad move)
	
exitScanSide:
	pop		{r4-r6, pc}


//-----------------------------------------------------------
// ScanBelow(): checks if possible to move mario lower
// Args: r0 (new x) r1: (new y)
// Returns: r0: 0(ground exists) or 1(move into that position)
//-----------------------------------------------------------
.globl ScanBelow
ScanBelow:
	push		{r4-r5, lr}

	cmp		r1, #18			//if y==18
	bne		notDead			
	bl		MarioDead		//animate mario death
	bl		RemoveLives		//decrement life
	mov		r0, #0			//return 0 
	b		exitScanBelow

notDead:
	ldr		r2, =currState		//else
	ldr		r2, [r2]		//get curr game map pointer
	add		r3, r0, r1, lsl #4		
	add		r3, r1, lsl #2
	add		r3, #20			//calc array offset
	ldrb		r4, [r2, r3]		//load whats in xy array position

	mov		r5, #1			//make return value 1 (good move)
	cmp		r4, #0			//if array xy coord == 0, exit
	beq		exitScanBelow
	cmp		r4, #10			//if array xy coord ==10
	bleq		IncreaseLives		//increase life
	beq		exitScanBelow		
	
	cmp		r4, #8			//else if array xy coord <8
	movlt		r5, #0			//return 0 (ground exists) pipe/blocks
	blt		exitScanBelow
	mov		r0, r4			//else, >=8, set arg: x coord
	bl		DestroyEnemy		//kill enemy since jumped from above
	
exitScanBelow:
	mov 		r0, r5
	pop		{r4-r5, pc}


//-----------------------------------------------------------
// ScanAbove(): checks if possible to move mario higher
// Args: r0 (new x) r1: (new y)
// Returns: r0: 0(ground exists) or 1(move into that position)
//-----------------------------------------------------------
.globl ScanAbove 
ScanAbove:
	push		{r4-r9, lr}
	
	mov		r4, r0			//x coord
	mov		r5, r1			//y coord
	ldr		r2, =currState
	ldr		r8, [r2]		//get curr game map pointer
	add		r9, r4, r5, lsl #4
	add		r9, r5, lsl #2
	sub		r9, #20			//get array offset
	ldrb		r6, [r8, r9]		//load whats in array at xy
	
	cmp		r6, #0			//if array xy ==0
	moveq		r7, #1			//exit function return 1 (good  move)
	beq		exitScanAbove
	
	cmp		r6, #10			//if array xy ==10 (value pack)
	bleq		IncreaseLives		//increase life
	moveq		r7, #1			//exit return 1 (good move)
	beq		exitScanAbove

	cmp		r6, #2			//if array xy ==2
	bne		wooden
	mov		r6, #3			
	strb		r6, [r8, r9]		//store 3 to the array (hit coin block, turns into reg block)
	
	mov		r1, r4			//arg: new x
	sub		r2, r5, #1		//arg: new y 
	ldr		r0, =block		//arg: bock image
	bl		DrawGrid
	bl		UpdateCoins		
	mov		r7, #0			//exit and reyurn 0 (ground exists)
	b		exitScanAbove

wooden:						//if array xy !=2
	mov		r7, #0			//set reyurn value as 0
	cmp		r6, #3			//if array xy ==3 (block), do nothing
	beq		exitScanAbove
	mov		r0, #50			//else must be wood block, set arg 50 points
	bl		UpdatePoints
	mov		r6, #0			
	strb		r6, [r8,r9]		//rewrite xy array position to 0

	mov		r1, r4			//arg: x
	sub		r2, r5, #1		//arg: y
	ldr		r0, =sky		//arg: sky image
	bl		DrawGrid

exitScanAbove:
	mov 		r0, r7
	pop		{r4-r9, pc}

//-----------------------------------------------------------
// MoveLeft(): moves mario to the left if possible
// No arguments
// No Return
//-----------------------------------------------------------
.globl MoveLeft
MoveLeft:
	push		{r4-r7, lr}
	ldr		r2, =marioPos
	ldrb		r6, [r2] 		// curr x value
	ldrb		r7, [r2, #1] 		// curr y value
	sub		r4, r6, #1		// new x pos 
	mov		r5, r7			// new y pos

	cmp 		r4, #0 			//if x <0
	bge		skipReload2
	mov		r0, r6			//arg: curr x
	mov		r1, r7			//arg: curr y
	bllt		UpdateState

	ldr		r2, =marioPos
	ldrb		r4, [r2]		//load new x
	ldrb		r5, [r2, #1]		//load new y

skipReload2:
	mov 		r0, r4			//arg: new x
	mov		r1, r5			//arg: new y
	bl		ScanSide		//check if it ok to move there	
	cmp		r0, #0			//if 1 (invalid)
	bne		exitLeft		
	ldr		r0, =marioL		//arg: image addr
	mov		r1, r4			//arg: new x
	mov 		r2, r5			//arg: new y
	bl		DrawMario

	bl		Fall

exitLeft:
	pop		{r4-r7, pc}		


//-----------------------------------------------------------
// MoveUp(): moves mario to jump up (5 squares) if possible
// No arguments
// No Return
//-----------------------------------------------------------
.globl MoveUp
MoveUp:
	push		{r4-r9, lr}

	ldr		r2, =marioPos
	ldrb		r6, [r2] 		// curr x value
	ldrb		r7, [r2, #1] 		// curr y value
	mov		r4, r6			// new x pos 
	sub		r5, r7, #1		// new y pos

	mov		r8, #0
	ldr		r9, =marioJumpR
upLoop:
	mov		r0, r4
	add		r1, r5, #1
	bl		ScanAbove
	cmp		r0, #1
	addne		r5, #1
	bne		startFall

	ldr		r0, =50000
	bl		Wait

	mov		r0, r9
	mov		r1, r4
	mov		r2, r5
	bl		DrawMario

	mov		r6, r4
	mov		r7, r5
	sub		r5, #1	

	bl		ReadSNES
	ldr		r3, =0xFF7F	//right
	cmp		r0, r3
	bne		leftJump
	ldr		r9, =marioJumpR
	add		r4, #1
	cmp		r4, #20
	blt		skipReload3
	b		updateMap
leftJump:
	ldr		r3, =0xFFBF	
	cmp		r0, r3			//if left button press
	bne		next
	ldr		r9, =marioJumpL		
	sub		r4, #1			//decrement x value
	cmp		r4, #0			//if x>=0, skip reload
	bge		skipReload3
	ldr		r2, =currState		
	ldr		r3, [r2]
	ldr		r2, =gameMap1
	cmp		r2, r3			//else  if curr map == game 1
	addeq		r4, #1
	beq		next			//jump to next2

updateMap:
	mov		r0, r6			//else, arg: curr x
	mov		r1, r5			//arg: new y
	bl		UpdateState		
	
	ldr		r2, =marioPos		
	ldrb		r4, [r2]		//get updated mario x
	ldrb		r5, [r2, #1]		//get updated mario y 
	b		next
	
skipReload3:	
	mov		r0, r4
	mov		r1, r5
	bl		ScanSide
	cmp		r0, #0
	movne		r4, r6

next:	add		r8, #1
	cmp		r8, #6
	blt		upLoop
startFall:
	bl		Fall
exitMoveUp:
	pop		{r4-r9, pc}

//-----------------------------------------------------------
// Fall(): draws mario's fall.
// No Arg:
// No Return
//-----------------------------------------------------------
Fall:
	push		{r4-r8, lr}
	bl		MoveEnemy

	ldr		r0, =marioPos
	ldrb		r4, [r0]
	ldrb		r5, [r0,#1]	
	ldr		r8, =marioJumpR

fallLoop:
	mov		r0, r4			//arg: curr x
	mov		r1, r5			//arg: curr y 
	bl		ScanBelow
	cmp		r0, #1			//if no ground beneath you
	moveq		r6, r4			//reset old x
	moveq		r7, r5			//reset old y
	addeq		r5, #1			//new y
	bne		exitFall		//else exit

	ldr		r0, =50000
	bl		Wait			//long delay

	bl		ReadSNES
	
	ldr		r3, =0xFF7F		
	cmp		r0, r3 			//if right button press
	bne		leftFall
	ldr		r8, =marioJumpR
	add		r4, #1			//increment x value
	cmp		r4, #20			//if x < 20 skip reload; 
	blt		skipReload5
	b		updateCurrMap		//else update the map
leftFall:
	ldr		r3, =0xFFBF	
	cmp		r0, r3			//if left button press
	bne		next2
	ldr		r8, =marioJumpL		
	sub		r4, #1			//decrement x value
	cmp		r4, #0			//if x>=0, skip reload
	bge		skipReload5
	ldr		r2, =currState		
	ldr		r3, [r2]
	ldr		r2, =gameMap1
	cmp		r2, r3			//else  if curr map == game 1
	addeq		r4, #1
	beq		next2			//jump to next2

updateCurrMap:
	mov		r0, r6			//else, arg: curr x
	mov		r1, r5			//arg: new y
	bl		UpdateState		
	
	ldr		r2, =marioPos		
	ldrb		r4, [r2]		//get updated mario x
	ldrb		r5, [r2, #1]		//get updated mario y 
	b		next2
	
skipReload5:	
	mov		r0, r4			//arg: new x
	mov		r1, r5			//arg: new y
	bl		ScanSide
	cmp		r0, #0			//if new space wasnt 0 (valid)
	movne		r4, r6
next2:	
	mov		r0, r8			//arg: image to print
	mov		r1, r4			//arg: x coord
	mov		r2, r5			//arg: y coord
	bl		DrawMario

	beq		fallLoop		//repeat
exitFall:
	pop		{r4-r8, pc}


//-----------------------------------------------------------
// UpdateState(): updates curr game map pointer and prints 
// new map when player attempts to move beyond the map.
// Arg:
// r0: new x
// r1: new y
// No Return
//-----------------------------------------------------------
.globl UpdateState
UpdateState:
	push		{r4-r8, lr}

	mov		r7, r0			//save x coord
	mov		r8, r1
	ldr		r6, =currState			
	ldr		r3, [r6]		//get current game map pointer
	ldr		r4, =gameMap1			

	cmp		r3, r4			//if current game map == game map 1
	bne		checkState2			
	cmp		r0, #19			//and if x == 19
	ldreq		r5, =gameMap2		//set curr game map pointer to game map 2
	beq		printUpdate	
	bne		exitUpdate

checkState2:
	ldr		r4, =gameMap2			
	cmp		r3, r4			//else if curr game map == game map 2
	bne		checkState3
	cmp		r0, #19				
	ldreq		r5, =gameMap3		//and x == 19 load game map 3
	ldrne		r5, =gameMap1		//and x !=19 load game map 1
	b		printUpdate

checkState3:
	ldr		r4, =gameMap3			
	cmp		r3, r4			//if curr game map == game map 3
	bne		checkState4
	cmp		r0, #19
	ldreq		r5, =gameMap4		//and x ==19 load game map 4
	ldrne		r5, =gameMap2		//and x !=19 load game map 2
	b		printUpdate

checkState4:					//else if curr game map == game map 4
	cmp		r0, #18			//and x ==18, win!
	bleq		UpdateWin			
	beq		exitUpdate
	ldrne		r5, =gameMap3		//else x!=18, load game map 3

printUpdate:
	bl		ClearValuePack		//clear value pack in curr game map

	str		r5, [r6]		//load new game map

	cmp		r7, #19
	moveq		r7, #0
	movne		r7, #19	
	ldr		r2, =marioPos
	strb		r7, [r2]		//store updated mario position
	strb		r8, [r2, #1]
	bl		DrawStage		//redraw new map
exitUpdate:
	pop		{r4-r8, pc}


//-----------------------------------------------------------
// IncreaseLives(): increases lives (from value pack) and draw 
// updated value to screen
// No Arg:
// No Return
//-----------------------------------------------------------
.globl IncreaseLives
IncreaseLives:
	push		{lr}
	bl		ClearValuePack		
	ldr		r1, =lives
	ldrb		r2, [r1]
	add		r2, #1			//increase life
	strb		r2, [r1]		//and save it
	
	mov		r0, r2			//arg: new life value
	mov		r1, #17			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		DrawUpdate		

	pop		{pc}

//-----------------------------------------------------------                       
// SetPauseOn(): sets pause flag on (so no value pack printed)                               
// No Arg:                                                                          
// No Return                                                                        
//----------------------------------------------------------- 
.globl SetPauseOn
SetPauseOn:
	push 		{lr}
	ldr		r0, =pause
	mov		r1, #1
	strb		r1, [r0]		//set pause flag on
	pop 		{pc}
	

//-----------------------------------------------------------                       
// SetPauseOff(): sets pause flag off                                              
// No Arg:                                                                          
// No Return                                                                        
//-----------------------------------------------------------                       
.globl SetPauseOff
SetPauseOff:     
        push            {lr}
        ldr		r0, =pause
        mov		r1, #0		
        strb            r1, [r0]		//set pause flag off
        pop             {pc}

	
//-----------------------------------------------------------
// ClearValuePack(): clears the value pack from array
// No Arg:
// No Return
//-----------------------------------------------------------
.globl ClearValuePack
ClearValuePack:
	push		{lr}
	ldr		r0, =mushroom		
	ldrb		r1, [r0]
	cmp		r1, #21			//if mushroom pos ==21
	beq		exitClearValuePack	

	ldr		r2, =currState		//else, get curr game map pointer
	ldr		r2, [r2]
	add		r3, r1, #300		//get array map offset for mushroom 
	mov		r1, #0
	strb		r1, [r2, r3]		//store 0 in the array

	mov		r1, #21
	strb		r1, [r0]		//store 0 for mushroom pos
exitClearValuePack:
	pop		{pc}

//-----------------------------------------------------------
// RemoveLives(): removes one life (and restarts game) or if 
// no more lives left, updates game lost.
// No Arg:
// No Return
//-----------------------------------------------------------
.globl RemoveLives
RemoveLives:
	push		{lr}

	ldr		r1, =lives
	ldrb		r2, [r1]
	sub		r2, #1			//decrement life counter
	strb		r2, [r1]		//and store it back

	cmp		r2, #0			//if life=0
	bleq		UpdateLose		//update lost flag
	bne		Died			//else load game for next life

	pop		{pc}

//-----------------------------------------------------------
// UpdatePoints(): updates score counter and prints to screen
// Arg:
// r0: points to increase
// No Return
//-----------------------------------------------------------
.globl UpdatePoints
UpdatePoints:
	push		{lr}
	ldr		r3, =score
	ldr		r2, [r3]
	add		r2, r0			//increment point counter
	str		r2, [r3]		//and store it back

	mov		r0, r2			//arg: value
	mov		r1, #2			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		DrawUpdate		

	pop		{pc}

//-----------------------------------------------------------
// UpdateCoins(): updates coin counter and prints to screen
// No Arg
// No Return
//-----------------------------------------------------------
.globl UpdateCoins
UpdateCoins:
	push		{lr}
	ldr		r1, =coins
	ldrb		r2, [r1]
	add		r2, #1			//increment coin count
	strb		r2, [r1]		//store it back

	mov		r0, r2			//arg: value
	mov		r1, #7			//arg: x coord
	mov		r2, #1			//arg: y coord
	bl		DrawUpdate		

	mov		r0, #100		//arg: 100 points to increment
	bl		UpdatePoints		

	pop		{pc}

//-----------------------------------------------------------
// DestroyEnemy(): clears enemy from array and updates points
// Arg:
// r0: 8 or 9 ( which enemy to destroy)
// No Return
//-----------------------------------------------------------
.globl DestroyEnemy
DestroyEnemy:
	push		{r4-r5, lr}

	cmp		r0, #9			//if 9 passed in
	ldreq		r2, =koopaPos		//load koopa
	ldrne		r2, =goombaPos		//else load goomba

	ldrb		r4, [r2]		//load enemy x coord
	ldrb		r5, [r2, #1]		//load enemy y coord

	mov		r0, #0
	strb		r0, [r2]		//reset x coord to 0
	strb		r0, [r2, #1]		//reset y coord to 0

	ldr		r2, =currState		
	ldr		r2, [r2]		//get current game map pointer
	add		r3, r4, r5, lsl #4	
	add		r3, r5, lsl #2		//get array offset
	mov		r0, #0
	strb		r0, [r2, r3]		//store 0 in the array position

	mov		r0, #100		//arg: 100 points
	bl		UpdatePoints		
	pop		{r4-r5, pc}

//-----------------------------------------------------------
// UpdateLose(): updates lose condition
// No Arg
// No Return
//-----------------------------------------------------------
.globl UpdateLose
UpdateLose:
	push		{lr}

	ldr		r0, =loseCond
	mov 		r1, #1
	strb		r1, [r0]		//sets game lost flag

	b		GameOver	

	pop		{pc}

//-----------------------------------------------------------
// UpdateWin(): updates win condition
// No Arg
// No Return
//-----------------------------------------------------------
.globl UpdateWin
UpdateWin:
	push		{lr}

	ldr		r0, =winCond
	mov 		r1, #1
	strb		r1, [r0]		//sets game won flag
	mov		r0, #400		//arg: 400 points
	bl		UpdatePoints		

	b		GameOver

	pop		{pc}

//-----------------------------------------------------------
// MoveEnemy(): moves an enemy in its loop
// No Arg
// No Return
//-----------------------------------------------------------
.globl MoveEnemy
MoveEnemy:
	push		{r4-r9, lr}

	ldr		r7, =currState
	ldr		r7, [r7]		
	ldr		r2, =gameMap2
	cmp		r7, r2			//if curr game == game map2, go to move goomba
	beq		moveGoomba
	ldr		r2, =gameMap3
	cmp		r7, r2			//else if curr game !=3 exit
	bne		exitMoveEnemy

moveKoopa:
	ldr		r4, =koopaPos		
	mov		r8, #9			//set koopa leftmost limit
	mov		r9, #15			//set koopa rightmost limit
	b		checkDead
moveGoomba:
	ldr		r4, =goombaPos
	mov		r8, #6			//set goomba leftmost limit
	mov		r9, #11			//set goomba rightmost limit

checkDead:
	ldr		r0, =marioPos		
	ldrb		r1, [r0]		//get mario x
	ldrb		r2, [r0, #1]		//get mario y

	ldrb		r5, [r4] 		//get enemy x
	ldrb		r0, [r4, #1]		//get enemy y
	ldrb		r6, [r4, #2]		//get move direction

	cmp		r0, #0			//if enemy is dead, exit
	beq		exitMoveEnemy

	cmp		r1, r5			//else, if mario x != enemy x; no collision		
	bne		noMarioCollision
	cmp		r2, #17			//or if mario y !=enemy y (17), no collision
	bne		noMarioCollision

	mov		r0, r5			//but if they were equal, set arg: x coord
	mov		r1, #17			//arg: y coord
	bl		MarioDead		//animate mario death
	bl		RemoveLives		//reduce mario life

noMarioCollision:				//move enemy
	mov		r1, r5			//arg: curr enemy x
	mov		r2, #17			//arg: curr enemy y
	ldr		r0, =sky		//arg: image addr
	bl		DrawGrid

	add		r3, r5, #340		//get array offfset
	mov		r0, #0
	strb		r0, [r7, r3]		//store 0 in array xy

	cmp		r5, r8			//if x == leftmost limit
	addeq		r3, #1			//increment array offset
	addeq		r5, #1			//increment x
	moveq		r6, #1			//change direction to 1
	beq		eMove

	cmp		r5, r9			//else if x == rightmost limit
	subeq		r3, #1			//decrement array offset
	subeq		r5, #1			//decrement x
	moveq		r6, #0			//change direction to 0 
	beq		eMove

	cmp		r6, #0			//else if direction ==0
	subeq		r3, #1			//decrement array offset and x
	subeq		r5, #1
	addne		r3, #1			//if direction ==1 increment array offset and x
	addne		r5, #1

eMove:	
	ldr		r0, =goombaPos		
	cmp		r4, r0			//if enemy was a goomba
	ldreq		r0, =goomba		//arg: load goomba image
	ldrne		r0, =koopa		//arg: else load koopa iamge

	moveq		r1, #8			//and move corresponding value 
	movne		r1, #9

	strb		r6, [r4, #2]		//update move direction
	strb		r5, [r4]		//update x value	
	strb		r1, [r7, r3]		//update new pos on array

	mov		r1, r5			//arg: x coord
	mov		r2, #17			//arg: y coord
	bl		DrawGrid

exitMoveEnemy:
	pop		{r4-r9, pc}

.section .data


