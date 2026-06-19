.8086
.model small
.stack 100h

.data
    public crearTableroDinamico
    public limpiarPantalla
    public imprimirTablero
    public leerTecla
    public imp_cartel
    public r2a
    public juegop
    public imprimirStats
    public proceso_obstaculos
    public recolectarReceta
    public reubicarTelarana
    public reiniciarParametros
    public preguntarReinicio

    movimientos db 50
    contadorAscii db "000", 0dh, 0ah, 24h


    filas      db 15   
    columnas   db 20
    tamano_tot dw 300 ; filas * columnas

    tablero    db 400 dup (24h), 24h
    semilla dw ?

    pos_H     dw 0
    pos_F     dw 24

    ;Inventario
    sopletes            db 3
    maderas             db 4
    cartelSopletes      db "Sopletes disponibles: ",0dh,0ah,24h

;indicador de receta
    tieneReceta         db 0   ; indicador de que homero no agarro la receta
    mostrarReceta       db 0
    cartelReceta        db "AGARRASTE LA RECETA!",0dh,0ah,24h
    cartelSinReceta     db "NECESITAS LA RECETA PARA GANAR!",0dh,0ah,24h

;Victoria
    cartelGano          db "Llegaste a la meta, ganaste!!!", 0dh, 0ah, 24h

    cartelmovrestantes  db "Movimientos restantes: ", 0dh, 0ah, 24h
    cartelPerdiste      db "Te quedaste sin movimientos, perdiste!", 0dh, 0ah, 24h

;jugar de nuevo
    msg_reintentar      db "QUIERES JUGAR DE NUEVO? (1=SI / 2=NO)", 0dh, 0ah, 24h
    finalJuego            db 0
    
    rayas db "=====================", 0dh, 0ah, 24h
    rayas1 db "================================================================", 0dh, 0ah, 24h
.code

;FUNCION PARA IMPRIMIR CARTELES
imp_cartel proc 
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
imp_cartel endp
;-------------------------------

limpiarPantalla proc

    mov ax,0003h
    int 10h

    ret
limpiarPantalla endp

;--------------------------------
;RECOLECTAR RECETA
;--------------------------------
recolectarReceta proc
    cmp tablero[bx],'R'
    jne finRecolectarReceta

    mov tieneReceta, 1
    mov mostrarReceta, 1 

    finRecolectarReceta:
        ret
recolectarReceta endp

imprimirTablero proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; 1. Apuntamos el registro de segmento ES a la memoria de video color
    mov ax, 0B800h
    mov es, ax

    mov si, 0        ; Índice para recorrer tu arreglo 'tablero'
    
    ; 2. Calcular la posición inicial en la pantalla (Fila 2, Columna 15)
    ; Fórmula: (Fila * 80 + Columna) * 2
    ; (2 * 80 + 15) * 2 = (160 + 15) * 2 = 175 * 2 = 350
    mov di, 350      ; DI será nuestro puntero en la pantalla de video

    xor cx, cx
    mov cl, filas    ; 15 filas

    fila:
        push cx
        xor cx, cx
        mov cl, columnas ; 20 columnas

    columna:
        ; Leer el carácter de tu tablero
        mov al, tablero[si]

        ; --- FILTRO DE COLORES---
        mov ah, 0Fh      ; Por defecto: Blanco sobre Negro
        
        cmp al, 'H'
        je  c_homero
        cmp al, 'F'
        je  c_moe
        cmp al, 'V'
        je  c_viga
        cmp al, 'T'
        je  c_tierra
        cmp al, 'A'
        je  c_telarana
        cmp al, 'R'
        je  c_receta
        jmp escribir_pantalla

    c_homero:
        mov ah, 0Eh      ; Amarillo brillante
        jmp escribir_pantalla
    c_moe:
        mov ah, 0Bh      ; Cyan brillante
        jmp escribir_pantalla
    c_viga:
        mov ah, 08h      ; Gris oscuro / Cemento
        mov al, 219      ; Código ASCII del bloque sólido █
        jmp escribir_pantalla

    c_tierra:
        mov ah, 06h      ; Marrón / Madera
        mov al, 177      ; Código ASCII de la trama media ▒ 
        jmp escribir_pantalla
    c_telarana:
        mov ah, 02h      ; Verde
        jmp escribir_pantalla
    c_receta:
        mov ah, 0Ch      ; Verde claro brillante
        jmp escribir_pantalla

    escribir_pantalla:
        ; Mandamos el carácter (AL) y su color (AH) directo a la pantalla
        mov es:[di], al   ; Pone el ASCII en la memoria de video
        inc di
        mov es:[di], ah   ; Pone el atributo de color en la memoria de video
        inc di

        inc si            ; Siguiente elemento de tu tablero
        loop columna      ; Decrementa CX (columnas) y salta si no es 0

        ; --- SALTO DE LÍNEA EN LA PANTALLA ---
        ; Al terminar una fila de 20 columnas, tenemos que avanzar DI hasta 
        ; el principio de la siguiente línea en la pantalla de 80 columnas.
        ; Restamos las 20 columnas impresas (40 bytes) a las 80 totales (160 bytes): 160 - 40 = 120 bytes.
        add di, 120       

        pop cx
        dec cl
        jnz fila

        ; 3. DEJAR EL CURSOR DE LA BIOS ABAJO PARA LOS CARTELES
        ; Para que la INT 21h sepa dónde seguir escribiendo los stats sin pisar el mapa,
        ; movemos el cursor de la BIOS a la fila 18, columna 0.
        mov ah, 02h
        mov bh, 0
        mov dh, 18        ; Fila abajo del mapa
        mov dl, 0         ; Columna 0
        int 10h

        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret
imprimirTablero endp

