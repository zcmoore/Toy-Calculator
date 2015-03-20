# Error Handling

# ERROR STATES

# Overflow
# Underflow
# Invalid input? currently in main as inavlid input
# Divide by Zero?
# Index out of bounds

err_overflow:
	#TODO: verify uart portion is correct
	sw $a0, 0(string_overflow)
	j reset_waiting_state
	nop
string_overflow:
     	.asciiz "Error: Overflow" # null terminator inserted at end of string
	nop

err_underflow:
	sw $a0, 0(string_underflow)
	j reset_waiting_state
	nop
string_underflow:
     	.asciiz "Error: Overflow" # null terminator inserted at end of string
	nop	

err_invalid_input:
	sw $a0, string_invalid_input
	j reset_waiting_state
	nop
string_invalid_input:
     	.asciiz "Error: Invalid Input" # null terminator inserted at end of string
	nop	

err_division_by_zero:
	sw $a0, string_division_by_zero
	j reset_waiting_state
	nop
string_division_by_zero:
     	.asciiz "Error: Division by zero" # null terminator inserted at end of string
	nop	

err_index_out_of_bounds:
	sw $a0, string_index_out_of_bounds
	j reset_waiting_state
	nop
string_index_out_of_bounds:
     	.asciiz "Error: Index out of bounds" # null terminator inserted at end of string
	nop	

reset_waiting_state:
		li $t4, WAITING_STATE
		or $t0, $t4, $1  # turn on WAITING bit
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state
		sw $t3, 0($t1) # store the new state
		#TODO: determine where the program needs to continue from or if registers need to be reset
		jal calc_begin
		nop