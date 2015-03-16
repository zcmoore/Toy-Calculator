calc_push_ascii:
	# Display the byte as received input
	jal libplp_uart_write
	nop

	# Validate input
	jal get_input_classification
	nop
	li $t0, INVALID_INPUT
	beq $v0, $t0, err_inavlid_input # if byte is invalid, err out
	nop
	
	# Else, parse byte and add it to the stack
	li $t0, NUMBER
	beq $v0, $t0, calc_push_number
	nop
	li $t0, OPERATION
	beq $v0, $t0, calc_push_operation
	nop
	li $t0, CONTROL_START
	beq $v0, $t0, register_control_start
	nop
	li $t0, CONTROL_END
	beq $v0, $t0, register_control_end
	nop
		
calc_push_number:
	move $t0, $v1 # Holds the binary value of the current byte
	pop $t1 # Encoding of the last entry

	# If last entry is raw, treat the current byte as a digit of the last number
	li $t2, RAW_DATA
	beq $t1, $t2, calc_push_number_append_digit
	nop

	# Else, treat the current byte as a new number
	push $t1 # Restore last encoding
	push $t0 # Push value
	push $t2 # Push Encoding
	jr $ra
	nop

	calc_push_number_append_digit:
		pop $t3 # Binary value of the last number
		li $t4, 10 # Shift last number left by once decimal digit
		mullo $t4, $t3, $t4 # Modified "last number"
		addu $t4, $t4, $t0 # Add the new digit
		
		# Put the new number back on the stack
		push $t4 # New Number
		push $t2 # Encoding
		jr $ra
		nop

# Currently being overhauled. calc_push_operation code may no longer be relevant
calc_push_operation:
	move $s0, $a0
	jal input_get_previous_classification
	nop
	move $a0, $s0
	li $t0, OPERATION
	beq $v0, $t0, register_operation_check_class # If the previous input was an opertation, check it's class
		register_operation_check_class:
		move $s0, $a0 # Hold the input byte
		jal get_operation_classification
		nop
		move $s1, $v0 # Hold the operation classification
		jal input_get_previous_operation_class
		nop
		move $s2, $v0 # Hold the previous operation classification
		move $a0, $s0 # Restore the input byte
		bne $s1, $s2, 
	append_par0:
				
		register_control_start:
			
		register_control_end:
		
		register_push:
			

calc_begin:
	# Push NULL to stack, to indicate stopping position
	push $0
	jr $ra
	nop

calc_stop:
	

condense_stack:
