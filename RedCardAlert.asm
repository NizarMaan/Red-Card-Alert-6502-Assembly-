	processor 6502
SCREEN = $900f ;36879
PLOT	=	$fff0	;affects A, X, Y regs
SCNKEY	=	$ff9f	;scan for keyboard input
GETIN	=	$ffe4	;get input
CHROUT	=	$ffd2	;output char
INTERNAL_CLOCK	=	162
COLOR_MAP_BASE	=	$9600 ;38400
COLOR_MAP_2	=	$969a	;38554
COLOR_MAP_3	=	$9734	;38708
CHARLOC	=	$9005 ;36869
RAMLOC	=	$1c00 ;7168
RAMLOC2	=	$1cff 
RAMLOCLAST = $1dff
ROMLOC	=	$8000	;32768
ROMLOC2	=	$80ff	;33023
clearscreen	=	$93
RASTER	=	$9004
right	=	$1d
left	=	$9d
up		=	$91
down	=	$11
return	=	$d
;-------VARIABLES IN RAM------------------
xcord	=	$1a00	;row	x and y are inverted in my program
ycord	=	$1a01	;column
ONES	=	$1a02
TENS	=	$1a03
HUNDREDS	=	$1a04
ticktrack	=	$1a05
ballx	=	$1a06	;array of 10 balls, uses 19 memory locations
bally	=	$1a07
objectspeed	=	$1b00
nospeedup	=	$1b01
redcardhit	=	$1b02
yellowhitcount	=	$1dfa
redcardx	=	$1d10	;array of red cards, uses 5 mem locations
redcardy	=	$1d11
yellowcardx = $1d1c	;array of yellow cards from 7452 to 7465
yellowcardy	=	$1d1d

main:	.org   $1001 ;4097
		.byte $0c; start
		.byte $10
		.byte $10
		.byte $0a
		.byte $9e ;sys
		.byte $20 
		.byte $34 
		.byte $31 
		.byte $31 
		.byte $30 
		.byte $00 
		.byte $00 
		.byte $00
;----KNOWN BUGS----
;	-Gameobjects sometimes flash bluedue to slight delay between plotting/drawing and then recoloring
;	-Collisions are (rarely) missed
	lda	#93		;black background
	sta	SCREEN	
;---SPLASH SCREEN-----
	jsr	CLEARSCREEN
	clc
	ldx	#10
	ldy	#4
	jsr PLOT
	ldx	#0
printsplash:
	lda	splashtext,x
	jsr	CHROUT
	inx
	cpx	#14
	bne	printsplash
	clc
	ldx	#12
	ldy	#5
	jsr PLOT
	ldx	#14
printname:
	lda	splashtext,x
	jsr CHROUT
	inx
	cpx	#27
	bne	printname
	clc
	ldx	#3
	ldy	#2
	jsr	PLOT
splashwait:
	lda	INTERNAL_CLOCK
	cmp	#120	;display splash screen for 1.5 seconds
	bne	splashwait
	jmp	init
splashtext:
	.byte	"RED CARD ALERT"
	.byte	"BY NIZAR MAAN"
;--------------MOVING 64 CHARACTERS FROM ROM TO RAM---------------
init:
	lda	#28 ;making basic think it has 512 bytes less memory to work with
	sta	$34	;
	sta	$38	; 
	ldx	#0
loop1:	
	lda	ROMLOC,x
	sta	RAMLOC,x
	inx
	cpx	#255
	bne	loop1
	ldx	#0
loop2:
	lda	ROMLOC2,x
	sta	RAMLOC2,x
	inx
	cpx	#255
	bne	loop2
	lda	$81ff,x
	sta	RAMLOCLAST
	lda	#255
	sta	CHARLOC
;-----------------CUSTOMIZE CHARACTERS-------------------
	;create ball character by overwriting '+' location
	lda	#60
	sta	$1d58
	sta	$1d5f
	lda	#126
	sta	$1d5a
	sta	$1d59
	sta	$1d5d
	sta	$1d5e
	sta	$1d5b
	sta	$1d5c
	;create the player's ascii character by overwriting ']'
	lda	#56	
	sta	$1ce8	;7176
	sta	$1ce9
	sta	$1cea
	lda	#18
	sta	$1ceb
	lda	#126
	sta	$1cec
	lda	#80
	sta	$1ced
	lda	#28
	sta	$1cee
	lda	#36
	sta	$1cef
	lda	#60
	ldx	#0
