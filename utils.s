// General utils

// ----------------------------------------------------------------------
// Pushes a 64 bit register to the stack
// ----------------------------------------------------------------------
.macro push     reg
    str         \reg, [sp, #-16]!
.endm

.macro pushp    reg, reg2
    stp         \reg, \reg2, [sp, #-16]!
.endm

// ----------------------------------------------------------------------
// Pushes 2 128 bit registers to the stack
// ----------------------------------------------------------------------
.macro pushpq   reg, reg2
    stp         \reg, \reg2, [sp, #-32]!
.endm

// ----------------------------------------------------------------------
// Pushes all 64 bit registers to stack
// ----------------------------------------------------------------------
.macro pusha64
    pushp       x0, x1
    pushp       x2, x3
    pushp       x4, x5
    pushp       x6, x7
    pushp       x8, x9
    pushp       x10, x11
    pushp       x12, x13
    pushp       x14, x15
    pushp       x16, x17
    pushp       x18, x19
    pushp       x20, x21
    pushp       x22, x23
    pushp       x24, x25
    pushp       x26, x27
    pushp       x28, x29
    push        x30
.endm

// ----------------------------------------------------------------------
// Pops a 64 bit register from the stack
// ----------------------------------------------------------------------
.macro pop      reg
    ldr         \reg, [sp], #16
.endm

.macro popp     reg, reg2
    ldp         \reg, \reg2, [sp], #16
.endm

// ----------------------------------------------------------------------
// Pops 2 128 bit registers from the stack
// ----------------------------------------------------------------------
.macro poppq    reg, reg2
    ldp         \reg, \reg2, [sp], #32
.endm

// ----------------------------------------------------------------------
// Pops all 64 bit registers from stack
// ----------------------------------------------------------------------
.macro popa64
    pop        x30
    popp       x28, x29
    popp       x26, x27
    popp       x24, x25
    popp       x22, x23
    popp       x20, x21
    popp       x18, x19
    popp       x16, x17
    popp       x14, x15
    popp       x12, x13
    popp       x10, x11
    popp       x8, x9
    popp       x6, x7
    popp       x4, x5
    popp       x2, x3
    popp       x0, x1
.endm

// ----------------------------------------------------------------------
// Gets a variable's value
// Clobbers x24
// ----------------------------------------------------------------------
.macro getv     target, variable
    adr         x24, \variable
    ldr         \target, [x24]
.endm

.macro getvoff  target, variable, offset
    adr         x24, \variable
    ldr         \target, [x24, \offset]
.endm

// ----------------------------------------------------------------------
// Sets a variable's value
// Clobbers x24
// ----------------------------------------------------------------------
.macro setv     src, variable
    adr         x24, \variable
    str         \src, [x24]
.endm

.macro setvoff  target, variable, offset
    adr         x24, \variable
    str         \target, [x24, \offset]
.endm



// Debug utils

// ----------------------------------------------------------------------
// Prints a long to console
// ----------------------------------------------------------------------
.macro LOGLONG  reg
    pusha64

    mov     x0, \reg
    bl      PrintLong

    popa64
.endm

// ----------------------------------------------------------------------
// Prints "ASMSTEP x"
// Ex:  LOGSTEP 1
//      mov w1, #23
//      LOGSTEP 2
//      ....
// ----------------------------------------------------------------------
.macro LOGSTEP  step
    pusha64

    mov     w0, \step
    bl      ASMDBG

    popa64
.endm

// ----------------------------------------------------------------------
// Prints a char to console
// ----------------------------------------------------------------------
.macro LOGCHAR  char
    pusha64

    mov     w0, \char
    bl      PrintChar

    popa64
.endm
