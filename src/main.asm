# main source file

.org 0x10000000
.equ SWITCHES	0xf0100000 #switches
.equ LEDS 		0xf0200000 #LEDs
li $sp, 0x10fffffc

j test_div
nop

#########################################
############## SUBROUTINE ###############
# Performs integer division on the values of $a0 and $a1 and stores the result in $v0 such that:
# $v0 = $a0 / $a1
#
# if division by 0 is attempted, 1 will be stored in $v1, and 0 will be returned via $v0
# else, 0 will be stored in $v1
#
# Warning: "call" should be used to call this subroutine rather than j, jal, or similar, as div calls "return" on completion
#########################################
div:
	# check base case (div-by-0)
	beq $a1, $0, div_by_zero
	
	# setup "local variables"
	move $s0, $a0 # $s0 holds the initial value of the numerator
	move $t0, $a0 # $t0 holds the modified value of the numerator (remaining sum)
	move $s1, $a1 # $s1 holds the initial value of the denominator
	move $t1, $a1 # $t1 holds the modified value of the denominator (condition determinate)
	move $t2, $0 # $t2 holds the will-be result

	# multiply denominator ($t1) by 2 until it is greater than or equal to the numerator ($s0)
	div_subroutine_mul2:
		slt $t9, $t1, $s0
		beq $t9, $0, div_sublabel_main #if denominator >= numerator then begin calculations
		nop
		sll $t1, $t1, 1 #else, multiply denominator by 2
		j div_subroutine_mul2
		nop
	div_sublabel_main:
		slt $t9, $t0, $s1
		bne $t9, $0, div_subroutine_finish #if remainingSum < initialDenominator then end
		nop
		slt $t9, $t1, $t0
		bne $t9, $0, div_main_sublabel_use_current #if denominator < remainingSum then count the current denominator towards the sum
		nop
		beq $t0, $t1, div_main_sublabel_use_current #if denominator == remainingSum then count the current denominator towards the sum
		nop
		#else, disregard this condition determinate and move to the next
		div_main_sublabel_next:
			sll $t2, $t2, 1 #multiply will-be result by 2
			srl $t1, $t1, 1 #divide denominator by 2
			j div_sublabel_main
			nop
		div_main_sublabel_use_current:
			addiu $t2, $t2, 1 #increase will-be result by 1 (indicates the current numerator is used towards the sum)
			subu $t0, $t0, $t1 #decrease remaining sum by the determinate we are using
			j div_main_sublabel_next
			nop
	div_by_zero:
		li $v0, 0
		li $v1, 1 #indicate division error
		return
		nop

	div_subroutine_finish:
		#divide modifiedDenominator by 2 until it is less than the initialDenominator, and multiply the quotient by 2 for each shift
		#this will result in an extra shift to the quotient
		slt $t9, $t1, $s1
		bne $t9, $0, end_loop #if modifiedDenominator < initialDenominator then end loop
		nop
		srl $t1, $t1, 1 #divide modifiedDenominator by 2
		sll $t2, $t2, 1 #multiply the quotient by 2 for each shift
		j div_subroutine_finish
		nop

		end_loop:
		srl $t2, $t2, 1 #account for extra shift
		move $v0, $t2 #return the quotient (result)
		li $v1, 0 #indicate no division errors
		return
		nop

# Unit test of the "div" subroutine specified in extended_math
# Currently includes tests for all even/odd combination cases, and divde-by-zero
# Cases involving both even and uneven division are included, however they are not included for every even/odd combination
# TODO: expand even/odd combination cases to include both even and uneven division cases (where possible)
test_div:
	div_test_1: #even / even = even
		# test 80 / 8 = 10
		li $a0, 80
		li $a1, 8
		call div
		nop
		li $a0, 1 #error code
		li $t0, 10 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop

	div_test_2: #even / even = odd
		# test 36 / 12 = 3
		li $a0, 36
		li $a1, 12
		call div
		nop
		li $a0, 2 #error code
		li $t0, 3 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_3: #even / odd = even
		# test 1200 / 5 = 240
		li $a0, 1200
		li $a1, 5
		call div
		nop
		li $a0, 3 #error code
		li $t0, 240 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_4: #even / odd = odd
		# test 30 / 9 = 3
		li $a0, 30
		li $a1, 9
		call div
		nop
		li $a0, 4 #error code
		li $t0, 3 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_5: #odd / odd = even
		# test 109 / 9 = 12
		li $a0, 109
		li $a1, 9
		call div
		nop
		li $a0, 5 #error code
		li $t0, 12 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_6: #odd / odd = odd
		# test 15 / 5 = 3
		li $a0, 15
		li $a1, 5
		call div
		nop
		li $a0, 6 #error code
		li $t0, 3 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_7: #odd / even = even
		# test 150009 / 100 = 1500
		li $a0, 150009
		li $a1, 100
		call div
		nop
		li $a0, 7 #error code
		li $t0, 1500 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop
	
	div_test_8: #odd / even = odd
		# test 423 / 60 = 7
		li $a0, 423
		li $a1, 60
		call div
		nop
		li $a0, 8 #error code
		li $t0, 7 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		bne $v1, $0, test_failed #if div_by_zero_error then FAIL
		nop

	div_test_9:
		# test 20 / 0 = 0 and error
		li $a0, 20
		li $a1, 0
		call div
		nop
		li $a0, 9 #error code
		li $t0, 0 #expected result
		bne $v0, $t0, test_failed #if result != expected then FAIL
		nop
		beq $v1, $0, test_failed #if no div_by_zero_error then FAIL
		nop

# Highlights all 8 LEDs and exits the program
test_successful:
	li $t0, LEDS
	li $t1, 255
	sw, $t1, 0($t0)
	j exit_program
	nop
	
# Displays the error code specified by $a0 on the LEDs and exits the program
test_failed:
	li $t0, LEDS
	sw, $a0, 0($t0)
exit_program:
