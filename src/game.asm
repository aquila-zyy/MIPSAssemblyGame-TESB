##################################################################### 
# 
# CSCB58 Winter 2021 Assembly Final Project 
# University of Toronto, Scarborough 
# 
# Student: Yiyang Zhou, 1005719386, zhouyiy8
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 4
# - Unit height in pixels: 4 
# - Display width in pixels: 512 (128 visual pixels)
# - Display height in pixels: 512 (128 visual pixels)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone None!
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features) 
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any) 
# 3. (fill in the feature, if any) 
# ... (add more if necessary) 
#
# Link to video demonstration for final submission: 
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it! 
# 
# Are you OK with us sharing the video with people outside course staff? 
# - yes / no / yes, and please share this project github link as well! 
# 
# Any additional information that the TA needs to know: 
# - (write here, if any) 
# 
#####################################################################
.data	
MAP:	.word	0:16384	# The map is 128x128 = 16384 in size
OBST:	.byte	0:30	# struct obst {
			#     char x;
			#     char y;
			#     char speed;
			# }
			# We can have at most 10 obstacles simultaneously.
			
ENEMY:	.byte	0:6	# struct enemy {
			#     char x;
			#     char y;
			#     char frame;
			# }

.eqv	BASE_ADDRESS	0x10008000	# The top left of the map
.eqv	PLAY_ADDRESS	0x1000c410	# The top left of the actual game
.eqv	WIDTH		128
.eqv	HEIGHT		128
.eqv	WIDTH_ADDR	512
	# Colors
.eqv	WHITE		0x00ffffff
.eqv	RED		0x00ac3232
.eqv	YELLOW		0x00fbf236
.eqv	GREEN		0x0000ff00
.eqv	CYAN		0x0000ffff
.eqv	BLUE		0x000000ff
.eqv	VIOLET		0x00ff00ff
.eqv	DARK_GREY		0x0045283c
.eqv	BLACK		0x00000000

.text
.globl main
main:	# Initialize the game
	# Draw the borders
	li $a0, 0
	li $a1, 0
	li $a2, WIDTH
	li $a3, CYAN
	jal draw_hori	# Draw top border
	li $a0, 0
	li $a1, 127
	li $a2, WIDTH
	jal draw_hori	# Draw bottom border
	li $a0, 0
	li $a1, 30
	li $a2, WIDTH
	jal draw_hori	# Draw middle border
	li $a0, 0
	li $a1, 0
	li $a2, HEIGHT
	jal draw_vert	# Draw left border
	li $a0, 127
	li $a1, 0
	li $a2, HEIGHT
	jal draw_vert	# Draw right border
	
	li $a0, 5
	li $a1, 79
	li $a2, -1
	li $a3, -1
	jal draw_plane	# Draw entire plane
	
	li $v0, 32
	li $a0, 2000
	syscall
	
	li $a0, 5
	li $a1, 78
	li $a2, 5
	li $a3, 79
	jal draw_plane
	
	li $v0, 32
	li $a0, 2000
	syscall
	
	li $a0, 5
	li $a1, 79
	li $a2, 5
	li $a3, 78
	jal draw_plane
	
	# Terminate
	li $v0, 10
	syscall
	
	
	
# This function draws a horizontal line starting from (x, y) inclusive to (x, y+k) exclusive with color c,
# where x, y, k, c are passed from $a0, $a1, $a2, $a3.
# This function modifies $a0, $a1, $a2, and $t9. $a3 is perserved.
draw_hori:
	# Calculate the actual address of the starting point
	move $t8, $ra	# Temporarily move $ra for nested function calls
	jal coor_to_addr
	move $ra, $t8	# Move $ra back
	
dh_do:	sw $a3, 0($v0)	# Paint color to the map
	addi $a2, $a2, -1	# k--
	addi $v0, $v0, 4	# Advance pointer
	bgtz $a2, dh_do	# if k>0, loop
	
	jr $ra	# return
	
# This function draws a vertical line starting from (x, y) inclusive to (x+k, y) exclusive with color c,
# where x, y, k, c are passed in from $a0, $a1, $a2, $a3.
# This function modifies $a0, $a1, $a2, $t8, $t9, and $v0. $a3 is perserved.
draw_vert:
	# Calculate the actual address of the starting point
	move $t8, $ra	# Temporarily move $ra for nested function calls
	jal coor_to_addr
	move $ra, $t8	# Move $ra back
	
dv_do:	sw $a3, 0($v0)	# Paint color to the map
	addi $a2, $a2, -1	# k--
	addi $v0, $v0, WIDTH_ADDR	# Advance pointer
	bgtz $a2, dv_do	# if k>0, loop
	
	jr $ra	# return
	
# This function draws a horizontal line starting from some address x and k pixel right, with some 
# color c.
# x, k, c, is passed in with $a0, $a2, $a3 (!)
# This function does not modify anything besides $a0, $a2.
draw_hori_addr:
dha_do:	sw $a3, 0($a0)	# Paint color to the map
	addi $a2, $a2, -1	# k--
	addi $a0, $a0, 4	# Advance pointer
	bgtz $a2, dha_do	# if k>0, loop
	
	jr $ra	# return

