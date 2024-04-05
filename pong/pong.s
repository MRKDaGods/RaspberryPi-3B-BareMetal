// PONG :P

.global update_pong
.global render_pong
.global handle_pong_input
.global mainloop_pong
.global pong_menu

.include "./utils.s"

.section .data

.equ        PLAYER_HEIGHT,          100
.equ        PLAYER_WIDTH,           10
.equ        PLAYER_X_OFFSET,        10
.equ        BALL_WIDTH,             22
.equ        AI_SPEED,               10
.equ        BALL_INIT_VEL_X,        1
.equ        BALL_INIT_VEL_Y,        1
.equ        WIN_SCORE,              5

// ball image
.align 4
ball_sprite:
    .incbin "./assets/ball2.ms"

// ball pos
.align 4
ball_pos:
    .int        100         // x
    .int        100         // y

ball_velocity:
    .int        BALL_INIT_VEL_X           // vx
    .int        BALL_INIT_VEL_Y           // vy

.align 4
player1_pos:
    .int        50

.align 4
player2_pos:
    .int        50

player1_score:
    .int        0

player2_score:
    .int        0

player1_name:
    .string     "PLAYER 1"

player2_name:
    .string     "PLAYER 2"

vs_text:
    .string     "VS"

wins_text:
    .string     "WINS"

.align 4
pong_mode:
    .int        2

// ball size multiplier
ball_size:
    .int        22

has_ai:
    .int        1

.section .text

handle_pong_input:
    pusha64

    bl          i_w
    cbnz        w0, dec_p1

    bl          i_s
    cbnz        w0, inc_p1

    bl          i_e
    cbnz        w0, inc_p2

    bl          i_d
    cbnz        w0, dec_p2

    b           1f

dec_p1:
    getv        w1, player1_pos
    sub         w1, w1, #10
    setv        w1, player1_pos
    b           1f

inc_p1:
    getv        w1, player1_pos
    add         w1, w1, #10
    setv        w1, player1_pos
    b           1f

dec_p2:
    getv        w1, player2_pos
    sub         w1, w1, #10
    setv        w1, player2_pos
    b           1f

inc_p2:
    getv        w1, player2_pos
    add         w1, w1, #10
    setv        w1, player2_pos

1:
    popa64

    ret

.section .data
opt_title:
    .string     "PONG"

opt1:
    .string     "Normal"

opt2:
    .string     "changing speed"

opt3: 
    .string     "changing size"

opt4_off:
    .string     "AI OFF"

opt4_on:
    .string     "AI ON"

.align 4
opt_selected:
    .int        0


.section .text
pong_menu:
    //  render player 1
    pusha64

    // disable double buffering
    mov         w0, wzr
    bl          fb_set_double_buffer

pong_menu_render:
    // clear screen
    ldr         w0, =0xff1f0a15
    bl          fb_clear

    getv        w5, opt_selected

1:
    //title
    adr         x0, opt_title                                // player1 name
    mov         w1, #350                             // label 1 xpos
    mov         w2, #40                             // the y pos
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #3
    bl          fb_drawstring

    // draw box 1
    mov         w0, 250                            // 
    mov         w1, 100                                 // 
    mov         w2, 300                               // width = 300
    mov         w3, 50                             // 
    
    cbz         w5, 1f
    mov         w4, #0xffff0000
    b           2f
1:
    mov         w4, #0xff0000ff
2:
    bl          fb_drawfilledrect

    adr         x0, opt1                                // player1 name
    mov         w1, #350                             // label 1 xpos
    mov         w2, #120                             // the y pos
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #2
    bl          fb_drawstring

    // render box 2
    mov         w0, 250      // p1.x = width - 10 - pwidth
    mov         w1, 175                                 // 
    mov         w2, 300                              // width = 300
    mov         w3, 50                              // height = PLAYER_HEIGHT

    cmp         w5, #1
    beq         1f
    mov         w4, #0xffff0000
    b           2f