overwritef:
	;create card by overwriting '@'
	sta	$1c00,x
	inx
	cpx	#8
	bne	overwritef
playagain:
;----------SETTING UP INITIAL ON-SCREEN VALUES---------------------	
	jsr	CLEARSCREEN
	lda	#48	;ascii value for 0/zero
	sta	ONES
	sta	TENS
	sta	HUNDREDS
	;--set up all ball coordinates in consecutive memory locations starting from address of ballx bally
	ldx	#0
printlabel:
	lda	scorelabel,x
	jsr	CHROUT
	inx
	cpx	#7
	bne	printlabel
	jsr	printscore
	;setup player character
	ldx	#18	;setup character coordinates
	ldy	#5
	stx	xcord
	sty	ycord
	jsr	movecursor
	jsr	printchar	;draw initial player character
	lda	#1	;white score
	ldx	#0	;counter
	jsr	colorscore
	clc
	ldx	#0
	ldy	#14
	jsr	PLOT
printlabel2:
	lda	hits,x
	jsr	CHROUT
	inx
	cpx	#5
	bne	printlabel2
	lda	#2	;red
	ldx	#14
	jsr	colorhitslabel
	;-------load ball coordinates and draw them--------
	ldx	#0
loadballsx:	
	stx	$1cfd	;temp store for x counter
	inx
	txa
	ldx	$1cfd
	sta	ballx,x
	inx
	inx
	cpx	#20
	bne	loadballsx
	ldx	#0
;hardcoding initial positions of balls
loadballsy:
	cpx	#0
	bne	ball1
	lda	#13
ball1:
	cpx	#2
	bne	ball2
	lda	#21
ball2:
	cpx	#4
	bne	ball3
	lda	#14
ball3:
	cpx	#6
	bne	ball4
	lda	#8
ball4:
	cpx	#8
	bne	ball5
	lda	#27
ball5:
	cpx	#10
	bne	ball6
	lda	#3
ball6:
	cpx	#12
	bne	ball7
	lda	#12
ball7:
	cpx	#14
	bne	ball8
	lda	#15
ball8:
	cpx	#16
	bne	ball9
	lda	#19
ball9:
	cpx	#18
	bne	sety
	lda	#24
sety:
	sta	bally,x
	inx
	inx
	cpx	#20
	bne loadballsy
	;------load red cards-----------
	ldx	#0
loadredcardsx:
	stx	$1cfd	;temp store for x counter
	inx
	txa
	ldx	$1cfd
	sta	redcardx,x
	inx
	inx
	cpx	#6
	bne	loadredcardsx
	ldx	#0
loadredcardsy:
	cpx	#0
	bne	rcard1
	lda	#7
rcard1:
	cpx	#2
	bne	rcard2
	lda	#18
rcard2:
	cpx	#4
	bne	setrcardy
	lda	#5
setrcardy:
	sta	redcardy,x
	inx
	inx
	cpx	#6
	bne loadredcardsy
	ldx	#0
	;------load yellowcards----------
	ldx	#0
loadyelcardsx:
	stx	$1cfd	;temp store for x counter
	inx
	txa
	ldx	$1cfd
	sta	yellowcardx,x
	inx
	inx
	cpx	#14
	bne	loadyelcardsx
	ldx	#0
loadyelcardsy:
	cpx	#0
	bne	card1
	lda	#11
card1:
	cpx	#2
	bne	card2
	lda	#20
card2:
	cpx	#4
	bne	card3
	lda	#10
card3:
	cpx	#6
	bne	card4
	lda	#15
card4:
	cpx	#8
	bne	card5
	lda	#19
card5:
	cpx	#10
	bne	card6
	lda	#6
card6:
	cpx	#12
	bne	setycardy
	lda	#1
