.data
#State Arrays

enableArray: .space 80 #track which columns are to be updates
currentRow: .space 80 #track current start of digtial rain for a column
updateQueue: .space 40 #queue to manage columns to send

#Output Strings
userPrompt: .asciiz "Please enter a number from 1 to 40: "

#Useful macros

.eqv ROW_OFFSET_MULTIPLIER 320
.eqv COLUMN_OFFSET_MULTIPLIER 4
.eqv TERMINAL_REGION_START 0xFFFF6150
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
la $a0, userPrompt
addi $v0, $zero, 4
syscall
addi $v0, $zero, 5
syscall
#actually implement this 
#addi $v0, $zero, 1 #dummy input; DO NOT LEAVE THIS IN

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
#Call random with range from 0 to 150
addi $v0, $zero, 42
addi $a0, $zero, RANDOM_ID
addi $a1, $zero, 150 # range is now 0-150
syscall
addi $a0, $a0, 1 #adds 1 to result so range is effectively 1-150, inclusive
sb $a0, enableArray($t2) # stores value from above into enabled
addi $t0, $t0, -1 #decrement column needed index
j initialColumnSelectLoop

startDigitalRain:
addi $s0, $zero, 0 #Using $s0 as global cycle count, start at 1
rainLoop:
addi $s0, $s0, 1
jal resetGlobalCycleCounter
jal selectNewColumns
add $a0, $zero, $s0
jal identifyColumnsToRefresh
add $s1, $zero, $v0 #number of items in updateQueue
and $s2, $zero, $s2 #set index 
refreshColumnsLoop:
beq $s2, $s1, rainLoop
lb $a0, updateQueue($s2) #dequeue a columm from updateQueue
lb $a1, currentRow($a0) #get row from currentRow for column
jal updateColumn
addi $s2, $s2, 1
j refreshColumnsLoop
#Terminate Program incase it goes too far
addi $v0, $zero, 10
syscall

#Functions

#function to reset s0 to 1 if becomes greater than 150
resetGlobalCycleCounter:
bne $s0, 151, returnFromReset
addi $s0, $zero, 1
returnFromReset:
jr $ra

#Function to update row if row 40 is reached
selectNewColumns:
addi $t0, $zero, -1 #index of currentRow 
checkRowArrayLoop:
addi $t0, $t0, 1
beq $t0, 80, exitSelectNewColumns
lb $t1, currentRow($t0)
sltiu $t2, $t1, 64
beqz $t1, checkRowArrayLoop # if value is zero, just loop
beq $t2, 1, checkRowArrayLoop #if value is less than 40, just loop
#Reset appropriate columns
sb $zero, currentRow($t0)
sb $zero, enableArray($t0)
#call random with range from 0 - 80
addi $a0, $zero, RANDOM_ID
addi $a0, $zero, 80
addi $v0, $zero, 42
syscall
lb $t3, enableArray($a0)
beqz $t3, newColumnSelect #if index at enableArray is zero, perform rest of the stuff
#perserve
addi $sp, $sp, -8
sw $ra, 4($sp)
sw $t0, 0($sp)
jal collisionResolution
#restore 
lw $ra, 4($sp)
lw $t0, 0($sp)
addi $sp, $sp, 8
#set a0 to empty index from collisionResolution
add $a0, $zero, $v0 #to be consistent with above instructions
newColumnSelect:
add $t4, $zero, $a0 #t4 contains new index to update
#call random with range from 0 - 150 per java.util.Random
addi $a0, $zero, RANDOM_ID
addi $a1, $zero, 150
addi $v0, $zero, 42
syscall
addi $a0, $a0, 1 # now 1-150; inclusive
sb $a0, enableArray($t4)
j checkRowArrayLoop

exitSelectNewColumns:
jr $ra



#Function to refresh individual columns
# $a0 = column index
# $a1 = current row for column
updateColumn:
add $t0, $zero, $a0 # $t0 = column
add $t1, $zero, $a1 # $t1 = row
#update currentRow here
addi $a1, $a1, 1 
sb $a1, currentRow($a0)
addi $t2, $zero, 0 #greenValue index
rowLoop: 
#Perserving $t0 and $t1
addi $sp, $sp, -16
sw $ra, 12($sp)
sw $t2, 8($sp)
sw $t1, 4($sp)
sw $t0, 0($sp)
#set arguments for fetchColumnAddress
add $a1, $zero, $t1
add $a0, $zero, $t0
jal fetchColumnAddress
add $t3, $zero, $v0 #stores address from fetchColumnAddress
#Restore Values
lw $ra 12($sp)
lw $t2 8($sp)
lw $t1 4($sp)
lw $t0 0($sp)
addi $sp, $sp, 16
#perserve for next function call
addi $sp, $sp, -20
sw $ra, 16($sp)
sw $t3, 12($sp)
sw $t2, 8($sp)
sw $t1, 4($sp)
sw $t0, 0($sp)
#set arguments for createWordForConsole
add $a0, $zero, $t2
jal createWordForConsole
lw $ra, 16($sp)
lw $t3, 12($sp)
lw $t2, 8($sp)
lw $t1, 4($sp)
lw $t0, 0($sp)
addi $sp, $sp, 20
sw $v0, 0($t3) #stores word into address of terminal
beq $t2, 250, exitUpdateColumn #if greenValue is 250, exit
slti $t5, $t1, 64
beqz $t5, exitUpdateColumn #if row reaches end, exit
addi $t2, $t2, 10
addi $t1, $t1, 1 
j rowLoop
exitUpdateColumn:
jr $ra

#Function to create word to load into array
# $a0 = current Green Value
createWordForConsole:
add $t0, $zero, $a0 # t0 contains current green value
#generates a random value now
add $a0, $zero, RANDOM_ID
add $a1, $zero, 94
addi $v0, $zero, 42
syscall
addi $a0, $a0, 33 # a0 should be from 33 - 127
sll $v0, $a0, 24 # v0 now contains character in right portion
sll $t1, $t0, 8
add $v0, $v0, $t1 # v0 should contain right word for address at terminal
jr $ra

#Function to calculate memory address of terminal region 
#for given column and row
# $a0 = column
# $a1 = row
# #v0 = address of column and region
fetchColumnAddress:
add $v0, $zero, TERMINAL_REGION_START #Start of terminal memory region in $t0
#Calculate offset to row
addi $t0, $zero, COLUMN_OFFSET_MULTIPLIER # t1 = column constant; 4
addi $t1, $zero, ROW_OFFSET_MULTIPLIER # $t0 = row calculation constant; 320
multu $a0, $t0 #column index * column_multiplier
mflo $t2 # t2 = calculated column offset
multu $a1, $t1 # row index * row_multiplier
mflo $t3 # t3 = calculated row offset
#adding offset to final result
add $v0, $v0, $t2
add $v0, $v0, $t3
jr $ra

#Function to resolve collisions between random generated numbers
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

#Function to queue columns to refresh
# $a0 = current global cycle count
# $v0 = number of items currently in the queue
identifyColumnsToRefresh:
and $t0, $zero, $t0 # index of enableArray
and $t1, $zero, $t1 # index of updateQueue
enqueueColumnsLoop:
beq $t0, 80, returnQueueSize
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
#maybe need to add one here?
jr $ra


