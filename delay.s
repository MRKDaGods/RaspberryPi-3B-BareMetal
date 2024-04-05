.global delay_msec
.global get_system_timer

.include "utils.s"
.include "offsets.s"

.section .text

// ----------------------------------------------------------------------
// Gets system timer BCM
//
// Arguments:
//
// Returns:
//  x0 - timer
//
// ----------------------------------------------------------------------
get_system_timer:
    pushp       x1, x2
    push        x3

    h           .req    w1
    l           .req    w2

    mov         w3, wzr                 // w3 = 0
    
1:
    ldr         x0, =SYSTMR_HI
    ldr         h, [x0]                 // h = *SYSTMR_HI
    
    ldr         x0, =SYSTMR_LO
    ldr         l, [x0]                 // l = *SYSTMR_LO

    cbnz        w3, 2f                  // w3 != 0
    add         w3, w3, #1              // w3++

    // read again if changed
    ldr         x0, =SYSTMR_HI
    ldr         w3, [x0]                // mightve changed while read
    cmp         w3, h                   // changed?
    bne         1b                      // read again if changed

2:
    orr         x0, x2, x1, LSL #32     // (h << 32) | l

    .unreq      h
    .unreq      l

    pop         x3
    popp        x1, x2

    ret

// ----------------------------------------------------------------------
// Delay for n millisecs
// Clobbers x0
//
// Arguments:
//   w0 - msecs
//
// Returns:
//
// ----------------------------------------------------------------------
delay_msec:
    push        x30
    pushp       x1, x2

    mov         w1, #1000
    mul         w0, w0, w1              // convert to microseconds

    mov         w1, w0                  // copy n*1000 to w1

    bl          get_system_timer        // w0 = get_system_timer()

    cbz         w0, 2f                  // if t == 0, dont do anth
    mov         w2, w0                  // w2 = t

1:
    bl          get_system_timer        // get time now
    sub         w0, w0, w2              // now - t
    cmp         w0, w1                  // now - t < n?
    blt         1b

2:
    popp        x1, x2
    pop         x30

    ret
