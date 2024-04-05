// laplace demon or wtvr it's called
// ammar

.global mainloop_ldm

.include "./utils.s"

.equ        BG_COLOR,           0xff000000
.equ        GROUND_HEIGHT,      100

.section .data

.align 4
player:
player_pos:
    .int    0
    .int    480 - GROUND_HEIGHT - 51
player_dims:
    .int    34
    .int    50
player_vel_y:
    .int    0
player_health:
    .int    101

table:
table_pos:
    .int    500
    .int    480 - GROUND_HEIGHT - 41
table_dims:
    .int    60
    .int    40

box:
box_pos:
    .int    300
    .int    480 - GROUND_HEIGHT - 51
box_dims:
    .int    40
    .int    50

player_frame_1:
    .incbin "./assets/MCFrame1.ms"

player_frame_2:
    .incbin "./assets/MCFrame2.ms"

table_pic:
    .incbin "./assets/table.ms"

heart_pic:
    .incbin "./assets/seif.ms"

deadMsg:
    .string "GAME OVER"

.align 8
current_frame:
    .long   0

.section .text

mainloop_ldm:
    pusha64

    // begin
    
    // disable double buffering
    mov         w0, wzr
    bl          fb_set_double_buffer

    // clear screen
    ldr         w0, =BG_COLOR
    bl          fb_clear

    // render ground
    bl          render_ground

    bl          damage

1:
    bl          i_w
    cbnz        w0, incCC
    b           mmmm

incCC:
    mov         w0, #4
    setv        w0, player_vel_y

mmmm:

    getv        x25, current_frame
    add         x25, x25, #1
    setv        x25, current_frame

    getv        w1, player_pos              // x
    getvoff     w2, player_pos, #4          // y

    // check player velocity
    getv        w5, player_vel_y
    tst         w5, w5
    bpl         velcheck

    cmp         w2, #480 - GROUND_HEIGHT - 51
    bge         pl                          // dont check
    
velcheck:
    // read velocity, and update accordingly
    sub         w2, w2, w5
    sub         w5, w5, #2
    setv        w5, player_vel_y

pl:
    adr         x0, player
    adr         x3, render_player
    ldr         w11, =BG_COLOR
    mov         w12, #1
    bl          move_obj


    // render table if applicable
    getv        w1, table_pos              // x
    getvoff     w2, table_pos, #4          // y

    cmp         w1, #-60
    ble         end_table

    mov         w15, #5
    udiv        x15, x25, x15
    sub         w1, w1, w15

    cmp         w1, #-60
    blt         3f
    b           4f
3:
    mov         w1, #800

4:

    adr         x0, table
    adr         x3, render_table
    bl          move_obj
    b           t2

end_table:
    mov         w0, #800
    setv        w0, table_pos

t2:
    // render box if applicable
    getv        w1, box_pos              // x
    getvoff     w2, box_pos, #4          // y

    cmp         w1, #-40
    ble         end_box

    mov         w15, #10
    udiv        x15, x25, x15
    sub         w1, w1, w15

    cmp         w1, #-40
    blt         3f
    b           4f
3:
    mov         w1, #900
4:

    adr         x0, box
    adr         x3, render_box
    bl          move_obj

    b           box2

end_box:
    mov         w0, #800
    setv        w0, table_pos

box2:

    // check collision
    getv        w0, player_pos
    getvoff     w1, player_pos, #4

    adr         x5, table_pos
    bl          intersection

    adr         x5, box_pos
    bl          intersection

    getv        w10, player_health
    cmp         w10, wzr
    ble         death

    mov         w0, 50
    bl          delay_msec

    b           1b

death:
    ldr         w0, =BG_COLOR
    bl          fb_clear

    adr         x0, deadMsg
    mov         w1, #300
    mov         w2, #100
    mov         w3, #0xff00ffff
    mov         w4, #4
    bl          fb_drawstring

    mov         w0, #3000
    bl          delay_msec

    popa64

    ret

