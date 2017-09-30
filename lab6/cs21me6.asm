# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 09/30/17
# cs21me6.asm -- A program for fibonacci-like sequences

.text

main:	li	$v0, 5
	syscall
	move	$a0, $v0
	jal	fib

	move	$a0, $v0
	li	$v0, 1
	syscall

	li	$v0, 10
	syscall

fib:	subu	$sp, $sp, 8
	sw	$ra, 4($sp)
	sw	$s0, ($sp)
	add	$s7, $s7, 1

	move	$s0, $a0	# n = argument
	bgtz	$s0, nbc	# if n > 0, not base case
	li	$v0, 0		# base case: return 0
	b	return

nbc:	subu	$a0, $s0, 1	# a = n - 1
	jal	fib		# fib(a)
	move	$a0, $v0	# b = fib(a)
	jal	fib		# fib(b)
	subu	$v0, $s0, $v0	# return n - b

return:	lw	$ra, 4($sp)
	lw	$s0, ($sp)
	addu	$sp, $sp, 8
	jr	$ra
