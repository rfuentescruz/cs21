# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 09/05/17
# cs21me3.asm -- A reduce a 5-integer array to the sum of its elements

.text
.macro get_effective_word_addr(%reg, %addr, %offset)
	li	%reg, 4			# Compute the actual address based on
	mul	%reg, %reg, %offset	# the logical offset (0, 1, 2, 3).
	addu	%reg, %reg, %addr
.end_macro

.macro read_and_store_int(%addr, %offset)
	get_effective_word_addr($t8, %addr, %offset)

	li	$v0, 5
	syscall
	sw	$v0, ($t8)
.end_macro


.macro read_and_store_index_pair(%addr, %offset, %reg_a, %reg_b)
	get_effective_word_addr($t8, %addr, %offset)

	li	$a1, 4			# Read n - 1 characters.
	la	$a0, ($t8)
	li	$v0, 8
	syscall

	lb	%reg_a, 0($t8)		# Convert the first character to its
	sub	%reg_a, %reg_a, 97	# effective index value.
					# (a = 0, b = 1, c = 2, etc.)

	lb	%reg_b, 1($t8)		# Do the same for the second character.
	sub	%reg_b, %reg_b, 97
.end_macro

.macro print_index_pair(%addr, %offset)
	get_effective_word_addr($t8, %addr, %offset)

	lb	$t9, 0($t8)		# Convert the first character to
	sub	$t9, $t9, 32		# uppercase.
	sb	$t9, 0($t8)

	lb	$t9, 1($t8)		# Do the same for the second character.
	sub	$t9, $t9, 32
	sb	$t9, 1($t8)

	li	$v0, 4
	la	$a0, ($t8)
	syscall
.end_macro

.macro	shift_array(%addr, %offset)
	do_shift(%addr, %offset, 0)	# Maybe shift index 1 to 0
	do_shift(%addr, %offset, 1)	# Maybe shift index 2 to 1
	do_shift(%addr, %offset, 2)	# Maybe shift index 3 to 2
	do_shift(%addr, %offset, 3)	# Maybe shift index 4 to 3
.end_macro

.macro do_shift(%addr, %offset, %n)
	get_effective_word_addr($t8, %addr, %offset)
	get_effective_word_addr($t9, %addr, %n)		# Get the address of index we may want to shift

	div	$t8, $t9, $t8				# Get the address of the new data source of this
	mul	$t8, $t8, 4				# index %n.
	add	$t7, $t9, $t8				# This will be pointing to the next integer if $t9 >= $t8

	lw	$t8, ($t7)				# Load the integer
	sb	$t8, ($t9)				# Store it in N
.end_macro

.macro reduce_array(%addr, %x, %y, %n)
	get_effective_word_addr($t0, %addr, %x)		# Get address of int at index X
	lw	$t1, ($t0)				# Load int at index X -> $t1

	get_effective_word_addr($t0, %addr, %y)		# Get address of int at index Y
	lw	$t2, ($t0)				# Load int at index Y -> $t2

	shift_array(%addr, %y)				# Shift array down starting at index Y.
	shift_array(%addr, %x)				# Shift array down starting at index X.

	addu	$t1, $t1, $t2				# Add loaded ints
	get_effective_word_addr($t0, %addr, %n)		# Get address of the end of array (n)
	sb	$t1, ($t0)				# Store sum at end of array

	add	$a0, $zero, $t1
	li	$v0, 1
	syscall						# Print sum
	la	$a0, nl
	li	$v0, 4
	syscall						# Print newline

.end_macro

.macro exit
	li	$v0, 10
	syscall
.end_macro

main:
	la	$s0, arr
	la	$s1, pairs

	read_and_store_int($s0, 0)
	read_and_store_int($s0, 1)
	read_and_store_int($s0, 2)
	read_and_store_int($s0, 3)
	read_and_store_int($s0, 4)

	read_and_store_index_pair($s1, 0, $s2, $s3)	# Read index X and index Y -> $s2, $s3
	reduce_array($s0, $s2, $s3, 3)

	read_and_store_index_pair($s1, 1, $s2, $s3)
	reduce_array($s0, $s2, $s3, 2)

	read_and_store_index_pair($s1, 2, $s2, $s3)
	reduce_array($s0, $s2, $s3, 1)

	read_and_store_index_pair($s1, 3, $s2, $s3)
	reduce_array($s0, $s2, $s3, 0)

	print_index_pair($s1, 0)
	print_index_pair($s1, 1)
	print_index_pair($s1, 2)
	print_index_pair($s1, 3)
	exit

.data
pairs:	.space 16	# Allocate memory for 4 null terminated 2-char strings
arr:	.space 20	# Allocate memory for a 5-word array
nl:	.asciiz "\n"