;=========================================================
; crearTableroDinamico
;
; Genera un nuevo tablero para cada partida.
;
; Pasos:
;   1) Calcula el tamaño real del mapa.
;   2) Inicializa la semilla aleatoria.
;   3) Llena el tablero con casilleros vacíos '.'.
;   4) Coloca a Homero y a Moe.
;   5) Distribuye obstáculos y objetos aleatoriamente.
;=========================================================
crearTableroDinamico proc
    ; Guardamos los registros que vamos a modificar
    ; para no alterar el estado del programa.
    push ax
    push bx
    push cx
    push dx
    push si

    ; Calculamos la cantidad total de casilleros:
    ; filas × columnas.
    ; En este caso: 15 × 20 = 300.
    mov al, filas
    mov bl, columnas
    mul bl

    mov tamano_tot, ax

    ; Obtenemos los ticks del reloj de la BIOS
    ; para utilizar un valor distinto como semilla
    ; en cada ejecución del juego.
    mov ah,00h
    int 1Ah
    mov semilla, dx

    ; Inicializamos todos los casilleros como vacíos.
    ; El símbolo '.' representa una posición libre.
    xor si, si
    mov cx, tamano_tot
    llenarPuntos:
        mov tablero[si], '.'
        inc si
        loop llenarPuntos

        ; Homero siempre comienza en la esquina superior izquierda.
        ; Índice 0 del arreglo.
        mov tablero[0], 'H'
        mov pos_H, 0

        ; Moe siempre se ubica en el último casillero
        ; del tablero, representando la meta.
        mov ax, tamano_tot
        dec ax

        mov si, ax

        mov tablero[si], 'F'

        mov pos_F, si

    ; Colocamos 60 bloques de tierra.
    ; La tierra puede romperse consumiendo movimientos.
    mov cx, 90
    ponerTierras:

    buscarTierra:
        ; Generamos una posición aleatoria.
        mov bx, tamano_tot
        call numeroAleatorio

        mov si, dx

        ; Solo colocamos tierra en casilleros vacíos.
        cmp tablero[si], '.'
        jne buscarTierra

        ; Insertamos el obstáculo.
        mov tablero[si], 'T'

        loop ponerTierras

    ; Colocamos 20 vigas.
    ; Las vigas son obstáculos indestructibles.
    mov cx, 50
    ponerVigas:

    buscarViga:
        mov bx, tamano_tot
        call numeroAleatorio

        mov si, dx
        ; Buscamos una posición libre para colocar la viga.
        cmp tablero[si], '.'
        jne buscarViga

        mov tablero[si], 'V'

        loop ponerVigas

    ; Colocamos 25 telarañas.
    ; Las telarañas consumen movimientos y luego
    ; reaparecen en otra ubicación del mapa.
    mov cx, 35
    ponerTelaranas:

    buscarTelarana:
        mov bx, tamano_tot
        call numeroAleatorio

        mov si, dx

        cmp tablero[si], '.'
        jne buscarTelarana

        mov tablero[si], 'A'

        loop ponerTelaranas

    ; La receta es obligatoria para poder ganar.
    ; Solo existe una en todo el tablero.
    buscarReceta:
        ; Elegimos aleatoriamente un casillero vacío
        ; hasta encontrar uno disponible.
        mov bx, tamano_tot
        call numeroAleatorio

        mov si, dx

        cmp tablero[si], '.'
        jne buscarReceta

        mov tablero[si], 'R'

    ; Colocamos dos sopletes.
    ; Los sopletes permiten destruir obstáculos
    ; cercanos al jugador.
    mov cx, 2
    ponerSopletes:

    buscarSoplete:
        mov bx, tamano_tot
        call numeroAleatorio

        mov si, dx

        cmp tablero[si], '.'
        jne buscarSoplete

        mov tablero[si], 'S'

        loop ponerSopletes

    ; Por seguridad volvemos a colocar a Homero y a Moe
    ; Esto garantiza que ningún objeto haya sobrescrito accidentalmente estas posiciones.
    mov tablero[0], 'H'

    mov ax, tamano_tot
    dec ax

    mov si, ax

    mov tablero[si], 'F'

    ; Restauramos los registros al estado original
    ; antes de regresar al programa principal
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret
crearTableroDinamico endp

juegop proc
    juego:

        call limpiarPantalla
        call imprimirTablero

        lea dx, rayas1
        call imp_cartel

        mov dl, movimientos
        lea bx, contadorAscii
        call r2a

        lea dx, cartelmovrestantes
        call imp_cartel

        lea dx, contadorAscii
        call imp_cartel

        call imprimirStats

        lea dx, rayas1
        call imp_cartel

        cmp mostrarReceta,1
        jne seguirJuego

        lea dx, cartelReceta
        call imp_cartel
        mov mostrarReceta,0

    seguirJuego:

        call leerTecla

        ; === CHECK SALIDA GENERAL ===
        cmp finalJuego, 1
        je salirJuego

        ; === PERDIDA POR MOVIMIENTOS ===
        cmp movimientos, 0
        jbe juegoperdido

        jmp juego


    ;cuando el usuario pierde
    juegoperdido:
        mov finalJuego, 1
        call limpiarPantalla
        lea dx, cartelPerdiste
        call imp_cartel

        mov ah,08h
        int 21h
        
        jmp salirJuego

    ;salida unificada
    salirJuego:
        ret
juegop endp

imprimirStats proc
    lea dx, cartelSopletes
    call imp_cartel

    mov dl, sopletes
    lea bx, contadorAscii
    call r2a

    lea dx, contadorAscii
    call imp_cartel

    ret
imprimirStats endp

leerTecla proc

    mov ah,08h
    int 21h

    cmp al,'6'
    je salirTecla

    cmp al,'w'
    je arriba

    cmp al,'s'
    je abajo

    cmp al,'a'
    je izquierda

    cmp al,'d'
    je derecha

    cmp al,'o'
    je soplete

    mayus:
        cmp al,'W'
        je arriba
    
        cmp al,'S'
        je abajo
    
        cmp al,'A'
        je izquierda
    
        cmp al,'D'
        je derecha

        cmp al,'O'
        je soplete

    ret

    arriba:
        call moverArriba
        ret

    abajo:
        call moverAbajo
        ret

    izquierda:
        call moverIzquierda
        ret

    derecha:
        call moverDerecha
        ret

    soplete:
        call usarSoplete
        ret
    salirTecla:
        mov finalJuego, 1
        ret
leerTecla endp

moverDerecha proc
    mov si,0

    buscarDerecha:

        cmp si, tamano_tot
        jae finMoverDerecha

        cmp tablero[si],'H'
        je encontradoDerecha

        inc si
        jmp buscarDerecha

    encontradoDerecha:

        mov ax,si
        xor bx, bx
        mov bl, columnas
        div bl

        mov dl, columnas
        dec dl

        cmp ah, dl
        je finMoverDerecha

        mov bx, si
        inc bx

        cmp tablero[bx],'V'
        je finMoverDerecha

        call proceso_obstaculos
        cmp al, 0
        je finMoverDerecha

        cmp tablero[bx],'F'
        jne seguirDerecha
        cmp tieneReceta, 1
        je puedeGanarDer
        jmp sinRecetaDerecha

    puedeGanarDer:
        jmp victoria
        
    sinRecetaDerecha:
        lea dx, cartelSinReceta
        call imp_cartel
        mov ah, 08h
        int 21h
        ret

    seguirDerecha:
        call recolectarReceta
        call recolectarObjeto
        dec movimientos
        mov tablero[si],'.'
        mov tablero[bx],'H'
        ret

    finMoverDerecha:
        ret
moverDerecha endp

moverIzquierda proc
    mov si,0
    
    buscarIzquierda:

        cmp si, tamano_tot
        jae finMoverIzquierda

        cmp tablero[si],'H'
        je encontradoIzquierda

        inc si
        jmp buscarIzquierda

    encontradoIzquierda:

        mov ax,si
        xor bx, bx

        mov bl, columnas
        div bl

        cmp ah,0
        je finMoverIzquierda

        mov bx,si
        dec bx

        cmp tablero[bx],'V'
        je finMoverIzquierda

        call proceso_obstaculos
        cmp al, 0
        je finMoverIzquierda

        cmp tablero[bx],'F'
        jne seguirIzquierda
        cmp tieneReceta,1
        je puedeGanarIzq
        jmp sinRecetaIzq

    puedeGanarIzq:
        jmp victoria

    sinRecetaIzq:
        lea dx, cartelSinReceta
        call imp_cartel
        mov ah, 08h
        int 21h
        ret

    seguirIzquierda:
        call recolectarReceta
        call recolectarObjeto
        dec movimientos
        mov tablero[si],'.'
        mov tablero[bx],'H'

    finMoverIzquierda:
        ret
moverIzquierda endp

moverArriba proc

    mov si,0

    buscarArriba:

        cmp si, tamano_tot
        jae finMoverArriba

        cmp tablero[si],'H'
        je encontradoArriba

        inc si
        jmp buscarArriba

    encontradoArriba:
        xor ax, ax
        mov al, columnas

        cmp si, ax
        jb finMoverArriba

        mov bx,si
        sub bx, ax

        cmp tablero[bx],'V'
        je finMoverArriba

        call proceso_obstaculos
        cmp al, 0
        je finMoverArriba

        cmp tablero[bx],'F'
        jne seguirArriba
        cmp tieneReceta, 1
        je puedeGanarArriba
        jmp sinRecetaArriba

    puedeGanarArriba:
        jmp victoria
        
    sinRecetaArriba:
        lea dx, cartelSinReceta
        call imp_cartel
        mov ah, 08h
        int 21h
        ret

    seguirArriba:
        call recolectarReceta
        call recolectarObjeto
        dec movimientos
        mov tablero[si],'.'
        mov tablero[bx],'H'

    finMoverArriba:
        ret
moverArriba endp

moverAbajo proc
    mov si,0

    buscarAbajo:
        cmp si, tamano_tot
        jae finMoverAbajo

        cmp tablero[si],'H'
        je encontradoAbajo

        inc si
        jmp buscarAbajo

    encontradoAbajo:
        mov bx,si
        xor ax, ax
        mov al, columnas
        add bx, ax

        cmp bx, tamano_tot
        jae finMoverAbajo

        cmp tablero[bx],'V'
        je finMoverAbajo

        call proceso_obstaculos
        cmp al, 0
        je finMoverArriba

        cmp tablero[bx],'F'
        jne seguirAbajo
        cmp tieneReceta, 1
        je puedeGanarAbajo
        jmp sinRecetaAbajo

    puedeGanarAbajo:
        jmp victoria

    sinRecetaAbajo:
        lea dx, cartelSinReceta
        call imp_cartel
        mov ah,08h
        int 21h
        ret

    seguirAbajo:
        call recolectarReceta
        call recolectarObjeto
        dec movimientos
        mov tablero[si],'.'
        mov tablero[bx],'H'

    finMoverAbajo:

        ret
moverAbajo endp

recolectarObjeto proc

        cmp tablero[bx],'S'
        jne revisarMadera

        inc sopletes
        ret
        revisarMadera:
            cmp tablero[bx],'M'
            jne finRecolectar

            inc maderas
        finRecolectar:
            ret
recolectarObjeto endp

victoria:

    mov finalJuego, 1

    call limpiarPantalla
    call imprimirTablero

    lea dx, cartelGano
    call imp_cartel

    mov ah,08h
    int 21h

    ret

salto proc

    push ax
    push dx

    mov dl,0Dh
    mov ah,02h
    int 21h

    mov dl,0Ah
    int 21h

    pop dx
    pop ax

    ret
salto endp

;===r2a===================================================================
; DL = numero a convertir, BX = donde guardar mov dl lea bx
r2a proc ;Número binario → 3 dígitos ASCII
    push ax
    push dx
    push cx
    push bx

    mov cl, 10
    add bx, 2      ; apunto al último dígito
    xor ax, ax
    mov al, dl     ; número a convertir

    div cl
    mov [bx], ah
    add byte ptr [bx], 30h

    dec bx
    xor ah, ah
    div cl
    mov [bx], ah
    add byte ptr [bx], 30h

    dec bx
    xor ah, ah
    div cl
    mov [bx], ah
    add byte ptr [bx], 30h

    pop bx
    pop cx
    pop dx
    pop ax
    ret
r2a endp
;==========================================================================
proceso_obstaculos proc

    push bx

    ;VIGA # H, rebota
    cmp tablero[bx], 'V'
    je camino_bloqueado

    ;TIERRA T, H rompe
    cmp tablero[bx], 'T'
    je chocar_tierra

    ;TELARAÑA A, rompe A y se reubica
    cmp tablero[bx], 'A'
    je chocar_telarana

    camino_libre:
    mov al, 1
    pop bx
    ret

    chocar_tierra:
    cmp movimientos, 2
    jb camino_bloqueado   ; Si no tiene 2 movimientos, rebota de verdad
    
    sub movimientos, 2    ; Restamos el costo
    mov tablero[bx], '.'  ; Rompemos la tierra en la matriz
    jmp camino_libre      ; ¡Devuelve AL=1 para que Homero avance este mismo turno!

    chocar_telarana:
    cmp movimientos, 5
    jb camino_bloqueado
    
    dec movimientos       ; Cuesta 1 movimiento
    mov tablero[bx], '.'  ; Desaparece la telaraña
    call reubicarTelarana ; Se muda la araña
    jmp camino_libre      ; ¡Devuelve AL=1 para que avance de una!

    camino_bloqueado:
    mov al, 0 
    pop bx
    ret    
