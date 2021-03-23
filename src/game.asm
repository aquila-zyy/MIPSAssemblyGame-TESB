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
OBSTS:	.byte	0:60	# struct obst {
			#     char x;
			#     char y;
			#     char speed;
			#     char alive;
			# }
			# We can have at most 10 obstacles simultaneously.

HP:	.byte	10	# This is the player's HP
HP_BAR:	.byte	23	# The x coord of the last pixel of the HP_BAR (y is 21)

OBSTS_END:	.word	0
			# This is an optimization. Instead of calculating the end point of the OBSTS array
			# everytime, we do it once at the begining. Furthermore it also changes with the 
			# MAX_ROCK.
LAST_DEAD:	.word	0
			# This is an optimization. Instead of performing a linear search on OBSTS array
			# every time we need to find a empty slot to spawn something (aka a "dead" item),
			# we remember the last item that is set to "dead". In case of a successful spawn,
			# we advance this variable by 1 index, and carry around to 0 if it exceeds the 
			# maximum index.
			
SCORE:		.half	0
			# These two bytes stores the score. It uses a special structure to save
			# the effort of converting binary value to decimal value (for printing)
			# Each 4 bits represents a digit in decimal, for example:
			# 0011 1011 0000 1001 represents 3709 points. Note: each digit is never 
			# greater than 1001 (9). Note2: each digit shall use an unsigned value.

SCORE_MODIFIED:	.byte	0
			# This stores which digits in SCORE should be updated on screen this 
			# frame.
			

.eqv	BASE_ADDRESS	0x10010000	# The top left of the map
.eqv	PLAY_ADDRESS	0x10014410	# The top left of the actual game
.eqv	WIDTH		128
.eqv	HEIGHT		128
.eqv	WIDTH_ADDR	512		# The amount of address shift between two neighbouring pixels
					# on different rows.

.eqv	MAX_ROCK1		5		# The maximum number of rock type 1 on screen simultaneously.

# Keys
.eqv	KEY_DETECT	0xffff0000	# This address will be set to 1 if a key is pressed when syscalled
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

# $s0 and $s1 are the (x, y) coordinates of the player. Try not to move them since they 
#   come quite handy as global variables.
# $s3 is the color of the plane. We need to read the color every time we need to repaint the
# plane so it's faster to not store it in memory.
# $s4 is number of obstacles on screen. Since we need to check it every frame, it's better
#   that we keep it in the register file.
# $s5 is obstacle count down (obst_cd), the delay before another obstacle should spawn. Again, 
#   we need to check it every frame so it'll be faster to not store it in memory.
# $s6 is the maximum number of obstacles that are allowed on screen at the same time.
# $s7 is the score (in binary).

main:	# Initialize the program.
	move $fp, $sp	# Set frame pointer to the inital stack pointer.
	
	la $t0, OBSTS	# Set LAST_DEAD to the first item in OBSTS
	la $t1, LAST_DEAD
	sw $t0, 0($t1)
	la $t2, OBSTS_END
	
	li $t1, MAX_ROCK1	# Calculate the end address of the OBSTS array.
	sll $t1, $t1, 2	# Times 4, since each obst struct takes 4 bytes.
	add $t1, $t1, $t0	# Add the starting address
	sw $t1, 0($t2)
	
	li $s6, MAX_ROCK1
	li $s7, 0
	
	jal draw_ui
	
	# Draw player plane
	li $s0, 5
	li $s1, 79
	li $s3, RED	# Default color is red
	li $a0, -1	# Draw all, not only the shifted.
	move $a1, $s3	# Red
	jal draw_plane

	# Init obst_cd
	li $s5, 1
	# Init num_obst to 0
	li $s4, 0
	# Init score
	li $s7, 0
mainloop:	
	jal key_event
	jal move_rocks
	
	bgtz $s5, no_spawn_yet	# Do not spwan if the countdown is not 0
	
	beq $s4, $s6, hold_spawn	# Hold the spawn if there're more obstacles on
				# screen than the maximum allowed number.
	jal spawn_rock
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 5
	jal add_score
	addi $s7, $s7, 5
	jal draw_score
no_spawn_yet:
	addi $s5, $s5, -1
