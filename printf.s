SYS_EXIT    equ 60
SYS_READ    equ 0
SYS_WRITE   equ 1
STDIN       equ 0
STDOUT      equ 1
VARSIZE     equ 8

section .text
    global _start

_start:
    push helloWorld
    push 123
    push 123
    push 123
    push 123
    push 94
    push printfStringArg
    call printf
    pop rax
    pop rax
    pop rax
    pop rax
    pop rax
    pop rax
    pop rax

exit:
    mov rax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov rdi,0                   ; Exit with return code of 0 (no error)
    syscall

;-----------------------------------------------------------------------------
; Prints string which address is in stack[-1] with argument like:
; %% -- changes to %
; %c -- changes to character which number is in stack
; %s -- changes to string which address is in stack
; %b, %o, %d, %x -- changes to number from stack in binary, octal,
; decimal or hexadecimal numeric systems
;
; Entry: stack[-1] -> string
;        stack[...] = arguments
;
; Exit:
;
; Destr: rax, rbx, rcx, rdx, r8, r9, r10, r11, r12
;-----------------------------------------------------------------------------

printf:
    push rbp
    mov rbp,rsp
    add rbp,2*VARSIZE
    
    mov rax,[rbp]
    add rbp,VARSIZE
    mov rbx,rax
    cmp byte [rbx],0
    jne printfLoop

    printfExit:
        pop rbp
        ret

    printfLoop:
        cmp byte [rbx],`%`
        je printfParseArg

        printfParseArgReturn:
            inc rbx
            cmp byte [rbx],0
            jne printfLoop
            call printGotString
            jmp printfExit

    printfParseArg:
        inc rbx
        cmp byte [rbx],`%`
        je printfPercent
        cmp byte [rbx],`b`
        je printfBinary
        cmp byte [rbx],`o`
        je printfOctal
        cmp byte [rbx],`d`
        je printfDecimal
        cmp byte [rbx],`x`
        je printfHex
        cmp byte [rbx],`c`
        je printfChar
        cmp byte [rbx],`s`
        je printfString
        jmp printfError

    printfPercent:
        call printGotString
        mov rax,rbx
        inc rax
        jmp printfParseArgReturn

    printfBinary:
        mov r8,2
        call printInBase
        jmp printfParseArgReturn

    printfOctal:
        mov r8,8
        call printInBase
        jmp printfParseArgReturn

    printfDecimal:
        mov r8,10
        call printInBase
        jmp printfParseArgReturn

    printfHex:
        mov r8,16
        call printInBase
        jmp printfParseArgReturn

    printInBase:
        dec rbx
        call printGotString
        inc rbx
        mov rcx,[rbp]
        add rbp,VARSIZE

        mov r12,rbx
        push printf_params
        push r8
        push rcx
        call ItoA
        pop rcx
        pop r8
        pop rax
        mov rsi,printf_params + 1
        xor rdx,rdx
        mov dl,[printf_params]
        call printMsg
        mov rbx,r12

        mov rax,rbx
        inc rax
        ret

    printfChar:
        dec rbx
        call printGotString
        inc rbx
        mov rcx,[rbp]
        add rbp,VARSIZE

        mov [printf_params],cl
        mov rsi,printf_params
        mov rdx,1
        call printMsg

        mov rax,rbx
        inc rax
        jmp printfParseArgReturn

    printfString:
        dec rbx
        call printGotString
        inc rbx

        mov rsi,[rbp]
        mov rcx,rsi
        add rbp,VARSIZE
        mov rdx,0
        cmp byte [rcx],0
        jne printfStringLen

        printfStringLenRet:
            call printMsg
            mov rax,rbx
            inc rax
            jmp printfParseArgReturn
        
        printfStringLen:
            inc rdx
            inc rcx
            cmp byte [rcx],0
            jne printfStringLen
            jmp printfStringLenRet

    printfError:
        mov rsi,printfErrArg
        mov rdx,printfErrArgLen
        call printMsg
        jmp printfExit

    printGotString:
        mov rsi,rax
        mov rdx,rbx
        sub rdx,rax
        cmp rdx,0
        jne printGotCallWrite
        ret
        printGotCallWrite:
            call printMsg
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
; Destr: rax, rbx, rcx, rdx, r8, r9, r10
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

section .data
    printfErrArg:           db `\nInvalid argument after % (if you want to print % symbol try to use %%)\n`
    printfErrArgLen:        equ $-printfErrArg
    printfStringArg:        db `Do you know that 2%c3=8?\n`,\
                               `Ok, what about 20%% of 10? It's 2!\n`,\
                               `Let's see %d in different numerical systems:\n`,\
                               `Binary: 0b%b\n`,\
                               `Octal: 0o%o\n`,\
                               `Hexadecimal: 0x%x\n`,\
                               `And I want to print that great string: %s\n`,0
    printfStringArgLen:     equ $-printfStringArg
    helloWorld:             db `Hello, world!`,0

    newLine:                db `\n`
    newLineLen:             equ $-newLine
    hexStr:                 db `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ`
    hexStrLen:              equ $-hexStr

section .bss
    printf_params:          resb 66
