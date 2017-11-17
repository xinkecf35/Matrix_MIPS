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
beqz $t0, rainLoop # once zero, branch out
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
addi $a0, $zero, RANDOM_ID
addi $a1, $zero, 255 # range is now 0-255
syscall
addi $a0, $a0, 1 #adds 1 to result so range is effectively 1-255, inclusive
sb $a0, enableArray($t2) # stores value from above into enabled
addi $t0, $t0, -1 #decrement column needed index
j initialColumnSelectLoop

rainLoop:

#Terminate Program
addi $v0, $zero, 10
syscall

#Functions
# $a0 = column index 
# #v0 = next availible column index
collisionResolution:

jr $ra