hold_spawn:
	# Increase difficulty for each 128 + 5 * num_obst points the player get.
	addi $t0, $s6, -MAX_ROCK1
	addi $t0, $t0, 1
	sll $t0, $t0, 7	# Multiply by 128
	mul $t1, $s4, 5
	add $t0, $t0, $t1
	blt $s7, $t0, no_increase_difficulty
	beq $s6, 15, no_increase_difficulty	# We've only allocated 15 indices for OBSTS
	# Increase max_obst
	addi $s6, $s6, 1
	# Shift OBSTS_END
	la $t0, OBSTS_END
	lw $t1, 0($t0)
	addi $t1, $t1, 4
	sw $t1, 0($t0)
no_increase_difficulty:
	li $v0, 32
	li $a0, 10
	syscall
	j mainloop
mainend:	
	# Draw "GAME OVER"
	li $a0, 48
	li $a1, 64
	li $a2, RED
	jal draw_G
	li $a0, 52
	li $a1, 64
	li $a2, RED
	jal draw_A
	li $a0, 56
	li $a1, 64
	li $a2, RED
	jal draw_M
	li $a0, 60
	li $a1, 64
	li $a2, RED
	jal draw_E
	
	li $a0, 64
	li $a1, 64
	li $a2, RED
	jal draw_O
	li $a0, 68
	li $a1, 64
	li $a2, RED
	jal draw_V
	li $a0, 72
	li $a1, 64
	li $a2, RED
	jal draw_E
	li $a0, 76
	li $a1, 64
	li $a2, RED
	jal draw_R
prog_end:
	# Terminate
	li $v0, 10
	syscall
	
# Move all rocks to the left.
# This function checks the OBSTS array and moves all "living" items to the left by 1 pixel. 
# If any item reaches the left end point of the screen, this function will set its living state
# to 0, and call draw_rock to erase it from the screen.
# This function also checks if any rock has collided with the player plane in this frame. 
# Collisions will cause the rock to disappear and an HP deduction.
move_rocks:
	# $t0 points to the start of the obstacle array, and we shift it as we progress.
	# $t1 is the end address of obst array so that we can know if we should stop iterating.
	# $t2 is temorarily used to see if a rock is alive.
	# Push $ra to stack first
	sw $ra, -4($sp)
	addi $sp, $sp, -4
	# Does not care about frame pointer since we don't need it.
	la $t0, OBSTS
	# Set $t1 to OBSTS_END
	la $t1, OBSTS_END
	lw $t1, 0($t1)
move_loop:
	beq $t0, $t1, move_end	# End loop if we've reached the end
	# Load alive
	lb $t2, 3($t0)		# The 4th byte of the struct is "alive"
	beq $t2, 0, move_skip	# If not alive, skip
	# If is alive, move it.
	lb $a0, 0($t0)		# Load x from struct directly to parameter field.
	lb $a1, 1($t0)		# Load y from struct directly to parameter field.
				# We'll call draw function very soon.
	addi $a0, $a0, -1		# x--
	sb $a0, 0($t0)		# Save x back
	
	li $a3, 0			# Default "should_erase" to 0
	bgt $a0, 5, dont_kill
	# If after the movement, the rock's x coordinate is less or equal to 5, then
	# we need to kill it, decrease $s4 (num_obst) by one, and ask draw_rock function
	# to remove it from screen.
	sb $zero, 3($t0)		# Set "alive" in struct to 0
	addi $s4, $s4, -1		# Decrease $s4
	la $t2, LAST_DEAD		# Set LAST_DEAD to $t0 as an optimization.
	sw $t0, 0($t2)
	li $a3, 1			# Reset "should_erase" to 1
	addi $a0, $a0, 1		# Set x coordinate back to where it was, so that
				# the draw function can erase it properly.
	# If not, then we don't need to do anything special.
dont_kill:
	# Push $t0 and $t1 to stack. We don't care about $t2 since it's only temporary.
	sw $t0, -4($sp)
	sw $t1, -8($sp)
	addi $sp, $sp, -8
	jal draw_rock1
	# Do not pop them immediately, we might need to call drawer functions right after this.
	beqz $v1, no_collision
