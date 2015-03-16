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


	
# Performs xor operation on $a0 and $a1 and stores the result in $v0
# Equivalent to (($a0 OR $a1) AND ($a0 NAND $a1))
xor:
	or $t0, $a0, $a1 # first part
	and $t1, $a0, $a1 # second part (partial)
	nor $t1, $t1, $0 # invert to achieve NAND gate
	and $v0, $t0, $t1
	jr $ra
	nop
