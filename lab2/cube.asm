.text

.macro square(%n, %reg)
	li	%reg, %n
	mul	%reg, %reg, %reg
.end_macro

.macro cube(%n, %reg)
	square(%n, %reg)
	mul	%reg, %reg, %n
.end_macro

main:
	li	$t1, 0x8000
	li	$t2, 0x7FFF
	li	$t3, 0x7FFE