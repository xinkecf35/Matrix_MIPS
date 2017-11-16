.data
#State Arrays

enableArray: .space 80 #track which columns are to be updates
currentRow: .space 80 #track current start of digtial rain for a column
updateQueue: .space 40 #queue to manage columns to send


#Useful macros

.eqv ROW_OFFSET_MULTIPLIER 320
.eqv COLUMN_OFFSET_MULTPLIER 4
.eqv TERMINAL_REGION_START 0xFFFF8000
.eqv RANDOM_ID 1

.text 
#set Random id and Seed
#grab time
addi $v0, $zero, 30
syscall
add $a1, $zero, $a0 #set low order half of time to be seed
addi $a0, $zero, RANDOM_ID
addi $v0, $zero, 40 
syscall

#Terminate Program
addi $v0, $zero, 10
syscall