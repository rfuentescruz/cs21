.text
.macro get(%dest, %label)
	la	$t8, %label
	lw	%dest, ($t8)
.end_macro

.macro	set(%value, %label)
	la	$t8, %label
	add	$t9, $zero, %value
	sw	$t9, ($t8)
.end_macro

.macro read_int(%dest)
	li	$v0, 5
	syscall
	move	%dest, $v0
.end_macro

.macro print_char(%c)
	li	$v0, 11,
	add	$a0, $zero, %c
	syscall
.end_macro

.macro print_int(%n, %sep)
	li	$v0, 1
	add	$a0, $zero, %n
	syscall
	print_char(%sep)
.end_macro

.macro  log2(%dest, %n)
	li	$t8, 1
	li	%dest, 0
loop:	bge	$t8, %n, end	# If the number is zero, end
	sll	$t8, $t8, 1	# Divide by two through logical bit shift
	add	%dest, %dest, 1
	b loop
end:
.end_macro

.macro get_bits(%dest, %n, %len, %start)
	li	$t8, 32
	sub	$t8, $t8, %start
	sub	$t8, $t8, %len

	sllv	%dest, %n, $t8		# Shift left to truncate
	srlv	%dest, %dest, $t8	# Move back
	add	$t8, $zero, %start
	srlv	%dest, %dest, $t8	# Move copied bits to index 0
.end_macro

.macro get_tag(%dest, %n)
	get($t5, num_tag_bits)
	get($t6, num_index_bits)
	get($t7, num_offset_bits)
	add	$t6, $t6, $t7		# Compute the start of the tag field

	get_bits(%dest, %n, $t5, $t6)
.end_macro

.macro	get_index(%dest, %n)
	get($t5, num_index_bits)
	get($t6, num_offset_bits)
	get_bits(%dest, %n, $t5, $t6)
.end_macro

.macro	get_cache_block_address(%dest, %label, %index)
	la	%dest, %label
	add	$t8, $zero, %index
	sll	$t8, $t8, 2
	add	%dest, %dest, $t8
.end_macro

.macro	get_cache_block(%n, %label, %index)
	get_cache_block_address($t9, %label, %index)
	lw	%n, ($t9)
.end_macro

.macro	put_cache_block(%n, %label, %index)
	get_cache_block_address($t9, %label, %index)
	sw	%n, ($t9)
.end_macro

.macro set_valid_bit(%n, %value)
	add	$t8, $zero, %value
	bgtz	$t8, one
	andi	%n, %n, 0x7FFFFFFF	# Set value to 0
	b	end
one:	ori	%n, %n, 0x80000000	# Set value to 1
end:
.end_macro

main:
	read_int($t0)		# Read number of address bits

	read_int($t1)		# Read block size in nibbles
	srl	$t1, $t1, 1	# Convert block size to bytes, divide by 2

	read_int($t2)		# Read number of cache blocks
	set($t2, num_blocks)

	log2($s1, $t1)		# Get offset bits
	set($s1, num_offset_bits)
	log2($s2, $t2)		# Get index bits
	set($s2, num_index_bits)

	sub	$s3, $t0, $s1
	sub	$s3, $s3, $s2	# Subtract offset and index bits to get tag bits
	set($s3, num_tag_bits)

	print_int($s3, '\n')
	print_int($s2, '\n')
	print_int($s1, '\n')
	print_int($t1, '\n')

	read_int($t0)			# Read number of byte accesses
loop:	read_int($t1)
	get_index($t2, $t1)		# Get index bits
	get_tag($t4, $t1)		# Get tag bits

	get_cache_block($t3, cache, $t2)

	bgez	$t3, miss		# Metadata is positive, last bit (the
					#    valid bit) is 0

	set_valid_bit($t3, 0)		# else, clear valid bit so we can
					#    compare easily

	bne	$t3, $t4, miss		# Tag field do not match, miss
	get($t3, hit_rate)		#  else, increment hit rate
	add	$t3, $t3, 1
	set($t3, hit_rate)
	b store

miss:	get($t3, miss_rate)		# On miss, increment miss rate
	add	$t3, $t3, 1
	set($t3, miss_rate)

store:	set_valid_bit($t4, 1)		# Overstore valid bit in the tag bit
	put_cache_block($t4, cache, $t2) # Store valid bit + tag bit

	sub	$t0, $t0, 1
	bgtz	$t0, loop	# Loop until we've read all byte accesses

	get($t0, num_blocks)
	li	$t1, 0
loop1:	get_cache_block($t2, cache, $t1)
	print_int($t1, ' ')		# Print index number
	bltz	$t2, valid
	print_int(0, ' ')		# Print valid bit as 0 if metadata < 0
	print_char('#')			# Print '#' for tag since its unused
	print_char('\n')
	b	inc
valid:	print_int(1, ' ')		# Print 1 for valid bit if metadata > 0
	set_valid_bit($t2, 0)		# Remove the overstored valid bit
	print_int($t2, '\n')		# Print tag field
inc:	add	$t1, $t1, 1
	blt	$t1, $t0, loop1

	get($t0, hit_rate)
	get($t1, miss_rate)
	add	$t2, $t0, $t1
	print_int($t2, '\n')
	print_int($t0, '\n')
	print_int($t1, '\n')

.data
num_blocks:		.word 0
num_offset_bits:	.word 0
num_index_bits:		.word 0
num_tag_bits:		.word 0
hit_rate:		.word 0
miss_rate:		.word 0

cache:		.space 1045696	# Theoretical max tag field size x cache blocks
				# 32 x 32678
