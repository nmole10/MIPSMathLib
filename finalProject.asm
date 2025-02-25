.data
greeting: .asciiz "Hello, users may use this tool to run a variety of non-trivial floating point operations.\n"
opMenu: .asciiz "Options are as listed;\n 1: Square Root sqrt(x)\n 2: Natural Logarithm ln(x)\n 3: e^x \n 4: x^y\n 5: Trigonometry\n 6: Factorial\n"
selection: .asciiz "Select an operation/function to run: "
errorMsg: .asciiz "Invalid, please try again.\n" 
realPositiveNumber: .asciiz "Enter a non-negative real number for x: "
realNumber: .asciiz "Enter a real number for x: "
realNumberY: .asciiz "Enter a real number for y: "
returnSqrt: .asciiz "Square root of inputted value is: "
invalidInput: .asciiz "Invalid input, value must be greater than 0. Please try again.\n"
lnMsg: .asciiz "Approx. natural logarithm using taylor series: "
eMsg: .asciiz "Approx. value of e^x using taylor series: "
xyMsg:.asciiz "Approx. value of x^y for any x and y using taylor series: "
trigMenu: .asciiz "Select a trigonomic function:\n 1: Sin(x)\n 2: Cos(x)\n 3: Tan(x)\n 4: Cot(x)\n 5: Sec(x)\n 6: Csc(x)\n"
angle: .asciiz "Enter an angle in radians: "
factMsg: .asciiz "The factorial of x is: "
zero: .float 0.0
.text
main:
li $v0, 4		# print greeting
la $a0, greeting
syscall
li $v0, 4		# print Ops Menu
la $a0, opMenu
syscall

select:
li $v0, 4		# prompt user to select an op
la $a0, selection
syscall
li $v0, 5
syscall
move $t0, $v0		# move option number selected to $t0
# validate then send to appropriate function call
bgt $t0, 6, error
blt $t0, 1, error	# validate the number is b/w appropriate range of options

# branch off to appropriate operation label
selectionLoop: 
beq $t0, 1, square_root
beq $t0, 2, ln
beq $t0, 3, ePower
beq $t0, 4, powerFX
beq $t0, 5, trig
beq $t0, 6, fact
j selectionLoop

# FP OP 1 ########################################
# square root stack setting & function calling
square_root:
li $v0, 4
la $a0, realPositiveNumber
syscall
li $v0, 6
syscall
mov.s $f2, $f0
# step 1:
addiu $sp, $sp, -12
# step 2: 
swc1 $f2, 0($sp)
sw $ra, 8($sp)
# step 3:
jal squareRoot
# step 4: load return vals
lwc1 $f30, 4($sp)	# return value will always be moved to $f30
lw $ra, 8($sp)
# step 5: 
addiu $sp, $sp, 12

# print square root output msg
li $v0, 4
la $a0, returnSqrt
syscall
j answer

# FP OP 2 ######################################
ln:
l.s $f1, zero		# prompt input and store in f2
li $v0, 4
la $a0, realPositiveNumber
syscall
li $v0, 6
syscall
mov.s $f2, $f0
# validate
c.lt.s $f2, $f1
bc1t errorLn

# step 1: 		# function call
addiu $sp, $sp, -12
# step 2: 
swc1 $f2, 0($sp)
# step 3: 
jal natLog 
beq $t1, -1, invalid
# step 4: load return vals
lwc1 $f30, 4($sp)
# step 5: 
addiu $sp, $sp 12

# print nat log output msg
li $v0, 4
la $a0, lnMsg
syscall
j answer

# FP OP 3 ########################################
ePower:
li $v0, 4
la $a0, realNumber		# prompt input and store in f2
syscall
li $v0, 6
syscall
mov.s $f2, $f0
# step 1: 
addiu $sp, $sp, -12
# step 2: 
swc1 $f2, 0($sp)
# step 3: 
jal eTOx 
# step 4: load return vals
lwc1 $f30, 4($sp)
# step 5: 
addiu $sp, $sp 12

# print e ^ x output msg
li $v0, 4
la $a0, eMsg
syscall
j answer

# FP OP 4 #######################################
powerFX: 
li $v0, 4
la $a0, realNumber	# prompt input and store x in f1
syscall
li $v0, 6
syscall
mov.s $f1, $f0
li $v0, 4
la $a0, realNumberY	# prompt input and store y in f2
syscall
li $v0, 6
syscall
mov.s $f2, $f0
# step 1: 
addiu $sp, $sp, -16
# step 2: 
swc1 $f1, 0($sp)	# store x to 0
swc1 $f2, 4($sp)	# store y to 4
sw $ra, 12($sp)
# step 3: 
jal xTOy 
# step 4: load return vals
lwc1 $f30, 8($sp)
lw $ra, 12($sp)
# step 5: 
addiu $sp, $sp 16

# print e ^ x output msg
li $v0, 4
la $a0, xyMsg
syscall
j answer


# FP OP 5 #############################################################
trig:
li $v0, 4		# print trig menu
la $a0, trigMenu
syscall
li $v0, 4
la $a0, selection	# prompt user to select option
syscall
li $v0, 5
syscall
move $t0, $v0		# option number in t0
li $v0, 4
la $a0, angle		# prompt user to enter angle
syscall
li $v0, 6
syscall
mov.s $f1, $f0
# validate option number selected
blt $t0, 1, errorTrig
bgt $t0, 6, errorTrig
# step 1: 
addiu $sp, $sp, -16
# step 2:
swc1 $f1, 0($sp)	# store angle into stack
sw $t0, 4($sp)		# store operation number
sw $ra, 12($sp)		# store ra
# step 3:
jal trigFX
# step 4: 
lwc1 $f30, 8($sp)	# load return value
# step 5:
addiu $sp, $sp, 16
j answer


# FP OP ##############################################################
fact: 
l.s $f1, zero			# intialize f1 for comparison 
li $v0, 4
la $a0, realPositiveNumber	# prompt for input and store in f2
syscall
li $v0, 6
syscall
mov.s $f2, $f0
c.lt.s $f2, $f1
bc1t errorFact
# step 1:
addiu $sp, $sp, -12
# step 2: 
swc1 $f2, 0($sp)
sw $ra, 8($sp)
# step 3:
jal factorial
# step 4: load return vals
lwc1 $f30, 4($sp)	# return value will always be moved to $f30
lw $ra, 8($sp)
# step 5: 
addiu $sp, $sp, 12

# print square root output msg
li $v0, 4
la $a0, factMsg
syscall
j answer

errorLn:	# print error msg then send back to Ln
li $v0, 4
la $a0, errorMsg
syscall
j ln

errorFact:	# print error msg then send back to fact
li $v0, 4
la $a0, errorMsg
syscall
j fact

errorTrig:	# print error msg then send back to trig
li $v0, 4
la $a0, errorMsg
syscall
j trig

answer: 	# return values are always stored in f30
li $v0, 2
mov.s $f12, $f30
syscall 
j end

invalid:	# print invalid input msg then send back to ln
li $v0, 4
la $a0, invalidInput
syscall
j ln

error:
li $v0, 4
la $a0, errorMsg
syscall
j select




#terminate program
end: 
li $v0, 10
syscall
