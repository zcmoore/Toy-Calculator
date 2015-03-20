# Error Handling

# ERROR STATES

# Overflow
# Underflow
# Invalid input? currently in main as inavlid input
# Divide by Zero?
# Index out of bounds

j error_handling_end
nop

string_overflow:
        .asciiz "Error: Overflow"

string_underflow:
     	.asciiz "Error: Underflow"

string_invalid_input:
     	.asciiz "Error: Invalid Input"

string_division_by_zero:
     	.asciiz "Error: Division by zero"

string_index_out_of_bounds:
     	.asciiz "Error: Index out of bounds"

err_overflow:
	li $t0, string_overflow
	sw $a0, 0($t0)
	j reset_waiting_state
	nop

err_underflow:
	li $t0, string_underflow
	sw $a0, 0($t0)
	j reset_waiting_state
	nop

# This misspelling appears throughout the code, and should be replaced.
err_inavlid_input:
err_invalid_input:
	li $t0, string_invalid_input
	sw $a0, 0($t0)
	j reset_waiting_state
	nop

err_division_by_zero:
	li $t0, string_division_by_zero
	sw $a0, 0($t0)
	j reset_waiting_state
	nop

err_index_out_of_bounds:
	li $t0, string_index_out_of_bounds
	sw $a0, 0($t0)
	j reset_waiting_state
	nop

err_invalid_state:
	# TODO

err_undefined:
	# TODO

reset_waiting_state:
		li $t4, WAITING_STATE
		ori $t0, $t4, 1  # turn on WAITING bit
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state
		sw $t3, 0($t1) # store the new state
		#TODO: verify
		jr $ra
		nop

error_handling_end:
