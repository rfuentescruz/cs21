.text
.macro shift_left(%reg, %n)
	rol	%reg, %reg, %n
	srl	%reg, %reg, %n
	rol	%reg, %reg, %n
.end_macro

.macro rotate_right(%reg, %n)
	li	$t0, 32
	sub	$t0, $t0, %n

	not	$t1, $zero
	srlv	$t1, $t1, $t0
	and	$t1, $t1, %reg
	sllv	$t1, $t1, $t0

	srl	%reg, %reg, %n
	or	%reg, $t1, %reg
.end_macro

main:	li	$s0, 27
	shift_left($s0, 5)
	li	$s1, 27
	sll	$s1, $s1, 5
	
	li	$s2, 5
	rotate_right($s2, 1)
	li	$s3, 5
	ror	$s3, $s3, 1
	
	li	$t0, 21140145
	lui	$t2, 322
	ori	$t1, $t2, 37553
	
	ori	$t3, $zero, 0x20100c00
	
	not	$t4, $zero
	xori	$t4, $t4, 0x40000000

	li	$t2, 0xFFFF0300
	andi	$t2, $t2, 0x00000100
	bnez	$t2, yes
	la	$a0, NO
	b print
yes:	la	$a0, YES
print:	li	$v0, 4
	syscall
.data
YES:	.asciiz "YES"
NO:	.asciiz "NO"
	