collision_happened:
	# First, read (but not pop) $t0 from stack so that we can set the "alive" field of the rock to 0.
	lw $t0, 4($sp)
	sb $zero, 3($t0)
	# Now, erase the rock from the screen
	# Since draw_rock function keeps the arguments untouched, we can use the (x, y) directly.
	li $a3, 1		# "should_erase" = 1
	jal draw_rock1
	# Redraw plane since we might have erased some part of the plane along with the rock.
	li $a0, -1
	move $a1, $s3
	jal draw_plane
	addi $s4, $s4, -1	# Shrink num_obst
	# Deduct HP
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	addi $t1, $t1, -1	# Deduct 1
	sb $t1, 0($t0)	# Save HP value back
	# Shirnk HP bar visually
	la $t0, HP_BAR	# Load HP_BAR, the x coordinates of the last pixel of the HP bar.
	lb $a0, 0($t0)
	addi $a0, $a0, -1
	sb $a0, 0($t0)	# Update x in memory
	# Erase the last column of the HP bar
	addi $a0, $a0, 1	# Set x to what it was.
	li $a1, 21	# The pre-calculated y coordinate.
	li $a2, 5		# The height of the bar.
	li $a3, BLACK	# Paint it black.
	jal draw_vert 
	# Check if the HP is 0, jump to game over if so.
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	beqz $t1, mainend
no_collision:
	# Only now we pop $t0 and $t1
	lw $t1, 0($sp)
	lw $t0, 4($sp)
	addi $sp, $sp, 8
move_skip:
	addi $t0, $t0, 4	# Advance address
	j move_loop
move_end:
	# Pop $ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Spawn a new rock at the right side of the screen.
# This function finds an empty (dead) location in the OBSTS array and spawns a new rock in it.
# This function first checks the LAST_DEAD address, since there is most likely a dead rock. If 
# not, it cycles through the entire array to find a spot for the new rock. If there's no free
# spot, it will create in an infinate loop so call this only if there is absolutely a spawnable
# spot.
spawn_rock:
	# Push $ra to stack
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	# Push previous frame pointer to stack
	sw $fp, 0($sp)
	# Set this frame pointer 
	move $fp, $sp
	# Reserve space for local variables
	addi $sp, $sp, -8
	# Load relavant addresses
	la $t9, OBSTS_END
	lw $t9, 0($t9)
	la $t8, OBSTS
	la $t7, LAST_DEAD
	lw $t0, 0($t7)	# This will be our main pointer of interest.
	# Push local variables on stack frame
	sw $t9, -8($fp)
find_dead:
	lb $t1, 3($t0)
	beqz $t1, spawn_start
	addi $t0, $t0, 4	# Shift pointer to next index
	bne $t0, $t9, find_dead
	move $t0, $t8	# Wrap around the end
	j find_dead
spawn_start:
	# First, store the address to the frame
	sw $t0, -4($fp)
	# Call RNG, decide the y coord for the rock.
	# y should range from 35 to 122.
	li $v0, 42
	li $a0, 0
	li $a1, 87	# 122 - 35 = 87
	syscall
	addi $a1, $a0, 35
	li $a0, 122	# Load x coord for the rock
	sb $a0, 0($t0)
	sb $a1, 1($t0)
	li $t1, 1		# Init speed and alive to 1
	sb $t1, 2($t0)
	sb $t1, 3($t0)
	addi, $s4, $s4, 1	# Advance num_rocks
	# Draw the rock
	jal draw_rock1
	# Call RNG, decide the new count down.
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	addi, $s5, $a0, 5	# Ranges from 5 to 15
	
	# Advance LAST_DEAD since it's no longer vacant. The best bet is the next index.
	la $t7, LAST_DEAD
	la $t8, OBSTS
	lw $t9, -8($fp)
	lw $t0, -4($fp)
	addi $t0, $t0, 4
	bne $t0, $t9, no_wrap
	move $t0, $t8
no_wrap:	sw $t0, 0($t7)
	# Release local variables and pop $fp and $ra from stack.
	addi $sp, $sp, 8
	lw $fp, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra

key_event:
	# First push $ra to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Since we do not need local variables, we do not modify frame pointer.
	
	li $t9, KEY_DETECT
	lw $t8, 0($t9)
	beqz $t8, key_end	# Skip if no key is being pressed down.
	lw $t2, 4($t9)
	beq $t2, KEY_D, ke_d
	beq $t2, KEY_S, ke_s
	beq $t2, KEY_A, ke_a
	beq $t2, KEY_W, ke_w
	j key_end		# Skip if the key being pressed down isn't functional.
