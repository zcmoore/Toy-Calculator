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
	beq $v0, $t0, err_invalid_input # If byte is invalid, err out
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
	# Clear current partial equation
	li $t0, calc_equation_partial
	li $t1, calc_equation_partial_encoding
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
		vlidate_first:
		# First element (from the right) should always be a number
		pop $t0 # Encoding
		beq $t0, $0, err_invalid_state # Reached end of stack prematurly
		nop
		li $t1, ASCII_DATA
		beq $t0, $t1, err_invalid_input # Indicates a case such as: ...+) or ...*) or ...() etc.
		nop
		li $t1, NEGATIVE_OP
		beq $t0, $t1, err_invalid_input # Indicates a case such as ...-)
		nop
		#Else, encoding is RAW
		li $t1, calc_equation_partial_encoding
		li $t2, calc_equation_partial
		sw $t0, 16($t1) # Store partial equation encoding
		pop $t0 # Value
		sw $t0, 16($t2) # Store value
		
		validate_second:
		# Second element (from right) should be an operation, negative, open parenthesis, or end of stack
		pop $t0 # Encoding
		pop $t1 # Value
		li $t5, calc_equation_partial_encoding
		li $t6, calc_equation_partial
		sw $t0, 12($t5) # Store encoding
		sw $t1, 12($t6) # Store value

		beq $t0, $0, end_of_stack # Reached end of stack
		nop
		li $t4, RAW_DATA
		beq $t0, $t4, err_invalid_state # Two numbers should not be stacked against each other
		nop
		li $t4, NEGATIVE_OP
		bne $t0, $t4, check_ascii2 # If not negative operation, check for ascii
		nop
		# Else, perform operation on previous value, restore stack, and recurse
		push $t1 # Grabbed too much - restore the next element's encoding
		li $t6, calc_equation_partial
		lw $t1, 16($t6) # Load previous value
		li $t0, RAW_DATA # Endoding
		li $t2, -1
		mullo $t1, $t1, $t2 # Multiply previous by -1
		push $t1
		push $t0
		j condense_stack_recursive #recurse
		nop

		check_ascii2:
		# Evaluate Order of Operations
		# Value of operator is in $t1
		li $t4, MULTIPLICATION
		beq $t1, $t4, condense_stack_subroutine_operate # If operator is *, it takes priority
		nop
		li $t4, DIVISION
		beq $t1, $t4, condense_stack_subroutine_operate # If operator is /, it takes priority
		nop
		li $t4 OPEN_PAR
		bne $t1, $t4, validate_third # If not (, continue parsing
		nop
		# Else, remove open operator push the previous number, and return
		li $t6, calc_equation_partial
		lw $t1, 16($t6) # Load value of first number (from right)
		push $t1 # Previous Value
		j condense_stack_return
		nop

		validate_third:
		# Third element (from the right) should always be a number
		pop $t0 # Encoding
		beq $t0, $0, err_invalid_state # Reached end of stack prematurly
		nop
		li $t1, ASCII_DATA
		beq $t0, $t1, err_inavlid_input # Indicates a case such as: ...++) or ...-+) or (+... etc.
		nop
		li $t1, NEGATIVE_OP
		beq $t0, $t1, err_invalid_input # Indicates a case such as ...-*)
		nop
		#Else, encoding is RAW
		li $t1, calc_equation_partial_encoding
		li $t2, calc_equation_partial
		sw $t0, 8($t1) # Store partial equation encoding
		pop $t0 # Value
		sw $t0, 8($t2) # Store value
		
		validate_fourth:
		# Fourth element (from right) should be an operation, negative, open parenthesis, or end of stack
		pop $t0 # Encoding
		pop $t1 # Value
		li $t5, calc_equation_partial_encoding
		li $t6, calc_equation_partial
		sw $t0, 4($t5) # Store encoding
		sw $t1, 4($t6) # Store value
		# Validate
		beq $t0, $0, condense_lower3_restore_null_return # Reached end of stack; process bottom 3
		nop
		li $t4, RAW_DATA
		beq $t0, $t4, err_invalid_state # Cannot have 2 numbers directly adjacent to one another
		nop
		li $t4, NEGATIVE_OP
		bne $t0, $t4, check_ascii4 # If not negative operation, check for ascii
		nop
		# Else, perform operation on previous value, restore stack, and recurse
		li $t5, calc_equation_partial_encoding
		li $t6, calc_equation_partial
		# Combine & Push elements 3 and 4
		lw $t1, 8($t6) # Load previous value
		li $t0, RAW_DATA # Endoding
		li $t2, -1
		mullo $t1, $t1, $t2 # Multiply previous by -1
		push $t1
		push $t0
		# Restore element 2
		lw $t0, 12($t5) # 2nd element encoding
		lw $t1, 12($t6) # 2nd element value
		push $t1
		push $t0
		# Restore element 1
		lw $t0, 16($t5) # 1st element encoding
		lw $t1, 16($t6) # 1st element value
		push $t1
		push $t0
		# Recurse
		j condense_stack_recursive
		nop

		check_ascii4:
		# Evaluate Order of Operations
		# Value of operator is in $t1
		li $t4, MULTIPLICATION
		beq $t1, $t4, condense_stack_subroutine_operate_top # If operator is *, it takes priority
		nop
		li $t4, DIVISION
		beq $t1, $t4, condense_stack_subroutine_operate_top # If operator is /, it takes priority
		nop
		li $t4 OPEN_PAR
		beq $t1, $t4, condense_lower3_return # If (, remove the open operator, perform the previous operation, and return
		nop
		# Else, restore operator and perform bottom 3 operation, then recurse
		push $t1 # Value
		push $t0 # Encoding
		j condense_lower3_recurse
		nop
		
		
	condense_stack_subroutine_operate:
		move $a2, $t1 # Load operator as argument
		li $t6, calc_equation_partial
		lw $a1, 16($t6) # Load previous value as second operand
		pop $a0 # Previous encoding
		li $t4, RAW_DATA
		bne $a0, $t4, err_invalid_input #previous should be number
		nop
		pop $a0 # Previous value; use as first operand
		jal calculate
		nop
		li $t4, RAW_DATA # Encoding
		push $v0 # Result Value
		push $t4 # Result Encoding
		j condense_stack_recursive #recurse
		nop

	condense_stack_subroutine_operate_top:
		move $a2, $t1 # Load operator as argument
		li $t6, calc_equation_partial
		lw $a1, 8($t6) # Load previous value as second operand
		pop $a0 # Previous encoding
		li $t4, RAW_DATA
		bne $a0, $t4, err_invalid_input #previous should be number
		nop
		pop $a0 # Previous value; use as first operand
		jal calculate
		nop
		li $t4, RAW_DATA # Encoding
		push $v0 # Result Value
		push $t4 # Result Encoding
		j condense_stack_recursive #recurse
		nop
		# Restore element 2
		lw $t0, 12($t5) # 2nd element encoding
		lw $t1, 12($t6) # 2nd element value
		push $t1
		push $t0
		# Restore element 1
		lw $t0, 16($t5) # 1st element encoding
		lw $t1, 16($t6) # 1st element value
		push $t1
		push $t0
		# Recurse
		j condense_stack_recursive
		nop

	end_of_stack:
		push $0 # Restore stack termination element
		# Restore first value
		li $t5, calc_equation_partial_encoding
		li $t6, calc_equation_partial
		lw $t0, 16($t5) # Encoding of first element
		lw $t1, 16($t6) # Value of first element
		push $t1
		push $t0
		j condense_stack_return
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
# 	Push new element to stack
# 	Continue recursion
condense_lower3_recurse:
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

	move $t2, $v0 # Value
	li $t3, RAW_DATA # Encoding
	push $t2
	push $t3
	
	j condense_stack_recursive
	nop


