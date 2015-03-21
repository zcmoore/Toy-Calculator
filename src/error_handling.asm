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
string_invalid_state:
     	.asciiz "Error: Invalid State"
string_undefined:
     	.asciiz "Error: Undefined"

err_overflow:
	li $a0, string_overflow
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

err_underflow:
	li $a0, string_underflow
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

# This misspelling appears throughout the code, and should be replaced.
err_inavlid_input:
err_invalid_input:
	li $a0, string_invalid_input
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

err_division_by_zero:
	li $a0, string_division_by_zero
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

err_index_out_of_bounds:
	li $a0, string_index_out_of_bounds
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

err_invalid_state:
	li $a0, string_invalid_state
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

err_undefined:
	li $a0, string_undefined
	j libplp_uart_write_string
	nop
	j reset_waiting_state
	nop

reset_waiting_state:
	#print "Done! Ready for the next input."
	li $a0, complete_string
	jal libplp_uart_write_string
	nop
		li $t4, WAITING_STATE
		ori $t0, $t4, 1  # turn on WAITING bit
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state
		sw $t3, 0($t1) # store the new state
		#TODO: verify
		j main
		nop

error_handling_end:
