model small

.data
	x dw ?
	y dw ? ;Y
	z dw ? ;Z
	error db 'incorrect number$'
	buff db 11,12 Dup(?)
	mes1 db "Input X: ", 10, 13, '$'
	mes2 db "Input Y: ", 10, 13, '$'
	mes3 db "Input Z: ", 10, 13, '$'
	mes4 db "Result of 2*X^2+Y^2 <-- Z: ", 10, 13, '$'
	mes dw ?
.stack 100h	

.code
	start:
	.386 ;подключение данной директивы обеспечит работу с 32-битными числами, 
	;после перемножения 16-битных чисел
		mov ax, @data
		mov ds, ax
		mov mes, offset mes1
		call far ptr ShowMess
		call far ptr InputInt
		mov x,ax
		mov mes, offset mes2
		call far ptr ShowMess
		call far ptr InputInt
		mov y,ax
		mov mes, offset mes3
		call far ptr ShowMess
		call far ptr InputInt
		mov z,ax
		mov mes, offset mes4
		call far ptr ShowMess
		call far ptr FuncInt ;вызов дальней процедуры для вычисления 2X^2+Y^2
		call far ptr ShiftNumber ;вызов процедуры сдвига на значение хранящееся в 5 мл.битах числа Z
		;т.е. макс кол-во сдвигов-31, мин-0
		call far ptr OutInt ;вывод полученного числа в 10 СС
		mov ah, 01h ;прерывание дос на ожидание любого дествия с клавиатуры
		int 21h
		mov ah, 4Ch ;прерывание дос на завершение программы
		int 21h
		
		FuncInt proc far
			mov bx, x ;X и Y глобальные переменные
			mov cx, y
			xor eax ,eax
			xor edx, edx
			mov ax, bx
			mul bx ;x^2, результат помещается в пару dx:ax
			shl edx, 16 ;подготовка для получения целостного значения произведения
			add eax, edx ;целостное произведение
			mov ebx, eax ;занесение x2 в регистр bx
			xor eax ,eax
			xor edx, edx
			mov ax, cx
			mul cx ;y^2
			shl edx, 16
			add eax, edx
			mov ecx, eax ;занесение y2 в регистр cx
			mov eax, ebx
			mov ebx, 2 ;2*x^2 
			mul ebx;
			add eax, ecx ;2*x^2+y^2
			ret
		FuncInt endp

		ShiftNumber proc far
			mov dx, z
			mov cl, dl
			shl eax,cl ;сдвиг влево на значение cl
			ret
		ShiftNumber endp		
		
		OutInt proc far
			xor     cx, cx
			xor ebx, ebx
			mov     bx, 10 ; основание сс. 10 для десятеричной и т.п.
			oi2:
			xor     dx,dx
			div     ebx
			; Делим число на основание сс. В остатке получается последняя цифра.
			; Сразу выводить её нельзя, поэтому сохраним её в стэке.
			push    dx
			inc     cx
			; А с частным повторяем то же самое, отделяя от него очередную
			; цифру справа, пока не останется ноль, что значит, что дальше
			; слева только нули.
			test    eax, eax
			jnz     oi2
			; Теперь приступим к выводу.
			mov     ah, 02h
			oi3:
			pop     dx
			; Извлекаем очередную цифру, переводим её в символ и выводим.
			add     dl, '0'
			int     21h
			; Повторим ровно столько раз, сколько цифр насчитали.
			loop    oi3
			ret
		OutInt endp
		
		ShowMess proc far
			mov dx, mes
			mov ah,09
			int 21h
			ret
		ShowMess endp
		
		InputInt proc far
			mov ah,0ah
			xor di,di
			mov dx,offset buff ; аддрес буфера
			int 21h ; принимаем строку
			mov dl,0ah
			mov ah,02
			int 21h ; выводим перевода строки
			; обрабатываем содержимое буфера
			mov si,offset buff+2 ; берем аддрес начала строки
			;cmp byte ptr [si],"-" ; если первый символ минус
			jmp ii1
			;mov di,1  ; устанавливаем флаг
			;inc si    ; и пропускаем его
			ii1:
			xor ax,ax
			mov bx,10  ; основание сc
			ii2:
			mov cl,[si] ; берем символ из буфера
			cmp cl,0dh  ; проверяем не последний ли он
			jz endin
			; если символ не последний, то проверяем его на правильность
			cmp cl,'0'  ; если введен неверный символ <0
			jb er
			cmp cl,'9'  ; если введен неверный символ >9
			ja er
			sub cl,'0' ; делаем из символа число 
			mul bx     ; умножаем на 10
			add ax,cx  ; прибавляем к остальным
			inc si     ; указатель на следующий символ
			jmp ii2     ; повторяем
			er:   ; если была ошибка, то выводим сообщение об этом и выходим
			mov dx, offset error
			mov ah,09
			int 21h
			int 20h
			; все символы из буфера обработаны число находится в ax
			endin:
			;cmp di,1 ; если установлен флаг, то
			jmp ii3
			;neg ax   ; делаем число отрицательным
			ii3:
			ret
		InputInt endp		
	end start