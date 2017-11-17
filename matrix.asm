.data
#State Arrays

enableArray: .space 80 #track which columns are to be updates
currentRow: .space 80 #track current start of digtial rain for a column
updateQueue: .space 40 #queue to manage columns to send

#Output Strings
userPrompt: .asciiz "Please enter a number from 1 to 40: "

#Useful macros

.eqv ROW_OFFSET_MULTIPLIER 320
.eqv COLUMN_OFFSET_MULTPLIER 4
.eqv TERMINAL_REGION_START 0xFFFF8000
.eqv RANDOM_ID 1

.text 
#set random id and Seed
#grab time
addi $v0, $zero, 30
syscall
add $a1, $zero, $a0 #set low order half of time to be seed
addi $a0, $zero, RANDOM_ID
addi $v0, $zero, 40 
syscall
#Prompt User for input
#actually implement this 
addi $v0, $zero, 10 #dummy input; DO NOT LEAVE THIS IN

add $t0, $zero, $v0 #moves user input into t0 for intial column selection
#Select inital columns to be selected 
#set random id and random with range syscall
initialColumnSelectLoop:
beqz $t0, startDigitalRain # once zero, branch out
#set random id and random with range syscall
addi $v0, $zero, 42
addi $a0, $zero, RANDOM_ID
addi $a1, $zero, 80 #intial range is 0-80
syscall
lb $t1, enableArray($a0) #Use returned value as offset to load byte
beqz $t1, noCollision
#Perserving registers
addi $sp, $sp, -8
sw $t1, 4($sp)
sw $t0, 0($sp)
jal collisionResolution #argument for column index is already in a0
add $a0, $zero, $v0 #setting a0 to returned value to keep consistent
#Restoring registers
lw $t0, 0($sp)
lw $t1, 4($sp)
addi $sp, $sp, 8
noCollision: 
add $t2, $zero, $a0 # $t2 = index to enabled array
#Call random with range from 0 to 255
addi $v0, $zero, 42
addi $a0, $zero, RANDOM_ID
addi $a1, $zero, 255 # range is now 0-255
syscall
addi $a0, $a0, 1 #adds 1 to result so range is effectively 1-255, inclusive
sb $a0, enableArray($t2) # stores value from above into enabled
addi $t0, $t0, -1 #decrement column needed index
j initialColumnSelectLoop

startDigitalRain:
addi $s0, $zero, 1 #Using $s0 as global cycle count, start at 1
rainLoop:
add $a0, $zero, $s0
jal identifyColumnsToRefresh
add $t0, $zero, $zero

#Terminate Program
addi $v0, $zero, 10
syscall

#Functions
# $a0 = column index 
# #v0 = next availible column index
collisionResolution:
addi $v0, $a0, 1
findOpenIndexLoop:
beq $v0, 80, setIndexToZero
lb $t1, enableArray($v0)
beqz $t1, returnEmptyIndex
addi $v0, $v0, 1
j findOpenIndexLoop
setIndexToZero:
and $v0, $v0, $zero 
j findOpenIndexLoop
returnEmptyIndex: 
jr $ra

# $a0 = current global cycle count
# $v0 = number of items currently in the queue
identifyColumnsToRefresh:
and $t0, $zero, $t0 # index of enableArray
and $t1, $zero, $t1 # index of updateQueue
enqueueColumnsLoop:
beq $t0, 40, returnQueueSize
lb $t3, enableArray($t0)
beqz $t3, incrementQueueLoop
#if value is non-zero, determine whether to enqueue or not
divu $t3, $a0 
mfhi $t4
bnez $t4, incrementQueueLoop # if remainder is not zero, do not enqueue
sb $t0, updateQueue($t1) # enqueue index of enableArray onto queue
addi $t1, $t1, 1 # increase updateQueue index
incrementQueueLoop:
addi $t0, $t0, 1 #increase enableArray queue
j enqueueColumnsLoop

returnQueueSize:
add $v0, $zero, $t1
jr $ra


