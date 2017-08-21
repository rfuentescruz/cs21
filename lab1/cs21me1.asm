# CS 21 THWMVW -- S1 AY 17-18
# Rolando Cruz -- 08/21/17
# cs21me1.asm -- A simple program that loads numbers of different bases to registers

.text

main:	li	$a1, 0xB0B09A90 	# load binary 1011 0000 1011 0000 1001 1010 1001 0000 to $a1
	li	$a2, 0xACE21    	# load decimal 708129 to $a2
	li	$a3, 0x21140145 	# load octal 4105000505 to $a3
	li	$t0, 0xFFF3B1BE		# load binary 1111 1111 1111 0011 1011 0001 1011 1110 to $t0
	li	$t1, 0x10B91DF		# load binary 0001 0000 1011 1001 0001 1101 1111 to $t1
	li	$t2, 3014901760 	# load binary 1011 0011 1011 0011 1100 0000 0000 0000 to $t2
	li	$t3, -1330591030	# load 2C binary 1011 0000 1011 0000 1100 1010 1100 1010 to $t3
	li	$t4, 34808115		# load hex 2132133 to $t4
	li	$t5, 21173303		# load BCD 0010 0001 0001 0111 0011 0011 0000 0011 to $t5
	li	$t6, 01442		# load decimal 802 to $t6
	li	$t7, 0100630106		# load hex 1033046 to $t7
	li	$s0, 01372760665	# load base 13 3258ABCA to $s0
	li	$v0, 10			# prepare syscall code 10 (exit)
	syscall