setycardy:
	sta	yellowcardy,x
	inx
	inx
	cpx	#14
	bne loadyelcardsy
	ldx	#0
;----------------------------MAIN GAME LOOP-----------------------
	;initializing some values
	ldx	#0
	stx	nospeedup
	stx	ticktrack	;initialize game tick tracking
	stx	redcardhit
	stx	yellowhitcount	;initialize yellow card hit count to 0-255
	lda	#5
	sta	objectspeed
get:
	jsr	checkspeedup
	ldx	yellowhitcount
	cpx	#3
	beq	gameover
	jsr	movecursor
	jsr	printchar
	jsr	colorplayer
	lda	#0
	sta	INTERNAL_CLOCK
	jsr	gameticks
	lda	ticktrack
	cmp	#0		;for every 'objectspeed' (1-5) game ticks, move non-player game objects
	bne	nomoveobj
	jsr	moveballs
	jsr	moveycards
	jsr	movercards
	lda	objectspeed
	sta	ticktrack
nomoveobj:
	ldx	ticktrack
	dex
	stx	ticktrack
	jsr SCNKEY	;check for input
	jsr	GETIN	;get char
	ldx	xcord
	ldy	ycord
	cmp	#0	;check if null
	beq	getcont
	cmp	#up
	beq	moveup
	cmp	#down
	beq	movedown
	cmp	#left
	beq	moveleft
	cmp	#right
	beq	moveright
getcont:
	jsr	checkballcollision
	jsr	checkycardcollision
	jsr	checkredcardcollision
	lda	redcardhit
	cmp	#1
	beq	gameover
	jmp	get
gameover:
	jsr	CLEARSCREEN
	clc
	ldx	#10
	ldy	#6
	jsr PLOT
	ldx	#0
	jsr	printgameover
prompt:
	jsr SCNKEY	;check for input
	jsr	GETIN	;get char
	cmp	#0
	beq	prompt
	cmp	#81		;'Q' value
	beq	quit
	cmp	#return	;value for "enter" key
	bne	prompt
	jmp	playagain
quit:
	rts	;end program	
;-------------------------------------MOVE LOGIC-----------------------
moveup:
	cpx	#1
	beq	getcont
	jsr	clearchar
	dex
	stx	xcord
	jsr	movecursor
	jsr	printchar
	jmp	getcont
movedown:
	cpx	#22
	beq	getcont
	jsr	clearchar
	inx
	stx	xcord
	jsr	movecursor
	jsr	printchar
	jmp	getcont
moveleft:	
	cpy	#0
	beq	getcont
	jsr	clearchar
	ldy	ycord
	dey
	sty	ycord
	jsr	movecursor
	jsr	printchar
	jmp getcont
moveright:
	cpy	#20
	beq	goget	;have to branch to goget in this case because branching directly to get is out of reach
	jsr	clearchar
	ldy	ycord
	iny
	sty	ycord
	jsr	movecursor
	jsr	printchar
goget:
	jmp getcont
moveballs:
	ldx	#0
iterateballs:
	lda	ballx,x
	sta	$1cfe	;temp store for x cord
	inx
	lda	ballx,x
	stx	$1cfd	;temp store for x counter
	sta	$1cff	;temp store for y cord
	ldy	$1cff
	cpy	#0
	beq wrap
	ldy	$1cff
	dey
	sty	$1cff
	tya
	sta	ballx,x
	clc
	ldx	$1cfe
	ldy	$1cff
	jsr	PLOT
	jsr	drawball
	ldx	$1cfe
	ldy	$1cff
	lda	#1
	jsr	plotcolor
	ldy	$1cff
	iny
	clc
	ldx	$1cfe
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	inx
	cpx	#20
	bne	iterateballs
	rts
wrap:
	jsr	relocateball
	clc
	ldx	$1cfe	;stored x cord
	ldy	$1cff	;stored y cord
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	cpx	#19		;check if all balls have been iterated
	bne	finish_ball
	rts
finish_ball: ;loop back again to finish all ball movements
	inx
	jmp	iterateballs
moveycards:
	ldx	#0
