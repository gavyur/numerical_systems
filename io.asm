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

    jmp cmpInput

exit:
    mov eax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov ebx,0                   ; Exit with return code of 0 (no error)
    int INTERRUPT

cmpInput:                       ; Compare input with 1 and 0
    cmp byte [ecx],'1'
    je inputOneHandle

    cmp byte [ecx],'0'
    je inputZeroHandle

    jmp anotherInputHandle

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

inputOneHandle:
    mov ecx,inputOne
    mov edx,inputOneLen
    call printMsg
    jmp exit

inputZeroHandle:
    mov ecx,inputZero
    mov edx,inputZeroLen
    call printMsg
    jmp exit

anotherInputHandle:
    mov ecx,anotherInput
    mov edx,anotherInputLen
    call printMsg
    jmp exit

clearStdin:                         ; if user entered long text read it all untill next line
    cmp eax,BUFSIZE
    jne anotherInputHandle          ; if read less then BUFSIZE bytes then input ended
    jmp clearStdinLoop              ; else read another part of input

clearStdinLoop:
    cmp byte [ecx + BUFSIZE - 1],`\n`
    je anotherInputHandle           ; if last read part ends with \n then input ended
    mov ecx,input
    mov edx,inputLen
    call inputMsg                   ; read another part of input
    jmp clearStdin

section .data
    inviteCmd:          db `Enter your input> `
    inviteCmdLen:       equ $-inviteCmd
    inputOne:           db `Edinichka input\n`
    inputOneLen:        equ $-inputOne
    inputZero:          db `Nolik input\n`
    inputZeroLen:       equ $-inputZero
    anotherInput:       db `Incorrect input\n`
    anotherInputLen:    equ $-anotherInput

section .bss
    input:              resb BUFSIZE
    inputLen:           equ $-input