ke_d:	bge $s0, 122, key_end # Skip if x is already at right border
	# Update coordinates
	addi $s0, $s0, 1
	li $a0, 3
	move $a1, $s3
	jal draw_plane
	j key_end
ke_a:	ble $s0, 5, key_end # Skip if x is already at left border
	# Update coordinates
	addi $s0, $s0, -1
	li $a0, 2
	move $a1, $s3
	jal draw_plane
	j key_end
ke_s:	bge $s1, 122, key_end # Skip if y is already at bottom border
	# Update coordinates
	addi $s1, $s1, 1
	li $a0, 1
	move $a1, $s3
	jal draw_plane
	j key_end
ke_w:	ble $s1, 35, key_end # Skip if y is already at top border
	# Update coordinates
	addi $s1, $s1, -1
	li $a0, 0
	move $a1, $s3
	jal draw_plane
key_end:	# Pop back $ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	
# This function draws a horizontal line starting from (x, y) inclusive to (x, y+k) exclusive with color c,
# @param const $a0, the x coordinate of the left end point of the line.
# @param const $a1, the y coordinate of the left end point of the line.
# @param const $a2, the length of the line.
# @param const $a3, the color of the line.
draw_hori:
	# Call coor_to_addr to calculate the actual address of the starting point
	addi $sp, $sp, -4
	sw $ra, 0($sp)	# Push $ra to stack for nested function calls
	jal coor_to_addr
	lw $ra, 0($sp)	# Pop $ra from stack
	addi $sp, $sp, 4
	move $t2, $a2
dh_do:	sw $a3, 0($v0)	# Paint color to the map
	addi $t2, $t2, -1	# k--
	addi $v0, $v0, 4	# Advance pointer
	bgtz $t2, dh_do	# if k>0, loop
	jr $ra	# return
	
# This function draws a vertical line starting from (x, y) inclusive to (x+k, y) exclusive with color c,
# @param const $a0, the x coordinate of the top end point of the line.
# @param const $a1, the y coordinate of the top end point of the line.
# @param const $a2, the length of the line.
# @param const $a3, the color of the line.
draw_vert:
	# Call coor_to_addr to calculate the actual address of the starting point
	addi $sp, $sp, -4
	sw $ra, 0($sp)	# Push $ra to stack for nested function calls
	jal coor_to_addr	# coor_to_addr does not modify $a0 or $a1
	lw $ra, 0($sp)	# Pop $ra from stack
	addi $sp, $sp, 4
	move $t2, $a2
dv_do:	sw $a3, 0($v0)	# Paint color to the map
	addi $t2, $t2, -1	# k--
	addi $v0, $v0, WIDTH_ADDR	# Advance pointer
	bgtz $t2, dv_do	# if k>0, loop
	jr $ra	# return


# This function converts a set of coordinates (x, y) to a memory address on the bit map, 
# @param const $a0, the x coordinate on the map.
# @param const $a1, the y coordinate on the map.
# @return $v0, the corresponding memory address.
coor_to_addr:
	li $t0, WIDTH_ADDR
	mul $v0, $a1, $t0	# Amount of memory we shift downward
	sll $t0, $a0, 2	# Amount of memory we shift right
	add $v0, $v0, $t0	# Total memory shift from base_address
	addi $v0, $v0, BASE_ADDRESS	# Actual memory address
	jr $ra		# return

# This function reads global variable $s0, $s1, and draws the player plane at ($s0, $s1) centralized. 
# It takes two parameters: movement($a0) and color($a1). Set movement to -1 to draw an entire plane. 
# Set movement to 0, 1, 2, or 3 to indicate the plane has moved towards up, down, left, or right, respectively. 
# This function only draws the difference between two frames if possible. Therefore simply changing the color
# on the fly would cause 
# @param const $a0, the direction that the plane has moved since the last frame.
# @param const $a1, the color of the main part of the plane.
draw_plane:
	# Push $ra to stack. We need to nest functions here.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Push previous stack frame onto the stack
	addi $sp, $sp, -4
	sw $fp, 0($sp)
	# Set stack frame for this function
	move $fp, $sp
	# Reserve memory for local variables.
	addi $sp, $sp, -8
	# Init different colors.
	sw $a0, -4($fp)	# This is movement.
	sw $a1, -8($fp)	# This is the main color of the plane.
	# Carry current coord to $a0 and $a1. Prepare to convert to address.
	move $a0, $s0
	move $a1, $s1
	jal coor_to_addr	# Note: now $v0 is the center address of the plane.
	# Pop variables back
	lw $a0, -4($fp)
	lw $t1, -8($fp)
	# Load other color constants.
	li $t0, DARK_GREY
	li $t2, YELLOW
	li $t3, BLACK
	# Check in which way should we draw this frame
	beq $a0, -1, drawp_whole
	beq $a0, -2, drawp_end
	beq $a0, 2, delta_left
	beq $a0, 3, delta_right
	beq $a0, 1, delta_down
	beq $a0, 0, delta_up
	j drawp_end