iteratecards:
	lda	yellowcardx,x
	sta	$1cfe	;temp store for x cord
	inx
	lda	yellowcardx,x
	stx	$1cfd	;temp store for x counter
	sta	$1cff	;temp store for y cord
	ldy	$1cff
	cpy	#0
	beq wrapycard
	ldy	$1cff
	dey
	sty	$1cff
	tya
	sta	yellowcardx,x
	clc
	ldx	$1cfe
	ldy	$1cff
	jsr	PLOT
	jsr	drawcard
	ldx	$1cfe
	ldy	$1cff
	lda	#7
	jsr	plotcolor
	ldy	$1cff
	iny
	clc
	ldx	$1cfe
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	inx
	cpx	#14
	bne	iteratecards
	rts
wrapycard:
	jsr	relocateycard
	clc
	ldx	$1cfe	;stored x cord
	ldy	$1cff	;stored y cord
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	cpx	#13		
	bne	finish_ycard
	rts
finish_ycard:
	inx
	jmp	iteratecards
movercards:
	ldx	#0
iterateredcards:
	lda	redcardx,x
	sta	$1cfe	;temp store for x cord
	inx
	lda	redcardx,x
	stx	$1cfd	;temp store for x counter
	sta	$1cff	;temp store for y cord
	ldy	$1cff
	cpy	#0
	beq wraprcard
	ldy	$1cff
	dey
	sty	$1cff
	tya
	sta	redcardx,x
	clc
	ldx	$1cfe
	ldy	$1cff
	jsr	PLOT
	jsr	drawcard
	ldx	$1cfe
	ldy	$1cff
	lda	#2
	jsr	plotcolor
	ldy	$1cff
	iny
	clc
	ldx	$1cfe
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	inx
	cpx	#6
	bne	iterateredcards
	rts
wraprcard:
	jsr	relocateredcard
	clc
	ldx	$1cfe	;stored x cord
	ldy	$1cff	;stored y cord
	jsr	PLOT
	lda	emptychar
	jsr	CHROUT
	ldx	$1cfd
	cpx	#5		
	bne	finish_rcard
	rts
finish_rcard:
	inx
	jmp	iterateredcards
movecursor:
	clc
	ldx	xcord
	ldy	ycord
	jsr	PLOT	;set cursor cords to x and y register values (row, and column respectively)
	rts
printchar:
	lda	char
	jsr	CHROUT
	rts
clearchar:
	jsr	movecursor
	lda	emptychar
	jsr	CHROUT
	rts
drawball:
	lda	soccerball
	jsr	CHROUT
	rts
drawcard:
	lda	card
	jsr	CHROUT
	rts
;------------------iterate through ball/card coordinates to check if they match the player's
checkredcardcollision:
	ldx	#0
checkrcardcols:
	lda	redcardx,x
	stx	$1cfd	;temp store for card offset counter
	cmp	xcord	;compare with player character xcord
	beq	checkrcardy
	;check next card
	ldx	$1cfd
	inx
	inx
	cpx	#6
	bne	checkrcardcols
	jmp	norcardcol
checkrcardy:
	inx
	sta	$1cfe	;temp store for x cord
	stx	$1cfd	;temp store for card offset counter
	lda	redcardx,x
	cmp	ycord	;compare with player character ycord
	beq	redcardcol
	;check next card
	ldx	$1cfd
	inx
	cpx	#6
	bne	checkrcardcols
	jmp	norcardcol
redcardcol:
	sta	$1cff	;temp store for y cord
	lda	#1	;collision with a red card is insta-loss
	sta	redcardhit
	rts
relocateredcard:
;----reset y cord
	lda	#21
	ldx	$1cfd	;stored card counter/offset
	sta	redcardx,x
	;----random x cord----
	jsr randomgen
	cmp	#16
	beq	storenewx3
	cmp	#17
	beq	storenewx3
	cmp	#18
	beq	storenewx3
	cmp	#19
	beq	storenewx3
	cmp	#20
	beq	storenewx3
	cmp	#21
	beq	storenewx3
	lsr
	lsr
	lsr
	lsr
	cmp	#0
	bne	storenewx3
	tax
	inx
	txa
