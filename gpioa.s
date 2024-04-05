.global gpio_setup
.global gpio_input
.global gpio_init

.include "utils.s"

.section .text

gpio_setup:
        pusha64

        sub     sp, sp, #32
        str     w0, [sp, 12]
        str     w1, [sp, 8]
        mov     x0, 1059061760
        str     x0, [sp, 24]
        ldr     w0, [sp, 12]
        cmp     w0, 54
        bls     2f
        mov     w0, 0
        b       3f
2:
        ldr     w0, [sp, 8]
        cmp     w0, 7
        bls     4f
        mov     w0, 0
        b       3f
4:
        ldr     w2, [sp, 12]
        mov     w0, 52429
        movk    w0, 0xcccc, lsl 16
        umull   x0, w2, w0
        lsr     x0, x0, 32
        lsr     w1, w0, 3
        mov     w0, w1
        lsl     w0, w0, 2
        add     w0, w0, w1
        lsl     w0, w0, 1
        sub     w1, w2, w0
        mov     w0, w1
        lsl     w0, w0, 1
        add     w0, w0, w1
        str     w0, [sp, 20]
        ldr     w1, [sp, 12]
        mov     w0, 52429
        movk    w0, 0xcccc, lsl 16
        umull   x0, w1, w0
        lsr     x0, x0, 32
        lsr     w0, w0, 3
        uxtw    x0, w0
        lsl     x0, x0, 2
        ldr     x1, [sp, 24]
        add     x0, x1, x0
        ldr     w0, [x0]
        str     w0, [sp, 16]
        ldr     w0, [sp, 20]
        mov     w1, 7
        lsl     w0, w1, w0
        mvn     w0, w0
        mov     w1, w0
        ldr     w0, [sp, 16]
        and     w0, w0, w1
        str     w0, [sp, 16]
        ldr     w0, [sp, 20]
        ldr     w1, [sp, 8]
        lsl     w0, w1, w0
        ldr     w1, [sp, 16]
        orr     w0, w1, w0
        str     w0, [sp, 16]
        ldr     w1, [sp, 12]
        mov     w0, 52429
        movk    w0, 0xcccc, lsl 16
        umull   x0, w1, w0
        lsr     x0, x0, 32
        lsr     w0, w0, 3
        uxtw    x0, w0
        lsl     x0, x0, 2
        ldr     x1, [sp, 24]
        add     x0, x1, x0
        ldr     w1, [sp, 16]
        str     w1, [x0]
        mov     w0, 1
3:
        add     sp, sp, 32

        popa64

        ret

gpio_input:
        sub     sp, sp, #32
        str     w0, [sp, 12]
        mov     x0, 52
        movk    x0, 0x3f20, lsl 16
        str     x0, [sp, 24]
        ldr     w0, [sp, 12]
        cmp     w0, 53
        bhi     2f
        ldr     w0, [sp, 12]
        and     w0, w0, 31
        mov     w1, 1
        lsl     w0, w1, w0
        str     w0, [sp, 20]
        ldr     w0, [sp, 12]
        lsr     w0, w0, 5
        uxtw    x0, w0
        lsl     x0, x0, 2
        ldr     x1, [sp, 24]
        add     x0, x1, x0
        ldr     w0, [x0]
        str     w0, [sp, 16]
        ldr     w1, [sp, 16]
        ldr     w0, [sp, 20]
        and     w0, w1, w0
        cmp     w0, 0
        beq     2f
        mov     w0, 1
        b       3f
2:
        mov     w0, 0
3:
        add     sp, sp, 32
        ret

gpio_init:
        stp     x29, x30, [sp, -16]!
        mov     x29, sp
        mov     w1, 0
        mov     w0, 26
        bl      gpio_setup
        mov     w1, 0
        mov     w0, 16
        bl      gpio_setup
        mov     w1, 0
        mov     w0, 27
        bl      gpio_setup
        mov     w1, 0
        mov     w0, 22
        bl      gpio_setup
        nop
        ldp     x29, x30, [sp], 16
        ret