proceso_obstaculos endp
;==========================================================================================;
; usarSoplete
; Si hay sopletes disponibles, busca a Homero, descuenta un soplete
; y rompe bloques cercanos a distancia 2.
;==========================================================================================;

usarSoplete proc
    push ax
    push si

    cmp sopletes, 0
    je finUsarSoplete

    call buscarHomero
    jc finUsarSoplete

    dec sopletes
    call romperZonaSoplete

    finUsarSoplete:
        pop si
        pop ax
        ret
usarSoplete endp

;==========================================================================================;
; buscarHomero
; Salida:
;   SI = posicion donde esta Homero
;   CF = 0 si encontro
;   CF = 1 si no encontro
;==========================================================================================;
buscarHomero proc
    push ax

    mov si, 0

    recorrerTableroH:
        cmp si, tamano_tot
        jae noEncontroHomero

        cmp tablero[si], 'H'
        je encontroHomero

        inc si
        jmp recorrerTableroH

    encontroHomero:
        clc
        pop ax
        ret

    noEncontroHomero:
        stc
        pop ax
        ret
buscarHomero endp

;==========================================================================================;
; romperZonaSoplete
; Entrada:
;   SI = posicion de Homero
;
; Rompe en cruz hasta distancia 2.
;==========================================================================================;
romperZonaSoplete proc
    push ax
    push bx
    push dx

    ; ARRIBA 1 = SI - columnas
    xor ax, ax
    mov al, columnas

    cmp si, ax
    jb noArriba1

    mov bx, si
    sub bx, ax
    call romperCasillero

    noArriba1:

    ; ARRIBA 2 = SI - columnas * 2
        xor ax, ax
        mov al, columnas
        shl ax, 1

        cmp si, ax
        jb noArriba2

        mov bx, si
        sub bx, ax
        call romperCasillero

    noArriba2:

    ; ABAJO 1 = SI + columnas
        xor ax, ax
        mov al, columnas

        mov bx, si
        add bx, ax

        cmp bx, tamano_tot
        jae noAbajo1

        call romperCasillero

    noAbajo1:

    ; ABAJO 2 = SI + columnas * 2
        xor ax, ax
        mov al, columnas
        shl ax, 1

        mov bx, si
        add bx, ax

        cmp bx, tamano_tot
        jae noAbajo2

        call romperCasillero

    noAbajo2:

    ; Calculo columna de Homero: columna = SI MOD columnas
        mov ax, si
        mov bl, columnas
        div bl

        mov dl, ah

    ; IZQUIERDA 1 = SI - 1
        cmp dl, 0
        je noIzquierda1

        mov bx, si
        dec bx
        call romperCasillero

    noIzquierda1:

    ; IZQUIERDA 2 = SI - 2
        cmp dl, 1
        jbe noIzquierda2

        mov bx, si
        sub bx, 2
        call romperCasillero

    noIzquierda2:

    ; DERECHA 1 = SI + 1
        mov al, columnas
        dec al

        cmp dl, al
        jae noDerecha1

        mov bx, si
        inc bx
        call romperCasillero

    noDerecha1:

    ; DERECHA 2 = SI + 2
        mov al, columnas
        sub al, 2

        cmp dl, al
        jae noDerecha2

        mov bx, si
        add bx, 2
        call romperCasillero

    noDerecha2:

        pop dx
        pop bx
        pop ax
        ret
romperZonaSoplete endp

;==========================================================================================;
; romperCasillero
; Entrada:
;   BX = posicion del tablero a revisar
;==========================================================================================;
romperCasillero proc
    push ax

    mov al, tablero[bx]
    call esBloqueRompible
    jc finRomperCasillero

    mov tablero[bx], '.'

    finRomperCasillero:
        pop ax
        ret
romperCasillero endp

;==========================================================================================;
; esBloqueRompible
; Entrada:
;   AL = caracter a analizar
;
; Salida:
;   CF = 0 si es rompible
;   CF = 1 si no es rompible
;==========================================================================================;

esBloqueRompible proc

    cmp al, 'V'
    je noEsRompible

    cmp al, 'T'
    je siEsRompible

    cmp al, 'A'
    je siEsRompible

    noEsRompible:
        stc
        ret

    siEsRompible:
        clc
        ret
esBloqueRompible endp

reubicarTelarana proc
    push ax
    push bx
    push cx
    push dx
    push si

    buscar_hueco_vacio:
        ; 1. LEER EL RELOJ DE LA BIOS PARA OBTENER UN NÚMERO "ALFA"
        mov ah, 00h          ; Función 00h: Obtener ticks del sistema
        int 1Ah              ; DX contiene los ticks de menor peso (cambian rapidísimo)

        ; 2. CALCULAR EL MÓDULO PARA AJUSTARLO AL TAMAÑO DEL TABLERO (300)
        mov ax, dx           ; Pasamos el número a AX
        xor dx, dx           ; Limpiamos DX para la división
        mov bx, tamano_tot   ; BX = 300
        div bx               ; DX tiene el resto de la división (un número entre 0 y 299)

        mov si, dx           ; SI ahora es nuestro índice aleatorio candidato

        ; 3. VALIDAR QUE EL CASILLERO ELEGIDO ESTÉ VACÍO
        ; No podemos pisar a Homero, a Moe, ni poner una telaraña sobre una viga o tierra 
        cmp tablero[si], '.'
        jne buscar_hueco_vacio ; Si no está vacío ('.'), volvemos a intentar con otro tick de reloj

        ; 4. CLAVAR LA NUEVA TELARAÑA
        mov tablero[si], 'A' ; Colocamos la nueva telaraña en el mapa

        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret
reubicarTelarana endp

;=========================================================
; numeroAleatorio
;
; Genera un número pseudoaleatorio entre 0 y BX-1.
;
; Entrada:
;   BX = límite superior (no incluido).
;
; Salida:
;   DX = número pseudoaleatorio.
;
; Utiliza un generador congruencial lineal basado
; en una semilla inicializada con el reloj BIOS.
;=========================================================
numeroAleatorio proc
    push ax
    push bx
    ; Cargamos la semilla actual.
    mov ax, semilla
    ; Aplicamos la fórmula:
    ; nuevaSemilla = semilla × 25173 + 13849
    mov bx, 25173
    mul bx

    add ax, 13849
    ; Guardamos la nueva semilla para futuras llamadas.
    mov semilla, ax

    ; Calculamos el resto para obtener un valor dentro del rango solicitado.
    ; Resultado final en DX.
    xor dx, dx
    div bx

    pop bx
    pop ax
    ret
numeroAleatorio endp
;========================================
;reiniciar parametros
;========================================
reiniciarParametros proc
    push ax

    ; Movimientos iniciales
    mov movimientos, 50

    ; Inventario
    mov sopletes, 3
    mov maderas, 4

    ; Estado de juego
    mov tieneReceta, 0
    mov mostrarReceta, 0

    ; Posiciones iniciales (por seguridad)
    mov pos_H, 0
    mov pos_F, 24

    ; Semilla aleatoria (opcional pero recomendado)
    mov ah, 00h
    int 1Ah
    mov semilla, dx

    mov finalJuego, 0

    pop ax
    ret
reiniciarParametros endp

;==============================
;PREGUNTAR REINCIO
;==============================
preguntarReinicio proc
    lea dx, msg_reintentar
    call imp_cartel

    pidoTecla:
        mov ah, 08h
        int 21h

        cmp al, '1'
        je ok

        cmp al, '2'
        je ok

        jmp pidoTecla

    ok:
        ret
preguntarReinicio endp
end