# main source file

.org 0x10000000
.equ SWITCHES		0xf0100000 	# switches
.equ LEDS 			0xf0200000 	# LEDs
.equ INTERUPT_CONTROLLER	0xf0700000 	# Interrupt Controller
.equ ENABLE_INTERUPTS		5 	# Enable global and uart interupts, ignore all others
.equ STATUS_BIT_MASK		0xfffffffb	# Used to clear the uart status bit
.equ UART_INTERRUPT_VALUE	4	# Value of the interrupt status for uart events
.equ WAITING_STATE		0b001	# Bit used to represent this machine's "waiting for input" state
.equ PROCESSING_STATE		0b010	# Bit used to represent this machine's "currently processing intermediate input" state
.equ CALCULATING_STATE		0b100	# Bit used to represent this machine's "currently calculating result" state

# Input classifications
.equ INVALID_INPUT		0	# Any ASCII character other than 0-9 + - * / ( or )
.equ NUMBER			1	# ASCII characters representing [0-9] i.e. ASCII 48-57
.equ OPERATION		2	# ASCII + * - or /
.equ CONTROL_START		3	# ASCII (
.equ CONTROL_END		4	# ASCII )

li $sp, 0x10fffffc

j initialize
nop

state:
	.word 0

# Toggles the state-bit specified by $a0
# Equivalent to (state XOR $a0)
toggle_state:
	li $t0, state
	lw $a0, 0($t0) # get current state value
	move $a1, $t1 # load toggle state value
	jal xor
	nop
	li $t0, state
	sw $v0, 0($t0)
	
# Performs xor operation on $a0 and $a1 and stores the result in $v0
# Equivalent to (($a0 OR $a1) AND ($a0 NAND $a1))
xor:
	or $t0, $a0, $a1 # first part
	and $t1, $a0, $a1 # second part (partial)
	nor $t1, $t1, $0 # invert to achieve NAND gate
	and $v0, $t0, $t1
	jr $ra
	nop

initialize:
	li $s5, 0
	# Goto isr when interrupts occur
	li $iv, isr

	# Enable interrupts
	li $t0, INTERUPT_CONTROLLER
	li $t1, ENABLE_INTERUPTS
	sw $t1, 0($t0)

	# Clear interrupt status register
	sw $0, 4($t0) 

main:
	addiu $s5, $s5, 1
	j main
	nop

#process the byte in $a0
process_byte:
	li $t0, state
	lw $t0, 0($t0) # get the current state
	li $t1, WAITING_STATE
	and $t1, $t0, $t1 # check if WAITING STATE is active
	bne $t1, $0, start_input_parsing # if WAITING, start parsing
	nop
	j register_input_byte
	nop
	
	start_input_parsing:
		# Reset waiting bit
		nor $t0, WAITING_STATE, $0  # mask
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state
		ori $t3, $t3, PROCESSING_STATE # set processing state
		sw $t3, 0($t1)

		# Push NULL to stack, to indicate stopping position
		push $0
	
	register_input_byte:
		jal get_input_classification
		nop
		li $t0, INVALID_INPUT
		beq $v0, $t0, err_inavlid_input # if byte is invalid, err out
		nop
		

isr:
	# Evaluate interrupt source
	li $t0, INTERUPT_CONTROLLER
	li $t2, UART_INTERRUPT_VALUE
	lw $t1, 4($t0)
	and $t3, $t2, $t1

	# If the uart interupt bit is off, ignore it
	beq $t3, $0, isr_subroutine_finish
	nop
	# Else, process the input byte
	jal process_byte
	nop

	isr_subroutine_finish:
		# Preserve the current value of status register and  clear status bit
		li $t0, INTERUPT_CONTROLLER
		li $t1, STATUS_BIT_MASK
		lw $t2, 4($t0)
		and $t2, $t2, $t1
		sw $t2, 4($t0)

		# Values to enable interupts
		li $t0, INTERUPT_CONTROLLER
		li $t1, ENABLE_INTERUPTS
	
		# Enable interupts AFTER returning to main code	
		jr $ir 
		sw $t1, 0($t0)



j test_div
nop

err_inavlid_input:
	#TODO Handle err
	j exit_program
	nop

#########################################
# Returns the input classifcation of $a0, via $v0, as represented by:
# 	NUMBER, OPERATION, CONTROL, or INVALID_INPUT
# If the value is a NUMBER, the numeric value will be stored in $v1
#########################################
get_input_classification:
	li $t0, 40 # ASCII of (
	beq $a0, $t0, classify_control_start
	nop
	li $t0, 41 # ASCII of )
	beq $a0, $t0, classify_control_end
	nop
	li $t0, 42 # ASCII of *
	beq $a0, $t0, classify_operation
	nop
	li $t0, 43 # ASCII of +
	beq $a0, $t0, classify_operation
	nop
	li $t0, 45 # ASCII of -
	beq $a0, $t0, classify_operation
	nop
	li $t0, 47 # ASCII of /
	beq $a0, $t0, classify_operation
	nop
	li $t0, 48 # ASCII of 0
	sltu $t1, $a0, $t0 # If value < 48 it is out of bounds
	bne $t1, $0, classify_invalid
	nop
	li $t0, 58 # (ASCII of 9) + 1
	sltu $t1, $a0, $t0 # If value >= ((ASCII of 9) + 1) it is out of bounds
	beq $t1, $0, classify_invalid
	nop
	j classify_number # Else, value is a number
	nop

	
	classify_control_start:
		li $v0, CONTROL_START
		jr $ra
		nop
	classify_control_end:
		li $v0, CONTROL_END
		jr $ra
		nop
	classify_number:
		li $v0, NUMBER
		addiu $v1, $v0, -48
		jr $ra
		nop
	classify_operation:
		li $v0, OPERATION
		jr $ra
		nop
	classify_invalid:
		li $v0, INVALID_INPUT
		jr $ra
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
exit_program:
