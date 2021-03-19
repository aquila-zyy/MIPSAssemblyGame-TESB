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
# - Base Address for Display: 0x10010000 (static data) 
# (!) The board is too big to fit into $gp. Distruption with other chunks was observed (!)
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
OBSTS:	.byte	0:40	# struct obst {
			#     char x;
			#     char y;
			#     char speed;
			#     char alive;
			# }
			# We can have at most 10 obstacles simultaneously.

			
ENEMIES:	.byte	0:6	# struct enemy {
			#     char x;
			#     char y;
			#     char frame;
			# }


.eqv	BASE_ADDRESS	0x10010000	# The top left of the map
.eqv	PLAY_ADDRESS	0x10014410	# The top left of the actual game
.eqv	WIDTH		128
.eqv	HEIGHT		128
.eqv	WIDTH_ADDR	512

# Keys
.eqv	KEY_DETECT	0xffff0000
.eqv	KEY_A		0x61
.eqv	KEY_D		0x64
.eqv	KEY_S		0x73
.eqv	KEY_W		0x77
.eqv	KEY_P		0x70
.eqv	KEY_J		0x6a
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

.eqv	ROCK0		0x00484f4f
.eqv	ROCK1		0x00696a6a
.eqv	ROCK2		0x008c8f91
.eqv	ROCK3		0x00b9b9b9

.text
.globl main
main:	# Initialize the game
	# Draw the borders
	# Draw top border
	li $a0, 1
	li $a1, 1
	li $a2, WIDTH
	addi $a2, $a2, -2
	li $a3, WHITE
	jal draw_hori
	li $a0, 4
	li $a1, 4
	li $a2, WIDTH
	addi $a2, $a2, -8
	jal draw_hori
	li $a0, 2
	li $a1, 2
	li $a2, WIDTH
	addi $a2, $a2, -4
	li $a3, ROCK3
	jal draw_hori
	li $a0, 3
	li $a1, 3
	li $a2, WIDTH
	addi $a2, $a2, -6
	jal draw_hori
	# Draw middle border
	li $a0, 2
	li $a1, 29
	li $a2, WIDTH
	addi $a2, $a2, -4
	jal draw_hori
	li $a0, 3
	li $a1, 28
	li $a2, WIDTH
	addi $a2, $a2, -6
	jal draw_hori
	li $a0, 1
	li $a1, 30
	li $a2, WIDTH
	addi $a2, $a2, -2
	li $a3, WHITE
	jal draw_hori
	li $a0, 4
	li $a1, 27
	li $a2, WIDTH
	addi $a2, $a2, -8
	jal draw_hori
	# Draw left border
	li $a0, 1
	li $a1, 1
	li $a2, 29
	jal draw_vert
	li $a0, 4
	li $a1, 4
	li $a2, 23
	jal draw_vert
	li $a0, 2
	li $a1, 2
	li $a2, 27
	li $a3, ROCK3
	jal draw_vert
	li $a0, 3
	li $a1, 3
	li $a2, 25
	jal draw_vert
	# Draw right border
	li $a0, 125
	li $a1, 2
	li $a2, 27
	jal draw_vert
	li $a0, 124
	li $a1, 3
	li $a2, 25
	jal draw_vert
	li $a0, 126
	li $a1, 1
	li $a2, 29
	li $a3, WHITE
	jal draw_vert
	li $a0, 123
	li $a1, 4
	li $a2, 23
	jal draw_vert
	# Draw corner dots
	li $a0, 1
	li $a1, 1
	jal coor_to_addr
	li $t0, BLACK
	li $t1, WHITE
	sw $t0, 0($v0)
	sw $t0, 500($v0)
	sw $t1, 516($v0)
	sw $t1, 1008($v0)
	li $a0, 1
	li $a1, 30
	jal coor_to_addr
	sw $t0, 0($v0)
	sw $t0, 500($v0)
	sw $t1, -16($v0)
	sw $t1, -508($v0)
	
	li $a0, 5
	li $a1, 79
	li $a2, -1
	jal draw_plane	# Draw entire plane
	
	
