segment datos data
	anio_inicial	dw	1900
	febrero			db	28
	cant_dias		dw	31
	cant_meses		dw	1
	nom_arch		db	"juliana.txt",0
	centena			dw	100
	decena			db	10
	diez				dw  10
	tabLetraPack	db	"CAFEBD"

	registro	times 15	resb	1
	dia				resw	1
	mes				resb	1
	anio			resw	1

	fHandle	resb	1

	;Mensajes

	msjErrAbrir		db	"Error al abrir archivo",10,13,"$"
	msjErrLeer		db	"Error al leer archivo",10,13,"$"
	msjErrCerrar	db	"Error al cerrar archivo",10,13,"$"
	msjErrLetra		db	"Registro no es un empaquetado valido",10,13,"$"
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

	;Abrir archivo
abrirFile:
	mov		al,0					;tipo de acceso
	mov		dx,nom_arch		;nombre del archivo
	mov		ah,3dh				;servicio para abrir archivo 3dh
	int		21h						;se abre el archivo
	jc		errAbrir			;Carry <> 0
	mov 	[fHandle],ax	;en ax queda el handle del archivo

	;Leer registro
leerRegistro:
	mov		byte[febrero],28		;vuelvo la variable a su valor inicial
	mov		byte[cant_meses],1	;vuelvo la variable a su valor inicial
	mov		byte[cant_dias],31	;vuelvo la variable a su valor inicial
	mov		bx,[fHandle]	;handle del archivo
	mov		cx,12					;cantidad de bytes a leer
	mov		dx,registro		;memoria hacia donde se copia
	mov		ah,3fh				;servicio
	int		21h						;se lee
	jc		errLeer				;Carry <> 0
	cmp		ax,0
	je		cerrarArch
	
	;Verifico letra de empaquetado
	mov		cx,2
	mov		si,0
leerLetraUno:
	mov		al,byte[registro+3]
	jmp		verificarLetra
leerLetraDos:
	mov		al,byte[registro+11]
	mov		si,0
verificarLetra:
	cmp		al,byte[tabLetraPack+si]
	je		letraValida
	inc		si
	cmp		si,5
	jle		verificarLetra
letraNoValida:
	mov		dx,msjErrLetra
	call	mostrarMsj
	jmp		leerRegistro
letraValida:
	loop	leerLetraDos
	;Obtener <anio>
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

	;Obtener <dia>
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

	;Verifico si es bisiesto
	;Dividir <anio> por 4.
	sub		dx,dx
	mov		ax,[anio]
	mov		bx,4
	div		bx
	;¿El resto de la división es 0?
	cmp		dx,0
		;SI: El anio es bisiesto.
	je		esBisiesto
		;NO: Seguir.
	;Dividir <anio> por 100.
	mov		ax,[anio]
	mov		bx,100
	div		bx
	cmp		dx,0
	jne		buscoMes
	mov		ax,[anio]
	mov		bx,400
	div		bx
	cmp		dx,0
	jne		buscoMes
esBisiesto:
	;Asignar 29 a <febrero>.
	mov		byte[febrero],29
buscoMes:
	;¿El <dia> es menor o igual a <cant_dias>?
	mov		bx,[dia]
	cmp		bx,[cant_dias]
		;SI: El número de mes es <cant_meses>. Saltar a encontreMes.
	jle		encontreMes
		;NO: Seguir.
	;Le resto <cant_dias> a <dia>.
	mov		ax,[cant_dias]
	sub		[dia],ax
	;Le sumo 1 a <cant_meses>.
	inc		byte[cant_meses]
	mov		ax,[cant_meses]
	;¿<cant_meses> es igual a 2?
	cmp		byte[cant_meses],2
		;SI: Le asigno <febrero> a <cant_dias>.
	jne		noFebrero
	mov		al,[febrero]
	mov		byte[cant_dias],al
	jmp		buscoMes
		;NO: Seguir.
	;Divido <cant_meses> por 2.
noFebrero:
	cmp		byte[cant_meses],8
	jge		segundaMitad
	mov		bl,2
	mov		ax,[cant_meses]
	div		bl
	;¿El resto es 0?
	cmp		ah,0
		;SI: Le asigno 30 a <cant_dias>.
	je		esTreinta
		;NO: Le asigno 31 a <cant_dias>.
	jmp		esTreintaUno
segundaMitad:
	mov		bl,2
	mov		ax,[cant_meses]
	div		bl
	;¿El resto es 0?
	cmp		ah,0
		;SI: Le asigno 31 a <cant_dias>.
	je		esTreintaUno
		;NO: Le asigno 30 a <cant_dias>.
esTreinta:
	mov		byte[cant_dias],30
	;Seguir con buscoMes.
	jmp		buscoMes
esTreintaUno:
	mov		byte[cant_dias],31
	jmp		buscoMes
	;Año = <anio_inicial> + <anio>, Mes = <cant_meses>, Día = <dia>
encontreMes:
	;Mostrar por pantalla:
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
	sub		bl,bl
armoFecha:
	mov		dx,0			;pongo en 0 DX para la dupla DX:AX
	cmp		bl,1
	jne		armoMes
	mov		ax,[anio]	;copio el nro en AX para divisiones sucesivas
	mov		si,3			;'SI' apunta al ultimo byte de la cadena
	jmp		otraDiv
armoMes:
	cmp		bl,2
	jne		armoDia
	mov		ax,[cant_meses]
	mov		si,5
	jmp		otraDiv
armoDia:
	mov		ax,[dia]
	mov		si,7

otraDiv:
	div		word[diez]			;DX:AX div 10 ==> DX <- resto & AX <- cociente
	add		dx,30h					;convierto a ASCII el resto
	mov		[fechaGregoriana+si],dl	;lo pongo en la posicion anterior
	sub		si,1						;posiciono SI en el caracter anterior en la cadena
	cmp		ax,[diez]				;SI cociente < 10
	jl		finDiv					;ENTONCES fin division
	mov		dx,0						;pongo en 0 DX para la dupla DX:AX
	jmp		otraDiv

finDiv:
	add		ax,30h
	mov		[fechaGregoriana+si],al
	inc		bl
	cmp		bl,3
	jne		armoFecha
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

	;Seguir con punto 3.
	jmp		leerRegistro

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
