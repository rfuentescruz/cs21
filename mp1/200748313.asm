# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 10/12/17
# 200748313.asm -- A Rubik's cube face solver

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
.macro readc(%reg)
	li	$v0, 12
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

.macro call_move_cell(%to, %from)
	add	$a0, $zero, %to
	add	$a1, $zero, %from
	jal	move_cell
.end_macro

.macro do_action(%action, %direction)
	add	$a0, $zero, %action
	add	$a1, $zero, %direction
	jal	action
.end_macro

################################################################################
# main
################################################################################
main:
	la	$t0, action_pointer
	la	$t1, actions
	sw	$t1, ($t0)

	read_string(cube, 55)
	read_int($s0)
	beqz	$s0, free_mode

	readc($s4)
	move	$a0, $s4
	jal	orient_cube
	move	$a0, $s4
	jal	solve_corners
	move	$a0, $s4
	jal	solve_cross

	print_string(actions)
	b	exit

free_mode:
	read_string(actions, 1001)
	la	$s1, actions
free_mode_loop:
	lb	$s2, ($s1)		# Load c
	beqz	$s2, free_mode_end	# if c == 0, free_mode_end
	beq	$s2, 10, free_mode_end	# if c == '\n', free_mode_end

	lb	$s3, 1($s1)		# Load c + 1
	li	$a1, 1			# Set direction = clockwise initially
	bne	$s3, '\'', next_move	# if (c + 1) != "'", do action immediately
	li	$a1, -1			# direction = counter-clockwise
	add	$s1, $s1, 1		# Skip next char
next_move:
	move	$a0, $s2
	jal	action			# action(c, direction)
	add	$s1, $s1, 1
	b	free_mode_loop

free_mode_end:
	print_string(cube)

exit:	li	$v0, 10
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
	sw	$ra, ($sp)

	move	$s0, $a0		# face = args[0]
	move	$s1, $a1		# direction = args[1]

	lw	$t0, action_pointer
	sb	$s0, ($t0)
	add	$t0, $t0, 1
	bgtz	$s1, action_flush
	li	$t1, '\''
	sb	$t1, ($t0)
	add	$t0, $t0, 1
action_flush:
	sw	$t0, action_pointer

	# printc($s0)

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
	la	$a0, cube
	la	$a1, grid
	jal	copy
	call_move_cell(5, 32)
	call_move_cell(32, 23)
	call_move_cell(23, 14)
	call_move_cell(14, 5)
	call_move_cell(4, 31)
	call_move_cell(31, 22)
	call_move_cell(22, 13)
	call_move_cell(13, 4)
	b	action_end

translate_v:
	li	$a0, 'R'
	li	$a1, 1
	jal	rotate			# rotate(v)
	li	$a0, 'L'
	li	$a1, -1
	jal	rotate			# rotate(v)
	la	$a0, cube
	la	$a1, grid
	jal	copy
	call_move_cell(37, 1)
	call_move_cell(1, 46)
	call_move_cell(46, 25)
	call_move_cell(25, 37)
	call_move_cell(40, 4)
	call_move_cell(4, 49)
	call_move_cell(49, 22)
	call_move_cell(22, 40)
	b	action_end

face_rotate:
	move	$a0, $s0
	move	$a1, $s1
	jal	rotate			# rotate(v)

action_end:
	# bltz	$s1, ccw
# 	printc(' ')
	# b	np
# ccw:	printc('\'')
# np:	printc(':')
# 	printc(' ')
# 	print_string(cube)
# 	printc('\n')
	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
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

	move	$s0, $a0		# face = args[0]
	move	$s1, $a1		# direction = args[1]

	la	$a0, cube
	la	$a1, grid
	jal	copy

	move	$a0, $s0
	jal	get_index		# get_index(face)
	move	$s0, $v0		# i = get_index(face)
	mul	$s0, $s0, 9		# i = i * 9

	move	$s2, $s0
	move	$s3, $s0
	bgtz	$s1, clockwise
	add	$s2, $s2, 6
	b	rotate_loop
clockwise:
	add	$s2, $s2, 2

rotate_loop:
	call_move_cell($s2, $s3)

	mul	$t0, $s1, 3		# Move row up or down
	add	$s2, $s2, $t0
	add	$s3, $s3, 1		# Move copy target to next byte

	sub	$t0, $s3, $s0		# Check progress
	rem	$t0, $t0, 3
	bnez	$t0, rotate_loop

	mul	$t0, $s1, 9		# Reset back row changes
	neg	$t0, $t0
	add	$s2, $s2, $t0

	mul	$t0, $s1, 1		# Adjust column
	neg	$t0, $t0
	add	$s2, $s2, $t0
	sub	$t0, $s3, $s0
	blt	$t0, 9, rotate_loop

	lw	$ra, 28($sp)
	lw	$s0, 24($sp)
	lw	$s1, 20($sp)
	lw	$s2, 16($sp)
	lw	$s3, 12($sp)
	addu	$sp, $sp, 32
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

move_cell:
	move	$t0, $a0
	move	$t1, $a1

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
	jr	$ra

orient_cube:
	subu	$sp, $sp, 32
	sw	$s0, 28($sp)
	sw	$s0, 24($sp)
	sw	$ra, ($sp)

	move	$s0, $a0
	li	$s1, 0