# This function converts a set of coordinates (x, y) to a memory address on the bit map, 
# where x, y are passed in from $a0 and $a1, and the return value is stored in $v0.
# This function modifies $a0, $a1, $v0, and $t9;
# This function does not call other functions.
coor_to_addr:
	li $t9, WIDTH_ADDR
	mul $a1, $a1, $t9	# Amount of memory we shift downward
	sll $a0, $a0, 2	# Amount of memory we shift right
	add $a0, $a0, $a1	# Total memory shift from base_address
	addi $v0, $a0, BASE_ADDRESS	# Actual memory address
	jr $ra		# return

# This function draws the player plane at (x, y) centralized. It takes four parameters: 
# x, y, old_x, old_y and uses register calling convention. Set old_x to -1 to draw an 
# entire plane, or set old_x to zero, and old_y to -1 to skip rendering. 
# Otherwise, (x, y) and (old_x, old_y) should be neighbouring pixels and this function 
# only draws the difference between two frames.
# This function modifies a lot of things, do not assume any perservation.
draw_plane:
	move $t8, $ra	# Move $ra away, this function calls many other functions
	# Load color values
	li $t0, DARK_GREY
	li $t1, RED
	li $t2, YELLOW
	li $t3, BLACK
	# Draw entire plane if old_x is negative.
	bltz $a2, drawp_whole
	# Skip if old_y is negative.
	bltz $a3, drawp_end
	# Else, check in which way have the plane moved.
	blt $a0, $a2, delta_left
	bgt $a0, $a2, delta_right
	bgt $a1, $a3, delta_down
#	blt $a1, $a3, delta_up
delta_up:
	jal coor_to_addr
	# Draw new cockpit
	sw $t0, 0($v0)
	sw $t0, 4($v0)
	# Draw new nose
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	# Overwrite old cockpit
	addi $a0, $v0, WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	# Overwrite old nose
	sw $t3, 12($a0)
	sw $t3, 16($a0)
	# Overwrite old right shoulder
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, 4($a0)
	sw $t3, 8($a0)
	# Draw new right pulser
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	# Overwrite old right remaining
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, 0($a0)
	sw $t3, -12($a0)
	sw $t3, -16($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, -4($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, -8($a0)
	# Draw new left shoulder
	addi $a0, $v0, -WIDTH_ADDR
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	# Overwrite old left pulser
	sw $t3, -16($a0)
	sw $t3, -12($a0)
	# Draw left remaining
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -4($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -8($a0)
	j drawp_end
	
delta_down:
	jal coor_to_addr
	# Draw new cockpit
	sw $t0, 0($v0)
	sw $t0, 4($v0)
	# Draw new nose
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	# Overwrite old cockpit
	addi $a0, $v0, -WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	# Overwrite old nose
	sw $t3, 12($a0)
	sw $t3, 16($a0)
	# Overwrite old left shoulder
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, 4($a0)
	sw $t3, 8($a0)
	# Draw new left pulser
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	# Overwrite old left remaining
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, 0($a0)
	sw $t3, -12($a0)
	sw $t3, -16($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, -4($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, -8($a0)
	# Draw new right shoulder
	addi $a0, $v0, WIDTH_ADDR
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	# Overwrite old right pulser
	sw $t3, -16($a0)
	sw $t3, -12($a0)
	# Draw right remaining
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -4($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -8($a0)
	j drawp_end
delta_left:

delta_right:
	
drawp_whole:
	# Get central address
	jal coor_to_addr
	# Draw cockpit
	sw $t0 0($v0)
	sw $t0 4($v0)
	# Draw nose
	sw $t1, 8($v0)
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	# Draw behind cockpit
	sw $t1, -8($v0)
	sw $t1, -4($v0)
	# Draw right shoulder
	addi $a0, $v0, WIDTH_ADDR
	addi $a0, $a0, -8
	li $a2, 5
	li $a3, RED
	jal draw_hori_addr
	# Draw right pulser
	addi $a0, $a0, WIDTH_ADDR
	addi $a0, $a0, -24
	sw $t2, -4($a0)	# Draw that yellow dot
	li $a2, 4
	jal draw_hori_addr
	# Draw right wing remaining
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -12($a0)
	sw $t1, -8($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -12($a0)
	# Draw left shoulder
	addi $a0, $v0, -WIDTH_ADDR
	addi $a0, $a0, -8
	li $a2, 5
	li $a3, RED
	jal draw_hori_addr
	# Draw left pulser
	addi $a0, $a0, -WIDTH_ADDR
	addi $a0, $a0, -24
	sw $t2, -4($a0)	# Draw that yellow dot
	li $a2, 4
	jal draw_hori_addr
	# Draw left wing remaining
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -12($a0)
	sw $t1, -8($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -12($a0)
	
	
	
	
drawp_end:
	jr $t8
	