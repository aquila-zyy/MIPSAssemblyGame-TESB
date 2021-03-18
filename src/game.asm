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
	# Colors
.eqv	WHITE		0x00ffffff
.eqv	RED		0x00ff0000
.eqv	YELLOW		0x00ffff00
.eqv	GREEN		0x0000ff00
.eqv	CYAN		0x0000ffff
.eqv	BLUE		0x000000ff
.eqv	VIOLET		0x00ff00ff

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
	sll $t9, $t9, 2	# $t9 is WIDTH, shift left 2 so that it is now 
			# address difference between rows
	
dv_do:	sw $a3, 0($v0)	# Paint color to the map
	addi $a2, $a2, -1	# k--
	add $v0, $v0, $t9	# Advance pointer
	bgtz $a2, dv_do	# if k>0, loop
	
	jr $ra	# return
	
# This function converts a set of coordinates (x, y) to a memory address on the bit map, 
# where x, y are passed in from $a0 and $a1, and the return value is stored in $v0.
# This function modifies $a0, $a1, $v0, and $t9;
# This function does not call other functions.
coor_to_addr:
	li $t9, WIDTH
	mul $a1, $a1, $t9
	sll $a1, $a1, 2	# Amount of memory we shift downward
	sll $a0, $a0, 2	# Amount of memory we shift right
	add $a0, $a0, $a1	# Total memory shift from base_address
	addi $v0, $a0, BASE_ADDRESS	# Actual memory address
	jr $ra		# return

# This function draws the player plane at (x, y) centralized. It takes four parameters: 
# x, y, old_x, old_y and uses register calling convention. Set old_x or old_y to -1 to 
# draw an entire plane. Otherwise, (x, y) and (old_x, old_y) should be neighbouring 
# pixels and this function only draws the difference between two frames.
# This function modifies $a0, $a1, $t8, $t9.
draw_plane: