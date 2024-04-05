// all graphics related

.global gfx_beginframe
.global gfx_endframe

.include "utils.s"
.include "mbox_constants.s"

.section .data

.align 4
fps:
    .int 0

.align 4
frame_counter:
    .int 0

.align 8
last_frame:
    .long 0

.section .text

gfx_beginframe:
    push        x30

    // swap
    bl          fb_swap

    //mov         w0, #10
    //bl          delay_msec

    pop         x30

    ret

gfx_endframe:
    push        x30

    // render fps
    bl          gfx_draw_fps

    pop         x30

    ret

// ----------------------------------------------------------------------
// Renders the FPS at the top left of screen
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
gfx_draw_fps:
    push        x30
    pushp       x0, x1
    pushp       x2, x3

    getv        x0, last_frame

    ldr         x1, =1000000
    add         x1, x0, x1              // x1 = lastFrame + 1 sec

    getv        w3, frame_counter       // Increment frame count
    add         w3, w3, #1

    bl          get_system_timer        // load time into w0

    cmp         x1, x0
    bgt         1f                      // update fps

    setv        w3, fps

    setv        x1, last_frame
    mov         w3, wzr

1:
    setv        w3, frame_counter

    getv        w0, fps                 // get fps
    bl          num_to_str              // convert to str, store str in w0

    mov         w1, #2
    mov         w2, #5
    ldr         w3, =0xFF00FFFF
    mov         w4, #1
    bl          fb_drawstring

    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret
