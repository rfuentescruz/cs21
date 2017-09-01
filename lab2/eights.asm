.text

main:	li	$v0, 5
	syscall			# Read a
	move	$t1, $v0
	li	$v0, 5
	syscall			# Read b
	add	$t1, $t1, $v0	# a + b
	mul	$t1, $t1, $t1	# (a + b)^2
	mul	$t1, $t1, $t1	# ((a + b)^2)^2 = (a + b)^4
	mul	$t1, $t1, $t1	# ((a + b)^4)^2 = (a + b)^8
	li	$v0, 10
	syscall			# qed