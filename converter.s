SYS_EXIT    equ 60
SYS_READ    equ 0
SYS_WRITE   equ 1
STDIN       equ 0
STDOUT      equ 1
VARSIZE     equ 8

section .text
    global _start

_start:
    call inputNumber
    push rax
    call printInBases
    pop rax

exit:
    mov rax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov rdi,0                   ; Exit with return code of 0 (no error)
    syscall

;-----------------------------------------------------------------------------
; Reads number in 2, 10, 16 bases from stdin
;
; Entry:
;
; Exit: rax = number
;
; Destr: rax, rbx, rdx, r8
;-----------------------------------------------------------------------------

inputNumber:
    push rsi

    mov rsi,inviteCmd
    mov rdx,inviteCmdLen
    call printMsg

    mov rsi,input
    call inputChar
    xor rcx,rcx
    xor r8,r8

    cmp rdx,`b`
    je binaryInput

    cmp rdx,`d`
    je decimalInput

    cmp rdx,`h`
    je hexadecimalInput

    jmp incorrectInputHandle

    readDigits:
        mov rsi,input
        call inputChar
        cmp rdx,`\n`
        je endReading
        cmp rdx,`a`
        jae parseLowerLetter
        cmp rdx,`A`
        jae parseUpperLetter
        cmp rdx,`0`
        jae parseDigit
        jmp incorrectInputHandle
        continueReadingDigits:
            xor rax,rax
            mov al,dl
            cmp rax,rbx
            jae incorrectInputHandle
            mov rax,r8
            mov r8,rdx
            xor rdx,rdx
            mul rbx
            add r8,rax
            jmp readDigits

    endReading:
        mov rax,r8
        pop rsi
        ret

binaryInput:
    mov rbx,2
    jmp readDigits

decimalInput:
    mov rbx,10
    jmp readDigits

hexadecimalInput:
    mov rbx,16
    jmp readDigits

parseLowerLetter:
    cmp dl,'z'
    ja incorrectInputHandle
    sub dl,`a`-10
    jmp continueReadingDigits

parseUpperLetter:
    cmp dl,'Z'
    ja incorrectInputHandle
    sub dl,`A`-10
    jmp continueReadingDigits

parseDigit:
    cmp dl,'9'
    ja incorrectInputHandle
    sub dl,`0`
    jmp continueReadingDigits

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Prints number stored in stack[-1] in 2, 10, 16 bases
; Entry: stack[-1] = integer
; Exit:
; Destr: rax, rdi, rsi, rdx, r8
;-----------------------------------------------------------------------------

printInBases:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov r8,[rbp]
    mov rsi,binaryOutput
    mov rdx,binaryOutputLen
    call printMsg
    push resultNum
    push 2
    push r8
    call ItoA
    pop r8
    pop rax
    pop rax
    mov rsi,resultNum + 1
    xor rdx,rdx
    mov dl,[resultNum]
    call printMsg

    mov rsi,decimalOutput
    mov rdx,decimalOutputLen
    call printMsg
    push resultNum
    push 10
    push r8
    call ItoA
    pop r8
    pop rax
    pop rax
    mov rsi,resultNum + 1
    xor rdx,rdx
    mov dl,[resultNum]
    call printMsg

    mov rsi,hexOutput
    mov rdx,hexOutputLen
    call printMsg
    push resultNum
    push 16
    push r8
    call ItoA
    pop r8
    pop rax
    pop rax
    mov rsi,resultNum + 1
    xor rdx,rdx
    mov dl,[resultNum]
    call printMsg

    pop rbp
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from stack[-1] in base stored in stack[-2] to string which
; address in stack[-3]
;
; Entry: stack[-1] = integer
;        stack[-2] = base
;        stack[-3] -> string
;
; Exit: [stack[-3]] = length of string
;       [stack[-3] + 1] = first byte of resulting string
;
; Destr: rax, rbx, rcx, rdx, r8, r9
;-----------------------------------------------------------------------------

ItoA:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov rdx,[rbp]
    mov rax,[rbp+VARSIZE]
    mov r8,[rbp+2*VARSIZE]

    cmp rax,2
    je callItoA2
    cmp rax,16
    je callItoA16

    push rax
    push rdx
    call countDigits            ; rcx = countDigits(rdx, rax)
    pop rdx
    pop rax

    mov [r8],cl                 ; *r8 = cl
    inc byte [r8]               ; (*r8)++
    inc r8                      ; r8++

    ItoALoop:
        dec rcx                 ; rcx--
        mov r10,rdx             ; rbx = rdx

        push rcx
        push rax
        call power              ; rax = rax^rcx

        mov r9,rax
        mov rax,r10             ; rax = r10
        xor rdx,rdx             ; rdx = 0
        div r9                  ; rax, rdx = rax / r9
        mov rbx,hexStr          ; rbx = hexStr
        xlat                    ; rax = ascii(rax)
        mov [r8],al             ; *r8 = al
        inc r8                  ; (*r8)++

        pop rax
        pop rcx
        cmp rcx,0               ; if (rcx > 0) 
        ja ItoALoop             ; goto ItoALoop

    mov byte [r8],`\n`          ; *r8 = `\n`

    ItoAExit:
        pop rbp
        ret

    callItoA2:
        push r8
        push rdx
        call ItoA2
        pop rdx
        pop r8
        jmp ItoAExit

    callItoA16:
        push r8
        push rdx
        call ItoA16
        pop rdx
        pop r8
        jmp ItoAExit

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from stack[-1] in base 2 to string which address in stack[-2]
;
; Entry: stack[-1] = integer
;        stack[-2] -> string
;
; Exit: [stack[-2]] = length of string
;       [stack[-2] + 1] = first byte of resulting string
;
; Destr: rax, rbx, rcx, rdx
;-----------------------------------------------------------------------------

