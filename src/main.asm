# main source file

.org 0x10000000
.equ SWITCHES		0xf0100000 	# switches
.equ LEDS 			0xf0200000 	# LEDs
.equ INTERUPT_CONTROLLER	0xf0700000 	# Interrupt Controller
.equ ENABLE_INTERUPTS		5 	# Enable global and uart interupts, ignore all others
.equ STATUS_BIT_MASK		0xfffffffb	# Used to clear the uart status bit
.equ UART_INTERRUPT_VALUE	4	# Value of the interrupt status for uart events
.equ LOWER_BYTE_MASK		0x000000ff	# Masks the lower 8 bits

# Machine States
.equ WAITING_STATE		0b001	# Bit used to represent this machine's "waiting for input" state
.equ CALCULATING_STATE		0b010	# Bit used to represent this machine's "currently calculating result" state

# Input classifications
.equ INVALID_INPUT		5	# Any ASCII character other than 0-9 + - * / ( or )
.equ NUMBER			1	# ASCII characters representing [0-9] i.e. ASCII 48-57
.equ OPERATION		2	# ASCII + * - or /
.equ CONTROL_START		3	# ASCII (
.equ CONTROL_END		4	# ASCII )

# Order of Operations
.equ OOO_CLASS_1		1	# Classification for * and /
.equ OOO_CLASS_2		2	# Classification for + and -

# ASCII Identifiers
.equ MULTIPLICATION		42	# ASCII Code for *
.equ ADDITION		43	# ASCII Code for +
.equ SUBTRACTION		45	# ASCII Code for -
.equ DIVISION		47	# ASCII Code for /
.equ OPEN_PAR		40	# ASCII Code for (
.equ CLOSE_PAR		41	# ASCII Code for )

# Enumerated Identifiers
.equ END_OF_STACK		0
.equ RAW_DATA		1
.equ ASCII_DATA		2
.equ NEGATIVE_OP		3

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
	
	# Set status to WAITING
	li $t0, state
	li $t1, WAITING_STATE
	sw $t1, 0($t0)

main:
	addiu $s5, $s5, 1
	j main
	nop

#process the byte in $a0
process_byte:
	# Display the byte as received input
	move $s7, $ra
	jal libplp_uart_write
	nop
	move $ra, $s7
	
	# Get the current state
	li $t0, state
	lw $t0, 0($t0)

	# Check if WAITING STATE is active
	li $t1, WAITING_STATE
	and $t1, $t0, $t1 
	bne $t1, $0, initial_input_parsing # If WAITING, initialize parsing
	nop
	j register_input_byte # Else, continue parsing
	nop
	
	initial_input_parsing:
		# Reset waiting bit
		li $t4, WAITING_STATE
		nor $t0, $t4, $0  # mask to turn off WAITING bit
		li $t1, state
		lw $t2, 0($t1) # get the current state
		and $t3, $t0, $t2 # new state, turn off WAITING
		sw $t3, 0($t1) # store the new state

		move $s7, $ra
		jal calc_begin
		nop
		move $ra, $s7
	
	register_input_byte:
		move $s7, $ra
		jal calc_push_ascii
		nop
		jr $s7
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
	jal libplp_uart_read
	nop
	move $a0, $v0
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
err_invalid_input:
	#TODO Handle err
	j exit_program
	nop

err_invalid_state:

err_undefined:
	#TODO Handle err
	j exit_program
	nop



exit_program:
