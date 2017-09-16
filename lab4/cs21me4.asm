# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 09/16/17
# cs21me4.asm -- A string search and replace program

.text
.macro get_effective_str_addr(%reg, %addr, %index)
	mul	%reg, %index, 51
	add	%reg, %reg, %addr
.end_macro

.macro read_int(%reg)
	li	$v0, 5
	syscall
	move	%reg, $v0
.end_macro

.macro read_string(%reg, %n, %index)
	move	$a0, %reg

	add	$t8, $zero, %index	# Get the destination index in %reg
	mul	$t8, $t8, %n		# Convert index to an %n-byte offset
	add	$a0, $a0, $t8		# Add offset to destination address

	addu	$a1, $zero, %n		# Read in (%n - 1) bytes

	li	$v0, 8			
	syscall				# Read string
.end_macro

.macro println_int(%reg)
	add	$a0, $zero, %reg
	li	$v0, 1
	syscall				# Print integer
	la	$a0, nl
	li	$v0, 4
	syscall				# Print newline
.end_macro

.macro println_str(%addr)
	move	$a0, %addr
	li	$v0, 4
	syscall				# Print string at %addr
	la	$a0, nl
	li	$v0, 4
	syscall				# Print newline
.end_macro

.macro println_haystack_str(%addr, %index)
	get_effective_str_addr($t7, %addr, %index)

	to_uppercase($t7)
	println_str($t7)
	strlen($t6, $t7)
	println_int($t6)
.end_macro

.macro search_and_replace(%subject, %needle, %replace)
	la	$t5, temp
	move	$t6, %subject

loop:	lb	$t7, ($t6)
	match($t8, $t9, $t6, %needle)	# Attempt to find needle in subject
					# starting at the byte at $t6

	beqz	$t8, copy		# If the needle matches ($t8 == 0),
					#   copy the replacement to temp

	sb	$t7, ($t5)		# else, store the next byte to temp
	beqz	$t7, end		# If this is the NULL byte, end
	add	$t6, $t6, 1
	add	$t5, $t5, 1
	b 	loop

copy:	strcopy($t8, $t5, %replace)	# Append replacement to temp
	add	$t5, $t5, $t8		# Adjust the write-to index in temp 
					# based on the number bytes copied

	add	$t6, $t6, $t9		# Adjust the read-in index in subject
					# based on the number of bytes matched 
	b	loop

end:	la	$t5, temp		# Reset the pointer to the start temp
	strcopy($t8, %subject, $t5)	# Copy over temp to subject

.end_macro

.macro match(%result, %n, %haystack, %needle)
	move 	$t0, %needle
	move	$t1, %haystack

	li	%n, 0
loop:	lb	$t2, ($t0)		# Get one byte to match
	lb	$t3, ($t1)		# Get the byte to match it to
	beqz	$t2, end		# If we consumed the needle, end
	bne	$t2, $t3, end		# The two chars do not match, end
	add	$t0, $t0, 1		# Prepare to match the next byte
	add	$t1, $t1, 1
	b 	loop

end:	move	%result, $t2		# Set match result (0 if full match)
	sub	%n, $t0, %needle	# Set the number of matched bytes 
.end_macro

.macro strcopy(%n, %dest, %src)
	move 	$t0, %src
	move	$t1, %dest

	li	%n, 0
loop:	lb	$t2, ($t0)		# Get one byte from the source
	sb	$t2, ($t1)		# Store the byte onto the destination
	beqz	$t2, end		# If this is the end of the source, end
	add	$t0, $t0, 1		# Move source pointer up
	add	$t1, $t1, 1		# Move dest pointer up
	b 	loop
end:	sub	%n, $t0, %src		# Set the number of bytes copied
.end_macro

.macro to_uppercase(%addr)
	move	$t8, %addr
loop:
	lb	$t9, ($t8)		# Load char
	blt	$t9, 97, next		# Skip if ASCII is < 97
	bgt	$t9, 122, next		# Skip if ASCII is > 122
	sub	$t9, $t9, 32		# Convert to lowercase
	sb	$t9, ($t8)		# Store the char back
next:	add	$t8, $t8, 1		# Prepare for the next byte
	bnez	$t9, loop		# Loop unless this is the NULL byte
.end_macro

.macro trim(%addr)
	move	$t8, %addr
loop:	lb	$t9, ($t8)		# Load char
	bne	$t9, 10, end		# Skip if the char is not a newline
	li	$t9, 0			# Replace newline with NULL
	sb	$t9, ($t8)		# Store the NULL byte
end:	add	$t8, $t8, 1		# Prepare for the next char
	bnez	$t9, loop		# Loop until the character is NULL
.end_macro

.macro strlen(%reg, %addr)
	move	$t8, %addr
loop:	lb	$t9, ($t8)		# Load char
	beqz	$t9, end		# End if the character is NULL
	add	$t8, $t8, 1		# Move pointer
	b loop
end:	sub	%reg, $t8, %addr	# Set the number of chars in the string
.end_macro

.macro exit
	li	$v0, 10
	syscall
.end_macro

main:		la	$s0, strings
		la	$s1, needle
		la	$s2, replace
		read_int($s3)			# Get the number of strings

		# Loop to get $s2 strings
		li	$s4, 0			# Initialize iterator
get_strings:	read_string($s0, 51, $s4)	# Read at most a 50-char string
		get_effective_str_addr($s5, $s0, $s4)
		trim($s5)
		add	$s4, $s4, 1
		blt	$s4, $s3, get_strings

		read_string($s1, 51, 0)
		trim($s1)
		read_string($s2, 51, 0)
		trim($s2)

		# Loop to search and replace all strings
		li	$s4, 0
transform:	get_effective_str_addr($s5, $s0, $s4)
		search_and_replace($s5, $s1, $s2)
		add	$s4, $s4, 1
		blt	$s4, $s3, transform

		# Loop to prompt indexes to print
print_strings:	read_int($s4)
		beqz	$s4, end
		sub	$s4, $s4, 1
		println_haystack_str($s0, $s4)
		b print_strings

end:		exit

.data
needle:		.space 51
replace:	.space 51
temp:		.space 51
strings:	.space 1020	# 51 * 20
nl:		.byte '\n'