1:
    mov         w4, #0xff0000ff
2:                               // color = red    
    bl          fb_drawfilledrect

    adr         x0, opt2                                // player1 name
    mov         w1, #290                             // label 1 xpos
    mov         w2, #195                                // the y pos
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #2
    bl          fb_drawstring

    // render box 3
    mov         w0, 250      // p1.x = width - 10 - pwidth
    mov         w1, 250                                 // 
    mov         w2, 300                              // width = 300
    mov         w3, 50                              // height = PLAYER_HEIGHT
    cmp         w5, #2
    beq         1f
    mov         w4, #0xffff0000
    b           2f
1:
    mov         w4, #0xff0000ff
2:                               // color = red   
    bl          fb_drawfilledrect

    adr         x0, opt3                                // player1 name
    mov         w1, #290                             // label 1 xpos
    mov         w2, #270                                // the y pos
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #2
    bl          fb_drawstring

    // AI
    mov         w0, 250      // p1.x = width - 10 - pwidth
    mov         w1, 325                                 // 
    mov         w2, 300                              // width = 300
    mov         w3, 50                              // height = PLAYER_HEIGHT
    cmp         w5, #3
    beq         1f
    mov         w4, #0xffff0000
    b           2f
1:
    mov         w4, #0xff0000ff
2:                               // color = red   
    bl          fb_drawfilledrect

    // check if ai is on
    getv        w6, has_ai
    cbz         w6, 1f
    adr         x0, opt4_on                                // player1 name
    b           2f

1:
    adr         x0, opt4_off

2:
    mov         w1, #290                             // label 1 xpos
    mov         w2, #345                                // the y pos
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #2
    bl          fb_drawstring

    // get input
input:
    mov         w0, #1000
    bl          delay_msec

    bl          handle_input

    cmp         w0, 'w'
    beq         pong_decrement_option

    cmp         w0, 's'
    beq         pong_increment_option

    cmp         w0, '\n'
    beq         pong_enter

    b           input
    
pong_increment_option:
    add         w5, w5, #1
    cmp         w5, #3
    ble         pong_update

    // set 0
    mov         w5, wzr
    b           pong_update         

pong_decrement_option:
    sub         w5, w5, #1
    cmp         w5, wzr
    bge         pong_update

    // set 0
    mov         w5, #3
    b           pong_update

pong_enter:
    getv        w5, opt_selected
    cmp         w5, #3
    bne         1f

    // toggle ai
    getv        w6, has_ai
    eor         w6, w6, #1
    setv        w6, has_ai

    b           pong_update

1:
    setv        w5, pong_mode

    bl          mainloop_pong
    b           pong_end

pong_update:
    setv        w5, opt_selected
    b           pong_menu_render

pong_end:
    popa64

    ret

mainloop_pong:
    pusha64

    // enable double buffer
    mov         w0, #1
    bl          fb_set_double_buffer

    // reset scores
    setv        wzr, player1_score
    setv        wzr, player2_score
    
running:
    // check input
    bl          handle_pong_input

    bl          update_pong

    // gfx
    bl          gfx_beginframe
    bl          render_pong
    bl          gfx_endframe

    // check score
    // p1
    getv        w1, player1_score
    cmp         w1, WIN_SCORE
    beq         p1_win

    // p2
    getv        w1, player2_score
    cmp         w1, WIN_SCORE
    beq         p2_win

    b           running

p1_win:
    // load p1 name
    adr         x0, player1_name
    b           start_swap

p2_win:
    adr         x0, player2_name

start_swap:
    // save name
    push        x0

    // swap then disable buffer
    bl          fb_swap

    // disable double buffer
    mov         w0, wzr
    bl          fb_set_double_buffer

    // render win screen
render_win:
    // clear screen
    mov         x0, #0xff000000
    bl          fb_clear

    // restore name
    pop         x0

    // display winner at x0
    mov         w1, #250
    mov         w2, #150
    mov         w3, #0xff00ffff
    mov         w4, #4
    bl          fb_drawstring

    adr         x0, wins_text
    mov         w1, #300
    mov         w2, #250
    bl          fb_drawstring

    // delay then return
    mov         w0, #3000
    bl          delay_msec

    popa64

    ret

// ----------------------------------------------------------------------
// Updates game logic
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
update_pong:
    push        x30
    pushp       x0, x1
    pushp       x3, x4
    pushp       x10, x11
    pushp       x12, x13
    pushp       x14, x15
    pushp       x16, x17
    pushp       x18, x19
    push        x20

    vel_x       .req    w10
    vel_y       .req    w11
    pos_x       .req    w12
    pos_y       .req    w13
    xmin        .req    w14
    xmax        .req    w15
    ymin        .req    w16
    ymax        .req    w17
    p1_pos_y    .req    w18
    p2_pos_y    .req    w19
    size        .req    w20

    // get velocity
    getv        vel_x, ball_velocity            // get vx
    getvoff     vel_y, ball_velocity, #4        // get vy

    // get pos
    getv        pos_x, ball_pos                 // get px
    getvoff     pos_y, ball_pos, #4             // get py

    // get player ypos
    getv        p1_pos_y, player1_pos           // get player 1 y
    getv        p2_pos_y, player2_pos           // get player 2 y

    // get screen rect
    mov         xmin, #PLAYER_X_OFFSET + PLAYER_WIDTH
    mov         ymin, wzr                       // ymin = 0

    getv        size, ball_size

    getv        xmax, fb_width                  // xmax = width - offsetx - pwidth
    sub         xmax, xmax, #PLAYER_X_OFFSET + PLAYER_WIDTH
    sub         xmax, xmax, size

    getv        ymax, fb_height                 // ymax = height
    sub         ymax, ymax, size

    // mode thingie
    getv        w4, pong_mode
    cmp         w4, #2
    bne         1f

    // set ball size for sizemode
    // if size == 2
    cmp         size, #22
    bne         1f
    mov         size, #100
    setv        size, ball_size

1:

    // test collision
    // if (x < 0)       // score
    // if (x > xmax)    // score

    cmp         pos_y, ymin                     // y <= 0?
    ble         change_vel_y

    cmp         pos_y, ymax                     // y >= ymax?
    bge         change_vel_y

    b           1f

change_vel_y:
    neg         vel_y, vel_y                    // vely = -vely
    setvoff     vel_y, ball_velocity, #4        // save vel

1:
    //check x
    cmp         pos_x, xmin                     // x <= xmin?
    ble         handle_x_1

    cmp         pos_x, xmax                     // x >= xmax?
    bge         handle_x_2

    b           move_ball

handle_x_1:
    // check if y is within player 1 bounds
    sub         w0, pos_y, p1_pos_y             // w0 = ballY - player1Y
    mov         w1, #0                          // w1 is a flag, did we come from p1?
    b           handle_x


handle_x_2:
    // check if y is within player 2 bounds
    sub         w0, pos_y, p2_pos_y             // w0 = ballY - player2Y
    mov         w1, #1                          // w1 is a flag, did we come from p2?

handle_x:
    // score if w0 < 0 || w0 > height
    cmp         w0, wzr
    ble         score                           // score!

    cmp         w0, #PLAYER_HEIGHT
    bgt         score                           // score!

    // invert babe

    neg         vel_x, vel_x

    //check game mode
    getv        w4, pong_mode
    cmp         w4, wzr
    beq         default_mode

    cmp         w4, #1
    beq         speed_mode

    // size mode then
    b           size_mode

speed_mode:
    tst         vel_x, vel_x
    // speed it up too
    bmi         2f

1:  // inc
    add         vel_x, vel_x, #1
    b           default_mode

2: // dec
    sub         vel_x, vel_x, #1
    b           default_mode

size_mode:
    // dec size
    cmp         size, #5
    ble         default_mode                    // must be > 5

    sub         size, size, #5
    setv        size, ball_size


default_mode:   // do nothing

save_vel:
    setv        vel_x, ball_velocity            // save velocity
    b           move_ball

score:
    // if w1 == 0, that means p2 scored
    cbz         w1, score_p2

    // p1 scored
    getv        w2, player1_score               // get score
    add         w2, w2, #1                      // increment score
    setv        w2, player1_score               // save score
    
    b           reset_ball

score_p2:
    // p2 scored
    getv        w2, player2_score               // get score
    add         w2, w2, #1                      // increment score
    setv        w2, player2_score               // save score

reset_ball:
    // reset ball pos, and vel
    mov         pos_x, #100                     // ball pos
    setv        pos_x, ball_pos                 // x = 100

    mov         pos_y, pos_x
    setvoff     pos_y, ball_pos, #4             // y = 100

    mov         vel_x, #BALL_INIT_VEL_X         // ball vel
    setv        vel_x, ball_velocity            // vx = 5

    mov         vel_y, BALL_INIT_VEL_Y
    setvoff     vel_y, ball_velocity, #4        // vy = 5

    mov         size, #22
    setv        size, ball_size

move_ball:
    // inc pos by vel
    add         pos_x, pos_x, vel_x
    add         pos_y, pos_y, vel_y

    // save pos
    setv        pos_x, ball_pos
    setvoff     pos_y, ball_pos, #4

    getv        w0, has_ai
    cmp         w0, wzr
    beq         2f

simulate_ai:
    // ai simulation
    // check which side the ball is on
    mov         w0, xmax, LSR #1                // xmax / 2
    cmp         pos_x, w0                       // ballx <= w0?
    ble         automate_p1

    // automate p2
    // im p2 lolxd

    //b           2f
    mov         w0, p2_pos_y
    add         w0, w0, #PLAYER_HEIGHT / 2
    cmp         pos_y, w0                       // bally <= p2.y
    ble         p2_up

    // p2 down
    add         p2_pos_y, p2_pos_y, #AI_SPEED   // p2.y++
    add         w4, p2_pos_y, #PLAYER_HEIGHT
    cmp         w4, ymax
    ble         save_p2_pos

    sub         p2_pos_y, ymax, #PLAYER_HEIGHT
    b           save_p2_pos

p2_up:
    sub         p2_pos_y, p2_pos_y, #AI_SPEED   // p2.y--
    cmp         p2_pos_y, ymin
    bge         save_p2_pos

    // clamp
    mov         p2_pos_y, ymin

save_p2_pos:
    setv        p2_pos_y, player2_pos           // save pos
    
    b           2f

automate_p1:
    // automate p1
    mov         w0, p1_pos_y
    add         w0, w0, #PLAYER_HEIGHT / 2
    cmp         pos_y, w0                       // bally <= p1.y
    ble         p1_up

    // p1 down
    add         p1_pos_y, p1_pos_y, #AI_SPEED   // p1.y++
    add         w4, p1_pos_y, #PLAYER_HEIGHT
    cmp         w4, ymax
    ble         save_p1_pos

    sub         p1_pos_y, ymax, #PLAYER_HEIGHT
    b           save_p1_pos

p1_up:
    sub         p1_pos_y, p1_pos_y, #AI_SPEED   // p1.y--
    cmp         p1_pos_y, ymin
    bge         save_p1_pos

    // clamp
    mov         p1_pos_y, ymin

save_p1_pos:
    setv        p1_pos_y, player1_pos           // save pos

2:

    .unreq      vel_x
    .unreq      vel_y
    .unreq      pos_x
    .unreq      pos_y
    .unreq      xmin
    .unreq      xmax
    .unreq      ymin
    .unreq      ymax
    .unreq      p1_pos_y
    .unreq      p2_pos_y
    .unreq      size


    pop         x20
    popp        x18, x19
    popp        x16, x17
    popp        x14, x15
    popp        x12, x13
    popp        x10, x11
    popp        x3, x4
    popp        x0, x1
    pop         x30

    ret