storenewx3:
	ldx	$1cfd
	dex
	sta	redcardx,x
	sta	$1cfc
	clc
	ldx	$1cfc
	ldy	#21
	jsr	PLOT
	jsr	drawcard
	ldx	$1cfc
	ldy	#21
	lda	#2
	jsr	plotcolor
norcardcol:
	rts
checkycardcollision:
	ldx	#0
checkycardcols:
	lda	yellowcardx,x
	stx	$1cfd	;temp store for card offset counter
	cmp	xcord	;compare with player character xcord
	beq	checkycardy
	;check next card
	ldx	$1cfd
	inx
	inx
	cpx	#14
	bne	checkycardcols
	jmp	noycardcol
checkycardy:
	inx
	sta	$1cfe	;temp store for x cord
	stx	$1cfd	;temp store for card offset counter
	lda	yellowcardx,x
	cmp	ycord	;compare with player character ycord
	beq	ycardcol
	;check next card
	ldx	$1cfd
	inx
	cpx	#14
	bne	checkycardcols
	jmp	noycardcol
ycardcol:
	sta	$1cff	;temp store for y cord
	jsr	plusonehit	;collision with a yellow card, plus one hit
relocateycard:
	;----reset y cord
	lda	#21
	ldx	$1cfd	;stored card counter/offset
	sta	yellowcardx,x
	;----random x cord----
	jsr randomgen
	cmp	#16
	beq	storenewx2
	cmp	#17
	beq	storenewx2
	cmp	#18
	beq	storenewx2
	cmp	#19
	beq	storenewx2
	cmp	#20
	beq	storenewx2
	cmp	#21
	beq	storenewx2
	lsr
	lsr
	lsr
	lsr
	cmp	#0
	bne	storenewx2
	tax
	inx
	txa
storenewx2:
	ldx	$1cfd
	dex
	sta	yellowcardx,x
	sta	$1cfc
	clc
	ldx	$1cfc
	ldy	#21
	jsr	PLOT
	jsr	drawcard
	ldx	$1cfc
	ldy	#21
	lda	#7
	jsr	plotcolor
noycardcol:
	rts
checkballcollision:
	ldx	#0
checkballcols:
	lda	ballx,x
	stx	$1cfd	;temp store for ball offset counter
	cmp	xcord	;compare with player character xcord
	beq	checkbally
	;check next ball
	ldx	$1cfd
	inx
	inx
	cpx	#20
	bne	checkballcols
	jmp	noballcol
checkbally:
	inx
	sta	$1cfe	;temp store for x cord
	stx	$1cfd	;temp store for ball offset counter
	lda	ballx,x
	cmp	ycord	;compare with player character ycord
	beq	ballcol
	;check next ball
	ldx	$1cfd
	inx
	cpx	#20
	bne	checkballcols
	jmp	noballcol
ballcol:
	sta	$1cff	;temp store for y cord
	jsr	plusone	;collision with a ball, plus one point
;-----------------relocate ball using random gen. with masked 4 most significant bits-------------	
relocateball:
	;----reset y cord
	lda	#21
	ldx	$1cfd	;stored ball counter/offset
	sta	ballx,x
	;----random x cord----
	jsr randomgen
	cmp	#16
	beq	storenewx
	cmp	#17
	beq	storenewx
	cmp	#18
	beq	storenewx
	cmp	#19
	beq	storenewx
	cmp	#20
	beq	storenewx
	cmp	#21
	beq	storenewx
	lsr
	lsr
	lsr
	lsr
	cmp	#0
	bne	storenewx
	tax
	inx
	txa
storenewx:
	ldx	$1cfd
	dex
	sta	ballx,x
	sta	$1cfc
	clc
	ldx	$1cfc
	ldy	#21
	jsr	PLOT
	jsr	drawball
	ldx	$1cfc
	ldy	#21
	lda	#1
	jsr	plotcolor
noballcol:
	rts