orient_v_loop:
	li	$t0, 40
	lb	$t1, cube($t0)
	beq	$t1, $s0, orient_end
	do_action('V', 1)
	addu	$s1, $s1, 1
	blt	$s1, 4, orient_v_loop
	li	$s1, 0

	do_action('H', 1)
orient_h_loop:
	li	$t0, 40
	lb	$t1, cube($t0)
	beq	$t1, $s0, orient_end
	do_action('V', 1)
	addu	$s1, $s1, 1
	blt	$s1, 4, orient_h_loop


orient_end:
	lw	$s0, 28($sp)
	lw	$ra, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

solve_corners:
	subu	$sp, $sp, 32
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$ra, ($sp)

	move	$s0, $a0

	li	$s1, 4
	li	$s3, 0
solve_corner_loop:
	li	$s2, 0

	li	$t1, 44
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_corner_match

	li	$t1, 15
	lb	$t0, cube($t1)
	beq	$s0, $t0, corner_case1

	li	$t1, 8
	lb	$t0, cube($t1)
	beq	$s0, $t0, corner_case2

	li	$t1, 47
	lb	$t0, cube($t1)
	beq	$s0, $t0, corner_case3

	li	$t1, 2
	lb	$t0, cube($t1)
	beq	$s0, $t0, corner_case4

	li	$t1, 9
	lb	$t0, cube($t1)
	beq	$s0, $t0, corner_case5

	b	solve_corner_no_match

corner_case1:
	do_action('R', -1)
	do_action('D', -1)
	do_action('R', 1)
	b	solve_corner_match

corner_case2:
	do_action('R', 1)
	do_action('F', -1)
	do_action('R', -1)
	do_action('F', 1)
	b	solve_corner_match

corner_case3:
	do_action('R', -1)
	do_action('D', 1)
	do_action('R', 1)
	do_action('D', 1)
	do_action('D', 1)
	do_action('R', -1)
	do_action('D', -1)
	do_action('R', 1)
	b	solve_corner_match

corner_case4:
	do_action('F', 1)
	do_action('D', 1)
	do_action('F', -1)
	do_action('D', 1)
	do_action('D', 1)
	do_action('R', -1)
	do_action('D', 1)
	do_action('R', 1)
	b	solve_corner_match
corner_case5:
	do_action('R', -1)
	do_action('D', -1)
	do_action('R', 1)
	do_action('D', 1)
	do_action('R', -1)
	do_action('D', -1)
	do_action('R', 1)

solve_corner_match:
	li	$s2, 1
	sub	$s1, $s1, 1

solve_corner_no_match:
	bnez	$s2, solve_corner_next
	bge	$s3, 4, solve_corner_next
	do_action('D', 1)
	add	$s3, $s3, 1
	b	solve_corner_loop
solve_corner_next:
	li	$s3, 0
	do_action('H', 1)
	bgtz	$s1, solve_corner_loop

	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s2, 20($sp)
	lw	$s3, 16($sp)
	lw	$ra, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

solve_cross:
	subu	$sp, $sp, 32
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$ra, ($sp)

	move	$s0, $a0

	li	$s1, 0
solve_cross_loop:
	li	$t1, 43
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_skip

	li	$t1, 46
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_case1

	li	$t1, 7
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_case2

	li	$t1, 12
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_case3

	li	$t1, 5
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_case4

	li	$t1, 1
	lb	$t0, cube($t1)
	beq	$s0, $t0, solve_cross_case5

	b	solve_cross_next

solve_cross_skip:
	do_action('U', -1)
	add	$s1, $s1, 1
	bge	$s1, 4,	solve_cross_end
	b	solve_cross_loop

solve_cross_case1:
	do_action('F', 1)
	do_action('F', 1)
	do_action('R', -1)
	do_action('L', 1)
	do_action('D', 1)
	do_action('D', 1)
	do_action('R', 1)
	do_action('L', -1)
	b	solve_cross_next

solve_cross_case2:
	do_action('R', -1)
	do_action('L', 1)
	do_action('D', 1)
	do_action('R', 1)
	do_action('L', -1)
	do_action('F', -1)
	b	solve_cross_next

solve_cross_case3:
	do_action('F', -1)
	do_action('R', -1)
	do_action('L', 1)
	do_action('D', 1)
	do_action('R', 1)
	do_action('L', -1)
	b	solve_cross_next

solve_cross_case4:
	do_action('U', -1)
	do_action('R', 1)
	do_action('F', 1)
	do_action('B', -1)
	do_action('D', -1)
	do_action('F', -1)
	do_action('B', 1)
	b	solve_cross_next

solve_cross_case5:
	do_action('R', 1)
	do_action('L', -1)
	do_action('F', 1)
	do_action('F', 1)
	do_action('R', -1)
	do_action('R', -1)
	do_action('L', 1)
	do_action('L', 1)
	do_action('D', 1)
	do_action('R', 1)
	do_action('L', -1)
	do_action('F', -1)
	b	solve_cross_next

solve_cross_next:
	do_action('H', 1)
	li	$s1, 0
	b	solve_cross_loop

solve_cross_end:
	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
	lw	$ra, ($sp)
	addu	$sp, $sp, 32
	jr	$ra

.data
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
cube:		.space 55
grid:		.space 55
action_pointer:	.word 0
actions:	.space 1001
