calc_push_ascii:
	li $t0, 32 # ASCII Code for " " (space)
	beq $a0, $t0, skip # Disregard Whitespace
	nop
	
	#Classify input
	move $s6, $ra
	jal get_input_classification
	nop
	move $ra, $s6

	# Validate input
	li $t0, INVALID_INPUT
	beq $v0, $t0, err_inavlid_input # If byte is invalid, err out
	nop
	
	##Expected state: ascii code is in $a0, classification is in $v0, number value (if applicable) is in $v1

	# Else, parse byte and add it to the stack
	li $t0, NUMBER
	beq $v0, $t0, calc_push_number
	nop
	li $t0, OPERATION
	beq $v0, $t0, calc_push_operation
	nop
	li $t0, CONTROL_START
	beq $v0, $t0, calc_push_control_start
	nop
	li $t0, CONTROL_END
	beq $v0, $t0, calc_push_control_end
	nop

	skip:
		jr $ra
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
	# If operation is subtraction, parse it
	li $t0, SUBTRACTION
	beq $a0, $t0, parse_subtraction
	nop
	
	# Else, push the operation
	push $a0 # OP Code
	li $t0, ASCII_DATA
	push $t0 # Encoding
	
	jr $ra
	nop

	parse_subtraction:
		move $s0, $a0 # Save current byte
		pop $t0 # Holds previous encoding
		#Check if previous is raw
		li $t1, RAW_DATA
		beq $t0, $t1, previous_is_raw
		nop
		#Check if previous is negative_operation
		li $t1, NEGATIVE_OP
		beq $t0, $t1, negate_operation
		nop
		# Else, previous byte is ASCII
		move $s6, $ra
		pop $a0 # Get previous value
		jal get_input_classification
		nop
		move $ra, $s6

		li $t0, OPERATION
		beq $t0, $v0, previous_is_operation
		nop
		li $t0, CONTROL_START
		beq $t0, $v0, previous_is_control_start
		nop

		# Else, restore previous and push operation
		push $a0 # Previous Value
		li $t0, ASCII_DATA
		push $t0 # Previous Encoding
		push $s0 # Current Value
		push $t0 # Current Encoding
		jr $ra
		nop
		
		previous_is_raw:
			li $t1, RAW_DATA
			push $t1 # Restore Previous Encoding
			push $a0 # OP Code
			li $t0, ASCII_DATA
			push $t0 # Encoding
			jr $ra
			nop
		
		previous_is_operation:
		previous_is_control_start:
			# Restore previous
			push $a0 # Previous Value
			li $t0, ASCII_DATA
			push $t0 # Previous Encoding
			li $t0, NEGATIVE_OP # Current value represents negative operation
			push $t0 # Push Current Operation
			jr $ra
			nop
		
		negate_operation:
			# Don't restore previous operation
			# Don't add current operation
			jr $ra
			nop


				
calc_push_control_start:
	pop $t0 # Previous Encoding
	li $t1, RAW_DATA
	beq $t0, $t1, append_multiplication # If previous is a number (e.g., 3(2) ), it represents multiplication (e.g., 3 * (2) )
	nop

	# Else, push the control start
	push $t0 # Restore Previous Encoding
	li $t0, ASCII_DATA # Encoding
	push $a0 # Push Control Start
	push $t0 # Push Encoding
	jr $ra
	nop

	append_multiplication:
		push $t0 # Restore Previous Encoding
		li $t0, MULTIPLICATION # ASCII Code
		push $t0 # Multiplication Operation
		li $t0, ASCII_DATA # Operation Encoding
		push $t0 # Push Operation Encoding
		push $a0 # Push Control Start
		push $t0 # Push Encoding
		jr $ra
		nop

			
calc_push_control_end:
	j condense_stack
	nop

calc_begin:
	# Push NULL to stack, to indicate stopping position
	push $0
	push $0
	jr $ra
	nop

calc_stop:
	

# Space to hold the last 5 elements
# The expected order is: NUMBER, OPERATION, NUMBER, OPERATION, NUMBER
# 	with the first element (from left to right) being stored 
#	in 0(calc_equation_partial), the second element in 
#	4(calc_equation_partial), etc.
calc_equation_partial:
	.space 5

# Space to hold the encoding of the last 5 elements
# Each "index" holds the encoding of the corresponding 
# 	"index" in calc_equation_partial
calc_equation_partial_encoding:
	.space 5

# Holder for the address that should be returned to after condense_stack.
# This will be the same as $ra when condense_stack begins.
var_condense_stack_return_address:
	.word 0