intersection:
    push        x30
    ldr         w2, [x5]                    //tx
    ldr         w3, [x5, #4]                //ty

    cmp         w2, w0
    blt         no_intersect

    add         w4, w0, #34
    cmp         w2, w4
    bgt         no_intersect

    cmp         w3, w1
    blt         no_intersect

    add         w4, w1, #50
    cmp         w3, w4
    bgt         no_intersect

    bl          damage

no_intersect:
    pop         x30

    ret

damage:
    pusha64

    getv        w10, player_health
    sub         w10, w10, #10
    setv        w10, player_health

    cmp         w10, wzr
    ble         2f

    mov         w0, #300
    mov         w1, #10
    mov         w2, #200
    mov         w3, #50
    ldr         w4, =BG_COLOR
    bl          fb_drawfilledrect

    mov         w5, #25
    udiv        w5, w10, w5
    add         w5, w5, #1

    adr         x0, heart_pic

    mov         w2, #10

    mov         w1, #300

1:
    cbz         w5, 2f
    bl          fb_drawimage

    add         w1, w1, #50

    sub         w5, w5, #1
    b           1b

2:
    popa64

    ret


// ----------------------------------------------------------------------
// Moves object - non intersecting
//
// Arguments:
//  x0 - obj addr
//  w1 - new x
//  w2 - new y
//  x3 - RENDERER
//  w11 - clear color
//  w12 - ignore check
//
// Returns:
//
// ----------------------------------------------------------------------
move_obj:
    push        x30
    pushp       x3, x4
    push        x5
    push        x10

    ldr         w4, [x0]                // get x
    ldr         w5, [x0, #4]            // get y

    cbnz        w12, 1f

    cmp         w1, w4                  // is x != x2
    bne         1f

    cmp         w2, w5                  // y != y2
    bne         1f

    // same pos, so no
    b           post_render

1:  // lol
    // clear old
    // save new pos

    pushp       x0, x1
    pushp       x2, x3

    mov         x10, x0

    mov         w0, w4                  // x
    mov         w1, w5                  // y
    ldr         w2, [x10, #8]           // width
    ldr         w3, [x10, #12]          // height
    mov         w4, w11                 // color
    bl          fb_drawfilledrect

    popp        x2, x3
    popp        x0, x1

    // save new pos
    str         w1, [x0]                // x
    str         w2, [x0, #4]            // y


    // draw again...
    adr         x30, post_render
    // renderer with x0 = obj base
    br          x3

post_render:
    pop         x10
    pop         x5
    popp        x3, x4
    pop         x30

    ret

// ----------------------------------------------------------------------
// Player renderer
//
// Arguments:
//  x0 - obj addr
//
// Returns:
//
// ----------------------------------------------------------------------
render_player:
    push        x30
    pushp       x0, x1
    pushp       x2, x3

    ldr         w1, [x0]                // get x
    ldr         w2, [x0, #4]            // get y

    // draw frame
    // x % 2
    ands        x3, x25, #1
    cbz         x3, 1f

    adr         x0, player_frame_2
    b           2f

1:
    adr         x0, player_frame_1

2:
    bl          fb_drawimage

    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret

render_ground:
    push        x30
    pushp       x0, x1
    pushp       x2, x3
    push        x4

    mov         w0, wzr
    getv        w1, fb_height
    sub         w1, w1, #GROUND_HEIGHT
    getv        w2, fb_width
    mov         w3, #GROUND_HEIGHT
    ldr         w4, =0xff008800
    bl          fb_drawfilledrect

    pop         x4
    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret

render_table:
    push        x30
    pushp       x0, x1
    pushp       x2, x3

    ldr         w1, [x0]                // get x
    ldr         w2, [x0, #4]            // get y

    adr         x0, table_pic
    bl          fb_drawimage

    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret

render_box:
    push        x30
    pushp       x0, x1
    pushp       x2, x3
    push        x10

    mov         x10, x0

    ldr         w0, [x10]                // get x
    ldr         w1, [x10, #4]            // get y
    ldr         w2, [x10, #8]
    ldr         w3, [x10, #12]
    ldr         w4, =0xff444444
    bl          fb_drawfilledrect

    pop         x10
    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret