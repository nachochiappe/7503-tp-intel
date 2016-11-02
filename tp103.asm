segment datos data
	anio_inicial	dw	1900
	febrero			db	28
	cant_dias		db	31
	cant_meses		db	1
	nom_arch		db	"juliana.txt",0
	centena			dw	100
	decena			db	10

	registro	times 15	resb	1
	dia				resw	1
	mes				resb	1
	anio			resw	1

	fHandle	resb	1

	;Mensajes

	msjErrAbrir		db	"Error al abrir archivo",10,13,"$"
	msjErrLeer		db	"Error al leer archivo",10,13,"$"
	msjErrCerrar	db	"Error al cerrar archivo",10,13,"$"
	msjFin			db	"FIN$"
	msjTest1		db	"TEST1",10,13,"$"
	msjTest2		db	"TEST2",10,13,"$"
	msjTest3		db	"TEST3",10,13,"$"
	msjTest4		db	"TEST4",10,13,"$"
	msjTest5		db	"TEST5",10,13,"$"

	msjJuliana		db	"Juliana: $"
	msjGregoriana	db	"Gregoriana: $"

	fechaJuliana	resb	7
	fechaGregoriana	resb	9

	;Juliana: AADDDD (Ej.: 31/05/1950 -> 500151 (Día 151 del año 1950))
	;Gregoriana: AAAAMMDD (Ej.: 31/05/1950 -> 19500531)

segment pila stack
	resb	64
stacktop:

segment codigo code
..start:
	;Inicialización de registro DS y SS
	mov		ax,datos	;se copia en registro AX la dirección de inicio del segmento de datos
	mov		ds,ax			;se copia al registro DS la dirección de inicio del segmento de datos
	mov		ax,pila		;se copia en registro AX la dirección del segmento STACK
	mov		ss,ax			;se copia al registro SS la dirección del segmento STACK
	mov		sp,stacktop

	;1.	Abrir archivo
abrirFile:
	mov		al,0					;tipo de acceso
	mov		dx,nom_arch		;nombre del archivo
	mov		ah,3dh				;servicio para abrir archivo 3dh
	int		21h						;se abre el archivo
	jc		errAbrir			;Carry <> 0
	mov 	[fHandle],ax	;en ax queda el handle del archivo

	;2.	¿Está vacío?
		;2.1	SI: Saltar a fin.
		;2.2	NO: Seguir con punto 3.
	;3.	Leer registro

	mov		bx,[fHandle]	;handle del archivo
	mov		cx,12					;cantidad de bytes a leer
	mov		dx,registro		;memoria hacia donde se copia
	mov		ah,3fh				;servicio
	int		21h						;se lee
	jc		errLeer				;Carry <> 0
	cmp		ax,0
	je		cerrarArch
	;4. ¿Es el fin del archivo?
		;4.1	SI: Saltar a punto 18.
		;4.2	NO: Seguir con punto 5.
	;5. Obtener <anio>
	;Centena
	mov		al,byte[registro]
	sub		al,30h
	mul		byte[centena]
	mov		[anio],ax

	;Decena
	mov		al,byte[registro+1]
	sub		al,30h
	mul		byte[decena]
	add		[anio],ax

	;Unidad
	mov		al,byte[registro+2]
	sub		al,30h
	add		[anio],al

	mov		ax,[anio_inicial]
	add		[anio],ax

	;6. Obtener <dia>

	;Centena
	mov		al,byte[registro+8]
	sub		al,30
	mul		byte[centena]
	mov		[dia],ax

	;Decena
	mov		al,byte[registro+9]
	sub		al,30
	mul		byte[decena]
	add		[dia],ax

	;Unidad
	mov		al,byte[registro+10]
	sub		al,30
	add		[dia],al

	;7. Dividir <anio> por 100.

	sub		dx,dx
	mov		ax,[anio]
	div		word[centena]

	;8. ¿El resto de la división es 0?
	cmp		dx,0
		;8.1 SI: El anio NO es bisiesto.
	je		fin
		;8.2 NO: Seguir con punto 9.
	;9. ¿Es la primera división?
		;9.1 SI: Dividir <anio> por 4. Seguir con punto 8.
	mov		ax,[anio]
	;mov		bx,4
	;div		bx
	div		word[4]
		;9.2 NO: Saltar a punto 12.
	;10. Saltar a punto 8.
	;Temporalmente hago esto hasta completar punto 9
	cmp		dx,0
	je		fin
	;11. Asignar 29 a <febrero>.
	mov		byte[febrero],29
	;12. ¿El <dia> es menor o igual a <cant_dias>?
