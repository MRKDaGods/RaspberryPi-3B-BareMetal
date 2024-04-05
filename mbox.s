.global mbox_call
.global mbox_buffer

.include "offsets.s"
.include "utils.s"
.include "mbox_constants.s"

.section .data

.align 16
mbox_buffer: //36 * unsigned int (word), initialized with 0
    .rept   MBOX_BUFFER_SIZE
        .word   0
    .endr

.section .text
// ----------------------------------------------------------------------
// Calls mbox for a certain channel using the mbox_buffer
//
// Arguments:
//   w0 - channel
//
// Returns:
//   w0 - result (0 = failure, 1 = success)
// ----------------------------------------------------------------------
mbox_call:
    push        x30
    push        x25


    push        x11
    push        x12
    push        x13
    push        x21

    // load mbox_buffer address into x1
    adr         x11, mbox_buffer

    // 0xFFFFFFFFFFFFFFF0
    // change lowest nibble of x1 with channel's lower nibble
    and         x11, x11, #0xFFFFFFFFFFFFFFF0

    // keep lower nibble of channel
    and         w0, w0, #0xF

    // or with lower nibble of channel
    orr         w11, w11, w0


1:
    nop                             // delay

    // read mailbox status
    ldr         x12, =MBOX_STATUS    // read address of mbox_status
    ldr         w12, [x12]            // w2 = *MBOX_STATUS - load status into x2

    mov         w13, #MBOX_FULL
    tst         x12, x13

    // loop if full
    bne         1b

    // write addr of message to mailbox channel
    // our message is in w1 (28 bits + 4bits)
    ldr         x12, =MBOX_WRITE
    str         w11, [x12]            // *MBOX_WRITE = w1

2:
    nop
    // read status again, check for empty
    ldr         x12, =MBOX_STATUS    // read address of mbox_status
    ldr         w12, [x12]            // load status into x2

    mov         w13, #MBOX_EMPTY
    tst         w12, w13          // status & MBOX_EMPTY

    // loop if empty
    bne         2b

3:

    // check if our message was read, if so return the response
    ldr         x12, =MBOX_READ
    ldr         w12, [x12]            // w2 = *MBOX_READ

    cmp         w11, w12              // ourMessageAddress == *MBOX_READ

    // if not read, loop again..
    bne         2b

    // result = mbox[1] == MBOX_RESPONSE
    adr         x21, mbox_buffer
    ldr         w21, [x21, #4]        // w2 = mbox_buffer[1]

    mov         w13, #MBOX_RESPONSE

    mov         w11, #1              // set w1 to true
    cmp         w21, w13             // mbox_buffer[1] == MBOX_RESPONSE

    beq         4f                   // jump if true

    mov         w11, #0              // set w1 to false

4:
    // return w0
    mov         w0, w11

    // restore regs
    pop         x21
    pop         x13
    pop         x12
    pop         x11
    pop         x25
    pop         x30

    // return back to caller
    ret