;-------------------SCORE HANDLERS----------------------------
plusone:
	ldx	ONES
	cpx	#57
	beq	tens
	inx
	stx	ONES
	jmp	continue
tens:
	ldx	TENS
	cpx	#57
	beq	checkones
	jmp	inctens
checkones:
	ldx	ONES
	cpx	#57
	beq	hundreds
inctens:
	ldx	TENS
	inx
	stx	TENS
	ldx	#48
	stx	ONES
	jmp	continue
hundreds:
	ldx	HUNDREDS
	cpx	#57
	beq	end	;score stops incrementing at 999
	inx
	stx	HUNDREDS
	ldx	#48
	stx	TENS
	stx	ONES
continue:	
	jsr	resetcursor
	jsr	printscore
	lda	#1	;white
	ldx	#7	;counter
	jsr	colorscore
end:
	rts
;----------helper subroutines----------
resetcursor:;reset to top left corner
	clc
	ldx	#0
	ldy	#7
	jsr	PLOT
	rts
printscore:
	lda	HUNDREDS
	jsr	CHROUT
	lda	TENS
	jsr	CHROUT
	lda	ONES
	jsr	CHROUT
	rts
printgameover:
	lda	gameovermsg,x
	jsr	CHROUT
	inx
	cpx	#10
	bne	printgameover
	clc
	ldx	#14
	ldy	#0
	jsr	PLOT
	ldx	#10
printgameover2:
	lda	gameovermsg,x
	jsr	CHROUT
	inx
	cpx	#31
	bne	printgameover2
	clc
	ldx	#16
	ldy	#0
	jsr	PLOT
	ldx	#31
printgameover3:
	lda	gameovermsg,x
	jsr	CHROUT
	inx
	cpx	#42
	bne	printgameover3
	rts
plusonehit:
	ldx	yellowhitcount
	cpx	#1
	beq	twohits
	inx
	stx	yellowhitcount
	clc
	ldx	#0
	ldy	#19
	jsr	PLOT
	lda	card
	jsr	CHROUT
	lda	#7
	ldx	#19
	jsr	colorhiticons
	rts
twohits:
	inx
	stx	yellowhitcount
	clc
	ldx	#0
	ldy	#20
	jsr	PLOT
	lda	card
	jsr	CHROUT
	lda	#7
	ldx	#20
	jsr	colorhiticons
	rts
;-----color and text-----;
plotcolor:
	;passed in a color, and an x and y cord
	sta	$18ff	;temp color store
	sty	$18fe	;temp y cord store
	cpx	#1
	bne	x2
	ldx	#1*#22
	jsr	setupplot
	rts
x2:
	cpx	#2
	bne	x3
	ldx	#2*#22
	jsr	setupplot
	rts
x3:	
	cpx	#3
	bne	x4
	ldx	#3*#22
	jsr	setupplot
	rts
x4:	
	cpx	#4
	bne	x5
	ldx	#4*#22
	jsr	setupplot
	rts
x5:
	cpx	#5
	bne	x6
	ldx	#5*#22
	jsr	setupplot
	rts
x6:
	cpx	#6
	bne	x7
	ldx	#6*#22
	jsr	setupplot
	rts
x7:	
	cpx	#7
	bne	x8
	ldx	#7*#22
	jsr	setupplot
	rts
x8:
	cpx	#8
	bne	x9
	ldx	#1*#22
	jsr	setupplot2
	rts
x9:
	cpx	#9
	bne	x10
	ldx	#2*#22
	jsr	setupplot2
	rts
x10:
	cpx	#10
	bne	x11
	ldx	#3*#22
	jsr	setupplot2
	rts
x11:
	cpx	#11
	bne	x12
	ldx	#4*#22
	jsr	setupplot2
	rts
x12:
	cpx	#12
	bne	x13
	ldx	#5*#22
	jsr	setupplot2
	rts
x13:
	cpx	#13
	bne	x14
	ldx	#6*#22
	jsr	setupplot2
	rts
x14:	
	cpx	#14
	bne	x15
	ldx	#7*#22
	jsr	setupplot2
	rts
x15:	
	cpx	#15
	bne	x16
	ldx	#1*#22
	jsr	setupplot3
	rts
