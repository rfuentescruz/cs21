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
	# This is ugly, we assume that we own 2N - 1 space and that indeces
	# after N are NULL.
	get_effective_word_addr($t8, %addr, %offset)

	lw	$t9, 4($t8)		# Load N + 1
	sb	$t9, ($t8)		# Store it in N

	lw	$t9, 8($t8)		# Load N + 2
	sb	$t9, 4($t8)		# Store it in N + 1

	lw	$t9, 12($t8)		# Load N + 3
	sb	$t9, 8($t8)		# Store it in N + 2

	lw	$t9, 16($t8)		# Load N + 4
	sb	$t9, 12($t8)		# Store it in N + 3
.end_macro

.macro reduce_array(%sum, %addr, %x, %y, %n)
	get_effective_word_addr($t8, %addr, %x)		# Get address of int at index X -> $t3
	lw	$t4, ($t8)				# Load int at index X -> $t4

	get_effective_word_addr($t8, %addr, %y)		# Get address of int at index Y
	lw	$t5, ($t8)				# Load int at index Y -> $t5

	get_effective_word_addr($t8, %addr, %n)		# Get address of the end of array (n = 6)
	addu	%sum, $t4, $t5				# Add loaded ints
	sb	%sum, ($t8)				# Store sum at end of array

	shift_array(%addr, %y)				# Shift array down starting at index Y.
	shift_array(%addr, %x)				# Shift array down starting at index X.
.end_macro

.macro print_int(%dest, %n)
	add	$a0, $zero, %n
	li	$v0, 1
	syscall
	li	$a0, 10
	li	$v0, 11
	syscall
.end_macro

.macro exit
	li	$v0, 10
	syscall
.end_macro


main:
	la	$s0, arr
	la	$s1, pairs
	la	$s2, digits

	read_and_store_int($s0, 0)
	read_and_store_int($s0, 1)
	read_and_store_int($s0, 2)
	read_and_store_int($s0, 3)
	read_and_store_int($s0, 4)

	read_and_store_index_pair($s1, 0, $t1, $t2)	# Read index X and index Y -> $t1, $t2
	reduce_array($t3, $s0, $t1, $t2, 5)
	print_int($s2, $t3)

	read_and_store_index_pair($s1, 1, $t1, $t2)
	reduce_array($t3, $s0, $t1, $t2, 4)
	print_int($s2, $t3)

	read_and_store_index_pair($s1, 2, $t1, $t2)
	reduce_array($t3, $s0, $t1, $t2, 3)
	print_int($s2, $t3)

	read_and_store_index_pair($s1, 3, $t1, $t2)
	reduce_array($t3, $s0, $t1, $t2, 2)
	print_int($s2, $t3)

	print_index_pair($s1, 0)
	print_index_pair($s1, 1)
	print_index_pair($s1, 2)
	print_index_pair($s1, 3)
	exit
.data
digits:	.space 12	# Allocate memory for an 10 digit number (+ 2 for sign and a null byte)
pairs:	.space 16	# Allocate memory for 4 null terminated 2-char strings
arr:	.space 40	# Allocate memory for a 10-word array
