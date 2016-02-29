SYS_EXIT    equ 1
SYS_READ    equ 3
SYS_WRITE   equ 4
STDIN       equ 0
STDOUT      equ 1
INTERRUPT   equ 80h

section .text
    global _start

_start:
    call inputNumber
    call printInBases

exit:
    mov eax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov ebx,0                   ; Exit with return code of 0 (no error)
    int INTERRUPT

;-----------------------------------------------------------------------------
; Reads number in 2, 10, 16 bases from stdin
; Entry:
; Exit:
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

inputNumber:
    push edi
    push esi

    mov ecx,inviteCmd
    mov edx,inviteCmdLen
    call printMsg

    mov ecx,input
    call inputChar

    xor edi,edi

    cmp ebx,`b`
    je binaryInput

    cmp ebx,`d`
    je decimalInput

    cmp ebx,`h`
    je hexadecimalInput

    jmp incorrectInputHandle

    readDigits:
        mov ecx,input
        call inputChar
        cmp ebx,`\n`
        je endReading
        cmp ebx,`a`
        jae parseLowerLetter
        cmp ebx,`A`
        jae parseUpperLetter
        cmp ebx,`0`
        jae parseDigit
        jmp incorrectInputHandle
        continueReadingDigits:
            xor eax,eax
            mov al,bl
            cmp eax,esi
            jae incorrectInputHandle
            mov eax,edi
            xor edx,edx
            mul esi
            add eax,ebx
            mov edi,eax
            jmp readDigits

    endReading:
        mov eax,edi
        pop esi
        pop edi
        ret

binaryInput:
    mov esi,2
    jmp readDigits

decimalInput:
    mov esi,10
    jmp readDigits

hexadecimalInput:
    mov esi,16
    jmp readDigits

parseLowerLetter:
    cmp bl,'z'
    ja incorrectInputHandle
    sub bl,`a`-10
    jmp continueReadingDigits

parseUpperLetter:
    cmp bl,'Z'
    ja incorrectInputHandle
    sub bl,`A`-10
    jmp continueReadingDigits

parseDigit:
    cmp bl,'9'
    ja incorrectInputHandle
    sub bl,`0`
    jmp continueReadingDigits

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Prints number stored in eax in 2, 10, 16 bases
; Entry: eax = integer
; Exit:
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

printInBases:
    push edi
    mov edi,eax
    mov ecx,binaryOutput
    mov edx,binaryOutputLen
    call printMsg
    mov eax,edi
    mov ebx,2
    mov ecx,resultNum
    call ItoA2
    mov ecx,resultNum + 1
    mov dl,[resultNum]
    call printMsg

    mov ecx,decimalOutput
    mov edx,decimalOutputLen
    call printMsg
    mov eax,edi
    mov ebx,10
    mov ecx,resultNum
    call ItoA
    mov ecx,resultNum + 1
    mov dl,[resultNum]
    call printMsg

    mov ecx,hexOutput
    mov edx,hexOutputLen
    call printMsg
    mov eax,edi
    mov ecx,resultNum
    call ItoA16
    mov ecx,resultNum + 1
    mov dl,[resultNum]
    call printMsg
    pop edi
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from eax in base stored in ebx to string which address in ecx
; Entry: eax = integer
;        ebx = base
;        ecx -> string
; Exit: [ecx] = length of string
;       [ecx + 1] = first byte of resulting string
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

ItoA:
    push esi
    push edi
    push ebp
    mov ebp,ecx                 ; ebp = ecx
    mov edi,eax                 ; edi = eax
    call countDigits            ; ecx = countDigits(eax, ebx)
    mov edx,edi                 ; edx = edi
    mov [ebp],cl
    inc byte [ebp]
    inc ebp
    mov esi,ebx                 ; esi = ebx
    ItoALoop:
        dec ecx                 ; ecx--
        mov eax,esi             ; eax = esi
        mov edi,ecx             ; edi = ecx
        push edx
        call power              ; eax = eax^ecx
        mov ecx,edi             ; ecx = edi
        mov ebx,eax             ; ebx = eax
        pop eax
        xor edx,edx             ; edx = 0
        div ebx                 ; eax, edx = eax / ebx
        mov ebx,hexStr          ; ebx = hexStr
        xlat                    ; eax = ascii(eax)
        mov [ebp],al
        inc ebp
        cmp ecx,0
        ja ItoALoop
    mov byte [ebp],`\n`
    pop ebp
    pop edi
    pop esi
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from eax in base 2 to string which address in ecx
; Entry: eax = integer
;        ecx -> string
; Exit: [ecx] = length of string
;       [ecx + 1] = first byte of resulting string
; Destr: ebx, ecx, edx
;-----------------------------------------------------------------------------

