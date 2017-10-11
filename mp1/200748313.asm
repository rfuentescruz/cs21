.text
.macro read_string(%label, %len)
	la	$a0, %label
	add	$a1, $zero, %len
	li	$v0, 8
	syscall
.end_macro

.macro read_int(%reg)
	li	$v0, 5
	syscall
	move	%reg, $v0
.end_macro

.macro print_string(%label)
	la	$a0, %label
	li	$v0, 4
	syscall
.end_macro

.macro printc(%c)
	add	$a0, $zero, %c
	li	$v0, 11
	syscall
.end_macro

.macro print_int(%n)
	add	$a0, $zero, %n
	li	$v0, 1
	syscall
.end_macro

.macro call_swap(%gridA, %gridB, %dimA, %dimB)
	addu	$a0, $zero, %gridA
	addu	$a1, $zero, %gridB
	add	$t8, $zero, %dimA
	sb	$t8, -1($sp)
	add	$t8, $zero, %dimB
	sb	$t8, -2($sp)
	jal	swap
.end_macro

.macro get_grid_address(%reg, %grid)
	add	%reg, $zero, %grid
	mul	%reg, %reg, 9
	la	%reg, cube(%reg)
.end_macro

.macro get_row_address(%reg, %grid, %row)
	get_grid_address(%reg, %grid)
	add	$t8, $zero, %row
	mul	$t8, $t8, 3
	add	%reg, %reg, $t8
.end_macro

.macro get_column_address(%reg, %grid, %column)
	get_grid_address(%reg, %grid)
	add	%reg, %reg, %column
.end_macro

################################################################################
# main
################################################################################
main:	read_string(cube, 55)
	print_string(cube)
	printc('\n')

	read_int($s0)
	print_int($s0)
	printc('\n')

	read_string(actions, 1001)
	print_string(actions)

	la	$s1, actions
loop:	lb	$s2, ($s1)		# Load c
	beqz	$s2, end		# if c == 0, end
	beq	$s2, 10, end		# if c == '\n', end

	lb	$s3, 1($s1)		# Load c + 1
	li	$a1, 1			# Set direction = clockwise initially
	bne	$s3, '\'', next		# if (c + 1) != "'", do action immediately
	li	$a1, -1			# direction = counter-clockwise
	add	$s1, $s1, 1		# Skip next char
next:	move	$a0, $s2
	jal	action			# action(c, direction)
	add	$s1, $s1, 1
	b	loop

end:	li	$v0, 10
	syscall

################################################################################
# action(face, direction) - Perform a Rubik's cube rotation / action
#
# Params:
#   $a0 - The uppercase character representing the move
#   $a1 - 1 if clockwise, -1 if otherwise
################################################################################
action:	subu	$sp, $sp, 32
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$s4, 12($sp)
	sw	$ra, ($sp)

	move	$s0, $a0		# face = args[0]
	move	$s1, $a1		# direction = args[1]

	move	$a0, $s0
	jal	get_index		# v = get_index(face)
	move	$s4, $v0

	beq	$s0, 'H', translate_h
	beq	$s0, 'V', translate_v
	b	face_rotate

translate_h:
	li	$a0, 'U'
	li	$a1, -1
	jal	rotate			# rotate(v)
	li	$a0, 'D'
	li	$a1, 1
	jal	rotate			# rotate(v)
	b	swap_pair_start

translate_v:
	li	$a0, 'R'
	li	$a1, 1
	jal	rotate			# rotate(v)
	li	$a0, 'L'
	li	$a1, -1
	jal	rotate			# rotate(v)
	b	swap_pair_start

face_rotate:
	move	$a0, $s0
	move	$a1, $s1
	jal	rotate			# rotate(v)
	b	swap_pair_loop_end
swap_pair_start:
	mul	$t0, $s4, 4
	la	$s2, adjacents($t0)	# Get side rotation map

	li	$s3, 3			# Start with last swap pair
	bltz	$s1, swap_pair_loop
	li	$s3, 0			# Start w/ first swap pair if clockwise

swap_pair_loop:
	add	$t4, $s2, $s3
	add	$t5, $t4, $s1

	lb	$t0, ($t4)		# Get gridA index from pair
	srl	$t0, $t0, 4
	lb	$t1, ($t5)		# Get gridB index from pair
	srl	$t1, $t1, 4

	lb	$t2, ($t4)		# Get row_or_colA from pair
	and	$t2, $t2, 0x0F
	lb	$t3, ($t5)		# Get row_or_colB from pair
	and	$t3, $t3, 0x0F

	call_swap($t0, $t1, $t2, $t3)	# Swap row_or_colA with row_or_colB

	add	$s3, $s3, $s1		# Move to next swap pair
	blez	$s3, swap_pair_loop_end
	bge	$s3, 3, swap_pair_loop_end
	b	swap_pair_loop

swap_pair_loop_end:
	printc($s0)
	bltz	$s1, ccw_sw
	printc(' ')
	b	np