condense_lower3_restore_null_return:
	push $0
# Psuedo-Code:
# 	Process the last 3 elements (NUMBER, OPERATION, NUMBER)
# 	Push new element to stack
# 	return 
condense_lower3_return:
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

	move $t2, $v0 # Value
	li $t3, RAW_DATA # Encoding
	push $t2
	push $t3
	
	j condense_stack_return
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

calculate:
	addu $v0, $a0, $a1
	jr $ra
	nop

	li $t0, 43	#load ASCII value of + sign
	beq $t0, $a2, add	#branch to add function
	nop
	
	li $t0, 45	#load ASCII value of - sign
	beq $t0, $a2, subtract #branch to subtraction function
	nop
	
	li $t0, 42	#load ASCII value of * sign
	beq $t0, $a2, multiply #branch to multiplication function
	nop
	
	li $t0, 47	#load ASCII value of / sign
	beq $t0, $a2, divide #branch to division function
	nop
	
	#Math Operations
	add:
	addu $v0, $a0, $a1	#$a0 + $a1, store result in $v0
	j err_overflow #overflow
	nop

	subtract:
	subu $v0, $a0, $a1	#$a0 - $a1, store result in $v0	
	j eerr_underflow #underflow
	nop
	
	multiply:
	mullo $v0, $a0, $a1	#$a0 * $a1, store result in $v0
	j err_overflow #overflow
	nop
	
	divide:
	call div	#$a0 / $a1, store result in $v0
	nop
	j err_division_by_zero #divide by zero error
	nop
	j err_overflow #overflow
	nop
	j err_underflow #underflow
	nop

calculator_end:
	j condense_stack
	nop
