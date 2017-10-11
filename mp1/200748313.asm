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

	move	$a0, $s0
	move	$a1, $s1
	jal	rotate			# rotate(v)

	mul	$t0, $s4, 4
	la	$s2, scramble($t0)	# Get side rotation map

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

	move	$s1, $a0		# face = args[0]
	move	$s2, $a1		# direction = args[1]

	la	$s0, cube		# a = &cube
	jal	get_index		# get_index(face)
	move	$t0, $v0		# i = get_index(face)
	mul	$t0, $t0, 9		# i = i * 9
	add	$s0, $s0, $t0		# a += i

	move	$a0, $s0
	la	$a1, grid
	jal	copy

	la	$t0, grid		# Determine where to copy from grid

	bltz	$s2, ccw_o		# Check if counter-clockwise
	li	$t1, 2			# col = 2           ; start at column 3
	li	$t2, -1			# col_increment = -1; move left
	li	$t3, -1			# col_end = -1      ; until first column
	b	rol1
ccw_o:	li	$t1, 0			# col = 0           ; start at column 1
	li	$t2, 1			# col_increment = 1 ; move right
	li	$t3, 3			# col_end = 3       ; until last column

rol1:
	bltz	$s2, ccw_i		# Check if counter-clockwise
	li	$t4, 0			# row = 0           ; start at row 1
	li	$t5, 3			# row_increment = 3 ; move down rows
	li	$t6, 9			# row_end = 9       ; until last row
	b	ril1
ccw_i:	li	$t4, 6			# row = 6           ; start at row 3
	li	$t5, -3			# row_increment = -3; move up rows
	li	$t6, -3			# row_end = -3      ; until the top row
ril1:
	lb	$t7, ($t0)		# c = *grid         ; move first byte
	add	$t8, $s0, $t4
	add	$t8, $t8, $t1		# target = &cube[row][column]
	sb	$t7, ($t8)		# *target = c       ; put byte to cell

	add	$t4, $t4, $t5		# row += row_increment
	add	$t0, $t0, 1		# grid++            ; move next byte
	bne	$t4, $t6, ril1		# fill all rows in the column
					# with correct byte

	add	$t1, $t1, $t2		# col += col_increment
	bne	$t1, $t3, rol1		# fill all columns

	lw	$ra, 28($sp)
	lw	$s0, 24($sp)
	lw	$s1, 20($sp)
	lw	$s2, 16($sp)
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
q:	jr	$ra

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
	blt	$t0, 9, loop_copy
	jr	$ra


.data
scramble:	.word 0x50354213 # F
		.word 0x45235505 # R
		.word 0x40335215 # B
		.word 0x53254303 # L
		.word 0x30201000 # U
		.word 0x12223202 # D
cube:		.space 54
		.align 2
grid:		.space 9
		.align 2
actions:	.space 1000