condense_stack:
	# Stash the return address
	li $t0, var_condense_stack_return_address
	sw $ra, 0($t0)
	
	condense_stack_recursive:
		# Populate partial equation
		jal condense_stack_store_last5
		nop

		# TODO: evaluate all negative_operators
		
		# Evaluate Open-Parenthesis
		li $t0, calc_equation_partial
		lw $t1, 0($t0) # Value of first element
		li $t2, OPEN_PAR # ASCII Value of '('
		beq $t1, $t2, err_inavlid_input
		nop
		
		lw $t1, 4($t0) # Value of second element
		li $t2, OPEN_PAR # ASCII Value of '('
		beq $t1, $t2, condense_stack_return
		nop
		
		lw $t1, 8($t0) # Value of third element
		li $t2, OPEN_PAR # ASCII Value of '('
		beq $t1, $t2, err_inavlid_input
		nop
		
		lw $t1, 12($t0) # Value of fourth element
		li $t2, OPEN_PAR # ASCII Value of '('
		beq $t1, $t2, condense_lower3
		nop
		
		lw $t1, 16($t0) # Value of fifth element
		li $t2, OPEN_PAR # ASCII Value of '('
		beq $t1, $t2, err_inavlid_input
		nop
		
		
		# Validate State. 
		#If fourth element in calc_equation_partial_encoding is not ASCII, input is invalid
		li $t0, calc_equation_partial
		li $t1, calc_equation_partial_encoding
		lw $t2, 12($t1) # Encoding of fourth element
		li $t4, ASCII_DATA
		bne $t2, $t4, err_inavlid_input
		nop
		#If fifth and third elements in calc_equation_partial_encoding are not RAW, input is invalid
		lw $t2, 8($t1) # Encoding of third element
		li $t4, RAW_DATA
		bne $t2, $t4, err_inavlid_input
		nop
		lw $t2, 16($t1) # Encoding of fifth element
		li $t4, RAW_DATA
		bne $t2, $t4, err_inavlid_input
		nop
		
		# Evaluate Order of Operations
		lw $a0, 12($t0) # Value of fourth element
		jal get_operation_classification # Stores op classification in $v0	
		nop	
		li $t4, OOO_CLASS_1
		beq $v0, $t4, condense_lower3 # If operator is */, it takes priority
		nop
		# Else, evaluate second element
		li $t0, calc_equation_partial
		lw $a0, 12($t0) # Value of second element
		jal get_operation_classification # Stores op classification in $v0	
		nop	
		li $t4, OOO_CLASS_1
		beq $v0, $t4, condense_upper3 # If operator is */, it takes priority
		nop
		#Else, lower operation is clear to process
		j condense_lower3
		nop

	condense_stack_return:
		# Restore the return address
		li $t0, var_condense_stack_return_address
		lw $ra, 0($t0)
		# Return
		jr $ra
		nop

# Psuedo-Code:
# 	Process the last 3 elements (NUMBER, OPERATION, NUMBER)
# 	Restore first 2 elements to stack
# 	Push new element to stack
# 	Continue recursion
condense_lower3:
	# Get arguments & perform calculation
	li $t0, calc_equation_partial
	lw $a0, 8($t0) # First Operand
	lw $a2, 12($t0) # Operator
	lw $a1, 16($t0) # Second Operand
	move $s4, $ra
	jal calculate
	nop
	move $ra, $s4
	
	# Restore stack
	li $t0, calc_equation_partial
	li $t1, calc_equation_partial_encoding

	lw $t2, 0($t0) # Value
	lw $t3, 0($t1) # Encoding
	push $t2
	push $t3

	lw $t2, 4($t0) # Value
	lw $t3, 4($t1) # Encoding
	push $t2
	push $t3

	move $t2, $v0 # Value
	li $t3, RAW_DATA # Encoding
	push $t2
	push $t3
	
	j condense_stack_recursive
	nop

# Psuedo-Code:
# 	Process the first 3 elements (NUMBER, OPERATION, NUMBER)
# 	Push new element to stack
# 	Restore last 2 elements to stack
# 	Continue recursion
condense_upper3:
	# Get arguments & perform calculation
	li $t0, calc_equation_partial
	lw $a0, 0($t0) # First Operand
	lw $a2, 4($t0) # Operator
	lw $a1, 8($t0) # Second Operand
	move $s4, $ra
	jal calculate
	nop
	move $ra, $s4
	
	# Restore stack
	li $t0, calc_equation_partial
	li $t1, calc_equation_partial_encoding

	move $t2, $v0 # Value
	li $t3, RAW_DATA # Encoding
	push $t2
	push $t3

	lw $t2, 12($t0) # Value
	lw $t3, 12($t1) # Encoding
	push $t2
	push $t3

	lw $t2, 16($t0) # Value
	lw $t3, 16($t1) # Encoding
	push $t2
	push $t3
	
	j condense_stack_recursive
	nop

# Pop the last 5 elements in the stack and their encodings
# into calc_equation_partial and calc_equation_partial_encoding
condense_stack_store_last5:
	li $t0, calc_equation_partial
	li $t1, calc_equation_partial_encoding
	
	# Clear current partial
	sw $0, 0($t0)
	sw $0, 4($t0)
	sw $0, 8($t0)
	sw $0, 12($t0)
	sw $0, 16($t0)
	sw $0, 0($t1)
	sw $0, 4($t1)
	sw $0, 8($t1)
	sw $0, 12($t1)
	sw $0, 16($t1)
	
	pop $t2 # Encoding
	pop $t3 # Value
	beq $0, $t2, store_return
	nop
	sw $t3, 16($t0)
	sw $t2, 16($t1)
	
	pop $t2 # Encoding
	pop $t3 # Value
	beq $0, $t2, store_return
	nop
	sw $t3, 12($t0)
	sw $t2, 12($t1)
	
	pop $t2 # Encoding
	pop $t3 # Value
	beq $0, $t2, store_return
	nop
	sw $t3, 8($t0)
	sw $t2, 8($t1)
	
	pop $t2 # Encoding
	pop $t3 # Value
	beq $0, $t2, store_return
	nop
	sw $t3, 4($t0)
	sw $t2, 4($t1)
	
	pop $t2 # Encoding
	pop $t3 # Value
	beq $0, $t2, store_return
	nop
	sw $t3, 0($t0)
	sw $t2, 0($t1)
	
	store_return:
	jr $ra
	nop

calculate:
	addu $v0, $a0, $a1
	jr $ra
	nop

calculator_end:
