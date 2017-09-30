.text
main:	li	$t0, 1
	li	$t1, 1
	jal	fxn 		# call function
	add	$a0, $t0, $t1 	# a0 = t0 + t1
	li	$v0, 1 		# print t0 + t1
	syscall			# print t0 + 1
	li	$v0, 10
	syscall
fxn:	######preamble######
	subu	$sp, $sp, 32
	sw	$ra, 28($sp)
	sw	$fp, 24($sp)
	sw	$t0, 20($sp)
	sw	$t1, 16($sp)
	addu	$fp, $sp, 32
	######preamble######
	li	$t0, 2
	li	$t1, 2
	add	$a0, $t0, $t1 # a0 = t0 + t1
	li	$v0, 1 # print t0 + t1
	syscall
	######end######
	lw	$ra, 28($sp)
	lw	$fp, 24($sp)
	lw	$t0, 20($sp)
	lw	$t1, 16($sp)
	addu	$sp, $sp, 32
	addu	$fp, $sp, 32
	######end######
	jr	$ra