delta_up:
	# Draw the cockpit
	sw $t0, 0($v0)
	sw $t0, 4($v0)
	# Draw new nose
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	# Overwrite old cockpit
	addi $t4, $v0, WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t1, 4($t4)
	# Overwrite old nose
	sw $t3, 12($t4)
	sw $t3, 16($t4)
	# Overwrite old right shoulder
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, 4($t4)
	sw $t3, 8($t4)
	# Draw new right pulser
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	# Overwrite old right remaining
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, 0($t4)
	sw $t3, -12($t4)
	sw $t3, -16($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, -4($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, -8($t4)
	# Draw new left shoulder
	addi $t4, $v0, -WIDTH_ADDR
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	# Overwrite old left pulser
	sw $t3, -16($t4)
	sw $t3, -12($t4)
	# Draw left remaining
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -4($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -8($t4)
	j drawp_end
delta_down:
	# Draw new cockpit
	sw $t0, 0($v0)
	sw $t0, 4($v0)
	# Draw new nose
	sw $t1, 12($v0)
	sw $t1, 16($v0)
	# Overwrite old cockpit
	addi $t4, $v0, -WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t1, 4($t4)
	# Overwrite old nose
	sw $t3, 12($t4)
	sw $t3, 16($t4)
	# Overwrite old left shoulder
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, 4($t4)
	sw $t3, 8($t4)
	# Draw new left pulser
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	# Overwrite old left remaining
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, 0($t4)
	sw $t3, -12($t4)
	sw $t3, -16($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, -4($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, -8($t4)
	# Draw new right shoulder
	addi $t4, $v0, WIDTH_ADDR
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	# Overwrite old right pulser
	sw $t3, -16($t4)
	sw $t3, -12($t4)
	# Draw right remaining
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -4($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -8($t4)
	j drawp_end
delta_left:
	# Redraw cockpit line
	sw $t0, 0($v0)
	sw $t1, 8($v0)
	sw $t3, 20($v0)
	sw $t1, -8($v0)
	# Redraw left shoulder
	addi $t4, $v0, -WIDTH_ADDR
	sw $t3, 12($t4)
	sw $t1, -8($t4)
	# Redraw left pulser
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, 4($t4)
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	# Redraw left remaining
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, 0($t4)
	sw $t1, -8($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t3, -4($t4)
	sw $t1, -8($t4)
	# Redraw right shoulder
	addi $t4, $v0, WIDTH_ADDR
	sw $t3, 12($t4)
	sw $t1, -8($t4)
	# Redraw right pulser
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, 4($t4)
	sw $t2, -16($t4)
	sw $t1, -12($t4)
	# Redraw right remaining
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, 0($t4)
	sw $t1, -8($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t3, -4($t4)
	sw $t1, -8($t4)
	j drawp_end
delta_right:
	# Redraw cockpit line
	sw $t1, -4($v0)
	sw $t0, 4($v0)
	sw $t1, 16($v0)
	sw $t3, -12($v0)
	# Redraw left shoulder
	addi $t4, $v0, -WIDTH_ADDR
	sw $t1, 8($t4)
	sw $t3, -12($t4)
	# Redraw left pulser
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t3, -20($t4)
	sw $t2, -16($t4)
	# Redraw left remaining
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -4($t4)
	sw $t3, -12($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t3, -12($t4)
	# Redraw right shoulder
	addi $t4, $v0, WIDTH_ADDR
	sw $t1, 8($t4)
	sw $t3, -12($t4)
	# Redraw right pulser
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, 0($t4)
	sw $t3, -20($t4)
	sw $t2, -16($t4)
	# Redraw right remaining
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -4($t4)
	sw $t3, -12($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t3, -12($t4)
	j drawp_end
drawp_whole:
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
	addi $t4, $v0, WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	sw $t1, 0($t4)
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	# Draw right pulser
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -12($t4)
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	sw $t1, 0($t4)
	sw $t2, -16($t4)	# Draw that yellow dot
	# Draw right wing remaining
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t1, -8($t4)
	# Draw left shoulder
	addi $t4, $v0, -WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	sw $t1, 0($t4)
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	# Draw left pulser
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -12($t4)
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	sw $t1, 0($t4)
	sw $t2, -16($t4)
	# Draw left wing remaining
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -8($t4)
	sw $t1, -4($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t1, -8($t4)
drawp_end:
	# Free reserved variables from stack
	addi $sp, $sp, 8
	# Reset frame pointer to the previous one
	lw $fp, 0($sp)
	addi $sp, $sp, 4
	# Pop return address from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	# return;
	jr $ra
	
# This function draws the type 1 rock at (x, y) centralized. It takes 3 parameters:
# x, y, and should_erase. This function assumes that the coordinates are already shifted
# left by 1 pixel. If x is set to 122 (the right-most valid pixel), it draws an entire
# rock. If should_erase is set to 1, then it assumes that the (x, y) coordinates is not 
# shifted. 
# This function also return 1 if the rock has collided with the ship. It stores the return
# value in $v1. 
# @param const $a0, the x coordinate of the rock.
# @param const $a1, the y coordinate of the rock.
# @param const $a2, whether this function should instead erase the rock from the screen.
# @return $v1, if the a collision is detected while drawing the rock.
draw_rock1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v1, 0 # Init return value
	beq $a3, 1, drawr1_erase
	blt $a0, 122, drawr1_shift
drawr1_full: # Draw rock 1 full
	jal coor_to_addr
	# Load colors
	li $t0, BLACK
	li $t1, ROCK1
	li $t2, ROCK2
	sw $t1, 0($v0)
	sw $t1, -4($v0)
	sw $t1, 4($v0)
	sw $t2, -8($v0)
	sw $t2, 8($v0)
	addi $t4, $v0, WIDTH_ADDR
	sw $t2, 0($t4)
	sw $t2, -4($t4)
	sw $t2, 4($t4)	
	addi $t4, $t4, WIDTH_ADDR
	sw $t2, 0($t4)
	addi $t4, $v0, -WIDTH_ADDR
	sw $t2, 0($t4)
	sw $t2, -4($t4)
	sw $t2, 4($t4)	
	addi $t4, $t4, -WIDTH_ADDR
	sw $t2, 0($t4)
	j drawr1_end
drawr1_shift: # Draw rock 1 shift
	jal coor_to_addr
	# Load colors
	li $t0, BLACK
	li $t1, ROCK1
	li $t2, ROCK2
	# Test collision on nose
	lw $t3, -8($v0)
	bne $t3, $s3, no_collide1	# Here we're detecting whether the pixel this rock
				# will overwrite in this frame matches the current
				# color of the player plane.
	li $v1, 1
no_collide1: # Test end 1
	sw $t1, -4($v0)
	sw $t2, 8($v0)
	sw $t0, 12($v0)
	sw $t2, -8($v0)
	addi $t4, $v0, WIDTH_ADDR
	sw $t0, 8($t4)
	sw $t2, -4($t4)
	addi $t4, $t4, WIDTH_ADDR
	sw $t0, 4($t4)
	# Test collision on left point
	lw $t3, -4($t4)
	bne $t3, $s3, no_collide2
	li $v1, 1
no_collide2: # Test end 2
	sw $t2, 0($t4)
	addi $t4, $v0, -WIDTH_ADDR
	sw $t0, 8($t4)
	sw $t2, -4($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t0, 4($t4)
	# Test collision on right point
	lw $t3, -4($t4)
	bne $t3, RED, no_collide3
	li $v1, 1
no_collide3: # Test end 3
	sw $t2, 0($t4)
	j drawr1_end
drawr1_erase:
	jal coor_to_addr
	# Load colors
	li $t0, BLACK
	li $t1, ROCK1
	li $t2, ROCK2
	li $t3, ROCK3
	sw $t0, 0($v0)
	sw $t0, -4($v0)
	sw $t0, 4($v0)
	sw $t0, -8($v0)
	sw $t0, 8($v0)
	addi $t4, $v0, WIDTH_ADDR
	sw $t0, 0($t4)
	sw $t0, -4($t4)
	sw $t0, 4($t4)	
	addi $t4, $t4, WIDTH_ADDR
	sw $t0, 0($t4)
	addi $t4, $v0, -WIDTH_ADDR
	sw $t0, 0($t4)
	sw $t0, -4($t4)
	sw $t0, 4($t4)	
	addi $t4, $t4, -WIDTH_ADDR
	sw $t0, 0($t4)
drawr1_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# This function modifies SCORE. It takes for parameters ($a0, $a1, $a2, $a3) that stores the
# Thousands digit, hundreds digit, tens digit and ones digit of the amount of bonus score this 
# function should add to SCORE. Note: this function expects that all of the digits are less or
# equal to 1001 (9).
# @param $a0, the thousands digit of the bonus.
# @param $a1, the hundreds digit of the bonus.
# @param $a2, the tens digit of the bonus.
# @param $a3, the ones digit of the bonus.
add_score:
	# Load SCORE into $t0 to $t3
	la $t4, SCORE	# AAAABBBB CCCCDDDD
	lbu $t1, 0($t4)	# $t1 <- AAAABBBB
	lbu $t3, 1($t4)	# $t3 <- CCCCDDDD
	srl $t0, $t1, 4	# $t0 <- 0000AAAA
	srl $t2, $t3, 4	# $t2 <- 0000CCCC
	andi $t1, $t1, 15	# $t1 <- 0000BBBB
	andi $t3, $t3, 15	# $t3 <- 0000DDDD
	# Init $t5 to store which digits will have been modified.
	la $t6, SCORE_MODIFIED
	lbu $t5, 0($t6)
	beq $a3, 0, no_mod_ones
	ori $t5, $t5, 1
no_mod_ones:
	beq $a2, 0, no_mod_tens
	ori $t5, $t5, 2
no_mod_tens:
	beq $a1, 0, no_mod_hundreds
	ori $t5, $t5, 4
no_mod_hundreds:
	beq $a0, 0, no_mod_thousands
	ori $t5, $t5, 8
no_mod_thousands:
	# Add bonus to $t0 to $t3
	add $t3, $t3, $a3
	add $t2, $t2, $a2
	add $t1, $t1, $a1
	add $t0, $t0, $a0
	# Carry the digits
	blt $t3, 10, no_carry_ones
	addi $t3, $t3, -10
	addi $t2, $t2, 1
	ori $t5, $t5, 2
no_carry_ones:
	blt $t2, 10, no_carry_tens
	addi $t2, $t2, -10
	addi $t1, $t1, 1
	ori $t5, $t5, 4
no_carry_tens:
	blt $t1, 10, no_carry_hundreds
	addi $t1, $t1, -10
	addi $t0, $t0, 1
	ori $t5, $t5, 8
no_carry_hundreds:
	blt $t0, 10, no_carry_thousands
	addi $t0, $t0, -10	# After 9999, is 0000
no_carry_thousands:
	# Now, store each digit back
	sll $t0, $t0, 4	# $t0 <- AAAA0000
	sll $t2, $t2, 4	# $t2 <- CCCC0000
	or $t0, $t0, $t1	# $t0 <- AAAABBBB
	or $t2, $t2, $t3	# $t2 <- CCCCDDDD
	sb $t0, 0($t4)
	sb $t2, 1($t4)
	# Also store $t5 to SCORE_MODIFIED
	sb $t5, 0($t6)
	jr $ra
draw_ui:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
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
	# Draw "HP"
	li $a0, 6
	li $a1, 21
	li $a2, RED
	jal draw_H
	li $a0, 10
	jal draw_P
	# Draw HP bar
	li $a0, 14
	li $a1, 21
	li $a2, 10
	li $a3, RED
	jal draw_hori
	li $a1, 22
	jal draw_hori
	li $a1, 23
	jal draw_hori
	li $a1, 24
	jal draw_hori
	li $a1, 25
	jal draw_hori
	# Draw "SCORE: "
	li $a0, 83
	li $a1, 21
	li $a2, RED
	jal draw_S
	li $a0, 87
	jal draw_C
	li $a0, 91
	jal draw_O
	li $a0, 95
	jal draw_R
	li $a0, 99
	jal draw_E
	li $a0, 103
	jal draw_COLON
	# Draw " 0000"
	li $a0, 107
	jal draw_0
	li $a0, 111
	jal draw_0
	li $a0, 115
	jal draw_0
	li $a0, 119
	jal draw_0
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
draw_score:
	# Push $ra to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Push previous $fp to stack, set current $fp
	addi $sp, $sp, -4
	sw $fp, 0($sp)
	move $fp, $sp
	# Allocate memory for local variables
	addi $sp, $sp, -20
	# Load SCORE into $t0 to $t3
	la $t4, SCORE	# AAAABBBB CCCCDDDD
	lbu $t1, 0($t4)	# $t1 <- AAAABBBB
	lbu $t3, 1($t4)	# $t3 <- CCCCDDDD
	srl $t0, $t1, 4	# $t0 <- 0000AAAA
	srl $t2, $t3, 4	# $t2 <- 0000CCCC
	andi $t1, $t1, 15	# $t1 <- 0000BBBB
	andi $t3, $t3, 15	# $t3 <- 0000DDDD
	sw $t0, -4($fp)
	sw $t1, -8($fp)
	sw $t2, -12($fp)
	sw $t3, -16($fp)
	# Load SCORE_MODIFIED into $t5
	la $t6, SCORE_MODIFIED
	lbu $t5, 0($t6)
	sw $t5, -20($fp)
	# Init y coord
	li $a1, 21
	# Init color
	li $a2, RED
	
	
	andi $t7, $t5, 1
	beqz $t7, no_update_ones
	# Draw ones digit
	move $a3, $t3
	li $a0, 119
	jal draw_VOID
	jal draw_digit
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	lw $t2, -12($fp)
	lw $t5, -20($fp)
no_update_ones:
	andi $t7, $t5, 2
	beqz $t7, no_update_tens
	# Draw tens digit
	move $a3, $t2
	li $a0, 115
	jal draw_VOID
	jal draw_digit
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	lw $t5, -20($fp)
no_update_tens:
	andi $t7, $t5, 4
	beqz $t7, no_update_hundreds
	# Draw hundreds digit
	move $a3, $t1
	li $a0, 111
	jal draw_VOID
	jal draw_digit
	lw $t0, -4($fp)
	lw $t5, -20($fp)
no_update_hundreds:
	andi $t7, $t5, 8
	beqz $t7, no_update_thousands
	# Draw thousands digit
	move $a3, $t0
	li $a0, 107
	jal draw_VOID
	jal draw_digit
no_update_thousands:
	# Reset SCORE_MODIFIED to 0
	sb $zero 0($t6)
	
	# Free local variables
	addi $sp, $sp, 20
	# Load previous stack frame
	lw $fp, 0($sp)
	addi $sp, $sp, 4
	# Pop $ra from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

draw_digit:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $a3, 0, drawd0
	beq $a3, 1, drawd1
	beq $a3, 2, drawd2
	beq $a3, 3, drawd3
	beq $a3, 4, drawd4
	beq $a3, 5, drawd5
	beq $a3, 6, drawd6
	beq $a3, 7, drawd7
	beq $a3, 8, drawd8
	beq $a3, 9, drawd9
	j prog_end	# Break the program to signify an error.
drawd0:	jal draw_0
	j drawd_end
drawd1:	jal draw_1
	j drawd_end
drawd2:	jal draw_2
	j drawd_end
drawd3:	jal draw_3
	j drawd_end
drawd4:	jal draw_4
	j drawd_end
drawd5:	jal draw_5
	j drawd_end
drawd6:	jal draw_6
	j drawd_end
drawd7:	jal draw_7
	j drawd_end
drawd8:	jal draw_8
	j drawd_end
drawd9:	jal draw_9
	j drawd_end
drawd_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# ========== Draw letters and numbers ==========
draw_A:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_C:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_E:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_G:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_H:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_M:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_O:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_P:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_R:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_S:	addi $sp, $sp, -4
	sw $ra 0($sp)
	move $t8, $ra
	jal coor_to_addr
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_V:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_0:
	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_1:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_2:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_3:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_4:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_5:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_6:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_7:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_8:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_9:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_COLON:
	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	addi $v0, $v0, WIDTH_ADDR
	addi $v0, $v0, WIDTH_ADDR
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
draw_VOID:
	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	sw $zero, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	sw $zero, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	sw $zero, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	sw $zero, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	sw $zero, 8($v0)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra






