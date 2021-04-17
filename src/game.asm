##################################################################### 
# 
# CSCB58 Winter 2021 Assembly Final Project 
# University of Toronto, Scarborough 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 4
# - Unit height in pixels: 4 
# - Display width in pixels: 512 (128 units)
# - Display height in pixels: 512 (128 units)
# - Base Address for Display: 0x10010000 (static data) 
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features) 
# 1. b. Increase the difficulty as the game progresses.
# 2. c. Scoring system.
# 3. e. Enemy ships
# 4. g. Smooth graphics (expect the Falcon cus its sprite is too complicated 
#       to be worth the effort to do the erasing & redrawing)
#
# Link to video demonstration for final submission: 
# - https://youtu.be/05O-ADgilQ4
# 
# Are you OK with us sharing the video with people outside course staff? 
# - YES, https://github.com/aquila-zyy/MIPSAssemblyGame-TESB
# 
# Any additional information that the TA needs to know: 
# - The board is too big to fit into $gp. Interferences with other chunks were observed. Therefore 
# I have to use static data to store the bit map.
# - "It's the ship that made the Kessel Run in less than twelve parsecs!" 
#####################################################################
.data	
MAP:	.word	0:16384	# The map is 128x128 = 16384 in size
# Configurables
.eqv	INIT_DIFF		5		# The initial difficulty (num_obsts)
.eqv	SPF		40		# Inverse of FPS. Millisecond per frame.
.eqv	SP_REGENERATION_DELAY	200	# Ticks before SP starts to regenerate
.eqv	SP_REGENERATION_RATE	50	# Ticks between SP regenerations
.eqv	NUM_LASERS_MAX		10	
.eqv	FIRST_WAVE		1000	# Number of ticks before the first wave of enemies
					# will spawn.
.eqv	MAX_HP			8
.eqv	MAX_SP			5

.eqv	FIRE_CD_BASE		5
.eqv	FIRE_CD_RAND		10

# Crucial global variables
OBSTS:	.byte	0:60	# struct obst {
			#     char x;
			#     char y;
			#     char speed;	// usused
			#     char alive;
			# }
			# We can have at most 10 obstacles simultaneously.

HP:	.byte	10	# This is the player's HP
HP_BAR:	.byte	43	# The x coord of the last pixel of the HP_BAR (y is 21)
SP:	.byte	5	# This is the player's Shield Point
SP_BAR:	.byte	28	# The x coord of the last pixel of the SP_BAR (y is 15)

OBSTS_END:	.word	0
			# This is an optimization. Instead of calculating the end point of the OBSTS array
			# everytime, we do it once at the begining. Furthermore it also changes with the 
			# MAX_ROCK.
LAST_DEAD:	.word	0
			# This is an optimization. Instead of performing a linear search on OBSTS array
			# every time we need to find a empty slot to spawn something (aka a "dead" item),
			# we remember the last item that is set to "dead". In case of a successful spawn,
			# we advance this variable by 1 index, and carry around to array base if it 
			# exceeds the maximum address.

ENEMIES:		.byte	0:18
			# struct enemy {
			#     char x;
			#     char y;
			#     char dirct;
			#     char move_cd
			#     char fire_cd;
			#     char isAlive
			# }
ENEMY_ENABLED:	.half	0	# This value can be positive or negative.
				# When it's negative, it represents the number of ticks before
				# a new wave of enemies will spawn.
				# After spawning a wave, this will be set to a small positive
				# number and start to countdown. Before it counts to 0, destroyed
				# enemy ships will immediately respawn.
				# After it counts to 0 again, it will be set to a random large
				# negative number.
				
NUM_ENEMIES:	.byte	0	# Number of enemies currectly on screen
LASERS:		.byte	0:30
			# struct laser {
			#     char x;
			#     char y;
			#     char isAlive;
			# }
NUM_LASERS:	.byte	0

ANIMATIONS:	.byte	0:18
			# struct animations {
			#     char x;
			#     char y;
			#     char frame_counter;
			# }
NUM_ANIMATIONS:	.byte	0



# Statistics	
SCORE:		.half	0
			# These two bytes stores the score. It uses a special structure to save
			# the effort of converting binary value to decimal value (for printing)
			# Each 4 bits represent a digit in decimal, for example:
			# 0011 1011 0000 1001 represents 3709 points. Note: each digit is never 
			# greater than 1001 (9). Note2: each digit shall be interpreted as an 
			# unsigned value.

SCORE_MODIFIED:	.byte	0
			# This stores which digits in SCORE should be updated on screen in this 
			# frame.
			
HIT:		.half	0
HIT_MODIFIED:	.byte	0
# ========== Saved Registers Usage ==========
# $s0 and $s1 are the (x, y) coordinates of the player. Try not to move them since they 
#   come quite handy as global variables.
# $s2 is the shield regeneration counter. After some ticks of not taking any damage the 
#   shield will start to regenerate 1 point in each certain interval.
# $s3 is unused.
# $s4 is number of obstacles on screen. 
# $s5 is obstacle count down (obst_cd), the delay before another obstacle should spawn.
# $s6 is the maximum number of obstacles that are allowed on screen at the same time. It
#   also serves as the difficulty value.
# $s7 is the score (in binary).
			
# Constants
.eqv	BASE_ADDRESS	0x10010000	# The top left of the map
.eqv	PLAY_ADDRESS	0x10014410	# The top left of the actual game
.eqv	WIDTH		128
.eqv	HEIGHT		128
.eqv	WIDTH_ADDR	512		# The amount of address shift between two neighbouring pixels
					# on different rows.

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

.eqv	Falcon1		0x00545454
.eqv	Falcon2		0x00c8c8c8
.eqv	Falcon3		0x00e2e2e2
.eqv	Falcon4		0x008d8db3
.eqv	Falcon5		0x0064647e

.eqv	TIE1		0x00303030
.eqv	TIE2		0x009c9c9c
.eqv	TIE3		0x00c7c7c7

.eqv	Explo0		0x00ffffff
.eqv	Explo1		0x00d7421a
.eqv	Explo2		0x00a32706

.text
.globl main
main:	# Initialize the program.
	move $fp, $sp	# Set frame pointer to the inital stack pointer.
	
restart:	
	jal initialize_everything
	jal draw_ui
	# Draw player ship
	li $s0, 5
	li $s1, 79
	li $a0, -1	# Draw all, not only the shifted.
	move $a1, $s3
	jal draw_ship
mainloop:	
	jal key_event	# This also moves the player's ship
	jal move_rocks	# This also checks rock collisions
	jal check_rock_spawn
	jal progressively_increase_difficulty
	jal check_enemy_spawning	# Show / erase warning message, spawn enemies.
	jal move_enemies	# This also handles laser spawning
	jal move_lasers	# This also checks laser collisions
	# Animations
	la $t0, NUM_ANIMATIONS
	lb $t0, 0($t0)
	beqz $t0, skip_animations
	jal move_animations	# Only one animation for now, the explosion effect.
skip_animations:
	jal handle_shield_regeneration
	# Main loop sleep, for SPF milliseconds.
	li $v0, 32
	li $a0, SPF
	syscall
	j mainloop
mainend:	
	jal draw_gameover
restart_key_detect:
	li $t9, KEY_DETECT
	lw $t8, 0($t9)
	beqz $t8, restart_key_detect	# Skip if no key is being pressed down.
	lw $t2, 4($t9)
	li $v0, 32
	li $a0, 600		# Sleep, so we don't loop too quickly.
	syscall
	bne $t2, KEY_P, restart_key_detect
	j PAINT_BLACK_SCREEN
prog_end:	# Jump here if there's an exception.
	# Terminate
	li $v0, 10
	syscall
	
# Move all rocks to the left.
# This function checks the OBSTS array and moves all "living" items to the left by 1 pixel. 
# If any item reaches the left end point of the screen, this function will set its living state
# to 0, and call draw_rock to erase it from the screen.
# This function also checks if any rock has collided with the player ship in this frame. 
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
	sb $zero, 3($t0)		# Set "alive" in rock struct to 0
	addi $s4, $s4, -1		# Decrease $s4
	la $t2, LAST_DEAD		# Set LAST_DEAD to $t0 as an optimization.
	sw $t0, 0($t2)
	li $a3, 1			# Reset "should_erase" to 1
	addi $a0, $a0, 1		# Set x coordinate back to where it was, so that
				# the draw function can erase it properly.
	sw $t0, -4($sp)		# Prepare to call draw_rock1
	sw $t1, -8($sp)
	addi $sp, $sp, -8
	jal draw_rock1
	j no_collision
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
	# Branch, if it is a TIE who should be resolved
	bne $v1, -1, collision_with_TIE
	# Redraw ship since we might have erased some part of the ship along with the rock.
	li $a0, -1
	jal draw_ship
	addi $s4, $s4, -1	# Shrink num_obst
	jal handle_damage
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 1
	jal add_hit
	jal draw_hit
	# Check if the HP is 0, jump to game over if so.
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	blez $t1, mainend
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
collision_with_TIE:
	jal handle_TIE_damage
	j no_collision
	
	
	
check_rock_spawn:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	bgtz $s5, no_spawn_yet	# Do not spwan if the countdown is not 0
	beq $s4, $s6, hold_spawn	# Hold the spawn if there're more obstacles on
				# screen than the maximum allowed number.
	jal spawn_rock
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 1
	jal add_score
	addi $s7, $s7, 1
	jal draw_score
no_spawn_yet:
	addi $s5, $s5, -1
hold_spawn:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
progressively_increase_difficulty:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $s6, 15, no_increase_difficulty	# We've only allocated 15 indices for OBSTS
	# Increase difficulty for each 32 + 5 * num_obst points the player get.
	addi $t0, $s6, -INIT_DIFF
	addi $t0, $t0, 1
	sll $t0, $t0, 5	# Multiply by 32
	mul $t1, $s4, 5
	add $t0, $t0, $t1
	blt $s7, $t0, no_increase_difficulty
	# Increase max_obst
	addi $s6, $s6, 1
	# Shift OBSTS_END
	la $t0, OBSTS_END
	lw $t1, 0($t0)
	addi $t1, $t1, 4
	sw $t1, 0($t0)
no_increase_difficulty:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
handle_shield_regeneration:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Handle shield regeneration
	bgtz $s2, no_regenerate	# Do not regenerate if shield counter > 0
	la $t0, SP
	lb $t1, 0($t0)
	bge $t1, MAX_SP, no_regenerate# Do not regenerate if shield is at max
	# Add SP += 1
	addi $t1, $t1, 1
	sb $t1, 0($t0)
	# Draw SP_BAR
	la $t0, SP_BAR
	lb $a0, 0($t0)
	addi $a0, $a0, 3
	sb $a0, 0($t0)	# Update SP_BAR endpoint
	li $a1, 15
	li $a2, 5
	li $a3, CYAN
	jal draw_vert
	addi $a0, $a0, -1
	jal draw_vert
	addi $a0, $a0, -1
	jal draw_vert
	# Load shield regeneration cool down to counter
	li $s2, SP_REGENERATION_RATE
no_regenerate:
	# If no regenerate, decrease cool down
	addi $s2, $s2, -1
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
check_enemy_spawning:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Load the enemy counter
	la $t0, ENEMY_ENABLED
	lh $t1, 0($t0)
	bltz $t1, enemy_approching_count_up	# counter < 0, enemy approching
	bgtz $t1, enemy_chasing_count_down	# counter > 0, enemy spawning
	beqz $t1, prog_end			# counter should never be 0
enemy_approching_count_up:
	addi $t3, $t1, 1
	sh $t3, 0($t0)
	blt $t3, -50, skip_enemy_spawn_only_move# Do nothing when counter < -50
	bgt $t3, -50, no_print_warning	# Don't print warning again when -50 < counter < 0	
	# Print warning when counter is -50
	# "TIE INCOMING"
	li $a0, 15
	li $a1, 9
	li $a2, YELLOW
	jal draw_T
	li $a0, 19
	jal draw_I
	li $a0, 23
	jal draw_E
	li $a0, 31
	jal draw_I
	li $a0, 35
	jal draw_N
	li $a0, 39
	jal draw_C
	li $a0, 43
	jal draw_O
	li $a0, 47
	jal draw_M
	li $a0, 51
	jal draw_I
	li $a0, 55
	jal draw_N
	li $a0, 59
	jal draw_G
no_print_warning:
	bltz $t3, skip_enemy_spawn_only_move
	# If count to 0, set it to a positive value
	addi $t1, $t1, 50
	sh $t1, 0($t0)
	j spawn_enemy_attempt
enemy_chasing_count_down:
	addi $t1, $t1, -1
	sh $t1, 0($t0)
	bgtz $t1, spawn_enemy_attempt
	# if count to 0, generate a negative number.
	li $a0, 0
	li $a1, 500
	li $v0, 42
	syscall
	sub $t2, $zero, $a0
	addi $t2, $t2, -1000
	mul $t3, $s6, 50	# Accelerate next wave base on max_obst (difficulty)
	add $t2, $t2, $t3
	sh $t2, 0($t0)
	# Paint out "TIE INCOMING"
	li $a0, 15
	li $a1, 9
	li $a2, BLACK
	jal draw_T
	li $a0, 19
	jal draw_I
	li $a0, 23
	jal draw_E
	li $a0, 31
	jal draw_I
	li $a0, 35
	jal draw_N
	li $a0, 39
	jal draw_C
	li $a0, 43
	jal draw_O
	li $a0, 47
	jal draw_M
	li $a0, 51
	jal draw_I
	li $a0, 55
	jal draw_N
	li $a0, 59
	jal draw_G
	j skip_enemy_spawn_only_move
spawn_enemy_attempt:
# Try spawn enemies
	la $t0, NUM_ENEMIES
	lb $t1, 0($t0)
	beq $t1, 3, skip_enemy_spawn_only_move	# Do not spawn if num_enemies == 3
	jal spawn_enemy
skip_enemy_spawn_only_move:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# This function handles the visual effects when player takes a hit.
# When there's shield left, deduct 1 SP from the SP bar. Otherwise, deduct
# 1 HP from the HP bar. Whichever is deducted, reset the hit_counter ($s2)
# to some value so that the shield will stop regenerating.
# Call this function repeatedly to deal more damage.
handle_damage:
	# Push $ra on stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Check SP
	la $t0, SP
	lb $t1, 0($t0)
	beqz $t1, deduct_HP
	# Deduct SP if player has SP
	addi $t1, $t1, -1
	sb $t1, 0($t0)
	la $t0, SP_BAR
	lb $a0, 0($t0)
	addi $a0, $a0, -3
	sb $a0, 0($t0)
	addi $a0, $a0, 1
	li $a1, 15
	li $a2, 5
	li $a3, BLACK
	jal draw_vert
	addi $a0, $a0, 1
	jal draw_vert
	addi $a0, $a0, 1
	jal draw_vert
	j damage_end
deduct_HP:
	# Deduct HP if SP is 0
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	addi $t1, $t1, -1	# Deduct 1
	sb $t1, 0($t0)	# Save HP value back
	# Shirnk HP bar visually
	la $t0, HP_BAR	# Load HP_BAR, the x coordinates of the last pixel of the HP bar.
	lb $a0, 0($t0)
	addi $a0, $a0, -3
	sb $a0, 0($t0)	# Update x in memory
	# Erase the last column of the HP bar
	addi $a0, $a0, 1	# Set x to what it was.
	li $a1, 21	# The pre-calculated y coordinate.
	li $a2, 5		# The height of the bar.
	li $a3, BLACK	# Paint it black.
	jal draw_vert
	addi $a0, $a0, 1	# Set x to what it was.
	jal draw_vert
	addi $a0, $a0, 1	# Set x to what it was.
	jal draw_vert 
damage_end:
	li $s2, SP_REGENERATION_DELAY	# Reset shield regeneration counter
	# Pops $ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# This function removes the hit TIE
handle_TIE_damage:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $s4, $s4, -1	# Shrink num_obst
	
	lb $t0, 5($v1)
	addi $t0, $t0, -1
	sb $t0, 5($v1)
	bgtz $t0, TIE_not_destroyed
	# If isAlive is 0
	# Visually erase it
	lb $a0, 0($v1)	# Load x
	lb $a1, 1($v1)	# Load y
	li $a2, 4		# Ask draw_TIE to erase it
	addi $sp, $sp, -4
	sw $v1, 0($sp)
	jal draw_TIE
	addi $sp, $sp, 4
	lw $v1, 0($sp)
	jal spawn_animations	# Spawn explosion effect
	# Shrink NUM_ENEMIES
	la $t0, NUM_ENEMIES
	lb $t1, 0($t0)
	addi $t1, $t1, -1
	sb $t1, 0($t0)
	# Add points
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 2
	jal add_score
	addi $s7, $s7, 2
	j TIE_damage_done
TIE_not_destroyed:
	# Redraw TIE
	lb $a0, 0($v1)
	lb $a1, 1($v1)
	li $a2, -1
TIE_damage_done:
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
	li $t6, -1
find_dead:
	addi $t6, $t6, 1
	bgt $t6, 15, prog_end
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
	li $a1, 6
	syscall
	addi, $s5, $a0, 8	# Ranges from 8 to 13
	
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

# This function spawns an enemy at the left side of the screen
spawn_enemy:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t0, ENEMIES
	addi $t1, $t0, 18
	# Find a dead enemy in ENEMIES
find_enemy_slot:
	beq $t0, $t1, found_enemy_slot
	lb $t2, 5($t0)
	addi $t0, $t0, 6
	bnez $t2, find_enemy_slot
found_enemy_slot:
	addi $t0, $t0, -6
	# Increase NUM_ENEMIES
	la $t3, NUM_ENEMIES
	lb $t4, 0($t3)
	addi $t4, $t4, 1
	sb $t4, 0($t3)
	# Init enemy in ENEMIES
	# Call RNG, decide the y coord for the enemy.
	# y = 35 + 5 * <diff_in_addr> + rand[0, 20)
	li $v0, 42
	li $a0, 0
	li $a1, 20
	syscall
	addi $a1, $a0, 35
	la $t1, ENEMIES
	sub $t2, $t0, $t1
	mul $t2, $t2, 5
	add $a1, $a1, $t2
	
	li $a0, 5
	li $t3, 3		# direction
	li $t4, 25	# move_cd
	li $t5, 25	# fire_cd
	div $t6, $s6, 2	# isAlive (or HP) is based on the current max_obst, and ranges from
			# 3 to 7.
	sb $a0, 0($t0)
	sb $a1, 1($t0)
	sb $t3, 2($t0)
	sb $t4, 3($t0)
	sb $t5, 4($t0)
	sb $t6, 5($t0)
	li $a2, -1
	move $a3, $t0
	jal draw_TIE
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# This function moves all enemies 1 pixel towords the direction determined by their "dirct" field.
move_enemies:
	# Push $ra and $fp
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $fp, 0($sp)
	move $fp, $sp
	# Allocate local variables
	addi $sp, $sp, -16
	# Set index and end condition
	la $t0, ENEMIES
	addi $t1, $t0, 18
	addi $t0, $t0, -6
search_alive_enemy:
	addi $t0, $t0, 6
	beq $t0, $t1, move_enemies_end
	lb $t2, 5($t0)
	bgt $t0, $t1, prog_end
	blez $t2, search_alive_enemy
	# If found an alive slot, then...
	lb $a0, 0($t0)		# Read x
	lb $a1, 1($t0)		# Read y
	lb $a2, 2($t0)		# Read direct
	lb $t3, 3($t0)		# Read move_cd
	lb $t4, 4($t0)		# Read fire_cd
	# Save them as local variables
	sw $t0, -4($fp)		# Current pointer
	sw $t1, -8($fp)		# End condition
	sb $a0, -9($fp)		# x coord
	sb $a1, -10($fp)		# y coord
	sb $a2, -11($fp)		# Direction
	sb $t3, -12($fp)		# move_cd
	sb $t4, -13($fp)		# fire_cd
	move $a3, $t0
move_again:
	beq $a2, 0, move_e_up
	beq $a2, 2, move_e_down
	beq $a2, 1, move_e_left
	beq $a2, 3, move_e_right
	j prog_end
move_e_up:
	# Boundary is 35 + 5 * <addr_diff>
	la $t1, ENEMIES
	sub $t2, $t0, $t1
	mul $t2, $t2, 5
	addi $t2, $t2, 35
	ble $a1, $t2, invert_movement
	addi $a1, $a1, -1
	sb $a1, -10($fp)	# Update local variable
	jal draw_TIE
	j update_enemy_data
move_e_down:
	# Boundary is 55 + 5 * <addr_diff>
	la $t1, ENEMIES
	sub $t2, $t0, $t1
	mul $t2, $t2, 5
	addi $t2, $t2, 55
	bge $a1, $t2, invert_movement
	addi $a1, $a1, 1
	sb $a1, -10($fp)	# Update local variable
	jal draw_TIE
	j update_enemy_data
move_e_left:
	# Boundary is 5
	beq $a0, 5, invert_movement
	addi $a0, $a0, -1
	sb $a0, -9($fp)	# Update local variable
	jal draw_TIE
	j update_enemy_data
move_e_right:
	# Boundary is 35
	beq $a0, 35, invert_movement
	addi $a0, $a0, 1
	sb $a0, -9($fp)	# Update local variable
	jal draw_TIE
	j update_enemy_data
invert_movement:	
	addi $a2, $a2, 2
	ble $a2, 3, confirm_invert
	addi $a2, $a2, -4
confirm_invert:
	sb $a2, 2($t0)
	sb $a2, -11($fp)	# Update local variable
	j move_again
update_enemy_data:
	#lw $t0, -4($fp)		# Current pointer
	#lw $t1, -8($fp)		# End condition
	#lb $a0, -9($fp)		# x coord
	#lb $a1, -10($fp)		# y coord
	#lb $a2, -11($fp)		# Direction
	#lb $t3, -12($fp)		# move_cd
	#lb $t4, -13($fp)		# fire_cd
	bnez $v1, crash_with_player
	# Update the new position
	lw $t0, -4($fp)
	sb $a0, 0($t0)
	sb $a1, 1($t0)
	lb $t3, -12($fp)
	bgtz $t3, no_new_direction
	# Assign a new random direction for the TIE
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	sb $a0, 2($t0)
	li $t3, 25	# Change direction again after 25 frames
	sb $t3, 3($t0)
	j handle_fire
no_new_direction:
	# Decrese move_cd
	lb $t3, -12($fp)		# move_cd
	addi $t3, $t3, -1
	sb $t3, 3($t0)
handle_fire:
	# Else: decrese $t4 and store back
	lb $t4, -13($fp)		# fire_cd
	bgtz $t4, laser_charge_countdown
	# Get num_laser
	la $t6, NUM_LASERS
	lb $t5, 0($t6)
	beq $t5, NUM_LASERS_MAX, search_alive_enemy_continue
	# Start to spawn a new laser
	lb $a0, -9($fp)
	lb $a1, -10($fp)
	jal spawn_laser
	# Reset fire_cd, RNG from 5 to 15
	li $a0, 0
	li $a1, FIRE_CD_RAND
	li $v0, 42
	syscall
	addi $t4, $a0, FIRE_CD_BASE
	lw $t0, -4($fp)	# Get currect pointer
	sb $t4, 4($t0)
	j search_alive_enemy_continue
laser_charge_countdown:
	addi $t4, $t4, -1
	lw $t0, -4($fp)	# Get currect pointer
	sb $t4, 4($t0)
	j search_alive_enemy_continue
crash_with_player:
	jal handle_damage
	jal handle_damage
	jal handle_damage
	lw $t0, -4($fp)		# Current pointer
	sb $zero, 5($t0)		# Kill the TIE fighter
	la $t1, NUM_ENEMIES
	lb $t2, 0($t1)
	addi $t2, $t2, -1
	sb $t2, 0($t1)		# Shrink NUM_ENEMIES
	lb $a0, -9($fp)		# x coord
	lb $a1, -10($fp)		# y coord
	li $a2, 4
	jal draw_TIE
	jal spawn_animations	# Spawn explosion effect
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 1
	jal add_hit
	jal draw_hit
	# Check if the HP is 0, jump to game over if so.
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	blez $t1, mainend
search_alive_enemy_continue:
	lw $t0, -4($fp)
	lw $t1, -8($fp)		# End condition
	j search_alive_enemy
move_enemies_end:
	addi $sp, $sp, 16
	lw $fp, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# This function checks how many active items are actually there in LASERS and set num_lasers
# to the correct value.
# Called by spawn_laser, when no slot is avaliable in LASERS and someone requests another
# laser to be spawned. This means there's a de-sync somewhere between the actual active lasers
# and num_lasers.
recheck_num_lasers:
	la $t0, LASERS
	li $t3, 0
recheck_active_laser:
	beq $t0, $t1, recheck_laser_done
	lb $t2, 2($t0)
	addi $t0, $t0, 3
	beqz $t2, recheck_active_laser
	addi $t3, $t3, 1
	j recheck_active_laser
recheck_laser_done:
	la $t1, NUM_LASERS
	sb $t3, 0($t1)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
spawn_laser:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t0, LASERS	# Main pointer
	li $t1, NUM_LASERS_MAX
	mul $t1, $t1, 3
	add $t1, $t0, $t1	# End condition
	addi $t0, $t0, -3
find_empty_laser:
	addi $t0, $t0, 3
	beq $t0, $t1, recheck_num_lasers	# This should never happen
	lb $t2, 2($t0)
	bnez $t2, find_empty_laser	# If not empty, loop.
	# If empty, spawn
	li $t3, 1
	sb $t3, 2($t0)	# Set to alive
	addi $a0, $a0, 6	# Set offset from TIE fighters
	sb $a0, 0($t0)	# Store x
	sb $a1, 1($t0)	# Store y
	li $a2, -1
	jal draw_laser
	# Increase num_lasers
	la $t0, NUM_LASERS
	lb $t1, 0($t0)
	addi $t1, $t1, 1
	sb $t1, 0($t0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
move_lasers:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $fp, 0($sp)
	move $fp, $sp
	addi $sp, $sp, -8	# -4($fp) is main pointer
			# -8($fp) is end condition
	la $t0, LASERS	# Main pointer
	li $t1, NUM_LASERS_MAX
	mul $t1, $t1, 3
	add $t1, $t0, $t1	# End condition
	addi $t0, $t0, -3
find_living_laser:
	addi $t0, $t0, 3
	beq $t0, $t1, move_laser_done
	lb $t2, 2($t0)
	beqz $t2, find_living_laser
	# Living laser found
	lb $a0, 0($t0)	# Read x
	lb $a1, 1($t0)
	sw $t0, -4($fp)	# Update local variables
	sw $t1, -8($fp)
	bge $a0, 122, despawn_this_laser	# Despawn if almost at right edge
	addi $a0, $a0, 3	# Don't despawn, just shift
	sb $a0, 0($t0)
	li $a2, 0
	jal draw_laser
	beqz $v1, move_laser_continue
	# If it's a hit, despawn_this_laser then redraw the ship. Also add hit count
	lw $t0, -4($fp)
	sb $zero 2($t0)	# Set dead
	li $a2, 1		# Set erase
	jal draw_laser
	# Decrease num_lasers
	la $t0, NUM_LASERS
	lb $t1, 0($t0)
	addi $t1, $t1, -1
	sb $t1, 0($t0)
	li $a0, -1
	jal draw_ship
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 1
	jal add_hit
	jal draw_hit
	jal handle_damage
	# Check if the HP is 0, jump to game over if so.
	la $t0, HP	# Load HP address into $t0
	lb $t1, 0($t0)	# Load HP value into $t1
	blez $t1, mainend
	j move_laser_continue
despawn_this_laser:
	lw $t0, -4($fp)	# Load main pointer
	sb $zero 2($t0)	# Set dead
	li $a2, 1		# Set erase
	jal draw_laser
	# Decrease num_lasers
	la $t0, NUM_LASERS
	lb $t1, 0($t0)
	addi $t1, $t1, -1
	sb $t1, 0($t0)
	j move_laser_continue
move_laser_continue:
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	j find_living_laser
move_laser_done:
	addi $sp, $sp, 8
	lw $fp, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# This function spawns an animation at ($a0, $a1).
# Unlike other spawn functions, this function does check NUM_ANIMATIONS before trying to 
# spawn a new one.
spawn_animations:
	la $t0, NUM_ANIMATIONS
	lb $t0, 0($t0)
	blt $t0, 3, confirm_spawn_animation
	jr $ra
confirm_spawn_animation:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t0, ANIMATIONS
find_slot_animation:
	lb $t1, 2($t0)
	beqz $t1, found_slot_animation
	addi $t0, $t0, 3
	j find_slot_animation
found_slot_animation:
	# Set frame to 1
	li $t1, 1
	sb $t1, 2($t0)
	# Set x, y
	sb $a0, 0($t0)
	sb $a1, 1($t0)
	# Increse num_animations
	la $t0, NUM_ANIMATIONS
	lb $t1, 0($t0)
	addi $t1, $t1, 1
	sb $t1, 0($t0)
	# Return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra 	

move_animations:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $fp, 0($sp)
	move $fp, $sp
	addi $sp, $sp, -8
	
	la $t0, ANIMATIONS	# Main pointer
	addi $t1, $t0, 18	# End condition
find_active_animation:
	lb $t2, 2($t0)
	bgtz $t2, found_active_animation
	addi $t0, $t0, 3
	beq $t0, $t1, move_animations_end
	j find_active_animation
found_active_animation:
	# Store in frame
	sw $t0, -4($fp)
	sw $t1, -8($fp)
	lb $a0, 0($t0)
	lb $a1, 1($t0)
	move $a2, $t2
	jal draw_explosion_effect	# Draw the frame
	# Load from frame
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	# Advance the frame counter
	addi $a2, $a2, 1
	ble $a2, 6, animation_no_reset
	li $a2, 0	# Reset to 0 if completed
	la $t3, NUM_ANIMATIONS	# Decrese num_animations
	lb $t4, 0($t3)
	addi $t4, $t4, -1
	sb $t4, 0($t3)
animation_no_reset:
	sb $a2, 2($t0)
	# Advance pointer
	addi $t0, $t0, 3
	beq $t0, $t1, move_animations_end
	j find_active_animation
move_animations_end:
	addi $sp, $sp, 8
	lw $fp, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra 		

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

# This function reads global variable $s0, $s1, and draws the player ship at ($s0, $s1) centralized. 
# It takes two parameters: movement($a0) and color($a1). Set movement to -1 to draw an entire ship. 
# Set movement to 0, 1, 2, or 3 to indicate the ship has moved towards up, down, left, or right, respectively. 
# This function only draws the difference between two frames if possible. Therefore simply changing the color
# on the fly would cause 
# @param const $a0, the direction that the ship has moved since the last frame.
# @param const $a1, the color of the main part of the ship.
draw_ship:
	j draw_falcon
	
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
# @return $v1, the address of the object which this rock bumped into, if any. 0 otherwise.
draw_rock1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $fp, 0($sp)
	move $fp, $sp
	addi $sp, $sp, -16
	li $t0, BLACK
	li $t1, ROCK1
	li $t2, ROCK2
	sw $t0, -4($fp)
	sw $t1, -8($fp)
	sw $t2, -12($fp)
	beq $a3, 1, drawr1_erase
	blt $a0, 122, drawr1_shift
drawr1_full: # Draw rock 1 full
	jal coor_to_addr
	# Load colors
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	lw $t2, -12($fp)
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
	li $v1, 0 # Init return value
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	lw $t2, -12($fp)
	# Test collision on nose
	lw $t3, -8($v0)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	jal test_object_collision
	addi $sp, $sp, 4
	# Test end
	lw $t0, -4($fp)
	lw $t1, -8($fp)
	lw $t2, -12($fp)
	# Reload complete
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
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	jal test_object_collision
	addi $sp, $sp, 4
	# Test end
	lw $t0, -4($fp)
	lw $t2, -12($fp)
	# Reload complete
	sw $t2, 0($t4)
	addi $t4, $v0, -WIDTH_ADDR
	sw $t0, 8($t4)
	sw $t2, -4($t4)
	addi $t4, $t4, -WIDTH_ADDR
	sw $t0, 4($t4)
	# Test collision on right point
	lw $t3, -4($t4)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	jal test_object_collision
	addi $sp, $sp, 4
	# Test end
	lw $t2, -12($fp)
	# Reload complete
	sw $t2, 0($t4)
	j drawr1_end
drawr1_erase:
	jal coor_to_addr
	sw $zero, 0($v0)
	sw $zero, -4($v0)
	sw $zero, 4($v0)
	sw $zero, -8($v0)
	sw $zero, 8($v0)
	addi $t4, $v0, WIDTH_ADDR
	sw $zero, 0($t4)
	sw $zero, -4($t4)
	sw $zero, 4($t4)	
	addi $t4, $t4, WIDTH_ADDR
	sw $zero, 0($t4)
	addi $t4, $v0, -WIDTH_ADDR
	sw $zero, 0($t4)
	sw $zero, -4($t4)
	sw $zero, 4($t4)	
	addi $t4, $t4, -WIDTH_ADDR
	sw $zero, 0($t4)
drawr1_end:
	addi $sp, $sp, 16
	lw $fp, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# A helper function to detect collision.
test_object_collision:
	bnez $v1, already_found
	lw $t0, 0($sp)
	beqz $t0, no_collision_possible
	beq $t0, Falcon1, is_player	# Falcon cockpit
	beq $t0, Falcon2, is_player	# Falcon outline
	beq $t0, Falcon3, is_player	# Falcon light grey
	beq $t0, Falcon4, is_player	# Falcon light blue
	beq $t0, Falcon5, is_player	# Falcon dark blue
	j not_player
is_player:
	# Is player
	li $v1, -1
	jr $ra
not_player:
	#lw $t0, 0($sp)	# $t0 = actual color
	li $t1, TIE2	# Base color
	sub $t2, $t1, $t0	# $t2 = Address offset = base - actual
	bltz $t2, no_collision_possible	# Ignore TIE3 color
	bge $t2, 18, collision_exception	# Error if offset >18
	la $t3, ENEMIES	# Bass address
	add $v1, $t3, $t2
	jr $ra
no_collision_possible:
already_found:
	jr $ra
collision_exception:
	beq $t0, TIE1, no_collision_possible	# Ignore TIE1 color
	beq $t0, GREEN, no_collision_possible	# Ignore lasers
	beq $t0, Explo0, no_collision_possible	# Ignore explosions
	beq $t0, Explo1, no_collision_possible	# Ignore explosions
	beq $t0, Explo2, no_collision_possible	# Ignore explosions
	j prog_end
	
	
# This function modifies SCORE. It takes for parameters ($a0, $a1, $a2, $a3) that stores the
# Thousands digit, hundreds digit, tens digit and ones digit of the amount of bonus score this 
# function should add to SCORE. Note: this function expects that all of the digits are less or
# equal to 1001 (9).
# @param $a0, the thousands digit of the bonus.
# @param $a1, the hundreds digit of the bonus.
# @param $a2, the tens digit of the bonus.
# @param $a3, the ones digit of the bonus.
add_score:
	la $t4, SCORE
	la $t6, SCORE_MODIFIED
	j add_to_digit
add_hit:
	la $t4, HIT
	la $t6, HIT_MODIFIED
	j add_to_digit

add_to_digit:
	# Load old digits into $t0 to $t3
	lbu $t1, 0($t4)	# $t1 <- AAAABBBB
	lbu $t3, 1($t4)	# $t3 <- CCCCDDDD
	srl $t0, $t1, 4	# $t0 <- 0000AAAA
	srl $t2, $t3, 4	# $t2 <- 0000CCCC
	andi $t1, $t1, 15	# $t1 <- 0000BBBB
	andi $t3, $t3, 15	# $t3 <- 0000DDDD
	# Init $t5 to store which digits will have been modified.
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
	beq $t2, KEY_P, ke_p
	j key_end		# Skip if the key being pressed down isn't functional.
ke_d:	bge $s0, 122, key_end # Skip if x is already at right border
	# Update coordinates
	addi $s0, $s0, 1
	li $a0, 3
	move $a1, $s3
	jal draw_ship
	j key_end
ke_a:	ble $s0, 5, key_end # Skip if x is already at left border
	# Update coordinates
	addi $s0, $s0, -1
	li $a0, 2
	move $a1, $s3
	jal draw_ship
	j key_end
ke_s:	bge $s1, 122, key_end # Skip if y is already at bottom border
	# Update coordinates
	addi $s1, $s1, 1
	li $a0, 1
	move $a1, $s3
	jal draw_ship
	j key_end
ke_w:	ble $s1, 35, key_end # Skip if y is already at top border
	# Update coordinates
	addi $s1, $s1, -1
	li $a0, 0
	move $a1, $s3
	jal draw_ship
	j key_end
ke_p:	addi $sp, $sp, 4
	j PAINT_BLACK_SCREEN
key_end:	# Pop back $ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
draw_ui:
	# Draw the white-greyish frame
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
	# Draw the rounded corners
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
	li $a2, MAX_HP
	mul $a2, $a2, 3
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
	# Draw "SP"
	li $a0, 6
	li $a1, 15
	li $a2, CYAN
	jal draw_S
	li $a0, 10
	jal draw_P
	# Draw SP bar
	li $a0, 14
	li $a1, 15
	li $a2, MAX_SP
	mul $a2, $a2, 3
	li $a3, CYAN
	jal draw_hori
	li $a1, 16
	jal draw_hori
	li $a1, 17
	jal draw_hori
	li $a1, 18
	jal draw_hori
	li $a1, 19
	jal draw_hori
	# Draw "HIT: "
	li $a0, 91
	li $a1, 15
	li $a2, RED
	jal draw_H
	li $a0, 95
	jal draw_I
	li $a0, 99
	jal draw_T
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
	
draw_gameover:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
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
	jal draw_score_gameover
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

draw_score_gameover:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t4, SCORE
	li $a1, 70
	lbu $t1, 0($t4)	# $t1 <- AAAABBBB
	lbu $t3, 1($t4)	# $t3 <- CCCCDDDD
	srl $t6, $t1, 4	# $t0 <- 0000AAAA
	srl $t8, $t3, 4	# $t2 <- 0000CCCC
	andi $t7, $t1, 15	# $t1 <- 0000BBBB
	andi $t9, $t3, 15	# $t3 <- 0000DDDD
	li $a2, YELLOW
	li $a0, 56
	move $a3, $t6
	jal draw_digit
	li $a0, 60
	move $a3, $t7
	jal draw_digit
	li $a0, 64
	move $a3, $t8
	jal draw_digit
	li $a0, 68
	move $a3, $t9
	jal draw_digit
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
		
draw_score:
	la $t4, SCORE
	la $t6, SCORE_MODIFIED
	li $a1, 21
	j draw_statistics
draw_hit:
	la $t4, HIT
	la $t6, HIT_MODIFIED
	li $a1, 15
	j draw_statistics
draw_statistics:
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
	lbu $t5, 0($t6)
	sw $t5, -20($fp)
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
	j prog_end
drawd_end:
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
draw_I:	addi $sp, $sp, -4
	sw $ra 0($sp)
	move $t8, $ra
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
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
draw_N:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 0($v0)
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
draw_T:	addi $sp, $sp, -4
	sw $ra 0($sp)
	jal coor_to_addr
	sw $a2, 0($v0)
	sw $a2, 4($v0)
	sw $a2, 8($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
	sw $a2, 4($v0)
	addi $v0, $v0, WIDTH_ADDR
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
	

# Falcon
# @param  $a0, 0=up, 1=down, 2=left, 3=right
draw_falcon:
	add $sp, $sp, -8
	sw $ra, 4($sp)
	sw $a0, 0($sp)
	move $a0, $s0
	move $a1, $s1
	jal coor_to_addr
	
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	move $t0, $v0
	beq $a0, 0, deltaf_up
	beq $a0, 1, deltaf_down
	beq $a0, 2, deltaf_left
	beq $a0, 3, deltaf_right
	beq $a0, -1, falcon_draw
	j prog_end	# Break program to signify an error
deltaf_up:
	sw $zero, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, -16($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, -8($t0)
	sw $zero, -12($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 0($t0)
	sw $zero, -4($t0)
	j falcon_draw
deltaf_down:
	sw $zero, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 12($t0)
	addi $t0, $v0, -WIDTH_ADDR
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -16($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -12($t0)
	sw $zero, 8($t0)
	sw $zero, 4($t0)
	sw $zero, -8($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 0($t0)
	sw $zero, -4($t0)
	j falcon_draw
deltaf_left:
	sw $zero, 16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 20($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 12($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 12($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 4($t0)
	addi $t0, $v0, WIDTH_ADDR
	sw $zero, 20($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 12($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 4($t0)
	j falcon_draw
deltaf_right:
	sw $zero, -20($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -20($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, -8($t0)
	addi $t0, $v0, WIDTH_ADDR
	sw $zero, -20($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, -16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, -16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, -8($t0)
	j falcon_draw
falcon_draw:
	li $t1, Falcon1	# Border black
	li $t2, Falcon2	# Dark grey
	
	li $t4, Falcon3	# Light grey
	li $t5, Falcon5	# Dark blue
	li $t6, Falcon4	# Light blue
	
	move $t0, $v0	
	sw $t5, 0($t0)
	sw $t2, 4($t0)
	sw $t6, 8($t0)
	sw $t6, 12($t0)
	sw $t6, -4($t0)
	sw $t4, -8($t0)
	sw $t4, -12($t0)
	sw $t2, -16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t5, 0($t0)
	sw $t4, 4($t0)
	sw $t4, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t6, -4($t0)
	sw $t4, -8($t0)
	sw $t6, -12($t0)
	sw $t2, -16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t5, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t6, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t5, 0($t0)
	sw $t6, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, -4($t0)
	# Another side
	addi $t0, $v0, WIDTH_ADDR
	sw $t1, 0($t0)
	sw $t4, 4($t0)
	sw $t4, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	sw $t6, -4($t0)
	sw $t4, -8($t0)
	sw $t6, -12($t0)
	sw $t2, -16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t5, 0($t0)
	sw $t1, 4($t0)
	sw $t2, 8($t0)
	sw $t6, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t5, 0($t0)
	sw $t2, 4($t0)
	sw $t1, 8($t0)
	sw $t2, 12($t0)
	sw $t6, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, -4($t0)
	sw $t2, 0($t0)
falcon_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	

# This function draws a TIE fighter at ($a0, $a1). If $a2 = -1, it draws an entire TIE fighter.
# Otherwise, it shifts the sprite towards up, down, left, or right if $a2 is set to 0, 2, 1, 3,
# respectively. Set $a2 to 4 to erase all from the board.
# @param const $a0, the x coordinate of the TIE fighter.
# @param const $a1, the y coordinate of the TIE fighter.
# @param const $a2, how should the function draw this fighter.
# @param const $a3, the address of the struct of this TIE fighter. Not needed when in mode 4.
draw_TIE:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal coor_to_addr
	li $v1, 0
	jal detect_collision_TIE
	li $t1, TIE2
	li $t2, TIE2
	la $t4, ENEMIES
	sub $t4, $a3, $t4
	sub $t2, $t2, $t4
	li $t3, TIE3
	beq $a2, -1, TIE_ALL
	beq $a2, 0, TIE_UP
	beq $a2, 2, TIE_DOWN
	beq $a2, 1, TIE_LEFT
	beq $a2, 3, TIE_RIGHT
	beq $a2, 4, TIE_ERASE
	j prog_end	# Signify error
TIE_UP:	
	sw $t1, 0($v0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	sw $zero, -8($t0)
	sw $zero, -12($t0)
	sw $zero, -16($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	sw $t2, -16($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t2, 0($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero -4($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, WIDTH_ADDR
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	sw $t2, -16($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $zero, 0($t0)
	sw $zero, -4($t0)
	sw $zero, -8($t0)
	sw $zero, -12($t0)
	sw $zero, -16($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	j TIE_end
TIE_DOWN:	
	sw $t1, 0($v0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, WIDTH_ADDR
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	sw $zero, -8($t0)
	sw $zero, -12($t0)
	sw $zero, -16($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	sw $t2, -16($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t2, 0($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero -4($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, -4($t0)
	sw $t2, -8($t0)
	sw $t2, -12($t0)
	sw $t2, -16($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $zero, 0($t0)
	sw $zero, -4($t0)
	sw $zero, -8($t0)
	sw $zero, -12($t0)
	sw $zero, -16($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	j TIE_end
TIE_LEFT:
	sw $t1, 0($v0)
	sw $t2, -4($v0)
	sw $t2, 4($v0)
	sw $zero, 8($v0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t2, -4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, -16($t0)
	sw $zero, 20($t0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t2, -4($t0)
	sw $zero, 8($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, 4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, -16($t0)
	sw $zero, 20($t0)
	j TIE_end
TIE_RIGHT:
	sw $t1, 0($v0)
	sw $t2, 4($v0)
	sw $t2, -4($v0)
	sw $zero, -8($v0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t2, 4($t0)
	sw $zero, -8($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, 16($t0)
	sw $zero, -20($t0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t2, 4($t0)
	sw $zero, -8($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	sw $zero, -4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, 16($t0)
	sw $zero, -20($t0)
	j TIE_end
TIE_ALL:	
	sw $t1, 0($v0)
	sw $t2, 4($v0)
	sw $t2, -4($v0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, -4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, -16($t0)
	sw $t2, -12($t0)
	sw $t2, -8($t0)
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, -4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, -16($t0)
	sw $t2, -12($t0)
	sw $t2, -8($t0)
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	j TIE_end
TIE_ERASE:
	li $t1, 0
	li $t2, 0
	li $t3, 0
	sw $t1, 0($v0)
	sw $t2, 4($v0)
	sw $t2, -4($v0)
	addi $t0, $v0, WIDTH_ADDR
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, -4($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, WIDTH_ADDR
	sw $t2, -16($t0)
	sw $t2, -12($t0)
	sw $t2, -8($t0)
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
	addi $t0, $v0, -WIDTH_ADDR
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	sw $t2, -4($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t3, 0($t0)
	addi $t0, $t0, -WIDTH_ADDR
	sw $t2, -16($t0)
	sw $t2, -12($t0)
	sw $t2, -8($t0)
	sw $t2, -4($t0)
	sw $t2, 0($t0)
	sw $t2, 4($t0)
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 16($t0)
TIE_end:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

detect_collision_TIE:
	addi $t0, $v0, -2048
	addi $t1, $t0, 16
	addi $t0, $t0, -16
	addi $t2, $v0, 2048
	addi $t3, $t2, 16
	addi $t2, $t2, -16
	lw $t0, 0($t0)
	lw $t1, 0($t1)
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	beq $t0, Falcon1, ship_crash
	beq $t1, Falcon1, ship_crash
	beq $t2, Falcon1, ship_crash
	beq $t3, Falcon1, ship_crash
	beq $t0, Falcon2, ship_crash
	beq $t1, Falcon2, ship_crash
	beq $t2, Falcon2, ship_crash
	beq $t3, Falcon2, ship_crash
	beq $t0, Falcon3, ship_crash
	beq $t1, Falcon3, ship_crash
	beq $t2, Falcon3, ship_crash
	beq $t3, Falcon3, ship_crash
	beq $t0, Falcon4, ship_crash
	beq $t1, Falcon4, ship_crash
	beq $t2, Falcon4, ship_crash
	beq $t3, Falcon4, ship_crash
	beq $t0, Falcon5, ship_crash
	beq $t1, Falcon5, ship_crash
	beq $t2, Falcon5, ship_crash
	beq $t3, Falcon5, ship_crash
	j no_ship_crash
ship_crash:
	li $v1, 1
no_ship_crash:
	jr $ra

draw_laser:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal coor_to_addr
	li $t1, GREEN
	beq $a2, -1, draw_full_laser
	beq $a2, 0, shift_laser
	beq $a2, 1, erase_laser
	j prog_end
draw_full_laser:
	sw $t1, -4($v0)
	sw $t1, 0($v0)
	sw $t1, 4($v0)
	j draw_laser_done
shift_laser:
	jal detect_laser_hit
	li $t1, GREEN
	sw $t1, -4($v0)
	sw $t1, 0($v0)
	sw $t1, 4($v0)
	sw $zero, -8($v0)
	sw $zero, -12($v0)
	sw $zero, -16($v0)
	j draw_laser_done
erase_laser:
	sw $zero, -4($v0)
	sw $zero, 0($v0)
	sw $zero, 4($v0)
	j draw_laser_done
draw_laser_done:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
detect_laser_hit:
	li $v1, 0
	lw $t0, 8($v0)
	lw $t1, 12($v0)
	lw $t2, 16($v0)
	beq $t0, Falcon1, ship_hit
	beq $t1, Falcon1, ship_hit
	beq $t2, Falcon1, ship_hit
	beq $t0, Falcon2, ship_hit
	beq $t1, Falcon2, ship_hit
	beq $t2, Falcon2, ship_hit
	beq $t0, Falcon3, ship_hit
	beq $t1, Falcon3, ship_hit
	beq $t2, Falcon3, ship_hit
	beq $t0, Falcon4, ship_hit
	beq $t1, Falcon4, ship_hit
	beq $t2, Falcon4, ship_hit
	beq $t0, Falcon5, ship_hit
	beq $t1, Falcon5, ship_hit
	beq $t2, Falcon5, ship_hit
	jr $ra
ship_hit:
	li $v1, 1
	jr $ra
	
# This function draws explosion effects.
# @param const $a0, the x coordinate of the effect.
# @param const $a1, the y coordinate of the effect.
# @param const $a2, the frame of the effect.
draw_explosion_effect:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal coor_to_addr
	li $t0, Explo0
	li $t1, Explo1
	li $t2, Explo2
	beq $a2, 6, explo_f6
explo_f1:	sw $t0, 0($v0)
	sw $t1, -4($v0)
	sw $t1, 4($v0)
	sw $t1, 512($v0)
	sw $t1, -512($v0)
	sw $t2, 508($v0)
	sw $t2, 516($v0)
	sw $t2, -516($v0)
	sw $t2, -508($v0)
	beq $a2, 1, explo_fe
explo_f2:	sw $t2, -1024($v0)
	sw $t2, -1032($v0)
	sw $t2, -1016($v0)
	sw $t2, -8($v0)
	sw $t2, 8($v0)
	sw $t2, 1024($v0)
	sw $t2, 1032($v0)
	sw $t2, 1016($v0)
	beq $a2, 2, explo_fe
explo_f3:	sw $t0, 4($v0)
	sw $t0, -4($v0)
	sw $t0, 512($v0)
	sw $t0, -512($v0)
	sw $t1, 508($v0)
	sw $t1, 516($v0)
	sw $t1, -508($v0)
	sw $t1, -516($v0)
	sw $t1, 504($v0)
	sw $t1, 520($v0)
	sw $t1, -504($v0)
	sw $t1, -520($v0)
	sw $t1, 1020($v0)
	sw $t1, 1028($v0)
	sw $t1, -1020($v0)
	sw $t1, -1028($v0)
	sw $t2, 1540($v0)
	sw $t2, 1532($v0)
	sw $t2, -1540($v0)
	sw $t2, -1532($v0)
	sw $t2, 524($v0)
	sw $t2, 500($v0)
	sw $t2, -524($v0)
	sw $t2, -500($v0)
	beq $a2, 3, explo_fe
explo_f4:	sw $t1, 8($v0)
	sw $t1, -8($v0)
	sw $t2, 12($v0)
	sw $t2, -12($v0)
	addi $t3, $v0, WIDTH_ADDR
	sw $t2, 16($t3)
	sw $t2, -16($t3)
	addi $t3, $t3, 1024
	sw $t2, 0($t3)
	sw $t2, 12($t3)
	sw $t2, -12($t3)
	addi $t3, $t3, WIDTH_ADDR
	sw $t2, 4($t3)
	sw $t2, -4($t3)
	# The other side
	addi $t3, $v0, -WIDTH_ADDR
	sw $t2, 16($t3)
	sw $t2, -16($t3)
	addi $t3, $t3, -1024
	sw $t2, 0($t3)
	sw $t2, 12($t3)
	sw $t2, -12($t3)
	addi $t3, $t3, -WIDTH_ADDR
	sw $t2, 4($t3)
	sw $t2, -4($t3)
	beq $a2, 4, explo_fe
explo_f5:	addi $t3, $v0, 1024
	sw $t2, 20($t3)
	sw $t2, -20($t3)
	addi $t3, $t3, 1024
	sw $t2, 16($t3)
	sw $t2, -16($t3)
	sw $t2, 520($t3)
	sw $t2, 504($t3)
	# The other side
	addi $t3, $v0, -1024
	sw $t2, 20($t3)
	sw $t2, -20($t3)
	addi $t3, $t3, -1024
	sw $t2, 16($t3)
	sw $t2, -16($t3)
	sw $t2, -520($t3)
	sw $t2, -504($t3)
	j explo_fe
explo_f6:
	li $t0, 0
	li $t1, 0
	li $t2, 0
	j explo_f1
explo_fe:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
initialize_everything:
	# Init OBSTS, LAST_DEAD, OBSTS_END
	la $t0, OBSTS	# Set LAST_DEAD to the first item in OBSTS
	la $t1, LAST_DEAD
	sw $t0, 0($t1)
	la $t2, OBSTS_END
	li $t1, INIT_DIFF	# Calculate the end address of the OBSTS array.
	sll $t1, $t1, 2	# Times 4, since each obst struct takes 4 bytes.
	add $t1, $t1, $t0	# Add the starting address
	sw $t1, 0($t2)
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	sw $zero, 20($t0)
	sw $zero, 24($t0)
	sw $zero, 28($t0)
	sw $zero, 32($t0)
	sw $zero, 36($t0)
	sw $zero, 40($t0)
	sw $zero, 44($t0)
	sw $zero, 48($t0)
	sw $zero, 52($t0)
	sw $zero, 56($t0)
	
	# Init SCORE, HIT, HP, HP_BAR, SP, SP_BAR
	la $t0, SCORE
	sh $zero, 0($t0)
	la $t0, HIT
	sh $zero, 0($t0)
	la $t0, HP
	li $t1, MAX_HP
	sb $t1, 0($t0)
	la $t0, HP_BAR
	li $t2, 13
	mul $t1, $t1, 3
	add $t1, $t1, $t2
	sb $t1, 0($t0)
	la $t0, SP
	li $t1, MAX_SP
	sb $t1, 0($t0)
	la $t0, SP_BAR
	li $t2, 13
	mul $t1, $t1, 3
	add $t1, $t1, $t2
	sb $t1, 0($t0)
	
	# Init regeneration cd, max_obst, binary score.
	li $s2, SP_REGENERATION_DELAY
	li $s6, INIT_DIFF
	li $s7, 0
	
	# Init ENEMIES, ENEMY_ENABLED, NUM_ENEMIES
	la $t0, ENEMIES
	sb $zero, 0($t0)
	sb $zero, 1($t0)
	sb $zero, 2($t0)
	sb $zero, 3($t0)
	sb $zero, 4($t0)
	sb $zero, 5($t0)
	sb $zero, 6($t0)
	sb $zero, 7($t0)
	sb $zero, 8($t0)
	sb $zero, 9($t0)
	sb $zero, 10($t0)
	sb $zero, 11($t0)
	sb $zero, 12($t0)
	sb $zero, 13($t0)
	sb $zero, 14($t0)
	sb $zero, 15($t0)
	sb $zero, 16($t0)
	sb $zero, 17($t0)
	la $t0, ENEMY_ENABLED
	li $t1, -FIRST_WAVE
	sh $t1, 0($t0)
	la $t0, NUM_ENEMIES
	sb $zero, 0($t0)
	
	# Init LASERS, NUM_LASERS
	la $t0, LASERS
	sb $zero, 0($t0)
	sb $zero, 1($t0)
	sb $zero, 2($t0)
	sb $zero, 3($t0)
	sb $zero, 4($t0)
	sb $zero, 5($t0)
	sb $zero, 6($t0)
	sb $zero, 7($t0)
	sb $zero, 8($t0)
	sb $zero, 9($t0)
	sb $zero, 10($t0)
	sb $zero, 11($t0)
	sb $zero, 12($t0)
	sb $zero, 13($t0)
	sb $zero, 14($t0)
	sb $zero, 15($t0)
	sb $zero, 16($t0)
	sb $zero, 17($t0)
	la $t0, NUM_LASERS
	sb $zero, 0($t0)
	
	# Init ANIMATIONS, NUM_ANIMATIONS
	la $t0, ANIMATIONS
	sb $zero, 0($t0)
	sb $zero, 1($t0)
	sb $zero, 2($t0)
	sb $zero, 3($t0)
	sb $zero, 4($t0)
	sb $zero, 5($t0)
	sb $zero, 6($t0)
	sb $zero, 7($t0)
	sb $zero, 8($t0)
	sb $zero, 9($t0)
	sb $zero, 10($t0)
	sb $zero, 11($t0)
	sb $zero, 12($t0)
	sb $zero, 13($t0)
	sb $zero, 14($t0)
	sb $zero, 15($t0)
	sb $zero, 16($t0)
	sb $zero, 17($t0)
	la $t0, NUM_ANIMATIONS
	sb $zero, 0($t0)
	# Init obst_cd
	li $s5, 25
	# Init num_obst to 0
	li $s4, 0
	# Init score
	li $s7, 0
	jr $ra
	
# This function paints out the entire screen and jumps the the beginning of the program.
PAINT_BLACK_SCREEN:
	li $a0, 0
	li $a1, 0
	li $a2, 128
	li $a3, 0
PAINTB_NEXT:
	jal draw_hori
	addi $a1, $a1, 1
	blt $a1, 128, PAINTB_NEXT
	
	j restart
