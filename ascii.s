BUFSIZE     equ 2

SYS_EXIT    equ 60
SYS_READ    equ 0
SYS_WRITE   equ 1
STDIN       equ 0
STDOUT      equ 1

section .text
    global _start

_start:
    mov rsi,inviteCmd
    mov rdx,inviteCmdLen
    call printMsg

    mov rsi,input
    mov rdx,inputLen
    call inputMsg

    cmp rax,2
    jne clearStdin

    cmp byte [rsi + 1],`\n`
    jne clearStdin

    call printCharCode

exit:
    mov rax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov rdi,0                   ; Exit with return code of 0 (no error)
    syscall

printCharCode:
    xor rax,rax
    mov al,[rsi]
    mov [number],rax

    mov rsi,binaryOutput
    mov rdx,binaryOutputLen
    call printMsg
    mov rax,[number]
    mov rdi,2
    call printInt
    mov rsi,newLine
    mov rdx,newLineLen
    call printMsg

    mov rsi,decimalOutput
    mov rdx,decimalOutputLen
    call printMsg
    mov rax,[number]
    mov rdi,10
    call printInt
    mov rsi,newLine
    mov rdx,newLineLen
    call printMsg

    mov rsi,hexOutput
    mov rdx,hexOutputLen
    call printMsg
    mov rax,[number]
    mov rdi,16
    call printInt
    mov rsi,newLine
    mov rdx,newLineLen
    call printMsg
    ret

printInt:                       ; prints int from rax in base stored in rdi
    push rax
    push rdi
    call countDigits
    mov [base],rdi
    printIntLoop:
        dec rsi
        push rax                ; save rax
        mov rax,[base]          ; put in rax base
        call power              ; get in rax base^rsi
        mov rdi,rax             ; put result in rdi
        pop rax                 ; restore rax
        xor rdx,rdx             ; rdx = 0
        div rdi                 ; rax / rdi
        cmp rax,10
        jb writeDigitCode       ; if digit <= 9 then print it
        jmp writeCharCode       ; else print A,B,C,etc
        continuePrintingLoop:
            push rsi            ; save rsi
            push rdx            ; save rdx
            mov rsi,printChar
            mov rdx,1
            call printMsg
            pop rax
            pop rsi
            cmp rsi,0
            ja printIntLoop
    pop rdi
    pop rax
    ret
    writeDigitCode:
        add rax,`0`
        mov [printChar],al
        jmp continuePrintingLoop
    writeCharCode:
        add rax,`A`
        mov [printChar],al
        jmp continuePrintingLoop

countDigits:                    ; count digits of integer from rax in base stored in rdi to rsi
    push rax
    xor rsi,rsi
    countDigitsLoop:
        xor rdx,rdx
        div rdi
        inc rsi
        cmp rax,0
        jne countDigitsLoop
    pop rax
    ret

power:                          ; rax^rsi
    push rdi
    push rsi
    mov rdi,rax
    cmp rsi,0
    je zeroPower
    checkPowerLoop:
        dec rsi
        cmp rsi,0
        ja powerLoop
    jmp powerExit
    powerLoop:
        mul rdi
        jmp checkPowerLoop
    jmp powerExit
    zeroPower:
        mov rax,1
    powerExit:
        pop rsi
        pop rdi
        ret

printMsg:
    mov rax,SYS_WRITE           ; The system call for write (sys_write)
    mov rdi,STDOUT              ; File descriptor
    syscall                     ; Call the kernel
    ret

inputMsg:
    mov rax,SYS_READ            ; The system call for read (sys_read)
    mov rdi,STDIN               ; File descriptor
    syscall                     ; Call the kernel
    ret

incorrectInputHandle:
    mov rsi,incorrectInput
    mov rdx,incorrectInputLen
    call printMsg
    jmp exit

clearStdin:                         ; if user entered long text read it all untill next line
    cmp rax,BUFSIZE
    jne incorrectInputHandle        ; if read less then BUFSIZE bytes then input ended
    jmp clearStdinLoop              ; else read another part of input

clearStdinLoop:
    cmp byte [rsi + BUFSIZE - 1],`\n`
    je incorrectInputHandle         ; if last read part ends with \n then input ended
    mov rsi,input
    mov rdx,inputLen
    call inputMsg                   ; read another part of input
    jmp clearStdin

section .data
    inviteCmd:              db `Enter character> `
    inviteCmdLen:           equ $-inviteCmd
    incorrectInput:         db `Incorrect input\n`
    incorrectInputLen:      equ $-incorrectInput
    binaryOutput:           db `Binary character code: 0b`
    binaryOutputLen:        equ $-binaryOutput
    decimalOutput:          db `Decimal character code: `
    decimalOutputLen:       equ $-decimalOutput
    hexOutput:              db `Hexadecimal character code: 0x`
    hexOutputLen:           equ $-hexOutput
    newLine:                db `\n`
    newLineLen:             equ $-newLine

section .bss
    input:              resb BUFSIZE
    inputLen:           equ $-input
    base:               resd 4
    number:             resd 4
    printChar:          resb 1
