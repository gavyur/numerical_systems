; nasm -f elf -g -F dwarf code.asm -l code.lst
; ld -m elf_i386 -o code code.o

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
    call inputChar

    cmp byte [input],`b`
    je binaryInput

    cmp byte [input],`d`
    je decimalInput

    cmp byte [input],`h`
    je hexadecimalInput

    jmp incorrectInputHandle

    xor eax,eax
    mov [number],eax

    readDigits:
        mov ecx,input
        call inputChar
        cmp byte [input],`\n`
        je endReading
        cmp byte [input],`a`
        jae parseLowerLetter
        cmp byte [input],`A`
        jae parseUpperLetter
        cmp byte [input],`0`
        jae parseDigit
        jmp incorrectInputHandle
        continueReadingDigits:
            xor eax,eax
            mov al,byte [input]
            mov ebx,[base]
            cmp eax,ebx
            jae incorrectInputHandle
            mov eax,[number]
            mul dword [base]
            xor ebx,ebx
            mov bl,byte [input]
            add eax,ebx
            mov [number],eax
            jmp readDigits

    endReading:
        call printInBases

exit:
    mov eax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov ebx,0                   ; Exit with return code of 0 (no error)
    int INTERRUPT

binaryInput:
    mov byte [base],2
    jmp readDigits

decimalInput:
    mov byte [base],10
    jmp readDigits

hexadecimalInput:
    mov byte [base],16
    jmp readDigits

parseLowerLetter:
    cmp byte [input],'z'
    ja incorrectInputHandle
    sub byte [input],`a`-10
    jmp continueReadingDigits

parseUpperLetter:
    cmp byte [input],'Z'
    ja incorrectInputHandle
    sub byte [input],`A`-10
    jmp continueReadingDigits

parseDigit:
    cmp byte [input],'9'
    ja incorrectInputHandle
    sub byte [input],`0`
    jmp continueReadingDigits

printInBases:
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
        add eax,48
        mov [printChar],al
        jmp continuePrintingLoop
    writeCharCode:
        add eax,55
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

inputChar:
    mov eax,SYS_READ            ; The system call for read (sys_read)
    mov ebx,STDIN               ; File descriptor
    mov edx,1
    int INTERRUPT               ; Call the kernel
    ret

incorrectInputHandle:
    call clearStdin
    mov ecx,incorrectInput
    mov edx,incorrectInputLen
    call printMsg
    jmp exit

clearStdin:
    jmp clearStdinLoop
    clearStdinRet:
        ret

clearStdinLoop:                         ; if user entered long text read it all until next line
    mov ecx,input
    call inputChar                   ; read another part of input
    cmp byte [input],`\n`
    je clearStdinRet
    jmp clearStdinLoop

section .data
    inviteCmd:              db `Enter number (start with b for binary, d for decimal and h for hexadecimal)> `
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
    input:              resb 2
    base:               resd 4
    number:             resd 4
    printChar:          resb 1
