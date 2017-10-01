.text
main:	li	$v0, 5
	syscall
	move	$a0, $v0	# a0 is a (1st input parameter)
	li	$v0, 5
	syscall
	move	$a1, $v0	# a0 is b (2nd input parameter)
	li	$v0, 0		# v0 is base case return value
	jal	mul_alt		# call function
	move	$a0, $v0	# print product of a and b
	li	$v0, 1
	syscall
	li	$v0, 10
	syscall

mul_alt: #####preamble######
	subu	$sp, $sp, 32
	sw	$ra, 28($sp)
	sw	$fp, 24($sp)
	addu	$fp, $sp, 32
	#####preamble######

recurse:
	beqz	$a1, bc # b == 0 ? return 0 (line 27)
	add	$v0, $a0, $v0
	bltz	$a1, neg_step
	subi	$a1, $a1, 1
	j	recurse
neg_step:
	addi	$a1, $a1, 1
	bnez	$a1, recurse
	sub	$v0, $zero, $v0 # put back the negative

bc:	#####end######
	lw	$ra, 28($sp)
	lw	$fp, 24($sp)
	addu	$sp, $sp, 32
	addu	$fp, $sp, 32
	#####end######
	jr	$ra

.data