# s0 to s2 are plane position
# s4 is number of obstacles on screen * 4, so that it is the address
# shift to the first empty rock
# s5 is obstacle count down (obst_cd), the delay before another 
# obstacle should spawn.
	
	# Initialize $s0 to $s3 to store x, y, old_x, old_y
	li $s0, 5
	li $s1, 79
	li $s2, 5
	li $s3, 79
	# Init obst_cd to 125 (5 seconds before first spawn)
	li $s5, 125
	# Init num_obst to 0
	li $s4, 0
mainloop:	
	li $t9, KEY_DETECT
	lw $t8, 0($t9)
	beq $t8, 1, keyevent
	j key_end
keyevent:	lw $t2, 4($t9)
	beq $t2, KEY_D, ke_d
	beq $t2, KEY_S, ke_s
	beq $t2, KEY_A, ke_a
	beq $t2, KEY_W, ke_w
	
ke_d:	bge $s0, 122, key_end # Skip if x is already at right border
	# Update coordinates
	addi $s0, $s0, 1
	move $a0, $s0
	move $a1, $s1
	li $a2, 3
	jal draw_plane
	j key_end
ke_a:	ble $s0, 5, key_end # Skip if x is already at left border
	# Overwrite old coordinates
	move $s2, $s0
	move $s3, $s1
	# Update coordinates
	addi $s0, $s0, -1
	move $a0, $s0
	move $a1, $s1
	li $a2, 2
	jal draw_plane
	j key_end
ke_s:	bge $s1, 122, key_end # Skip if y is already at bottom border
	# Overwrite old coordinates
	move $s2, $s0
	move $s3, $s1
	# Update coordinates
	addi $s1, $s1, 1
	move $a0, $s0
	move $a1, $s1
	li $a2, 1
	jal draw_plane
	j key_end
ke_w:	ble $s1, 35, key_end # Skip if y is already at top border
	# Overwrite old coordinates
	move $s2, $s0
	move $s3, $s1
	# Update coordinates
	addi $s1, $s1, -1
	move $a0, $s0
	move $a1, $s1
	li $a2, 0
	jal draw_plane
	j key_end
key_end:	
	# Move all rocks left
	# $t6 points to the start of the obstacle array
	# $t5 is the index (shift)
	# $t0 is temorarily used to skip if not alive (can be modified)
	# $a0 and $a1 are the coordinates of the rock
	# $a3 is used to let drawer know whether a rock should be erased
	la $t6, OBSTS
	li $t5, 0
move_start:
	beq $t5, 40, move_end	# End loop if reached the end
	add $t6, $t6, $t5	# Shift pointer to the corrct index
	# Load alive
	lb $t0, 3($t6)
	beq $t0, 0, move_skip	# If not alive, skip
	# Load x and y
	lb $a0, 0($t6)
	lb $a1, 1($t6)
	addi $a0, $a0, -1	# x--
	sb $a0, 0($t6)	# Save x back
	li $a3, 0		# Init "should_erase" to 0
	bgt $a0, 5, in_game	# If after the movement the rock.x > 5, then it's still in game
reach_end:# If it is out of bound, set the field alive to 0 and $s4 -= 4
	sb $zero, 3($t6)
	addi $s4, $s4, -4	
	li $a3, 1		# Set "should_erase" to 1
	addi $a0, $a0, 1
in_game:	
	jal draw_rock1
	beqz $v1, move_skip
collision_happened:
	# Paint out rock and redraw plane
	lb $a0, 0($t6)
	lb $a1, 1($t6)
	li $a3, 1		# "should_erase" = 1
	jal draw_rock1
	sb $zero, 3($t6)	# Set dead in memory
	# Redraw plane
	move $a0, $s0
	move $a1, $s1
	li $a2, -1
	jal draw_plane
	addi $s4, $s4, -4	# Shrink num_obst
move_skip:
	addi $t5, $t5, 4	# Advance index
	j move_start
