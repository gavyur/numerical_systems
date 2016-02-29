BUFSIZE     equ 2

SYS_EXIT    equ 1
SYS_READ    equ 3
SYS_WRITE   equ 4
STDIN       equ 0
STDOUT      equ 1
INTERRUPT   equ 80h

section .text
    global _start

_start:
    mov ecx,inviteCmd
    mov edx,inviteCmdLen
    call printMsg

    mov ecx,input
    mov edx,inputLen
    call inputMsg

    cmp eax,2
    jne clearStdin

    cmp byte [ecx + 1],`\n`
    jne clearStdin

    call printCharCode

exit:
    mov eax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov ebx,0                   ; Exit with return code of 0 (no error)
    int INTERRUPT

printCharCode:
    xor eax,eax
    mov al,[ecx]
    mov [number],eax

    mov ecx,binaryOutput
    mov edx,binaryOutputLen
    call printMsg
    mov eax,[number]
    mov ebx,2
    call printInt
    mov ecx,newLine
    mov edx,newLineLen
    call printMsg

    mov ecx,decimalOutput
    mov edx,decimalOutputLen
    call printMsg
    mov eax,[number]
    mov ebx,10
    call printInt
    mov ecx,newLine
    mov edx,newLineLen
    call printMsg

    mov ecx,hexOutput
    mov edx,hexOutputLen
    call printMsg
    mov eax,[number]
    mov ebx,16
    call printInt
    mov ecx,newLine
    mov edx,newLineLen
    call printMsg
    ret

printInt:                       ; prints int from eax in base stored in ebx
    push eax
    push ebx
    call countDigits
    mov [base],ebx
    printIntLoop:
        dec ecx
        push eax                ; save eax
        mov eax,[base]          ; put in eax base
        call power              ; get in eax base^ecx
        mov ebx,eax             ; put result in ebx
        pop eax                 ; restore eax
        xor edx,edx             ; edx = 0
        div ebx                 ; eax / ebx
        cmp eax,10
        jb writeDigitCode       ; if digit <= 9 then print it
        jmp writeCharCode       ; else print A,B,C,etc
        continuePrintingLoop:
            push ecx            ; save ecx
            push edx            ; save edx
            mov ecx,printChar
            mov edx,1
            call printMsg
            pop eax
            pop ecx
            cmp ecx,0
            ja printIntLoop
    pop ebx
    pop eax
    ret
    writeDigitCode:
        add eax,`0`
        mov [printChar],al
        jmp continuePrintingLoop
    writeCharCode:
        add eax,`A`
        mov [printChar],al
        jmp continuePrintingLoop

countDigits:                    ; count digits of integer from eax in base stored in ebx to ecx
    push eax
    xor ecx,ecx
    countDigitsLoop:
        xor edx,edx
        div ebx
        inc ecx
        cmp eax,0
        jne countDigitsLoop
    pop eax
    ret

power:                          ; eax^ecx
    push ebx
    push ecx
    mov ebx,eax
    cmp ecx,0
    je zeroPower
    checkPowerLoop:
        dec ecx
        cmp ecx,0
        ja powerLoop
    jmp powerExit
    powerLoop:
        mul ebx
        jmp checkPowerLoop
    jmp powerExit
    zeroPower:
        mov eax,1
    powerExit:
        pop ecx
        pop ebx
        ret

printMsg:
    mov eax,SYS_WRITE           ; The system call for write (sys_write)
    mov ebx,STDOUT              ; File descriptor
    int INTERRUPT               ; Call the kernel
    ret

inputMsg:
    mov eax,SYS_READ            ; The system call for read (sys_read)
    mov ebx,STDIN               ; File descriptor
    int INTERRUPT               ; Call the kernel
    ret

incorrectInputHandle:
    mov ecx,incorrectInput
    mov edx,incorrectInputLen
    call printMsg
    jmp exit

clearStdin:                         ; if user entered long text read it all untill next line
    cmp eax,BUFSIZE
    jne incorrectInputHandle        ; if read less then BUFSIZE bytes then input ended
    jmp clearStdinLoop              ; else read another part of input

clearStdinLoop:
    cmp byte [ecx + BUFSIZE - 1],`\n`
    je incorrectInputHandle         ; if last read part ends with \n then input ended
    mov ecx,input
    mov edx,inputLen
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