ccw_sw:	printc('\'')
np:	printc(':')
	printc(' ')
	print_string(cube)
	printc('\n')

	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s2, 20($sp)
	lw	$s3, 16($sp)
	lw	$s4, 12($sp)
	lw	$ra, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

################################################################################
# rotate(face, direction) - Rotate a face
#
# Params:
#   $a0 - The uppercase character representing the move
#   $a1 - 1 if clockwise, -1 if otherwise
################################################################################
rotate:					# rotate(face)
	subu	$sp, $sp, 32
	sw	$ra, 28($sp)
	sw	$s0, 24($sp)
	sw	$s1, 20($sp)
	sw	$s2, 16($sp)
	sw	$s3, 12($sp)
	sw	$s4, 8($sp)
	sw	$s5, 4($sp)
	sw	$s6, ($sp)

	move	$s1, $a0		# face = args[0]
	move	$s2, $a1		# direction = args[1]

	la	$s0, cube		# a = &cube
	move	$a0, $s0
	la	$a1, grid
	jal	copy

	move	$a0, $s1
	jal	get_index		# get_index(face)
	move	$s1, $v0		# i = get_index(face)
	mul	$s1, $s1, 9		# i = i * 9
	add	$s0, $s0, $s1		# a += i
	la	$s4, grid($s1)		# Determine where to copy from grid

	move	$t0, $s1
	move	$t1, $s1
	bgtz	$s2, clockwise
	add	$t0, $t0, 6
	b	rotate_loop
clockwise:
	add	$t0, $t0, 2
rotate_loop:
	lb	$t2, grid($t1)
	sb	$t2, cube($t0)

	mul	$t3, $t1, 4
	lw	$t3, turn_pairs($t3)
	and	$t3, $t3, 0x0000FF00
	srl	$t3, $t3, 8
	bgt	$t3, 53, no_pair
	lb	$t2, grid($t3)
	
	mul	$t3, $t0, 4
	lw	$t3, turn_pairs($t3)
	and	$t3, $t3, 0x0000FF00
	srl	$t3, $t3, 8
	bgt	$t3, 53, no_pair
	sb	$t2, cube($t3)

	mul	$t3, $t1, 4
	lw	$t3, turn_pairs($t3)
	and	$t3, $t3, 0x000000FF
	bgt	$t3, 53, no_pair
	lb	$t2, grid($t3)
	
	mul	$t3, $t0, 4
	lw	$t3, turn_pairs($t3)
	and	$t3, $t3, 0x000000FF
	bgt	$t3, 53, no_pair
	sb	$t2, cube($t3)

no_pair:
	mul	$t2, $s2, 3		# Move row up or down
	add	$t0, $t0, $t2
	add	$t1, $t1, 1		# Move copy target to next byte

	sub	$t2, $t1, $s1		# Check progress
	rem	$t2, $t2, 3
	bnez	$t2, rotate_loop

	mul	$t2, $s2, 9		# Reset back row changes
	neg	$t2, $t2
	add	$t0, $t0, $t2

	mul	$t2, $s2, 1		# Adjust column
	neg	$t2, $t2
	add	$t0, $t0, $t2
	sub	$t2, $t1, $s1
	blt	$t2, 9, rotate_loop

	lw	$ra, 28($sp)
	lw	$s0, 24($sp)
	lw	$s1, 20($sp)
	lw	$s2, 16($sp)
	lw	$s3, 12($sp)
	lw	$s4, 8($sp)
	lw	$s5, 4($sp)
	lw	$s6, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

################################################################################
# swap(grid_indexA, grid_indexB, row_or_col_A, row_or_col_B)
#
# Swap rows or columns of one grid with another.
################################################################################
swap:	subu	$sp, $sp, 8
	lb	$t0, 7($sp)		# row_or_col_A
	lb	$t1, 6($sp)		# row_or_col_B
	sw	$ra, ($sp)

	mul	$t2, $a0, 9		# grid_offsetA = grid_indexA * 9
	la	$t2, cube($t2)		# gridA = &(cube + grid_offsetA)
	bge	$t0, 3, use_colsA	# Do we use columns or rows for gridA?
	mul	$t0, $t0, 3		# Use rows: Calculate row offset
	add	$t2, $t2, $t0		# gridA = gridA + row_offset
	li	$t0, 1			# incrementA = 1
	b	choose_A_end
use_colsA:
	sub	$t0, $t0, 3		# Use columns: Calculate column index
	add	$t2, $t2, $t0		# gridA = gridA + column_index
	li	$t0, 3			# incrementA = 3
choose_A_end:

	mul	$t3, $a1, 9
	la	$t3, cube($t3)		# gridB
	bge	$t1, 3, use_colsB
	mul	$t1, $t1, 3
	add	$t3, $t3, $t1
	li	$t1, 1
	b	choose_B_end
use_colsB:
	sub	$t1, $t1, 3
	add	$t3, $t3, $t1
	li	$t1, 3
choose_B_end:

	li	$t4, 3			# i = 3
