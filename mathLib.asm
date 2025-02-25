.data
ln2: .float 0.693147    # Precomputed ln(2)
e: .float 2.718281828	# value of e^1
epsilon: .float 0.0001	
one: .float 1.0
zero: .float 0.0
two: .float 2.0
three: .float 3.0
pi: .float 3.1415927		# pi
two_pi: .float 6.2831854	# 2pi
trigMsg: .asciiz "Calculated value of trig function for angle x: "

.text

# NON-TRIVIAL FP OP 1
.globl squareRoot
squareRoot: 
# A: load params
lwc1 $f2, 0($sp)
# B: business logic, run sqrt op
sqrt.s $f6, $f2
# C: store return values
swc1 $f6, 4($sp)
# D: return to caller
jr $ra

# NON-TRVIAL FP OP 2
.globl natLog
natLog:
# step A: load params, initialize regs
   lwc1 $f3, 0($sp)	# load value of x from stack
   # initialize values
   l.s $f0, zero	# load zero in f0
   l.s $f1, one		# load one into f1
   l.s $f2, two		# load two into f2
   li $t0, 0		# initialize k counter
   lwc1 $f8, epsilon	# load epsilon
# step B: business logic
   # validate
  
   c.lt.s $f3, $f1	# check if x is less than 1
   bc1t compute_very_small		
   c.lt.s $f3, $f2	# check if x < 2
   bc1t compute_ln_small
# normalize x -> x = 2^k * m (1 <= m < 2)
	normalize:
	c.lt.s $f3, $f2 	# if input is less than 2, then ln(x) = ln(m), branch to compute
	bc1t compute_ln_large 
	div.s $f3, $f3, $f2	# divide input by 2
	addi $t0, $t0, 1	# increment k counter by 1
	j normalize
	# initialize
	compute_ln_large:
	# compute ln(m)
	sub.s $f4, $f3, $f1	# f4 = y = x - 1
	mov.s $f5, $f4		# f5 = current term (y^n/n), start with y
	mov.s $f6, $f4		# f6 = ln(m), start with y
	mov.s $f20, $f1		# sign indicator
		taylor_large:
		neg.s $f20, $f20
		mov.s $f10, $f2		# f10 = denominator counter starting with 2 
		# compute next term: term = -term * y^n/n
		mul.s $f5, $f5, $f4	# term *= y(y^n)
		mov.s $f15, $f5		# move numerator to f15
		div.s $f16, $f15, $f10	# term /= n, starting with 2
		mul.s $f16, $f16, $f20	# multiply by sign
		add.s $f6, $f6, $f16	# ln(m) (+,-)= term
		# increment n
		add.s $f10, $f10, $f1	
		# check if | term | < epsilon
		abs.s $f7, $f5		# f7 = | term |
		c.lt.s $f7, $f8		# if |term| < epsilon, branch to done
		bc1t done_large
		j taylor_large
		
		done_large: 
		lwc1 $f9, ln2		# load ln2
		mtc1 $t0, $f11		# move k to f11
		cvt.s.w $f11, $f11	# convert k to FP
		mul.s $f12, $f9, $f11	# f12 = k * ln2, is 0 if x < 2 thus ln(x) = ln(m)
		add.s $f6, $f6, $f12	# f6 = ln(x )= ln(m) + k * ln(2)
		swc1 $f6, 4($sp)
		beq $t2, 1, done_very_small
		#beq $t2, 2, done_small
		
		j endLN
	compute_ln_small:
	sub.s $f4, $f3, $f1	# f4 = y = x - 1
	mov.s $f5, $f4		# f5 current term
	mov.s $f6, $f4		# ln(x) accumulator
	mov.s $f10, $f2		# denominator set to 2 starting from 2nd term
	mov.s $f20, $f1		# sign indicator at 1
		taylor_small:
		neg.s $f20, $f20	
		mul.s $f5, $f5, $f4	# term *= y *= x-1
		mov.s $f15, $f5		# numerator (1-x)^n
		div.s $f9, $f15, $f10	# term /= n
		mul.s $f9, $f9, $f20
		add.s $f6, $f6, $f9	# ln(x) -= term
		add.s $f10, $f10, $f1 	# increment denominator by 1
		abs.s $f7, $f5		# f7 = |term|
		c.lt.s $f7, $f8		# check if f7 is less than f8
		bc1t done_small
		
		j taylor_small
		
		done_small:
		swc1 $f6 4($sp)
		
		j endLN
		
	compute_very_small: 
	div.s $f4, $f1, $f3	# f4 = y = 1/x
	li $t2, 1		# indicator initialized
	mov.s $f3, $f4
	j normalize
	
		done_very_small:
		lwc1 $f6, 4($sp)
		neg.s $f6, $f6
		swc1 $f6, 4($sp)
		li $t2, 0	# clear indicator
		j endLN
		
# step D: return to caller	
	endLN:
	jr $ra
	
	
.globl eTOx
eTOx:
# step A: load params
lwc1 $f3, 0($sp)	# load value of x into f3
# initialize
l.s $f1, one		# f1 = 1.0 (current term)
l.s $f2, one		# f2 = 1.0 (starting result)
li $t0, 1		# factorial counter, n = 1

# step B: business logic
	compute_exp:
	# compute next term
	mul.s $f1, $f1, $f3	# term *= x
	mtc1 $t0, $f4
	cvt.s.w $f4, $f4	# move n to f4 and convert to FP
	div.s $f1, $f1, $f4	# term /= n
	
	# add term to result
	add.s $f2, $f2, $f1	# result += term
	
	# increment n
	addi $t0, $t0, 1
	
	# check if |term| < epsilon
	abs.s $f5, $f1		# f4 = |term|
	lwc1 $f6, epsilon
	c.lt.s $f5, $f6		# check if |term| < epsilon
	bc1t done1		# branch if small enough
	j compute_exp
# step C: store return value
	done1: 
	swc1 $f2, 4($sp)	# store return in stack
# step D: return to caller
	jr $ra
	
.globl xTOy	
xTOy: 
# step A: load params
lwc1 $f3, 0($sp)	# load x into f3
l.s $f8, epsilon	# load epsilon threshold into f8
l.s $f1, one		# f1 = 1
l.s $f0, zero		# f2 = ln(x) accumulator 
l.s $f2, two		# f2 = denominator = 2
# step B: business logic
	# compute ln(x)
	addiu $sp, $sp, -12
	swc1 $f3, 0($sp)
	sw $ra, 8($sp)
	jal natLog		# call natlog to find ln(x)
	lwc1 $f0, 4($sp) 	# f0 = ln(x)
	lw $ra, 8($sp)
	addiu $sp, $sp, 12
	lwc1 $f4, 4($sp)	# load y into f4
	# compute y*ln(x)
	ln_done:
	mul.s $f9, $f0, $f4	# f9 = y * ln(x) = z
	
	# compute e^(y*ln(x))
	mov.s $f10, $f1		# f10 = e^z accumulator starting at 1
	mov.s $f11, $f9		# f11 = current term = z
	add.s $f10, $f10, $f11	# result = 1 + z
	l.s $f12, two		# f12 = n = 2
	
	exp_loop:
	mul.s $f11, $f11, $f9	# current *= z
	div.s $f11, $f11, $f12	# f11 = current /= n
	add.s $f10, $f10, $f11	# f10 = result += current
	
	add.s $f12, $f12, $f1	# increment n by 1
	abs.s $f13, $f11	# |term|
	c.lt.s $f13, $f8	# check if |term| < epsilon
	bc1t exp_done		
	j exp_loop

#step C: store return value to stack
	exp_done:
	swc1 $f10, 8($sp)
# step D: return to caller
	jr $ra
	
.globl trigFX
trigFX:
lw $t1, 4($sp)		# load number of option selected
# iterate to appropriate fx to run
beq $t1, 1, sine
beq $t1, 2, cosine
beq $t1, 3, tangent
beq $t1, 4, cotangent
beq $t1, 5, secant
beq $t1, 6, cosecant

	sine:
	lwc1 $f1, 0($sp) 	# f1 = x
	l.s $f13, one
	l.s $f8, epsilon
	l.s $f2, two_pi		# f2 = 2pi
	l.s $f0, pi		# f0 = pi
	# normalize to -pi, pi
	div.s $f3, $f1, $f2	# f2 = x/2pi
	trunc.w.s $f4, $f3	# truncate to integer
	mul.s $f4, $f4, $f2	# f4 = integer * 2pi
	sub.s $f1, $f1, $f4	# f1 = x mod 2pi = remainder in radians
	
	c.le.s $f0, $f1		# if x > pi
	bc1f skip_negate	# skip negation if not true
	sub.s $f1, $f1, $f0	# x -= pi
	neg.s $f1, $f1		# x = -x
		skip_negate: 
		# initialize variables for the taylor series
		mov.s $f5, $f1	# f5 = current term (X^n / n)
		mov.s $f6, $f1	# f6 = sin(x), start with x
		mul.s $f7, $f1, $f1	# f7 = x^2
		l.s $f9, three	# denominator starts with 3
		l.s $f10, two
		taylor_sine:
		neg.s $f13, $f13 	# alternate sign
		# call factorial function
		# step 1: allocate stack space
		addiu $sp, $sp, -12
		# step 2: write stuff to stack
		swc1 $f9, 0($sp)	
		sw $ra, 8($sp)
		# step 3: call function
		jal factorial
		# step 4: read stuff from stack
		lw $ra, 8($sp)
		lwc1 $f12, 4($sp) # put n! in f12
		# step 5: deallocate
		addiu $sp, $sp, 12
	
		# compute next term
		mul.s $f5, $f5, $f7	# f5 = x^3 previous term *= x^2
		div.s $f4, $f5, $f12	# current term /= n!
		mul.s $f4, $f4, $f13	# term = -term
		add.s $f6, $f6, $f4	# f6 = sin(x) += term
		
		# increment n
		add.s $f9, $f9, $f10	# n += 2
		
		# check if |term| < epsilon
		abs.s $f11, $f4
		c.lt.s $f11, $f8	# if |term| < epsilon
		bc1t doneTrig	
		j taylor_sine
		
	
	cosine:
	lwc1 $f1, 0($sp)	# f1 = x
	l.s $f13, one
	l.s $f8, epsilon
	l.s $f2, two_pi		# f2 = 2pi
	l.s $f0, pi		# f0 = pi
	l.s $f9, two		# f9 = 2, starting factorial
	l.s $f10, two		# f10 = 2 = factorial incrementer 	
	# normalize to -pi, pi
	div.s $f3, $f1, $f2	# f2 = x/2pi
	trunc.w.s $f4, $f3	# truncate to integer
	mul.s $f4, $f4, $f2	# f4 = integer * 2pi
	sub.s $f1, $f1, $f4	# f1 = x mod 2pi = remainder in radians
	c.le.s $f0, $f1		# if x > pi
	bc1f skip_negate_cos	# skip negation if not true
	sub.s $f1, $f1, $f0	# x -= pi
	neg.s $f1, $f1		# x = -x
		skip_negate_cos:
		mov.s $f5, $f13		# f5 = current term starting at 1
		mov.s $f6, $f13		# f6 = cos(x) starting with 1
		mul.s $f7, $f1, $f1	# f7 = x^2
		
		taylor_cosine: 
		neg.s $f13, $f13
		# call factorial function
		# step 1: allocate stack space
		addiu $sp, $sp, -12
		# step 2: write stuff to stack
		swc1 $f9, 0($sp)	
		sw $ra, 8($sp)
		# step 3: call function
		jal factorial
		# step 4: read stuff from stack
		lw $ra, 8($sp)
		lwc1 $f12, 4($sp) # put n! in f12
		# step 5: deallocate
		addiu $sp, $sp, 12
		# compute next term
		mul.s $f5, $f5, $f7	# f5 = 1 * x^2 * x^2 ...
		div.s $f4, $f5, $f12	# current term /= n!
		mul.s $f4, $f4, $f13	# term = -term
		add.s $f6, $f6, $f4	# f6 = sin(x) += term
		
		# increment n
		add.s $f9, $f9, $f10	# n += 2
		
		# check if |term| < epsilon
		abs.s $f11, $f4
		c.lt.s $f11, $f8	# if |term| < epsilon
		bc1t doneTrig	
		j taylor_cosine
		
	tangent: # sin(x) / cos(x)
	li $t2, 2
	j sine
		tanInner:
		mov.s $f19, $f6
		li $t2, 3
		j cosine
		
		tanDone: 
		mov.s $f20, $f6
		div.s $f6, $f19, $f20	# tan(x) in f6
		li $t2, 0	# clear jump indicator
		j doneTrig
		
	cotangent: # cos(x) / sin(x)
	li $t2, 4
	j sine
		cotInner:
		mov.s $f19, $f6
		li $t2, 5
		j cosine
		
		cotDone: 
		mov.s $f20, $f6
		div.s $f6, $f20, $f19	# cot(x) in f6 = cos / sin
		li $t2, 0	# clear jump indicator
		j doneTrig
	secant: # 1/cos(x)
	li $t2, 6
	j cosine
		secDone:
		l.s $f13, one		# reset f13 to 1
		div.s $f6, $f13, $f6	# f6 = sec(x) = 1/cos(x)
		li $t2, 0	# clear jump indicator
		j doneTrig
	
	cosecant: # 1/sin(x)
	li $t2, 1	# initialize indicator
	j sine
	
		cscDone: 
		div.s $f6, $f13, $f6	# f6 = csc = 1/sin
		li $t2, 0	# clear indicator
	
doneTrig:
	beq $t2, 1, cscDone
	beq $t2, 2, tanInner
	beq $t2, 3, tanDone
	beq $t2, 4, cotInner
	beq $t2, 5, cotDone
	beq $t2, 6, secDone
	swc1 $f6, 8($sp)
	li $v0, 4
	la $a0, trigMsg
	syscall
	jr $ra
	
# factorial function
.globl factorial
factorial:
# step A: read params
lwc1 $f31, 0($sp)	# load n into $f31
# step B: business logic
l.s $f30, one	# default return value of 1
l.s $f27, zero	# $f27 = 0
c.le.s $f31, $f27 	# if n <= 0, skip everything and return 1
bc1t fact_done
# recursive case (need to generate n * factorial(n-1))
sub.s $f29, $f31, $f30	# f29 = n-1
# call factorial function (assume result goes into t3 = 
	# step 1: allocate stack space
	addiu $sp, $sp, -16
	# step 2: write stuff to stack
	swc1 $f29, 0($sp)	# store n-1
	sw $ra, 8($sp)
	swc1 $f31, 12($sp)
	# step 3: call function
	jal factorial
	# step 4: read stuff from stack
	lwc1 $f31, 12($sp)	# load n
	lw $ra, 8($sp)
	lwc1 $f28, 4($sp)	# load return value
	# step 5: deallocate
	addiu $sp, $sp, 16
	
mul.s $f30, $f31, $f28 	# f30 = n * factorial(n-1)
# mflo $f30	# result in t1
fact_done:
# step C: write return value to stack
swc1 $f30, 4($sp)
# step D: return to caller
jr $ra