move_end:
spawn_start:
	# Whether a new rock should spawn?
	bge $s4, 40, spawn_end	# Don't spawn and don't count down if there're already 10 rocks
	bgtz $s5, no_spawn		# Don't spawn if cd is not 0
	# Do spawn a rock
	# Find a dead element in the rock array
	la $t0, OBSTS
	li $t1, 0
find_dead_start:
	add $t0, $t0, $t1	# Shift pointer to next index
	lb $t2, 3($t0)
	beqz $t2, found_dead
	addi $t1, $t1, 4	# Advance index
	blt $t1, 40, find_dead_start	# Spawn a rock at the end of the array no matter what.
found_dead:
	# Call RNG, decide the y coord for the rock
	li $v0, 42
	li $a0, 0
	li $a1, 87
	syscall
	addi $a1, $a0, 35	# Shift the RN downward into the playground
	li $a0, 122	# Load x coord for the rock
	sb $a0, 0($t0)
	sb $a1, 1($t0)
	li $t1, 1		# Init speed and alive to 1
	sb $t1, 2($t0)
	sb $t1, 3($t0)
	addi, $s4, $s4, 4	# Advance num_rocks
	# Draw the rock
	jal draw_rock1
	# Call RNG, decide the new count down.
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	addi, $s5, $a0, 5	# New rock spawn in 25 to 75 (2 to 3 sec)
	j spawn_end
no_spawn:	
	addi, $s5, $s5, -1	# Count down
spawn_end:
	li $v0, 32
	li $a0, 40
	syscall
	j mainloop
mainend:		
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

