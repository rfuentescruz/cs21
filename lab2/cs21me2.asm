# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 08/21/17
# cs21me2.asm -- A simple program that will compute the expression (a−b)(a+b)(a^2+b^2).

.text
.macro print_int(%n)
	add	$a0, $zero, %n
	li	$v0, 1
	syscall
.end_macro

.macro read_int(%d)
	li	$v0, 5
	syscall
	move	%d, $v0
.end_macro

.macro square(%d, %n)
	add	$a0, $zero, %n
	mul	%d, $a0, $a0
.end_macro

.macro exit
	li	$v0, 10
	syscall
.end_macro

main:	read_int($t1)		# Read a
	read_int($t2)		# Read b

	# Compute (a - b)(a + b)(a^2 + b^2)
	sub	$t3, $t1, $t2	# a - b
	add	$t4, $t1, $t2	# a + b
	mul	$t3, $t3, $t4	# (a - b)(a + b)
	square($t4, $t1)	# a^2
	square($t5, $t2)	# b^2
	add	$t4, $t4, $t5	# a^2 + b^2
	mul	$t3, $t3, $t4	# (a - b)(a + b)(a^2 + b^2)
	
	print_int($t3)
	exit
