.text

main: 		li $v0, 8
		la $a0, name
number3: 	li $a1, 12
		syscall

		la $t0, suffix
		lhu $t1, 0($t0)
		addiu $t0, $t0, 2
		lhu $t2, 0($t0)
		addiu $t0, $t0, 2
		lhu $t3, 0($t0)
		la $t4, name
		sh $t1, 6($t4)
		sh $t2, 8($t4)
		sh $t3, 10($t4)

		li $v0, 4
		la $a0, name
		syscall
		li $v0, 10
		syscall

.data
name: 		.space 12
greeting: 	.asciiz "gokigenyou"
		.align 1
suffix: 	.ascii "-sama" # Note the space at the end of the string