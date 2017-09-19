.text
.macro read_int(%dest)
	li	$v0, 5
	syscall
	move	%dest, $v0
.end_macro

.macro print_int(%n)
	li	$v0, 1
	add	$a0, $zero, %n
	syscall
	la	$a0, nl
	li	$v0, 4
	syscall
.end_macro

.macro  log2(%dest, %n)
	li	$t8, 1
	li	%dest, 0
loop:	bge	$t8, %n, end
	sll	$t8, $t8, 1
	add	%dest, %dest, 1
	b loop
end:
.end_macro

main:
	read_int($s0)		# Read number of address bits
	read_int($s1)		# Read block size in nibbles
	srl	$s1, $s1, 1	# Convert block size to bytes, divide by 2
	read_int($s2)		# Read number of cache blocks

	log2($s3, $s1)		# Get offset bits
	log2($s4, $s2)		# Get index bits

	print_int($s4)
	print_int($s3)
	print_int($s1)

.data
nl:     .byte '\n'
