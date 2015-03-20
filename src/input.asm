# The first (least significant) byte holds the previous input byte
# The second byte holds the previous input classification
# The third byte holds the last OPERATION input
# The fouth byte holds the classification of the last OPERATION input
input_var_previous:
	.word 0

input_get_previous_byte:
	li $a0, 0
	j input_extract_byte_from_previous
	nop

input_get_previous_classification:
	li $a0, 8
	j input_extract_byte_from_previous
	nop

input_get_previous_operation:
	li $a0, 16
	j input_extract_byte_from_previous
	nop

input_get_previous_operation_class:
	li $a0, 24
	j input_extract_byte_from_previous
	nop

input_extract_byte_from_previous:
	li $v0, input_var_previous
	lw $v0, 0($v0)
	srlv $v0, $v0, $a0
	li $t0, LOWER_BYTE_MASK
	and $v0, $v0, $t0
	jr $ra
	nop

#########################################
# Returns the Order of Operations classifcation of $a0, via $v0, as represented by:
# 	OOO_CLASS_1, OOO_CLASS_2, or INVALID_INPUT
#########################################
get_operation_classification:
	li $t0, 42 # ASCII of *
	beq $a0, $t0, classify_ooo_1
	nop
	li $t0, 43 # ASCII of +
	beq $a0, $t0, classify_ooo_2
	nop
	li $t0, 45 # ASCII of -
	beq $a0, $t0, classify_ooo_2
	nop
	li $t0, 47 # ASCII of /
	beq $a0, $t0, classify_ooo_1
	nop
	j classify_invalid # Else, value is invalid
	nop

	classify_ooo_1:
		li $v0, OOO_CLASS_1
		addiu $v1, $v0, -48
		jr $ra
		nop
	classify_ooo_2:
		li $v0, OOO_CLASS_2
		jr $ra
		nop
	classify_invalid:
		li $v0, INVALID_INPUT
		jr $ra
		nop

#########################################
# Returns the input classifcation of $a0, via $v0, as represented by:
# 	NUMBER, OPERATION, CONTROL_START, CONTROL_END, or INVALID_INPUT
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
	beq $t1, $0, classify_number_invalid
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
		addiu $v1, $a0, -48
		jr $ra
		nop
	classify_operation:
		li $v0, OPERATION
		jr $ra
		nop
	classify_number_invalid:
		li $v0, INVALID_INPUT
		jr $ra
		nop
