.global game_loop

.include "utils.s"

.section .data

.align 4
pos_x:
    .int    0

.align 4
pos_y:
    .int    0

.align 4
modex:
    .int    0

.align 4
modey:
    .int    0

testmsg:
    .string "m and s"

.section .text

game_loop:
    pusha64

    adr         x20, modex
    ldr         w21, [x20]

    adr         x22, modey
    ldr         w23, [x22]

    adr         x10, pos_x
    ldr         w11, [x10]

    and         w21, w21, #1
    cbz         w21, ax
    b           bx

ax:
    add         w11, w11, #1
    b           sx

bx:
    sub         w11, w11, #1

sx:
    str         w11, [x10]

    // 1024 - 112 = 912
    cmp         w11, #912
    blt         n2
    b           mm

n2:
    cmp         w11, wzr
    bge         ystart

mm:
    mvn         w21, w21
    str         w21, [x20]


ystart:
    adr         x12, pos_y
    ldr         w13, [x12]

    and         w23, w23, #1
    cbz         w23, ay
    b           by

ay:
    add         w13, w13, #2
    b           sy

by:
    sub         w13, w13, #2

sy:
    str         w13, [x12]

    // 1024 - 112 = 912
    cmp         w13, #752
    blt         n3
    b           mb

n3:
    cmp         w13, wzr
    bge         wew

mb:
    mvn         w23, w23
    str         w23, [x22]

wew:
    mov         w0, w11
    mov         w1, w13
    mov         w2, #112
    mov         w3, #16
    mov         w4, #0xFFFF0000
    bl          fb_drawfilledrect

    //adr         x0, testmsg
    //mov         w1, w11
    //mov         w2, w13
    //mov         w3, #0xFF00FFFF
    //mov         w4, #2
    //bl          fb_drawstring

    popa64
    
    ret
