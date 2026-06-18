.8086
.model small
.stack 100h

.data
;mensajes de bienvenida
    titulo  db "====== LLAMARADA HOMERO ======", 0dh, 0ah, 24h
    alumnos db "Alumnos: Agustina Mendoza, Franco Spataro, Valentin Mokorel, Candela Casagrande",0dh, 0ah, 24h
    p_enter db "Presione enter", 0dh, 0ah,24h

;instrucciones
    titulo_insts db "====================== INSTRUCCIONES DEL JUEGO ========================", 0dh, 0ah, 24h
    inst1        db "Tu personaje es HOMERO (H) y debes llegar a la taberna de Moe (F) para llegar a la meta y ganar", 0dh, 0ah, 24h
    instreceta   db "OBJETIVO: tenes que recolectar la recera (R) antes de salir", 0dh, 0ah, 24h
    inst2        db "Movimientos: W --> Arriba | S --> Abajo | A --> izquierda | D --> derecha | O --> usar soplete", 0dh, 0ah, 24h
    instsoplete  db "Tu arma será un soplete para ayudarte a abrir el camino --> O", 0dh, 0ah, 24h
    inst3        db "Debera superar los obtaculos para llegar a la meta", 0dh, 0ah, 24h
    inst4        db "Limite de movimientos: 50", 0dh, 0ah, 24h
    salida       db "Para salir del juego, presiona 6", 0dh,0ah,24h
    rayitas      db "============================================================================", 0dh, 0ah, 24h 

;guia del tablero
    titulo_guia  db "----------------------- ELEMENTOS DEL TABLERO -----------------------", 0dh, 0ah, 24h
    hom          db "[H] : Homero (tu pesonaje) --> amarillo", 0dh, 0ah, 24h
    moe          db "[F] : Taberna de Moe --> celeste", 0dh, 0ah, 24h
    rec          db "[R] : Receta secreta (necesaria para ganar) --> verde", 0dh, 0ah, 24h
    tierra       db "[", 177, "]: Bloque de tierra (al cruzarlo se te restaran 2 movimientos) --> marron", 0dh, 0ah, 24h
    viga         db "[", 219, "]: Viga (es indestructible) --> Gris", 0dh, 0ah, 24h
    telarana     db "[A]: Telarana (resta un movimiento y reaparece en otro lado)",  0dh, 0ah, 24h
    sop          db "[S] : Soplete (ganas un soplete para liberar camino)", 0dh, 0ah, 24h 
    puntos       db "[.] : Puntos (podras caminar libremente sobre ellos)", 0dh, 0ah, 24h
;volver a jugar
    finalJuego   db 0

    movimientos db 100
.code

extrn limpiarPantalla:proc
extrn imprimirTablero:proc
extrn imprimirStats:proc
extrn leerTecla:proc
extrn imp_cartel:proc
extrn r2a:proc
extrn juegop:proc
extrn crearTableroDinamico:proc
extrn proceso_obstaculos:proc
extrn reiniciarParametros:proc
extrn preguntarReinicio:proc


main proc

    mov ax,@data
    mov ds,ax

    call limpiarPantalla
;Bienvenida
    lea dx, titulo
    call imp_cartel

    lea dx, alumnos
    call imp_cartel

    lea dx, p_enter
    call imp_cartel

    mov ah, 08h ; ponemos enter para saltar a las instrucciones, aunque puede ser cualquier caracter
    int 21h
;Instrucciones
    call limpiarPantalla

    lea dx, titulo_insts
    call imp_cartel

    lea dx, inst1
    call imp_cartel

    lea dx, inst2
    call imp_cartel

    lea dx, inst3
    call imp_cartel

    lea dx, salida
    call imp_cartel

    lea dx, inst4
    call imp_cartel

    lea dx, rayitas
    call imp_cartel

    lea dx, p_enter
    call imp_cartel

    mov ah, 08h ; ponemos enter para saltar a las instrucciones, aunque puede ser cualquier caracter
    int 21h

;guia del tablero
    call limpiarPantalla

    lea dx, titulo_guia
    call imp_cartel

    lea dx, hom
    call imp_cartel

    lea dx, moe
    call imp_cartel

    lea dx, rec
    call imp_cartel

    lea dx, tierra
    call imp_cartel

    lea dx, viga
    call imp_cartel

    lea dx, telarana
    call imp_cartel

    lea dx, sop
    call imp_cartel

    lea dx, puntos
    call imp_cartel

    lea dx, rayitas
    call imp_cartel

    lea dx, p_enter
    call imp_cartel

    mov ah, 08h ; ponemos enter para que comience el juego
    int 21h

inicioPartida:
    call reiniciarParametros
    call crearTableroDinamico
    call juegop

    call limpiarPantalla
    call preguntarReinicio

    cmp al, '1'  ; comparo lo que quedo en al
    je inicioPartida

    cmp al, '2'
    je salir

salir:
    mov ax, 4C00h
    int 21h

main endp

end main