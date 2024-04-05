.global composite_menu

.include "./utils.s"

.section .data
indicator:
    .string     ">"

title:
    .string     "hella cool console"

team_name:
    .string     "byte me if u can"

.align 4
pong_button:
    .incbin     "./assets/menu_pong.ms"

.align 4
ldm_button:
    .incbin     "./assets/menu_sch.ms"

// selected game
selected_option:
    .int        0

.section .text

// ----------------------------------------------------------------------
// Manually handles menu operations
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
composite_menu:
    pusha64

    width       .req    w10
    height      .req    w11
    halfWidth   .req    w12
    option      .req    w13

menu_start:

    // get width
    getv        width, fb_width
    getv        height, fb_height
    getv        option, selected_option

    // calc half width
    mov         halfWidth, width, LSR #1

    // disable double buffering
    mov         w0, wzr
    bl          fb_set_double_buffer

    // clear screen
    ldr         w0, =0xff1f0a15
    bl          fb_clear

    // render team name
    adr         x0, team_name
    sub         w1, width, #275
    sub         w2, height, #35
    ldr         w3, =0xff00ffff
    mov         w4, #2
    bl          fb_drawstring

    // render title
    adr         x0, title
    sub         w1, halfWidth, #300
    mov         w2, #75
    ldr         w3, =0xffffffff
    mov         w4, #4
    bl          fb_drawstring

    add         w5, w1, #5
    adr         x0, title
    ldr         w3, =0xff000000
    ldr         w6, =0x00222222

extrude:
    add         w1, w1, #1
    add         w2, w2, #1
    add         w3, w3, w6
    bl          fb_drawstring

    cmp         w5, w1
    bgt         extrude

    // increment y
    add         w2, w2, #100

    // games
    // pong
menu_pong:
    adr         x0, pong_button
    sub         w1, halfWidth, #170 / 2
    bl          fb_drawimage

    cbnz        option, menu_ldm         // is pong selected?
    // render indicator if selected
    adr         x0, indicator
    sub         w1, w1, #75
    add         w2, w2, #25
    ldr         w3, =0xffffffff
    mov         w4, #4
    bl          fb_drawstring

    // increment y
    add         w2, w2, #100

menu_ldm:
    adr         x0, ldm_button
    sub         w1, halfWidth, #170 / 2
    mov         w2, #300
    bl          fb_drawimage

    cbz         option, end              // is ldm selected?
    // render indicator if selected
    adr         x0, indicator
    sub         w1, w1, #75
    add         w2, w2, #25
    ldr         w3, =0xffffffff
    mov         w4, #4
    bl          fb_drawstring

end:
    // handle input
    // QEMU
input:
    mov         w0, #1000
    bl          delay_msec

    bl          handle_input

    cmp         w0, 'w'
    beq         menu_decrement_option

    cmp         w0, 's'
    beq         menu_increment_option

    cmp         w0, '\n'
    beq         menu_enter

    b           input


menu_increment_option:
    add         option, option, #1
    cmp         option, #1
    ble         update

    // set 0
    mov         option, wzr
    b           update         

menu_decrement_option:
    sub         option, option, #1
    cmp         option, wzr
    bge         update

    // set 0
    mov         option, #1
    b           update

menu_enter:
    cbz         option, pong
    bl          mainloop_ldm

    b           update

pong:
    bl          pong_menu

update:
    setv        option, selected_option
    b           menu_start

    .unreq      width
    .unreq      height
    .unreq      halfWidth
    .unreq      option

    popa64

    ret