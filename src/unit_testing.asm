# Unit test of the "div" subroutine specified in extended_math
# Currently includes tests for all even/odd combination cases, and divde-by-zero
# Cases involving both even and uneven division are included, however they are not included for every even/odd combination
# TODO: expand even/odd combination cases to include both even and uneven division cases (where possible)
#
# Highlights all LEDs if the test was successful, or highlights specific LEDs to display the relevant error code in binary
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
