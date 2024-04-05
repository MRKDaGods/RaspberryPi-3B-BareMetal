// system core related funcs

.global num_to_str
.global i_w
.global i_s
.global i_e
.global i_d
.global handle_input

.include "utils.s"

.section .data
str_buf:
    .skip   12  // Buffer for up to 10 digits plus null terminator

.section .text

// ----------------------------------------------------------------------
// Converts number to string
//
// Arguments:
//  x0 - number
//
// Returns:
//  x0 - address of output string
//
// ----------------------------------------------------------------------
num_to_str:
    pushp       x1, x2
    pushp       x3, x4

    mov         x1, 10
    mov         x2, str_buf + 11        // Start at the end of the buffer
    strb        wzr, [x2]               // Null terminator

1:  
    udiv        x3, x0, x1              // x3 = x0 / 10
    msub        x4, x3, x1, x0          // x4 = x0 % 10
    sub         x2, x2, 1               // Move to the next position in the buffer
    add         x4, x4, '0'             // Convert digit to character
    strb        w4, [x2]                // Store character in buffer
    mov         x0, x3                  // x0 = x0 / 10
    cbnz        x0, 1b                  // Repeat if x0 != 0

    mov         x0, x2                  // addr of str begin

    popp        x3, x4
    popp        x1, x2

    ret

i_w:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w0, 26
        bl      gpio_input
        ldp     x29, x30, [sp], 16
        ret
i_s:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w0, 16
        bl      gpio_input
        ldp     x29, x30, [sp], 16
        ret
i_e:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w0, 27
        bl      gpio_input
        ldp     x29, x30, [sp], 16
        ret
i_d:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w0, 22
        bl      gpio_input
        ldp     x29, x30, [sp], 16
        ret

handle_input:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w0, 26
        bl      gpio_input
        cmp     w0, 0
        beq     .L10
        mov     w0, 119
        b       .L11
.L10:
        mov     w0, 16
        bl      gpio_input
        cmp     w0, 0
        beq     .L12
        mov     w0, 115
        b       .L11
.L12:
        mov     w0, 27
        bl      gpio_input
        cmp     w0, 0
        beq     .L13
        mov     w0, 10
        b       .L11
.L13:
        mov     w0, 22
        bl      gpio_input
        cmp     w0, 0
        beq     .L14
        mov     w0, 100
        b       .L11
.L14:
        mov     w0, 0
.L11:
        ldp     x29, x30, [sp], 16
        ret
