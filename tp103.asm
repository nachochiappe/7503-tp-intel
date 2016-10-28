segment datos data
	anio_inicial	dw	1900
	febrero			db	28
	cant_dias		db	31
	cant_meses		db	1
	nom_arch		db	"juliana.txt",0
	registro		db	6
	
	dia		resw	1
	mes		resb	1
	anio	resw	1
	
	fHandle	resb	1
	
	;Mensajes
	
	msjErrAbrir		db	"Error al abrir archivo$"
	msjErrLeer		db	"Error al leer archivo$"
	msjErrCerrar	db	"Error al cerrar archivo$"
	msjFin			db	"FIN$"
	
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
	mov		ds,ax		;se copia al registro DS la dirección de inicio del segmento de datos
	mov		ax,pila		;se copia en registro AX la dirección del segmento STACK
	mov		ss,ax		;se copia al registro SS la dirección del segmento STACK
	mov		sp,stacktop
	
	;1.	Abrir archivo
abrirFile:
	mov		al,0		;tipo de acceso
	mov		dx,nom_arch	;nombre del archivo
	mov		ah,3dh		;servicio para abrir archivo 3dh
	int		21h			;se abre el archivo
	jc		errAbrir	;Carry <> 0
	mov 	[fHandle],ax	;en ax queda el handle del archivo
	
	;2.	¿Está vacío?
		;2.1	SI: Saltar a fin.
		;2.2	NO: Seguir con punto 3.
	;3.	Leer registro
	
	mov		bx,[fHandle]	;handle del archivo
	mov		cx,6			;cantidad de bytes a leer
	mov		dx,registro		;memoria hacia donde se copia
	mov		ah,3fh			;servicio
	int		21h				;se lee
	jc		errLeer			;Carry <> 0
	cmp		ax,0
	je		cerrarArch
	;4. ¿Es el fin del archivo?
		;4.1	SI: Saltar a punto 18.
		;4.2	NO: Seguir con punto 5.
	;5. Obtener <anio>
	
	
	
	;6. Obtener <dia>
	;7. Dividir <anio> por 100.
	;8. ¿El resto de la división es 0?
		;8.1 SI: El anio NO es bisiesto.
		;8.2 NO: Seguir con punto 9.
	;9. ¿Es la primera división?
		;9.1 SI: Dividir <anio> por 4. Seguir con punto 8.
		;9.2 NO: Saltar a punto 12.
	;10. Saltar a punto 8.
	;11. Asignar 29 a <febrero>.
	;12. ¿El <dia> es menor o igual a <cant_dias>?
		;12.1 SI: El número de mes es <cant_meses>. Saltar a punto 15.
		;12.2 NO: Seguir con punto 9.
	;13. Le resto <cant_dias> a <dia>.
	;14. Le sumo 1 a <cant_meses>.
	;15. ¿<cant_meses> es igual a 2?
		;15.1 Le asigno <diasfebrero> a <cant_dias>.
		;15.2 Seguir con punto 12.
	;16. Divido <cant_meses> por 2.
	;17. ¿El resto es 0?
		;17.1 SI: Es un mes par. Le asigno 30 a <cant_dias>.
		;17.2 NO: Es un mes impar. Le asigno 31 a <cant_dias>.
	;18. Seguir con punto 8.
	;19. Año = <anio_inicial> + <anio>, Mes = <cant_meses>, Día = <dia>
	;20. Mostrar por pantalla:
		;Juliana: AADDDD
		;Gregoriana: AAAAMMDD
	
	mov		dx,msjJuliana
	call	mostrarMsj
	
	mov		dx,msjGregoriana
	call	mostrarMsj
	
	;21. Seguir con punto 3.
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