swap_loop:
	lb	$t5, ($t2)		# a = &gridA
	lb	$t6, ($t3)		# b = &gridB

	sb	$t5, ($t3)		# *gridA = b
	sb	$t6, ($t2)		# *gridB = a

	add	$t2, $t2, $t0		# gridA += incrementA
	add	$t3, $t3, $t1		# gridB += incrementB
	sub	$t4, $t4, 1		# --i
	bgtz	$t4, swap_loop		# loop if i > 0

	lw	$ra, ($sp)
	addu	$sp, $sp, 8
	jr	$ra

################################################################################
# get_index(face) - Get the index of a face in the cube representation in memory
################################################################################
get_index:
	beq	$a0, 'F', face_f
	beq	$a0, 'R', face_r
	beq	$a0, 'B', face_b
	beq	$a0, 'L', face_l
	beq	$a0, 'U', face_u
	beq	$a0, 'D', face_d
	beq	$a0, 'H', move_h
	beq	$a0, 'V', move_v
face_f:	li	$v0, 0
	b	q
face_r:	li	$v0, 1
	b	q
face_b:	li	$v0, 2
	b	q
face_l:	li	$v0, 3
	b	q
face_u:	li	$v0, 4
	b	q
face_d:	li	$v0, 5
	b	q
move_h:	li	$v0, 6
	b	q
move_v:	li	$v0, 7
q:	jr	$ra

get_turn_pairs:

################################################################################
# copy(src_address, dest_address) - Copy a grid at $a0, to $a1
################################################################################
copy:	li	$t0, 0
	move	$t1, $a0
	move	$t2, $a1

loop_copy:
	lb	$t3, ($t1)
	sb	$t3, ($t2)
	add	$t0, $t0, 1
	add	$t1, $t1, 1
	add	$t2, $t2, 1
	blt	$t0, 54, loop_copy
	jr	$ra


.data
adjacents:	.word 0x50354213 # F
		.word 0x45235505 # R
		.word 0x40335215 # B
		.word 0x53254303 # L
		.word 0x30201000 # U
		.word 0x12223202 # D
		.word 0x11213101 # H
		.word 0x24544404 # V
turn_pairs:	.word 0x00001D2A   # ['0', '29', '42']
		.word 0x00012BFF   # ['1', '43']
		.word 0x00022C09   # ['2', '44', '9']
		.word 0x000320FF   # ['3', '32']
		.word 0x0004FFFF   # ['4']
		.word 0x00050CFF   # ['5', '12']
		.word 0x00062D23   # ['6', '45', '35']
		.word 0x00072EFF   # ['7', '46']
		.word 0x00080F2F   # ['8', '15', '47']
		.word 0x0009022C   # ['9', '2', '44']
		.word 0x000A29FF   # ['10', '41']
		.word 0x000B2612   # ['11', '38', '18']
		.word 0x000C05FF   # ['12', '5']
		.word 0x000DFFFF   # ['13']
		.word 0x000E15FF   # ['14', '21']
		.word 0x000F2F08   # ['15', '47', '8']
		.word 0x001032FF   # ['16', '50']
		.word 0x00111835   # ['17', '24', '53']
		.word 0x00120B26   # ['18', '11', '38']
		.word 0x001325FF   # ['19', '37']
		.word 0x0014241B   # ['20', '36', '27']
		.word 0x00150EFF   # ['21', '14']
		.word 0x0016FFFF   # ['22']
		.word 0x00171EFF   # ['23', '30']
		.word 0x00183511   # ['24', '53', '17']
		.word 0x001934FF   # ['25', '52']
		.word 0x001A2133   # ['26', '33', '51']
		.word 0x001B1424   # ['27', '20', '36']
		.word 0x001C27FF   # ['28', '39']
		.word 0x001D2A00   # ['29', '42', '0']
		.word 0x001E17FF   # ['30', '23']
		.word 0x001FFFFF   # ['31']
		.word 0x002003FF   # ['32', '3']
		.word 0x0021331A   # ['33', '51', '26']
		.word 0x002230FF   # ['34', '48']
		.word 0x0023062D   # ['35', '6', '45']
		.word 0x00241B14   # ['36', '27', '20']
		.word 0x002513FF   # ['37', '19']
		.word 0x0026120B   # ['38', '18', '11']
		.word 0x00271CFF   # ['39', '28']
		.word 0x0028FFFF   # ['40']
		.word 0x00290AFF   # ['41', '10']
		.word 0x002A001D   # ['42', '0', '29']
		.word 0x002B01FF   # ['43', '1']
		.word 0x002C0902   # ['44', '9', '2']
		.word 0x002D2306   # ['45', '35', '6']
		.word 0x002E07FF   # ['46', '7']
		.word 0x002F080F   # ['47', '8', '15']
		.word 0x003022FF   # ['48', '34']
		.word 0x0031FFFF   # ['49']
		.word 0x003210FF   # ['50', '16']
		.word 0x00331A21   # ['51', '26', '33']
		.word 0x003419FF   # ['52', '25']
		.word 0x00351118   # ['53', '17', '24']


inversions:	.word 0x01000100
		.word 0x00010000
cube:		.space 54
		.align 2
grid:		.space 54
		.align 2
actions:	.space 1000