ItoA2:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov rax,[rbp]
    mov rcx,[rbp+VARSIZE]

    mov rdx,64 ; in 64 bits there are maximum 64 digits in 2 base
    xor rbx,rbx

    ItoA2FirstLoop:         ; finds first non-zero digit
        dec rdx
        rol rax,1
        mov bl,al
        and bl,01b
        cmp bl,0
        jne ItoA2StartLoop
        cmp rdx,0
        jne ItoA2FirstLoop

    ItoA2StartLoop:
        inc rdx
        mov [rcx],dl
        add byte [rcx],1    ; add `\n` symbol length
        inc rcx
        ItoA2Loop:
            add rbx,`0`
            mov [rcx],bl
            inc rcx
            rol rax,1
            xor rbx,rbx
            mov bl,al
            and bl,01b
            dec rdx
            cmp rdx,0
            jne ItoA2Loop
        mov byte [rcx],`\n`

    pop rbp
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from stack[-1] in base 16 to string which address in stack[-2]
;
; Entry: stack[-1] = integer
;        stack[-2] -> string
;
; Exit: [stack[-2]] = length of string
;       [stack[-2] + 1] = first byte of resulting string
;
; Destr: rax, rbx, rcx, rdx
;-----------------------------------------------------------------------------

ItoA16:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov rax,[rbp]
    mov rcx,[rbp+VARSIZE]

    mov rdx,16 ; in 64 bits there are maximum 16 digits in 16 base
    xor rbx,rbx

    ItoA16FirstLoop:         ; finds first non-zero digit
        dec rdx
        rol rax,4
        mov bl,al
        and bl,0fh
        cmp bl,0
        jne ItoA16StartLoop
        cmp rdx,0
        jne ItoA16FirstLoop

    ItoA16StartLoop:
        inc rdx
        mov [rcx],dl
        add byte [rcx],1    ; add `\n` symbol length
        inc rcx
        ItoA16Loop:
            add rbx,hexStr
            mov rbx,[rbx]
            mov [rcx],bl
            inc rcx
            rol rax,4
            xor rbx,rbx
            mov bl,al
            and bl,0fh
            dec rdx
            cmp rdx,0
            jne ItoA16Loop
        mov byte [rcx],`\n`

    pop rbp
    ret
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Count digits of stack[-1] in base stack[-2]
; countDigits(number, base)
;
; Entry: stack[-1] = integer
;        stack[-2] = base
;
; Exit: rax = 0
;       rcx = digits count
;
; Destr: rbx, rdx
;-----------------------------------------------------------------------------

countDigits:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov rax,[rbp]
    mov rbx,[rbp+VARSIZE]

    xor rcx,rcx
    countDigitsLoop:
        xor rdx,rdx
        div rbx
        inc rcx
        cmp rax,0
        ja countDigitsLoop

    pop rbp
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Exponentiate base stack[-1] to exponent stack[-2]: stack[-1]^stack[-2]
;
; Entry: stack[-1] = base
;        stack[-2] = exponent
;
; Exit: rax = result of exponentiation
;
; Destr: rbx, rcx, rdx
;-----------------------------------------------------------------------------

power:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE

    mov rax,[rbp]
    mov rbx,[rbp+VARSIZE]

    mov rcx,rax
    cmp rbx,0
    je zeroPower

    powerLoop:
        dec rbx
        cmp rbx,0
        jbe powerExit
        xor rdx,rdx
        mul rcx
        jmp powerLoop
    jmp powerExit

    zeroPower:
        mov rax,1

    powerExit:
        pop rbp
        ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Prints message of length rdx stored in [rsi] to stdout
;
; Entry: rsi -> String containing message
;        rdx = Length of string
;
; Exit: rax = Number of bytes printed or -1 on error
;
; Destr: rcx, rdi, r11
;-----------------------------------------------------------------------------

printMsg:
    mov rax,SYS_WRITE           ; The system call for write (sys_write)
    mov rdi,STDOUT              ; File descriptor
    syscall                     ; Call the kernel
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Inputs one character from stdin
;
; Entry: rsi -> address for input byte
;
; Exit: rax = 1 on success or -1 on error
;       rdx = read byte
;
; Destr: rcx, rdi, r11
;-----------------------------------------------------------------------------

inputChar:
    mov rax,SYS_READ            ; The system call for read (sys_read)
    mov rdi,STDIN               ; File descriptor
    mov rdx,1
    syscall                     ; Call the kernel
    mov rdx,[rsi]
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Handles incorrect user input
; Entry:
; Exit:
; Destr: rax, rdi, rsi, rdx
;-----------------------------------------------------------------------------

incorrectInputHandle:
    call clearStdin
    mov rsi,incorrectInput
    mov rdx,incorrectInputLen
    call printMsg
    jmp exit

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Reads stdin to end of line
; Entry:
; Exit:
; Destr: rax, rdi, rsi, rdx
;-----------------------------------------------------------------------------

clearStdin:
    clearStdinLoop:
        mov rsi,input
        call inputChar                  ; read another part of input
        cmp rdx,`\n`
        jne clearStdinLoop              ; read next character if not read newline
    ret

;-----------------------------------------------------------------------------

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
    hexStr:                 db `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ`
    hexStrLen:              equ $-hexStr

section .bss
    input:              resb 1
    resultNum:          resb 66