# This function draws the player plane at (x, y) centralized. It takes three parameters: 
# x, y, and movement, and uses register calling convention. Set movement to -1 to 
# draw an entire plane. Set 0, 1, 2, 3 to indicate the plane has moved towards up, down,
# left, or right, respectively. Set movement to -2 to skip drawing entirely.
# This function only draws the difference between two frames.
# This function modifies a lot of things, do not assume any perservation.
draw_plane:
	move $t8, $ra	# Move $ra away, this function calls many other functions
	# Load color values
	li $t0, DARK_GREY
	li $t1, RED
	li $t2, YELLOW
	li $t3, BLACK
	# Check in which way should we draw this frame
	beq $a2, -1, drawp_whole
	beq $a2, -2, drawp_end
	beq $a2, 2, delta_left
	beq $a2, 3, delta_right
	beq $a2, 1, delta_down
	beq $a2, 0, delta_up
	j drawp_end
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
	jal coor_to_addr
	# Redraw cockpit line
	sw $t0, 0($v0)
	sw $t1, 8($v0)
	sw $t3, 20($v0)
	sw $t1, -8($v0)
	# Redraw left shoulder
	addi $a0, $v0, -WIDTH_ADDR
	sw $t3, 12($a0)
	sw $t1, -8($a0)
	# Redraw left pulser
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, 4($a0)
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	# Redraw left remaining
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, 0($a0)
	sw $t1, -8($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, -4($a0)
	sw $t1, -8($a0)
	# Redraw right shoulder
	addi $a0, $v0, WIDTH_ADDR
	sw $t3, 12($a0)
	sw $t1, -8($a0)
	# Redraw right pulser
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, 4($a0)
	sw $t2, -16($a0)
	sw $t1, -12($a0)
	# Redraw right remaining
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, 0($a0)
	sw $t1, -8($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, -4($a0)
	sw $t1, -8($a0)
	j drawp_end

delta_right:
	jal coor_to_addr
	# Redraw cockpit line
	sw $t1, -4($v0)
	sw $t0, 4($v0)
	sw $t1, 16($v0)
	sw $t3, -12($v0)
	# Redraw left shoulder
	addi $a0, $v0, -WIDTH_ADDR
	sw $t1, 8($a0)
	sw $t3, -12($a0)
	# Redraw left pulser
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t3, -20($a0)
	sw $t2, -16($a0)
	# Redraw left remaining
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -4($a0)
	sw $t3, -12($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t1, -8($a0)
	sw $t3, -12($a0)
	# Redraw right shoulder
	addi $a0, $v0, WIDTH_ADDR
	sw $t1, 8($a0)
	sw $t3, -12($a0)
	# Redraw right pulser
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, 0($a0)
	sw $t3, -20($a0)
	sw $t2, -16($a0)
	# Redraw right remaining
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -4($a0)
	sw $t3, -12($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t1, -8($a0)
	sw $t3, -12($a0)
	j drawp_end
	
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
	
# This function draws the type 1 rock at (x, y) centralized. It takes 3 parameters:
# x, y, and erase, and uses register calling convention. This function moves the rock to the
# left by 1 pixel, or if x is set to 122 (the right-most valid pixel, draws an entire
# stone. If erase is set to 1, erase the stone at (x, y)
# This function also return 1 if the rock has collided with the ship. It stores the return
# value in $v1. 
draw_rock1:
	move $t8, $ra
	li $v1, 0 # Init return value
	# Load colors
	li $t1, ROCK1
	li $t2, ROCK2
	li $t3, ROCK3
	beq $a3, 1, drawr1_erase
	blt $a0, 122, drawr1_shift	# Draw shift
	
drawr1_full: # Draw rock 1 full
	jal coor_to_addr
	sw $t1, 0($v0)
	sw $t1, -4($v0)
	sw $t1, 4($v0)
	sw $t2, -8($v0)
	sw $t2, 8($v0)
	addi $a0, $v0, WIDTH_ADDR
	sw $t2, 0($a0)
	sw $t2, -4($a0)
	sw $t2, 4($a0)	
	addi $a0, $a0, WIDTH_ADDR
	sw $t3, 0($v0)
	addi $a0, $v0, -WIDTH_ADDR
	sw $t2, 0($a0)
	sw $t2, -4($a0)
	sw $t2, 4($a0)	
	addi $a0, $a0, -WIDTH_ADDR
	sw $t3, 0($v0)
	jr $t8
drawr1_shift: # Draw rock 1 shift
	li $t0, BLACK	# We need to erase things
	jal coor_to_addr
	# Test collision on nose
	lw $t3, -8($v0)
	bne $t3, RED, no_collide1
	li $v1, 1
no_collide1: # Test end 1
	sw $t1, -4($v0)
	sw $t2, 8($v0)
	sw $t0, 12($v0)
	sw $t2, -8($v0)
	addi $a0, $v0, WIDTH_ADDR
	sw $t0, 8($a0)
	sw $t2, -4($a0)
	addi $a0, $a0, WIDTH_ADDR
	sw $t0, 4($a0)
	# Test collision on left point
	lw $t3, -4($a0)
	bne $t3, RED, no_collide2
	li $v1, 1
no_collide2: # Test end 2
	sw $t2, 0($a0)
	addi $a0, $v0, -WIDTH_ADDR
	sw $t0, 8($a0)
	sw $t2, -4($a0)
	addi $a0, $a0, -WIDTH_ADDR
	sw $t0, 4($a0)
	# Test collision on right point
	lw $t3, -4($a0)
	bne $t3, RED, no_collide3
	li $v1, 1
no_collide3: # Test end 3
	sw $t2, 0($a0)
	jr $t8
drawr1_erase:
	li $t0, BLACK
	jal coor_to_addr
	sw $t0, 0($v0)
	sw $t0, -4($v0)
	sw $t0, 4($v0)
	sw $t0, -8($v0)
	sw $t0, 8($v0)
	addi $a0, $v0, WIDTH_ADDR
	sw $t0, 0($a0)
	sw $t0, -4($a0)
	sw $t0, 4($a0)	
	addi $a0, $a0, WIDTH_ADDR
	sw $t0, 0($a0)
	addi $a0, $v0, -WIDTH_ADDR
	sw $t0, 0($a0)
	sw $t0, -4($a0)
	sw $t0, 4($a0)	
	addi $a0, $a0, -WIDTH_ADDR
	sw $t0, 0($a0)
	jr $t8
	
	
