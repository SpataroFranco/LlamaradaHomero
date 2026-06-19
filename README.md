# 🔥 Llamarada Homero

Juego desarrollado en **Assembler 8086** para DOS, donde el jugador controla a Homero Simpson y debe atravesar un mapa lleno de obstáculos para llegar a la taberna de Moe. Sin embargo, antes de alcanzar la meta deberá encontrar la **receta secreta**, indispensable para ganar la partida.

---

## 📌 Descripción

**Llamarada Homero** es un videojuego en modo texto que utiliza interrupciones de BIOS y DOS para gestionar la pantalla, el teclado y la generación aleatoria del escenario.

El proyecto fue desarrollado con fines académicos para aplicar conceptos de:

* Programación en Assembler 8086.
* Modularización mediante bibliotecas externas.
* Manipulación directa de memoria de video.
* Uso de interrupciones BIOS y DOS.
* Implementación de estructuras de juego y lógica de estados.

---

## 🎯 Objetivo del juego

El jugador controla a **Homero (H)** y debe:

1. Explorar el tablero.
2. Encontrar la **receta secreta (R)**.
3. Administrar correctamente sus movimientos y recursos.
4. Llegar a la **taberna de Moe (F)**.

### Condición de victoria

Para ganar es obligatorio:

* Obtener la receta secreta.
* Llegar a Moe antes de quedarse sin movimientos.

### Condición de derrota

El jugador pierde si:

* Se queda sin movimientos.
* Decide abandonar la partida presionando la tecla de salida.

---

## 🕹️ Controles

| Tecla | Acción                   |
| ----- | ------------------------ |
| W     | Mover hacia arriba       |
| A     | Mover hacia la izquierda |
| S     | Mover hacia abajo        |
| D     | Mover hacia la derecha   |
| O     | Usar soplete             |
| 6     | Salir del juego          |

---

## 🗺️ Elementos del tablero

| Símbolo | Descripción                         |
| ------- | ----------------------------------- |
| H       | Homero (jugador)                    |
| F       | Taberna de Moe (meta)               |
| R       | Receta secreta necesaria para ganar |
| .       | Casillero libre                     |
| T       | Tierra rompible                     |
| █       | Viga indestructible                 |
| A       | Telaraña                            |
| S       | Soplete                             |

---

## ⚙️ Mecánicas del juego

### Movimientos

El jugador dispone inicialmente de:

* **50 movimientos**

Cada desplazamiento consume movimientos.

---

### Tierra (T)

* Puede atravesarse.
* Consume **2 movimientos adicionales**.
* Se destruye luego de ser utilizada.

---

### Vigas (█)

* Son obstáculos permanentes.
* No pueden atravesarse.
* Tampoco pueden destruirse con el soplete.

---

### Telarañas (A)

* Consumen **1 movimiento adicional**.
* Desaparecen al atravesarlas.
* Se reubican aleatoriamente en otra posición del tablero.

---

### Receta secreta (R)

* Solo existe una por partida.
* Es obligatoria para poder ganar.

Si el jugador intenta llegar a Moe sin haberla obtenido, el juego mostrará un mensaje indicando que debe conseguirla primero.

---

### Sopletes (S)

El jugador comienza con:

* **3 sopletes**

Además, puede recolectar sopletes adicionales durante la partida.

#### Uso del soplete

El soplete destruye obstáculos rompibles formando una cruz alrededor de Homero:

```text
    X
    X
X X H X X 
    X
    X
```

Tiene un alcance máximo de **2 casillas**.

Puede destruir:

* Tierra (T)
* Telarañas (A)

No puede destruir:

* Vigas
* Moe
* Homero
* Recetas
* Casillas vacías

---

## 🎲 Generación aleatoria del tablero

Cada nueva partida genera automáticamente un escenario diferente.

Distribución del tablero:

| Elemento  | Cantidad |
| --------- | -------- |
| Tierra    | 60       |
| Vigas     | 20       |
| Telarañas | 25       |
| Receta    | 1        |
| Sopletes  | 2        |

El tablero tiene dimensiones de:

```text
15 filas × 20 columnas
```

equivalentes a **300 casilleros**.

La aleatoriedad se implementa utilizando:

* El reloj interno de la BIOS como semilla inicial.
* Un algoritmo para producir una secuencia de números pseudoaleatorios

---

## 🏗️ Arquitectura del proyecto

El proyecto está dividido en dos módulos principales:

### mainTP.asm

Controla el flujo general del juego:

* Pantalla de bienvenida.
* Instrucciones.
* Guía de símbolos.
* Inicio de partidas.
* Reinicio del juego.

### libTP.asm

Contiene toda la lógica:

* Generación del tablero.
* Impresión del mapa.
* Movimiento del jugador.
* Gestión de obstáculos.
* Inventario.
* Uso del soplete.
* Condiciones de victoria y derrota.
* Reinicio de parámetros.

---

## 🔄 Flujo general del juego

```text
Inicio
 ↓
Bienvenida
 ↓
Instrucciones
 ↓
Guía del tablero
 ↓
Generar partida
 ↓
Bucle principal
 ↓
Mover jugador
 ↓
Procesar obstáculos
 ↓
Verificar victoria o derrota
 ↓
¿Jugar nuevamente?
 ├─ Sí → Nueva partida
 └─ No → Salir
```

---

## 🛠️ Tecnologías utilizadas

* Assembler 8086
* Interrupciones BIOS
* Interrupciones DOS
* Memoria de video B800h
* DOSBox (para ejecución y pruebas)

---

## 👥 Integrantes

* Agustina Mendoza
* Franco Spataro
* Valentín Mokorel
* Candela Casagrande

---

## 📚 Objetivos académicos

Este proyecto fue desarrollado con el objetivo de aplicar los conocimientos adquiridos durante la cursada sobre:

* Programación de bajo nivel.
* Modularización y reutilización de código.
* Manejo de interrupciones del sistema.
* Administración eficiente de recursos.
* Diseño e implementación de videojuegos en modo texto.

---

## 📄 Licencia

Proyecto desarrollado con fines exclusivamente educativos y académicos.
