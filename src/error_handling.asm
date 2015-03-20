# Error Handling

# ERROR STATES

# Overflow
# Underflow
# Invalid input? currently in main as inavlid input
# Divide by Zero?
# Index out of bounds

err_overflow:
	li $t0, string_overflow
	sw $a0, 0($t0)
	j reset_waiting_state
	nop
#TODO: fix syntax? [ERROR] #22 Asm: preprocess(error_handling.asm:19): Invalid string literal.
# this error is given with all of the .asciiz  
string_overflow:
     	.asciiz "Error: Overflow" # null terminator inserted at end of string
	nop

err_underflow:
	li $t0, string_underflow
	sw $a0, 0($t0)
	j reset_waiting_state
	nop
string_underflow:
     	.asciiz "Error: Underflow" # null terminator inserted at end of string
	nop	

err_invalid_input:
	li $t0, string_invalid_input
	sw $a0, 0($t0)
	j reset_waiting_state
	nop
string_invalid_input:
     	.asciiz "Error: Invalid Input" # null terminator inserted at end of string
	nop	

err_division_by_zero:
	li $t0, string_division_by_zero
	sw $a0, 0($t0)
	j reset_waiting_state
	nop
string_division_by_zero:
     	.asciiz "Error: Division by zero" # null terminator inserted at end of string
	nop	

err_index_out_of_bounds:
	li $t0, string_index_out_of_bounds
	sw $a0, 0($t0)
	j reset_waiting_state
	nop
string_index_out_of_bounds:
     	.asciiz "Error: Index out of bounds" # null terminator inserted at end of string
	nop	

reset_waiting_state:
		li $t4, WAITING_STATE
		or $t0, $t4, 1  # turn on WAITING bit
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state
		sw $t3, 0($t1) # store the new state
		#TODO: verify
		jr $ra
		nop