ItoA2:
    mov edx,32 ; in 32 bits there are maximum 32 digits in 2 base
    xor ebx,ebx
    ItoA2FirstLoop:
        dec edx
        rol eax,1
        mov bl,al
        and bl,01h
        cmp bl,0
        jne ItoA2StartLoop
        cmp edx,0
        jne ItoA2FirstLoop
    ItoA2StartLoop:
        inc edx
        mov [ecx],dl
        add byte [ecx],1 ; add `\n` symbol length
        inc ecx
        ItoA2Loop:
            add ebx,`0`
            mov [ecx],bl
            inc ecx
            rol eax,1
            xor ebx,ebx
            mov bl,al
            and bl,01h
            dec edx
            cmp edx,0
            jne ItoA2Loop
        mov byte [ecx],`\n`
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Store integer from eax in base 16 to string which address in ecx
; Entry: eax = integer
;        ecx -> string
; Exit: [ecx] = length of string
;       [ecx + 1] = first byte of resulting string
; Destr: ebx, ecx, edx
;-----------------------------------------------------------------------------

ItoA16:
    mov edx,8 ; in 32 bits there are maximum 8 digits in 16 base
    xor ebx,ebx
    ItoA16FirstLoop:
        dec edx
        rol eax,4
        mov bl,al
        and bl,0fh
        cmp bl,0
        jne ItoA16StartLoop
        cmp edx,0
        jne ItoA16FirstLoop
    ItoA16StartLoop:
        inc edx
        mov [ecx],dl
        add byte [ecx],1 ; add `\n` symbol length
        inc ecx
        ItoA16Loop:
            add ebx,hexStr
            mov ebx,[ebx]
            mov [ecx],bl
            inc ecx
            rol eax,4
            xor ebx,ebx
            mov bl,al
            and bl,0fh
            dec edx
            cmp edx,0
            jne ItoA16Loop
        mov byte [ecx],`\n`
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Count digits of eax in base ebx
; Entry: eax = integer
;        ebx = base
; Exit: eax = 0
;       ecx = digits count
; Destr: eax, ecx, edx
;-----------------------------------------------------------------------------

countDigits:
    xor ecx,ecx
    countDigitsLoop:
        xor edx,edx
        div ebx
        inc ecx
        cmp eax,0
        jne countDigitsLoop
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Exponentiate base eax to exponent ecx: eax^ecx
; Entry: eax = base
;        ecx = exponent
; Exit: eax = result of exponentiation
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

power:
    mov ebx,eax
    cmp ecx,0
    je zeroPower

    powerLoop:
        dec ecx
        cmp ecx,0
        jbe powerExit
        xor edx,edx
        mul ebx
        jmp powerLoop
    jmp powerExit

    zeroPower:
        mov eax,1

    powerExit:
        ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Prints message of length edx stored in [ecx] to stdout
; Entry: ecx -> String containing message
;        edx = Length of string
; Exit: eax = Number of bytes printed or -1 on error
; Destr: eax, ebx
;-----------------------------------------------------------------------------

printMsg:
    mov eax,SYS_WRITE           ; The system call for write (sys_write)
    mov ebx,STDOUT              ; File descriptor
    int INTERRUPT               ; Call the kernel
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Inputs one character from stdin
; Entry: ecx -> address for input byte
; Exit: eax = 1 on success or -1 on error
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

inputChar:
    mov eax,SYS_READ            ; The system call for read (sys_read)
    mov ebx,STDIN               ; File descriptor
    mov edx,1
    int INTERRUPT               ; Call the kernel
    mov bl,[ecx]
    ret

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Handles incorrect user input
; Entry:
; Exit:
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

incorrectInputHandle:
    call clearStdin
    mov ecx,incorrectInput
    mov edx,incorrectInputLen
    call printMsg
    jmp exit

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Reads stdin to end of line
; Entry:
; Exit:
; Destr: eax, ebx, ecx, edx
;-----------------------------------------------------------------------------

clearStdin:
    clearStdinLoop:
        mov ecx,input
        call inputChar                  ; read another part of input
        cmp ebx,`\n`
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
    resultNum:          resb 34
