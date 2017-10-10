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
	li	$a1, 0			# Set reverse = false initially
	bne	$s3, '\'', next		# if (c + 1) != "'", do action immediately
	li	$a1, 1			# reverse = true
	add	$s1, $s1, 1		# Skip next char
next:	move	$a0, $s2
	jal	action			# action(c, reverse)
	add	$s1, $s1, 1
	b	loop

end:	li	$v0, 10
	syscall
################################################################################
# end main
################################################################################


################################################################################
# action(c) - Perform a Rubik's cube rotation / action
#
# Params:
#   $a0 - The uppercase character representing the move
################################################################################
action:	subu	$sp, $sp, 32
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$ra, ($sp)

	move	$s0, $a0

	move	$a0, $s0
	jal	get_index			# v = get_index($a0)
	move	$s1, $v0			# $t0 = $a0

	move	$a0, $s0
	jal	rotate

	mul	$t0, $s1, 4
	la	$s2, scramble($t0)

	li	$s3, 0
scramble_loop:
	add	$t5, $s2, $s3

	lb	$t0, ($t5)
	srl	$t0, $t0, 4
	lb	$t1, 1($t5)
	srl	$t1, $t1, 4

	lb	$t2, ($t5)
	and	$t2, $t2, 0x0F
	lb	$t3, 1($t5)
	and	$t3, $t3, 0x0F
	call_swap($t0, $t1, $t2, $t3)

	add	$s3, $s3, 1
	blt	$s3, 3, scramble_loop

	print_string(cube)
	printc('\n')

	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s2, 20($sp)
	lw	$s3, 16($sp)
	lw	$ra, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

################################################################################
# rotate(face) - Rotate a face
#
# Params:
#   $a0 - The uppercase character representing the move
################################################################################
rotate:					# rotate(face)
	subu	$sp, $sp, 32
	sw	$ra, 28($sp)
	sw	$s0, 24($sp)
	sw	$s1, 20($sp)

	la	$s0, cube		# a = &cube
	jal	get_index		# get_index(face)
	move	$t0, $v0		# i = get_index(face)
	mul	$t0, $t0, 9		# i = i * 9
	add	$s0, $s0, $t0		# a += i

	move	$a0, $s0
	la	$a1, grid
	jal	copy

	la	$t1, grid		# g = &grid
	li	$t2, 0			# i = 0
lr1: 	lb	$t3, ($t1)		# c = *g
	add	$t1, $t1, 1		# g++
	rem	$t4, $t2, 3		# end_index = i % 3
	add	$t4, $t4, 1		# end_index++
	mul	$t4, $t4, 3		# end_index = end_index * 3
	div	$t5, $t2, 3		# offset = i / 3
	add	$t5, $t5, 1		# offset++
	sub	$t4, $t4, $t5		# end_index -= offset
	add	$t4, $s0, $t4		# end_address = &cube + end_index
	sb	$t3, ($t4)		# *end_address = c
	add	$t2, $t2, 1		# i++
	blt	$t2, 9, lr1

	add	$t0, $s0, 9
rl:	lb	$t1, ($s0)		# c = *cube
	add	$s0, $s0, 1		# cube++
	blt	$s0, $t0, rl		# if a < b, loop rl

	lw	$ra, 28($sp)
	lw	$s0, 24($sp)
	lw	$s1, 20($sp)
	addu	$sp, $sp, 32
	jr	$ra

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
################################################################################
# end copy
################################################################################

################################################################################
# swap(grid_indexA, grid_indexB, row_or_col_A, row_or_col_B)
#
# Swap rows or columns of one grid with another.
################################################################################
swap:	subu	$sp, $sp, 8
	lb	$t0, 7($sp)		# row_or_col_A
	lb	$t1, 6($sp)		# row_or_col_B
	sw	$ra, ($sp)

	mul	$t2, $a0, 9
	la	$t2, cube($t2)	# gridA
	bge	$t0, 3, use_colsA
	mul	$t0, $t0, 3
	add	$t2, $t2, $t0
	li	$t0, 1
	b	choose_A_end
use_colsA:
	sub	$t0, $t0, 3
	add	$t2, $t2, $t0
	li	$t0, 3
choose_A_end:

	mul	$t3, $a1, 9
	la	$t3, cube($t3)	# gridB
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

	li	$t4, 3
swap_loop:
	lb	$t5, ($t2)
	lb	$t6, ($t3)

	sb	$t5, ($t3)
	sb	$t6, ($t2)

	add	$t2, $t2, $t0
	add	$t3, $t3, $t1
	sub	$t4, $t4, 1	
	bgtz	$t4, swap_loop

	lw	$ra, ($sp)
	addu	$sp, $sp, 8
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