// ----------------------------------------------------------------------
// Renders game gfx
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
render_pong:
    push        x30
    pushp       x0, x1
    pushp       x2, x3
    pushp       x4, x5
    pushp       x10, x11

    width       .req    w10
    halfWidth   .req    w11
    
    //store width
    getv        width, fb_width
    mov         halfWidth, width, LSR #1        // width / 2

    // clear
    ldr         w0, =0xff220000                 // =0xff17110d
    bl          fb_clear

    // render border
    mov         w0, wzr
    mov         w1, wzr
    mov         w2, width
    getv        w3, fb_height

    sub         w2, w2, #1
    sub         w3, w3, #1

    mov         w4, 0xffffffff
    bl          fb_drawrect

    // render mid line
    lsr         w0, width, #1
    sub         w0, w0, #2
    mov         w1, wzr
    mov         w2, #4
    ldr         w4, =0xff666666
    // w3 already has height
    bl          fb_drawfilledrect

    // render vs
    adr         x0, vs_text
    sub         w1, halfWidth, #30                              // x = w/2 - 4
    mov         w2, #10
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #4
    bl          fb_drawstring

    // render names

    // player 1
    adr         x0, player1_name                                // player1 name
    sub         w1, halfWidth, #300                             // label 1 xpos
    mov         w2, #15
    mov         w3, #0xff00ffff                                 // yellow
    mov         w4, #2
    bl          fb_drawstring

    // render score
    // player 1
    getv        w0, player1_score                               // w0 = player1score
    bl          num_to_str                                      // convert to str

    add         w1, w1, #175                                    // x += 175
    mov         w2, #20
    mov         w4, #4
    bl          fb_drawstring

    // player 2
    adr         x0, player2_name                                // player1 name
    add         w1, halfWidth, #175                             // label 1 xpos
    mov         w2, #15
    mov         w4, #2
    bl          fb_drawstring

    // render score
    // player 2
    getv        w0, player2_score                               // w0 = player2score
    bl          num_to_str                                      // convert to str

    sub         w1, w1, #75                                     // x -= 75
    mov         w2, #20
    mov         w4, #4
    bl          fb_drawstring


    getv        w1, ball_pos                                    // w1 = x
    getvoff     w2, ball_pos, #4                                // w2 = y

    getv        w5, ball_size
    cmp         w5, #22
    beq         ball_as_sprite

    // render as filled rect
    mov         w0, w1
    mov         w1, w2
    mov         w2, w5
    mov         w3, w5
    mov         w4, #0xffff0000
    bl          fb_drawfilledrect

    b           1f

ball_as_sprite:
    adr         x0, ball_sprite                                 // ball image at x0
    bl          fb_drawimage


1:
    //  render player 1
    mov         w0, #PLAYER_X_OFFSET                            // p1.x = 0
    getv        w1, player1_pos                                 // p1.y
    mov         w2, #PLAYER_WIDTH                               // width = 30
    mov         w3, #PLAYER_HEIGHT                              // height = PLAYER_HEIGHT
    mov         w4, 0xff0000ff                                  // color = red    
    bl          fb_drawfilledrect

    // render player 2
    sub         w0, width, #PLAYER_X_OFFSET + PLAYER_WIDTH      // p1.x = width - 10 - pwidth
    getv        w1, player2_pos                                 // p1.y
    mov         w2, #PLAYER_WIDTH                               // width = 30
    mov         w3, #PLAYER_HEIGHT                              // height = PLAYER_HEIGHT
    mov         w4, 0xffff0000                                  // color = red    
    bl          fb_drawfilledrect

    .unreq      width
    .unreq      halfWidth

    popp        x10, x11
    popp        x4, x5
    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret
