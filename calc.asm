; Where it all begins :3

section .bss                
    input resb 50           ; holds user input (1 + 2, 100 * 2) for parsing
    buffer resb 15          ; buffer for parsing user input for each number and opperation
    op resb 1               ; holds operator
    ansBuffer resb 60       ; this is the buffer for the answer when converting each int to a char
    ansBufferPos resb 8     ; holds the address of where we are at in ansbuffer which we use later to print the answer
    num1 resb 30            ; holds first number
    num2 resb 30            ; holds second number
    YN resb 2               ; (Y/N) for continue ?
 
section .data
    equal db "="                                            ; just to print out = sign
    space db " "                                            ; space before and after equal sign
    nl db "", 0xA                                           ; newline character for after the answer is printed
    error db "Exiting: Invalid Input", 0xA, 0               ; i believe the rest is self explanatory 
    errorlen EQU $ - error                                  
    askInput db "Enter Expression: (ex: 49 - 1)", 0xA, 0
    asklen EQU $ - askInput
    restart db "Continue? (Y/N)", 0xA, 0
    restartlen EQU $ - restart

section .text
    global _start
 
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, askInput                   ; ask for input
    mov rdx, asklen
    syscall

    call userInput
    
    call parser
 
userInput:
    mov rax, 0
    mov rdi, 0
    mov rsi, input                      ; get user input
    mov rdx, 50
    syscall
    ret

parser:                     ; start of parser
    mov rcx, input          ; load input address            
    mov rdx, buffer         ; buffer for parser
    xor r8, r8              ; just make sure these are clear (r8 is used to keep track if we are on num1, op, or num2)
    xor r9, r9              ; how many chars we put in the buffer
    xor r11, r11            ; used for checking how many chars we converted to int compared to the ammount in the buffer

parseLOOP:                  ; parser loop that checks for newline and spaces
    cmp byte [rcx], 0xA
    je Snum2                ; newline probably means we finished looping over each char for the second num
    cmp byte [rcx], 32
    je storeJMPS            ; each space we encounter means the we finished looping over the nums/op
    mov rax, [rcx]
    mov [rdx], al
    inc rdx
    inc r9                  ; counter for how long the the number is
    inc rcx
    jmp parseLOOP

storeJMPS:            
    cmp r8, 0               ; if r8 is 0, its num1, 1 for op, 2 for num2 (all for converting char to int besides the op char)
    je Snum1
    cmp r8, 1
    je Sop
    cmp r8, 2
    je Snum2

Snum1:                      ; set the stage for converting the first num inside buffer
    mov rax, num1
    mov rdx, buffer
    jmp Store

Snum2:
    mov rax, num2           ; set the stage for converting the second num inside buffer
    mov rdx, buffer
    jmp Store

Sop:
    mov al, byte [rdx - 1]  ; just takes the op char out of the buffer and puts it into (op)
    mov byte [op], al
    mov rdx, buffer
    xor r9, r9
    jmp clearBuff

Store:
    movzx r10, byte [rdx]   ; converting from char to int for both num1 and num2 also with error checking
    cmp r10, '0'    
    jl exitWithError        ; if the char is below '0' its not a number
    cmp r10, '9'
    jg exitWithError        ; if the char is above '9' its not a number
    sub r10, '0'         ; turn into int 
    cmp r11, 1              ; if the number is more than one digit we have to handle it differently
    jge doubleD
breakr:         ; something to jmp to if we jumped to double D
    mov [rax], r10          ; move the first int into num1/num2 (they both use the same process)
    push rax            ; push the current address (if the number is more than 1 digit we need this)
    inc rdx             ; inc buffer for next char
    inc r11             ; how many chars we converted
    cmp r11, r9         ; compares how many we have converted to how many we have put in the buffer
    jne Store           ; repeat if not equal

    xor r9, r9          ; clear r9 since we are clearing the buffer to use again
    pop r11             ; pop the rax we pushed if its not going to be used
    xor r11, r11        ; clear r11 since we are clearing the buffer
    mov rdx, buffer     ; for clearing
    jmp clearBuff