buscoMes:
	mov		bx,[dia]
	cmp		bx,[cant_dias]
		;12.1 SI: El número de mes es <cant_meses>. Saltar a punto 19.
	jle		encontreMes
		;12.2 NO: Seguir con punto 13.
	;13. Le resto <cant_dias> a <dia>.
	mov		al,[cant_dias]
	sub		[dia],al
	;14. Le sumo 1 a <cant_meses>.
	add		byte[cant_meses],1
	;15. ¿<cant_meses> es igual a 2?
	cmp		byte[cant_meses],2
		;15.1 SI: Le asigno <febrero> a <cant_dias>.
	jne		noFebrero
	mov		al,[febrero]
	mov		byte[cant_dias],al
	jmp		buscoMes
		;15.2 NO: Seguir con punto 12.
noFebrero:
	mov		dx,msjTest1
	call	mostrarMsj
	jmp		buscoMes
	;16. Divido <cant_meses> por 2.
	mov		bl,2
	mov		ax,[cant_meses]
	div		bl
	;17. ¿El resto es 0?
	cmp		ah,0
		;17.1 SI: Es un mes par. Le asigno 30 a <cant_dias>.
	je		esMesPar
		;17.2 NO: Es un mes impar. Le asigno 31 a <cant_dias>.
	mov		byte[cant_dias],31
	jmp		buscoMes
esMesPar:
	mov		byte[cant_dias],30
	;18. Seguir con punto 12.
	jmp		buscoMes
	;19. Año = <anio_inicial> + <anio>, Mes = <cant_meses>, Día = <dia>
encontreMes:
	;20. Mostrar por pantalla:
		;Juliana: AADDDD
		;Gregoriana: AAAAMMDD
	;Muestro registro actual (NO TIENE QUE ESTAR EN LA VERSIÓN FINAL)
	mov		byte[registro+12],10
	mov		byte[registro+13],13
	mov		byte[registro+14],'$'
	mov		dx,registro
	call	mostrarMsj

	;Armo fecha Juliana con formato AADDDD
	mov		ah,byte[registro+1]
	mov		[fechaJuliana],ah
	mov		ah,byte[registro+2]
	mov		[fechaJuliana+1],ah
	mov		ah,byte[registro+7]
	mov		[fechaJuliana+2],ah
	mov		ah,byte[registro+8]
	mov		[fechaJuliana+3],ah
	mov		ah,byte[registro+9]
	mov		[fechaJuliana+4],ah
	mov		ah,byte[registro+10]
	mov		[fechaJuliana+5],ah
	mov		byte[fechaJuliana+6],10
	mov		byte[fechaJuliana+7],13
	mov		byte[fechaJuliana+8],'$'

	;Muestro la fecha Juliana
	mov		dx,msjJuliana
	call	mostrarMsj
	mov		dx,fechaJuliana
	call	mostrarMsj

	mov		dx,msjGregoriana
	call	mostrarMsj

	;21. Seguir con punto 3.
	;22. Cerrar archivo.
	jmp		cerrarArch

errAbrir:
	mov		dx,msjErrAbrir
	call	mostrarMsj
	jmp		fin

errLeer:
	mov		dx,msjErrLeer
	call	mostrarMsj
	jmp		fin

cerrarArch:
	mov		bx,[fHandle]	;handle del archivo
	mov		ah,3eh			;servicio
	int		21h				;se cierra
	jc		errCerrar		;Carry <> 0
	jmp		fin

errCerrar:
	mov		dx,msjErrCerrar
	call	mostrarMsj
	jmp		fin

mostrarMsj:
	mov		ah,9
	int		21h
	ret

fin:
	mov		dx,msjFin
	call	mostrarMsj
	mov		ah,4ch
	int		21h
