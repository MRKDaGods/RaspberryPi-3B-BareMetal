// Holds all offsets

// Base physical address
.equ    MMIO_BASE,           0x3F000000

// Mailbox offsets
.equ    MBOX_BASE,              MMIO_BASE + 0x0000B880
.equ    MBOX_READ,              MBOX_BASE + 0x0
.equ    MBOX_POLL,              MBOX_BASE + 0x10
.equ    MBOX_SENDER,            MBOX_BASE + 0x14
.equ    MBOX_STATUS,            MBOX_BASE + 0x18
.equ    MBOX_CONFIG,            MBOX_BASE + 0x1C
.equ    MBOX_WRITE,             MBOX_BASE + 0x20

// Sys timer
.equ    SYSTMR_LO,              MMIO_BASE + 0x00003004
.equ    SYSTMR_HI,              MMIO_BASE + 0x00003008