doubleD:    ; this can handle more than double digits i just named it that >:)
    xor r12, r12            ; make sure r12 is clear
    pop rax                 ; pop the address we pushed earlier
    mov r12, qword [rax]    ; put the current value inside num1/num2 into r12
    imul r12, 10            ; multiply it by 10, (example buffer holds 120 for num1, we converted 1 so far, we have to multiply 1 by 10 = 10 then add 2 = 12 repeat for the 3rd num if there is one
    add r10, r12
    jmp breakr

clearBuff:              ; put 0 into each part of the buffer until we encounter 0, which means we hit the end of of all chars in the buffer
    mov byte [rdx], 0
    inc rdx
    cmp byte [rdx], 0
    jne clearBuff

    mov rdx, buffer         

check:                  ; checks if we are on the second number
    cmp r8, 2
    jne storeFIN        ; if not

    jmp opperation      ; if we are we are done parsing!!!!

storeFIN:               ; if we are not done parsing inc rcx (input) for the next char
    inc rcx
    inc r8              ; inc to tell we are on a different part of the input (op or num2)
    jmp parseLOOP       ; back to parsing

opperation:             ; checks the op, compares to +, -, *, and / if its not any of them exit
    mov rax, op
    cmp byte [rax], 43
    je addition
    cmp byte [rax], 45
    je subtraction
    cmp byte [rax], 42
    je multiplication
    cmp byte [rax], 47
    je division

    jmp exitWithError

addition:
    mov rax, qword [num1]
    mov rdx, qword [num2]
    add rax, rdx

    mov rcx, ansBuffer
    jmp Convert

subtraction:
    mov rax, qword [num1]
    mov rdx, qword [num2]
    sub rax, rdx

    mov rcx, ansBuffer
    jmp Convert

multiplication:
    mov rax, qword [num1]
    mov rdx, qword [num2]
    mul rdx

    mov rcx, ansBuffer
    jmp Convert

division:
    jmp FloatConvert    ; division gets special treatment

Convert:                ; converts all the answers into strings (for addition, subtraction, and multiplication)
    xor rdx, rdx
    mov rbx, 10
    idiv rbx
    add rdx, 48
    mov byte [rcx], dl
    inc rcx
    mov [ansBufferPos], rcx
    cmp rax, 0
    jne Convert

    mov rax, input
    jmp takeNEWLINE     ; remove the newline at the end of input since we are going to reprint the input with the answer 

takeNEWLINE:
    mov dl, byte [rax]
    cmp dl, 0xA
    je rmv

    inc rax
    jmp takeNEWLINE

rmv:
    mov byte [rax], 0

print:                  ; print input, space, equal sign, space, then answer
    mov rax, 1
    mov rdi, 1
    mov rsi, input
    mov rdx, 30
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, equal
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall

    mov rcx, [ansBufferPos]

printINT:               ; printing int, since we store the answer backwards (answer = 12, ansbuffer = 21 so we print it backwards) just easier that way I think ¯_ (ツ)_/¯
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, 1
    syscall

    mov rcx, [ansBufferPos]
    cmp rcx, ansBuffer
    je finPrint
    dec rcx
    mov [ansBufferPos], rcx
    jmp printINT

finPrint:       ; print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall

ask:            ; ask if they wanna continue
    mov rax, 1
    mov rdi, 1
    mov rsi, restart
    mov rdx, restartlen
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, YN
    mov rdx, 2
    syscall
                        ; you could literally enter anything 1 char long besides N/n and it will continue
    cmp byte [YN], 'N'
    je exit
    cmp byte [YN], 'n'
    je exit

    jmp clear           ; clears stuff for the next time

exit:
    mov rax, 60
    mov rdi, 0
    syscall

exitWithError:          ; error exit
    mov rax, 1
    mov rdi, 1
    mov rsi, error
    mov rdx, errorlen
    syscall

    mov rax, 60
    mov rdi, 1
    syscall


clear:                  ; clears a lot of stuff for just incase
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    mov qword [ansBuffer], 0
    jmp _start

FloatConvert:           ; float convert!!!      (WE CONVERT INTS AND FLOATS BACKWARDS so 12.42 would be stored as 24.21 and print it backwards)
    xor rdx, rdx
    mov rax, qword [num1]
    mov rcx, qword [num2]
    idiv rcx            ; divide num1 by num2
    push rax        ; push whole number to convert later (remember we convert backwards so fractional bit first)
    mov rax, rdx        ; put the remainder in rax
    xor rdx, rdx        ; clear remainder
    mov rbx, 1000       ; multiply remainder by 1000 (so 3 decimal places are printed)
    imul rax, rbx
    idiv rcx            ; divide the (remainder * 1000) by num2 to get the decimal places 
    mov rcx, ansBuffer
FLOOP:
    xor rdx, rdx        ; converts each number behind the decimal
    mov rbx, 10
    idiv rbx
    add rdx, 48
    mov byte [rcx], dl
    inc rcx
    mov [ansBufferPos], rcx
    cmp rax, 0
    jne FLOOP

addP:                   ; add decimal point
    mov byte [rcx], '.'
    inc rcx
    pop rax             ; value we pushed earlier

lastDigits:             ; now convert the whole number
    xor rdx, rdx
    mov rbx, 10
    idiv rbx
    add rdx, 48
    mov byte [rcx], dl
    inc rcx
    mov [ansBufferPos], rcx
    cmp rax, 0
    jne lastDigits

    mov rax, input
    jmp takeNEWLINE     ; does the same thing at the end like Convert does.