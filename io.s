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

    jmp cmpInput

exit:
    mov rax,SYS_EXIT            ; The system call for exit (sys_exit)
    mov rdi,0                   ; Exit with return code of 0 (no error)
    syscall

cmpInput:                       ; Compare input with 1 and 0
    cmp byte [rsi],'1'
    je inputOneHandle

    cmp byte [rsi],'0'
    je inputZeroHandle

    jmp anotherInputHandle

printMsg:
    mov rax,SYS_WRITE           ; The system call for write (sys_write)
    mov rdi,STDOUT              ; File descriptor
    syscall                     ; Call the kernel
    ret

inputMsg:
    mov rax,SYS_READ            ; The system call for read (sys_read)
    mov rdi,STDIN               ; File descriptor
    syscall               ; Call the kernel
    ret

inputOneHandle:
    mov rsi,inputOne
    mov rdx,inputOneLen
    call printMsg
    jmp exit

inputZeroHandle:
    mov rsi,inputZero
    mov rdx,inputZeroLen
    call printMsg
    jmp exit

anotherInputHandle:
    mov rsi,anotherInput
    mov rdx,anotherInputLen
    call printMsg
    jmp exit

clearStdin:                         ; if user entered long text read it all untill next line
    cmp rax,BUFSIZE
    jne anotherInputHandle          ; if read less then BUFSIZE bytes then input ended
    jmp clearStdinLoop              ; else read another part of input

clearStdinLoop:
    cmp byte [rsi + BUFSIZE - 1],`\n`
    je anotherInputHandle           ; if last read part ends with \n then input ended
    mov rsi,input
    mov rdx,inputLen
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