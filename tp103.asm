;*********************************************************************;
;      	           75.03 ORGANIZACION DEL COMPUTADOR                  ;
;                                                                     ;
; ALUMNO: Ignacio Chiappe                                             ;
; PADRON: 90340                                                       ;
; TP: 103 Intel 80x86 - Conversor de fechas (II)                      ;
;                                                                     ;
;*********************************************************************;

segment datos data
	anio_inicial	dw	1900
	febrero			db	28
	cant_dias		dw	31
	cant_meses		dw	1
	nom_arch		db	"juliana",0
	centena			dw	100
	decena			db	10
	diez			dw  10

	registro	times 6	resb	1
	dia				resw	1
	diaJuliano		resw	1
	mes				resb	1
	anio			resw	1

	fHandle			resb	2

	;Mensajes

	msjDatoNegativo	db	"Error: no puede haber valores negativos",10,13,"$"
	msjAnioInvalido	db	"Error: anio es mayor a 99",10,13,"$"
	msjDiaInvalido	db	"Error: dia es mayor a 366",10,13,"$"
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

	;Abrir archivo
abrirFile:
	mov		al,0			;tipo de acceso
	mov		dx,nom_arch		;nombre del archivo
	mov		ah,3dh			;servicio para abrir archivo 3dh
	int		21h				;se abre el archivo
	jc		errAbrir		;Carry <> 0
	mov 	[fHandle],ax	;en ax queda el handle del archivo

	;Leer registro
leerRegistro:
	mov		byte[febrero],28	;vuelvo la variable a su valor inicial
	mov		byte[cant_meses],1	;vuelvo la variable a su valor inicial
	mov		byte[cant_dias],31	;vuelvo la variable a su valor inicial
	mov		word[anio],0		;vuelvo la variable a su valor inicial
	mov		byte[mes],0			;vuelvo la variable a su valor inicial
	mov		byte[dia],0			;vuelvo la variable a su valor inicial
	mov		bx,[fHandle]		;handle del archivo
	mov		cx,6				;cantidad de bytes a leer
	mov		dx,registro			;memoria hacia donde se copia
	mov		ah,3fh				;servicio
	int		21h					;se lee
	jc		errLeer				;Carry <> 0
	cmp		ax,0
	je		cerrarArch

	;Verifico que no existan valores negativos en el registro
	mov		cx,2
	mov		si,1
datosNegativos:
	mov		al,byte[registro+si]
	shl		ax,12
	shr		ax,4
	;ahora tengo en ah la letra
	cmp		ah,0bh
	je		datoNegativo
	cmp		ah,0dh
	je		datoNegativo
	mov		si,5
	loop	datosNegativos
	sub		ah,ah

	;Obtener <anio>
	mov		al,byte[registro]
	shl		ax,4
	;ahora tengo en ah la centena
	cmp		ah,0
	jg		anioInvalido
	sub		ah,ah
	shr		ax,4
	;ahora tengo en al la decena
	mul		byte[decena]
	add		[anio],ax

	mov		al,byte[registro+1]
	shr		ax,4
	;ahora tengo en al la unidad
	add		[anio],al

	mov		ax,[anio_inicial]
	add		[anio],ax

	;Obtener <dia>
	sub		ax,ax
	mov		ax,word[registro+2]
	cmp		ax,0
	jg		diaInvalido

	mov		al,byte[registro+4]
	sub		ah,ah
	shl		ax,4
	xchg	ah,al
	shr		ah,4
	mov		bh,ah
	;ahora tengo en al la centena
	mul		byte[centena]
	mov		[dia],ax

	mov		al,bh
	;ahora tengo en al la decena
	mul		byte[decena]
	add		[dia],ax

	mov		al,byte[registro+5]
	sub		ah,ah
	shl		ax,4
	;ahora tengo en ah la unidad
	add		[dia],ah

	;Verifico que <dia> no sea mayor a 366
	cmp		word[dia],366
	jg		diaInvalido
	mov		ax,[dia]
	mov		[diaJuliano],ax

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
	jle		armoFechaJul
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
	;Mostrar por pantalla:
		;Juliana: AADDDD
		;Gregoriana: AAAAMMDD

	;Armo fecha Juliana con formato AADDDD
armoFechaJul:
	mov		dx,0		;pongo en 0 DX para la dupla DX:AX
	cmp		bl,1
	jne		armoDiaJul
	mov		ax,[anio]
	sub		ax,[anio_inicial]
	mov		si,1
	jmp		otraDivJul

armoDiaJul:
	mov		ax,[diaJuliano]
	mov		si,5

otraDivJul:
	div		word[diez]				;DX:AX div 10 ==> DX <- resto & AX <- cociente
	add		dx,30h					;convierto a ASCII el resto
	mov		[fechaJuliana+si],dl	;lo pongo en la posicion anterior
	sub		si,1					;posiciono SI en el caracter anterior en la cadena
	cmp		ax,[diez]				;SI cociente < 10
	jl		finDivJul				;ENTONCES fin division
	mov		dx,0					;pongo en 0 DX para la dupla DX:AX
	jmp		otraDivJul

finDivJul:
	add		ax,30h
	mov		[fechaJuliana+si],al
	inc		bl
	cmp		bl,3
	jne		armoFechaJul
	mov		byte[fechaJuliana+2],30h	;este dígito siempre es 0
	mov		byte[fechaJuliana+6],10
	mov		byte[fechaJuliana+7],13
	mov		byte[fechaJuliana+8],'$'

	;Armo fecha Gregoriana con formato AAAAMMDD
	sub		bl,bl
armoFecha:
	mov		dx,0		;pongo en 0 DX para la dupla DX:AX
	cmp		bl,1		;verifico si ya se armó el día
	jne		armoMes
	mov		ax,[anio]	;copio el nro en AX para divisiones sucesivas
	mov		si,3		;'SI' apunta al ultimo byte de la cadena
	jmp		otraDiv
armoMes:
	cmp		bl,2		;verifico si ya se armó el mes
	jne		armoDia
	mov		ax,[cant_meses]
	mov		si,5
	jmp		otraDiv
armoDia:
	mov		ax,[dia]
	mov		si,7

otraDiv:
	div		word[diez]				;DX:AX div 10 ==> DX <- resto & AX <- cociente
	add		dx,30h					;convierto a ASCII el resto
	mov		[fechaGregoriana+si],dl	;lo pongo en la posicion anterior
	sub		si,1					;posiciono SI en el caracter anterior en la cadena
	cmp		ax,[diez]				;SI cociente < 10
	jl		finDiv					;ENTONCES fin division
	mov		dx,0					;pongo en 0 DX para la dupla DX:AX
	jmp		otraDiv

finDiv:
	add		ax,30h
	mov		[fechaGregoriana+si],al
	inc		bl
	cmp		bl,3		;verifico si ya se armó el año
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

;****************************************;
;            RUTINAS INTERNAS            ;
;****************************************;

datoNegativo:
		mov		dx,msjDatoNegativo
		call	mostrarMsj
		jmp		leerRegistro

anioInvalido:
	mov		dx,msjAnioInvalido
	call	mostrarMsj
	jmp		leerRegistro

diaInvalido:
	mov		dx,msjDiaInvalido
	call	mostrarMsj
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
