.text
.macro printc(%c)
	add	$a0, $zero, %c
	li	$v0, 11
	syscall
.end_macro

main:	la	$a0, cube
	li	$a1, 55
	li	$v0, 8
	syscall

	li	$v0, 5
	syscall
	move	$s0, $v0

	la	$a0, cube
	li	$v0, 4
	syscall

	move	$a0, $s0
	li	$v0, 1
	syscall

	la	$a0, actions
	li	$a1, 1001
	li	$v0, 8
	syscall

	la	$a0, actions
	li	$v0, 4
	syscall

	la	$s1, actions
loop:	lb	$s2, ($s1)		# Load c
	beqz	$s2, end		# if c == 0, end
	beq	$s2, 10, end		# if c == '\n', end

	lb	$s3, 1($s1)		# Load c + 1
	li	$a1, 0			# reverse = false
	bne	$s3, 39, next		# if (c + 1) != "'", do action immediately
	li	$a1, 1			# reverse = true
	add	$s1, $s1, 1		# Skip next char
next:	move	$a0, $s2
	jal	action			# action(c, reverse)
	add	$s1, $s1, 1
	b	loop

end:	li	$v0, 10
	syscall

action:	subu	$sp, $sp, 32
	sw	$ra, 28($sp)

	move	$t0, $a0
	printc($a0)
	printc(':')
	printc(' ')

	move	$a0, $t0
	jal	rotate

	printc('\n')

	lw	$ra, 28($sp)
	addu	$sp, $sp, 32
	jr	$ra

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
	printc($t1)
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

copy:	li	$t0, 0
	move	$t1, $a0
	move	$t2, $a1
lc:	lb	$t3, ($t1)
	sb	$t3, ($t2)
	add	$t0, $t0, 1
	add	$t1, $t1, 1
	add	$t2, $t2, 1
	blt	$t0, 9, lc
	jr	$ra

.data
cube:		.space 54
		.align 2
grid:		.space 9
		.align 2
actions:	.space 1000