x16:
	cpx	#16
	bne	x17
	ldx	#2*#22
	jsr	setupplot3
	rts
x17:
	cpx	#17
	bne	x18
	ldx	#3*#22
	jsr	setupplot3
	rts
x18:
	cpx	#18
	bne	x19
	ldx	#4*#22
	jsr	setupplot3
	rts
x19:
	cpx	#19
	bne	x20
	ldx	#5*#22
	jsr	setupplot3
	rts
x20:
	cpx	#20
	bne	x21
	ldx	#6*#22
	jsr	setupplot3
	rts
x21:
	cpx	#21
	bne	x22
	ldx	#7*#22
	jsr	setupplot3
	rts
x22:
	ldx	#8*#22
	jsr	setupplot3
	rts
setupplot:
	ldy	$18fe
	jsr	addy
	lda	$18ff
	jsr	colorlocation
	rts
setupplot2:
	ldy	$18fe
	jsr	addy
	lda	$18ff
	jsr	colorlocation2
	rts
setupplot3:
	ldy	$18fe
	jsr	addy
	lda	$18ff
	jsr	colorlocation3
	rts
addy:
	sty	$18fe	
	ldy	#0
addyloop:
	inx
	iny
	cpy	$18fe
	bne	addyloop
	rts
colorlocation:
	sta	COLOR_MAP_BASE,x
	rts
colorlocation2:
	sta	COLOR_MAP_2,x
	rts
colorlocation3:
	sta	COLOR_MAP_3,x
	rts
colorscore:
	sta	COLOR_MAP_BASE,x
	inx
	cpx	#10
	bne	colorscore
	rts
colorhitslabel:
	sta	COLOR_MAP_BASE,x
	inx
	cpx	#19
	bne	colorhitslabel
	rts
colorhiticons:
	sta	COLOR_MAP_BASE,x
	inx
	cpx	#21
	bne	colorhiticons
	rts
colorplayer:
	lda	#0
	ldx	xcord
	ldy	ycord
	jsr	plotcolor
	rts
gameticks:
	lda	INTERNAL_CLOCK
	cmp	#2
	bne	gameticks
	rts
checkspeedup:
	lda	nospeedup
	cmp	#1
	beq	nospeeduptrue
	ldx	TENS
	cpx	#48	;score of 0
	bne	speed1
	ldx	ONES
	cpx	#53
	bne	speed1
	lda	#4
	sta	objectspeed
	rts
speed1:
	ldx	TENS	
	cpx	#49	;score of 10
	bne	speed2
	lda	#3
	sta	objectspeed
	rts
speed2:
	ldx	TENS
	cpx	#50	;score of 20
	bne	speed3
	lda	#2
	sta	objectspeed
	rts
speed3:	;score of 50
	ldx	TENS
	cpx	#53
	bne	nospeeduptrue
	lda	#1
	sta	objectspeed
	sta	nospeedup
	rts
nospeeduptrue:
	rts
CLEARSCREEN:
	lda	#clearscreen
	jsr	CHROUT
	rts
;-------------------------------------------------------------------------------
;http://sleepingelephant.com/ipw-web/bulletin/bb/viewtopic.php?f=10&t=6171#top
;by user FD22
; RANDOMGEN
; Generate a random number from 0-255
; Notes:    Returns value in .A, uses no other registers

randomgen:    
             lda $0                     ; Get next ZP value
             adc .seed                  ; Add seed value
             adc RASTER                 ; Add current raster count
             sta .seed                  ; Update seed value
             inc randomgen+1            ; Increment ZP address in first instruction
             rts

.seed        DC.B $73                   ; Initial seed value
;------------TEXT-----------------------
char:
	.byte	"]"
emptychar:
	.byte	" "
soccerball:
	.byte	"+"
card:
	.byte	"@"
scorelabel:
	.byte	"SCORE: "
hits:
	.byte	"HITS:"
gameovermsg:
	.byte	"GAME OVER!"
	.byte	"'ENTER' TO PLAY AGAIN"
	.byte	"'Q' TO QUIT"