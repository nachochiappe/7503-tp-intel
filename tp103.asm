segment datos data
	anio_inicial	dw	1900
	febrero			db	28
	cant_dias		dw	31
	cant_meses		db	1
	nom_arch		db	"juliana.txt",0
	centena			dw	100
	decena			db	10
	diez				dw  10

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

	msjJuliana		db	"Juliana: $"
	msjGregoriana	db	"Gregoriana: $"

	fechaJuliana	resb	9
	fechaGregoriana	times 8	db '0'
  				db'$' ;para agregar el fin de string para imprimir por pantalla

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
leerRegistro:
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
	sub		ax,ax
	;Centena
	mov		al,byte[registro+8]
	sub		al,30h
	mul		byte[centena]
	mov		[dia],ax

	;Decena
	mov		al,byte[registro+9]
	sub		al,30h
	mul		byte[decena]
	add		[dia],ax

	;Unidad
	mov		al,byte[registro+10]
	sub		al,30h
	add		[dia],al

	;7. Dividir <anio> por 100.

	sub		dx,dx
	mov		ax,[anio]
	div		word[centena]

	;8. ¿El resto de la división es 0?
	cmp		dx,0
		;8.1 SI: El anio NO es bisiesto.
	je		buscoMes
		;8.2 NO: Seguir con punto 9.
	;9. ¿Es la primera división?
		;9.1 SI: Dividir <anio> por 4. Seguir con punto 8.
	mov		ax,[anio]
	;mov		bx,4	con esto me da "Divide overflow"
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
	mov		ax,[cant_dias]
	sub		[dia],ax
	;14. Le sumo 1 a <cant_meses>.
	inc		byte[cant_meses]
	mov		ax,[cant_meses] ;esto es TEST
	;15. ¿<cant_meses> es igual a 2?
	cmp		byte[cant_meses],2
		;15.1 SI: Le asigno <febrero> a <cant_dias>.
	jne		noFebrero
	mov		al,[febrero]
	mov		byte[cant_dias],al
	jmp		buscoMes
		;15.2 NO: Seguir con punto 12.
	;16. Divido <cant_meses> por 2.
noFebrero:
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

	;Armo fecha Gregoriana con formato AAAAMMDD
	mov  dx,0			;pongo en 0 DX para la dupla DX:AX
	mov  ax,[anio]	;copio el nro en AX para divisiones sucesivas
	mov  si,7			;'SI' apunta al ultimo byte de la cadena

otraDiv:
	div  word[diez]			;DX:AX div 10 ==> DX <- resto & AX <- cociente
	add  dx,30h					;convierto a ASCII el resto
	mov  [fechaGregoriana+si],dl	;lo pongo en la posicion anterior
	sub  si,1						;posiciono SI en el caracter anterior en la cadena
	cmp  ax,[diez]			;IF cociente < 10
	jl   finDiv					;THEN fin division
	mov  dx,0						;pongo en 0 DX para la dupla DX:AX
	jmp  otraDiv

finDiv:
	add  ax,30h
	mov  [fechaGregoriana+si],al
	mov		byte[fechaGregoriana+8],10
	mov		byte[fechaGregoriana+9],13
	mov		byte[fechaGregoriana+10],'$'

mostrarFechas:
	;Muestro la fecha Juliana
	mov		dx,msjJuliana
	call	mostrarMsj
	mov		dx,fechaJuliana
	call	mostrarMsj

	;Muestro la fecha Gregoriana
	mov		dx,msjGregoriana
	call	mostrarMsj
	mov		dx,fechaGregoriana
	call	mostrarMsj

	;21. Seguir con punto 3.
	jmp		leerRegistro
	;22. Cerrar archivo.

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
