// Frame buffer :P

.global fb_init
.global fb_drawstring
.global fb_drawline
.global fb_clear
.global fb_swap
.global fb_addr
.global fb_height
.global fb_width
.global fb_pitch
.global fb_drawfilledrect
.global fb_drawimage
.global fb_drawrect
.global fb_set_double_buffer

.include "mbox_constants.s"
.include "utils.s"
.include "fontdata_constants.s"

.section .data

.equ    FB_RES_X,           800
.equ    FB_RES_Y,           480

.equ    FB_SWAP_BUF_SZ,     8 * 4
.equ    FB_OFFSET,          FB_RES_Y

.align 16
fb_swap_buffer:
    .int    FB_SWAP_BUF_SZ
    .int    MBOX_REQUEST
    .int    0x48009
    .int    8
    .int    8
    .int    0       // x
    .int    0       // y
    .int    MBOX_TAG_LAST

.align 4
fb_init_buffer:
    .int    35 * 4  // buffer size
    .int    MBOX_REQUEST

    // set - physical dimensions
    .int    0x48003
    .int    8
    .int    8
    .int    FB_RES_X    // width
    .int    FB_RES_Y    // height

    // set - virtual dimensions
    .int    0x48004
    .int    8
    .int    8
    .int    FB_RES_X    // vwidth
    .int    FB_RES_Y*2  // vheight

    // set - virtual offset
    .int    0x48009
    .int    8
    .int    8
    .int    0       // x
    .int    0       // y

    // set - bitdepth
    .int    0x48005
    .int    4
    .int    4
    .int    32      // depth

    // set - pixel order
    .int    0x48006
    .int    4
    .int    4
    .int    1       // RGB

    // get - framebuffer
    .int    0x40001
    .int    8
    .int    8
    .int    4096    // ptr
    .int    0       // size

    // get - pitch
    .int    0x40008
    .int    4
    .int    4
    .int    0       // pitch

    // mark last
    .int    MBOX_TAG_LAST

// actual dimensions
fb_width:
    .int    0
fb_height:
    .int    0

fb_pitch:
    .int    0

// address of our frame buffer
fb_addr_base:
    .int    0

fb_addr:
    .int    0

// size of frame buffer = width * height * 4
fb_size:
    .int    0

.section .text
// ----------------------------------------------------------------------
// Initializes the linear frame buffer
// resolution is set to closest to what's provided
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
fb_init:
    // qemu segfaults here if we dont wait? 7nshof

    // save regs
    push        x30                     // push LR (x30)

    pushp       x1, x2
    pushp       x3, x4
    pushp       x5, x6
    pushp       x7, x8
    pushp       x9, x10
    push        x11


    // initialize mbox values
    adr         x10, mbox_buffer       // x10 = &mbox_buffer (base)
    adr         x11, fb_init_buffer    // x11 = &fb_init_buffer (base)

    mov         x2, #0                  // x2 = 0 (offset) 

1:
    // copy init buffer (35 * 4) to mbox_buffer
    // load value at base+x2
    add         x3, x11, x2             // x3 = fb_init_buffer + offset
    ldr         w3, [x3]                // w3 = *x3 - load value at addr

    add         x4, x10, x2             // x4 = mbox_buffer + offset
    str         w3, [x4]                // *x4 = w3

    // increment offset
    add         x2, x2, #4              // x2 += 4

    // are we done? we're done when x2 == 35 * 4
    cmp         x2, #35*4
    bne         1b                      // loop back

    // send mbox message
    // ch = MBOX_CH_PROP (0x8)
    mov         w0, #MBOX_CH_PROP
    bl          mbox_call               // w0 = mbox_call(w0)

    // check if we succeeded, w0 == 1 && w1 == 32 && w2 != 0

    cmp         w0, #1                  // is w0 == true?
    bne         fail                    // fail incase of false

    ldr         w1, [x10, #20 * 4]      // w1 = *(mbox_buffer + 4*20)
    ldr         w2, [x10, #28 * 4]      // w2 = *(mbox_buffer + 4*28)
    
    cmp         w1, #32                 // w1 == 32, w1 is not used anywhere else
    bne         fail                    // fail if w1 != 32

    cmp         w2, #0                  // w2 == 0
    beq         fail                    // fail if w1 == 0

    // conditions met
    // convert gpu addr to physical addr
    and         w2, w2, #0x3FFFFFFF     // w2 &= 0x3FFFFFFF
    str         w2, [x10, #28 * 4]      // *(mbox_buffer + 4*28) = w2

    adr         x1, fb_addr_base        // x1 = &fb_addr_base
    ldr         w2, [x10, #28 * 4]      // w2 = *(mbox_buffer + 4*28)
    str         w2, [x1]                // fb_addr_base = w2

    // set width
    ldr         w2, [x10, #5 * 4]       // w2 = (*mbox_buffer + 4*5) aka width
    adr         x3, fb_width
    str         w2, [x3]                // fb_width = w2

    // calc fb size
    mov         w7, w2, LSL #2          // w7 = width * 4

    // set height
    ldr         w2, [x10, #6 * 4]       // w2 = (*mbox_buffer + 4*6) aka height
    adr         x3, fb_height
    str         w2, [x3]                // fb_height = w2

    mul         w7, w7, w2              // w7 *= height
    adr         x9, fb_size             // x9 = &fb_size
    str         w7, [x9]                // fb_size = w7

    // enable double buffer by default
    getv        w8, fb_addr_base
    adr         x1, fb_addr
    add         w2, w8, w7              // addr of sec buffer
    str         w2, [x1]                // fb_addr = w2

    // set pitch
    ldr         w2, [x10, #33 * 4]      // w2 = (*mbox_buffer + 4*33) aka pitch
    adr         x3, fb_pitch
    str         w2, [x3]                // fb_pitch = w2

    b           2f                      // return

fail:
    bl Error

2:

    // restore regs
    pop         x11
    popp        x9, x10
    popp        x7, x8
    popp        x5, x6
    popp        x3, x4
    popp        x1, x2
    pop         x30                     // pop LR

    ret

// ----------------------------------------------------------------------
// Enables/Disables the framebuffer
//
// Arguments:
//  w0 - 1 if enabled, 0 if not
//
// Returns:
//
// ----------------------------------------------------------------------
fb_set_double_buffer:
    push        x30
    pushp       x0, x1
    
    getv        w1, fb_addr_base        // get addr base

    cbz         w0, 2f                  // if w0 == 0, disable

1:  // enable
    getv        w0, fb_size             // fb size
    add         w0, w0, w1              // double buffer addr
    setv        w0, fb_addr             // fb_addr = fb_addr_base + fb_size

    b           3f

2:  // disable
    setv        w1, fb_addr             // fb_addr = fb_addr_base (direct)

3:  // end
    popp        x0, x1
    pop         x30

    ret


// ----------------------------------------------------------------------
// Swaps the framebuffer
//
// Arguments:
//
// Returns:
//
// ----------------------------------------------------------------------
fb_swap:
    pushp       x0, x1
    push        x2

    getv        w0, fb_addr
    getv        w1, fb_addr_base

    // if fb_addr == fb_addr_base, double buffer is disabled
    cmp         w0, w1
    beq         2f

    // Calculate the number of iterations needed
    mov         x2, #FB_RES_X * FB_RES_Y * 4 / 64  // 1536000 / 64

1:
    // Load 64 bytes from the source address into v0-v3
    ld4         {v0.4s, v1.4s, v2.4s, v3.4s}, [x0], #64

    // Store 64 bytes from v0-v3 to the destination address
    st4         {v0.4s, v1.4s, v2.4s, v3.4s}, [x1], #64

    // Decrement the counter and loop if not zero
    subs        x2, x2, #1
    bne         1b

2:
    pop         x2
    popp        x0, x1

    ret

// ----------------------------------------------------------------------
// Draws a pixel
//
// Arguments:
//   w0 - x
//   w1 - y
//   w2 - color
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawpixel:
    push        x3
    pushp       x5, x6
    pushp       x10, x11

    // test alpha
    // 0xAABBGGRR

    //check if 0
    tst         w2, w2
    beq         1f

    ldr         w5, =0xFF000000     // alpha
    cmp         w2, w5
    blt         1f

    // check x >= 0 x <= width
    //adr         x5, fb_width
    ldr         w5, =FB_RES_X

    cmp         w0, wzr             // x < 0
    blt         1f

    cmp         w0, w5              // x > width
    bgt         1f

    // check y >= 0 y <= height
    //adr         x6, fb_height
    ldr         w6, =FB_RES_Y

    cmp         w1, wzr             // y < 0
    blt         1f

    cmp         w1, w6              // y1 > height
    bgt         1f

    adr         x10, fb_addr
    ldr         w10, [x10]

    adr         x11, fb_pitch
    ldr         w11, [x11]          // w11 = fb_pitch
    
    // y * pitch
    // offset -> w3
    mul         w3, w1, w11         // offset = y * pitch
    add         w3, w3, w0, LSL #2  // offset += x * 4

    // compute target addr
    add         x6, x10, x3         // targetAddr = fb_addr + offset
    str         w2, [x6]            // store pixel :P

1:
    popp        x10, x11
    popp        x5, x6
    pop         x3

    ret


// ----------------------------------------------------------------------
// Draws a line
//
// Arguments:
//   w0 - x1
//   w1 - y1
//   w2 - x2
//   w3 - y2
//   w4 - color
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawline:
    push        x30
    push        x5
    push        x6
    push        x7
    push        x8
    push        x9
    push        x10
    push        x11

    // constraints fine, draw

    dx          .req    w5
    dy          .req    w6
    err         .req    w7
    stepx       .req    w8
    stepy       .req    w9
    i           .req    w10
    j           .req    w11

    mov         i, w0               // i = x1
    mov         j, w1               // j = y1

    sub         dx, w2, w0          // dx = x2 - x1
    sub         dy, w3, w1          // dy = y2 - y1
    sub         err, dy, dx         // error = dy - dx

    // stepx = dx >= 0 ? 1 : -1
    cmp         dx, wzr
    blt         1f                  // dx < 0

    // dx >= 0
    mov         stepx, #1
    b           2f

1:  // dx < 0
    mov         stepx, #-1

2:
    // stepy = dy >= 0 ? 1 : -1
    cmp         dy, wzr
    blt         3f                  // dy < 0

    // dy >= 0
    mov         stepy, #1
    b           4f

3:  // dy < 0
    mov         stepy, #-1

4:
    cmp         dx, dy
    blt         8f

    // dx >= dy
5:
    cmp         i, w2               // i, x2
    bge         7f                  // loop if i < x2

    // call draw pixel
    // store regs
    push        x0
    push        x1
    push        x2

    mov         w0, i               // x = i
    mov         w1, j               // y = j
    mov         w2, w4              // color
    bl          fb_drawpixel        // drawpixel(i, j, color)

    // restore regs
    pop         x2
    pop         x1
    pop         x0

    cmp         err, wzr            // error, 0
    blt         6f                  // error < 0

    // error >= 0
    add         j, j, stepy         // j += stepy
    sub         err, err, dx        // error -= dx

6:
    add         err, err, dy        // error += dy

    add         i, i, stepx         // i += stepx
    b           5b
7: 

8:  // dy > dx
    cmp         j, w3               // j, y2
    bge         10f                 // loop if j < y2

    // call draw pixel
    // store regs
    push        x0
    push        x1
    push        x2

    mov         w0, i               // x = i
    mov         w1, j               // y = j
    mov         w2, w4              // color
    bl          fb_drawpixel        // drawpixel(i, j, color)

    // restore regs
    pop         x2
    pop         x1
    pop         x0

    cmp         err, wzr            // error, 0
    blt         9f                  // error < 0

    // error >= 0
    cbz         dx, decerr          // dx == 0?
    add         i, i, stepx         // i += stepx
    
decerr:
    sub         err, err, dy        // error -= dy

9:
    add         err, err, dx        // error += dx

    add         j, j, stepy         // y += stepy
    b           8b

10:
    .unreq      dx
    .unreq      dy
    .unreq      err
    .unreq      stepx
    .unreq      stepy
    .unreq      i
    .unreq      j

    // pop regs
    pop         x11
    pop         x10
    pop         x9
    pop         x8
    pop         x7
    pop         x6
    pop         x5
    pop         x30
    
    ret

// ----------------------------------------------------------------------
// Draws a rectangle
//
// Arguments:
//   w0 - x1
//   w1 - y1
//   w2 - width
//   w3 - height
//   w4 - color
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawrect:
    push        x30
    push        x10
    push        x11
    push        x12
    push        x13
    push        x14
    push        x15
    push        x16

    // push x0-x3 to prevent clobber
    push        x0
    push        x1
    push        x2
    push        x3

    x           .req    w10
    y           .req    w11
    width       .req    w12
    height      .req    w13
    right       .req    w15
    bottom      .req    w16

    mov         x, w0
    mov         y, w1
    mov         width, w2
    mov         height, w3

    // tl (x, y)
    // tr (x+w, y)
    // bl (x, y+h)
    // br (x+w, y+h)

    add         right, x, width         // right = x+w
    add         bottom, y, height       // bottom = y+h

    // tl -> tr
    mov         w0, x
    mov         w1, y
    mov         w2, right
    mov         w3, y
    bl          fb_drawline

    // bl -> br
    mov         w0, x
    mov         w1, bottom
    mov         w2, right
    mov         w3, bottom
    bl          fb_drawline

    // tl -> bl
    mov         w0, x
    mov         w1, y
    mov         w2, x
    mov         w3, bottom
    bl          fb_drawline

    // tr -> br
    mov         w0, right
    mov         w1, y
    mov         w2, right
    mov         w3, bottom
    bl          fb_drawline

    .unreq      x
    .unreq      y
    .unreq      width
    .unreq      height
    .unreq      right
    .unreq      bottom

    // restore clobbered regs
    pop         x3
    pop         x2
    pop         x1
    pop         x0


    pop         x16
    pop         x15
    pop         x14
    pop         x13
    pop         x12
    pop         x11
    pop         x10
    pop         x30

    ret

// ----------------------------------------------------------------------
// Clears the screen with a certain color
// It clobbers q0-q7
//
// Arguments:
//   w0 - color
//
// Returns:
//
// ----------------------------------------------------------------------
fb_clear:
    pushp       x5, x6
    pushp       x10, x11
    pushpq      q0, q1
    pushpq      q2, q3
    pushpq      q4, q5
    pushpq      q6, q7

    getv        w10, fb_addr            // w10 = fb_addr    
    getv        w5, fb_size             // w5 = fb_size

    // we're using 128 bytes
    sub         w5, w5, #128            // w5 -= 128

    // process 16 bytes at once? 4 pixels
    // NOTE:
    //      USE 1 value of q for pixels divisible by 16
    //          2 values of q for .................. 32
    //          4 .................................. 64
    //          8 .................................. 128
    // fill q0 with w0|w0|w0|w0
    dup         v0.4s, w0               // q0 = w0|w0|w0|w0

    // we'll use 128 bytes
    mov         v1.16b, v0.16b          // q1
    mov         v2.16b, v0.16b          // q2
    mov         v3.16b, v0.16b
    mov         v4.16b, v0.16b
    mov         v5.16b, v0.16b
    mov         v6.16b, v0.16b
    mov         v7.16b, v0.16b          // ..q7

1:
    add         x6, x5, x10             // target = fb_addr + offset

    // copy 128 bytes at once (32 pixels)
    st4         {v0.4s, v1.4s, v2.4s, v3.4s}, [x6], #64 
    st4         {v4.4s, v5.4s, v6.4s, v7.4s}, [x6]

    subs        w5, w5, #128            // w5 -= 128
    bge         1b

    poppq       q6, q7
    poppq       q4, q5
    poppq       q2, q3
    poppq       q0, q1
    popp        x10, x11
    popp        x5, x6
    
    ret

// ----------------------------------------------------------------------
// Draws a character
//
// Arguments:
//   w0 - character
//   w1 - x
//   w2 - y
//   w3 - color
//   w4 - scale
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawchar:
    push        x30
    push        x5
    push        x6
    push        x7
    push        x10
    push        x11
    push        x12
    push        x13
    push        x14
    push        x15

    glyph       .req    x10
    i           .req    w11
    j           .req    w12
    mask        .req    w13
    glyphVal    .req    w14
    x           .req    w1
    y           .req    w2
    maxCharH    .req    w15

    // load font base addr
    adr         x5, fontdata            // x5 = &fontdata

    mov         w6, wzr                 // w6 is our offset
    cmp         w0, #FONT_GLYPH_COUNT   // valid character?
    bge         1f

    // ch < FONT_GLYPH_COUNT               char is valid
    mov         w6, w0                  // move our char to offset (valid)
    mov         w7, #FONT_GLYPH_SZ
    mul         w6, w6, w7              // offset *= FONT_GLYPH_SZ

1:
    mov         glyph, x5               // glyph = &fontData
    add         glyph, glyph, x6        // glyph += offset

    // maxCharH = fontHeight * scale
    mov         maxCharH, w4            // maxCharH = scale
    mov         w7, #FONT_HEIGHT        // w7 = fontHeight
    mul         maxCharH, maxCharH, w7  // maxCharH *= fontHeight

    // start iterating x*y
    // 1 <= i <= height*scale
    // 0 <  j <  width*scale
    
    mov         i, maxCharH             // i = maxCharH

2:  // i loop
    ldrb        glyphVal, [glyph]       // glyphVal = *glyph

    // j = fontWidth * scale - 1
    mov         j, w4                   // j = scale
    mov         w7, #FONT_WIDTH         // w7 = fontWidth
    mul         j, j, w7                // j *= fontWidth
    sub         j, j, #1                // j--

3:  // j loop
    // calc mask
    // mask = 1 << (j/scale)
    //LOGSTEP 8
    udiv        w7, j, w4               // w7 = j/scale
    mov         mask, #1                // mask = 1
    lsl         mask, mask, w7          // mask = 1 << w7

    tst         glyphVal, mask          // *glyph & mask
    beq         4f                      // dont draw pixel if it's outside of mask


    //LOGSTEP 9
    // clobber w0, we dont need it anymore
    // save x and y
    push        x1
    push        x2

    add         x, x, j                 // x += j
    mov         w0, x                   // w0 = x

    // invert i, letters are drawn inverted lmao
    sub         w7, maxCharH, i         // w7 = maxCharH - i
    add         y, y, w7                // y += inverted_i (w7)
    mov         w1, y                   // w1 = y

    mov         w2, w3                  // w2 = color

    bl          fb_drawpixel            // drawpixel(x+j, y+i, color)

    // restore x and y
    pop         x2
    pop         x1

    //LOGSTEP 10

4:
    //LOGSTEP 11
    sub         j, j, #1                // j--
    cmp         j, wzr
    bge         3b                      // loop if j >= 0

    udiv        w7, i, w4               // w7 = i / scale
    msub        w7, w7, w4, i           // w7 = i - w7 * scale
    cbnz        w7, 5f                  // do nothing if != 0
    add         glyph, glyph, #FONT_BYTES_PER_LINE

5:
    subs        i, i, #1                // i--
    bne         2b                      // loop if i > 0

    .unreq      glyph
    .unreq      i
    .unreq      j
    .unreq      mask
    .unreq      glyphVal
    .unreq      x
    .unreq      y
    .unreq      maxCharH

    pop         x15
    pop         x14
    pop         x13
    pop         x12
    pop         x11
    pop         x10
    pop         x7
    pop         x6
    pop         x5
    pop         x30

    ret

// ----------------------------------------------------------------------
// Draws a string
//
// Arguments:
//   x0 - string address
//   w1 - x
//   w2 - y
//   w3 - color
//   w4 - scale
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawstring:
    push        x30
    push        x5
    push        x6
    push        x7
    push        x8
    push        x9
    push        x10

    strAddr     .req    x10
    ch          .req    w5
    charW       .req    w6
    charH       .req    w7
    x           .req    w8
    y           .req    w9

    // lets not clobber x0, move address to x10
    mov         strAddr, x0             // strAddr = x0

    mov         x, w1                   // x = w1 (initial x)
    mov         y, w2                   // y = w2 (initial y)

    // calculate dims
    mov         charW, #FONT_WIDTH      // charW = FONT_WIDTH
    mul         charW, charW, w4        // charW *= scale

    mov         charH, #FONT_HEIGHT     // charH = FONT_HEIGHT
    mul         charH, charH, w4        // charH *= scale

1:
    ldrb        ch, [strAddr]           // ch = *strAddr
    and         ch, ch, #0xFF

    cbz         ch, 5f                  // ch == '\x0'

    cmp         ch, #0xD                // is it a carriage return?
    bne         2f

    // reset x
    mov         x, w1                   // x = initial x
    b           4f

2:
    cmp         ch, '\n'                // new line?
    bne         3f

    mov         x, w1                   // x = initial x
    add         y, y, charH             // y += charH
    b           4f

3:
    // call drawchar

    // save regs
    push        x0
    push        x1
    push        x2

    mov         w0, ch                  // w0 = ch
    mov         w1, x

    mov         w2, y

    // w3 and w4 remain unchanged
    bl          fb_drawchar             // drawchar(ch, x, y, color, scale)

    // restore regs
    pop         x2
    pop         x1
    pop         x0

    // increment x
    add         x, x, charW             // x += charW

4:
    add         strAddr, strAddr, #1    // increment string address
    b           1b

5:    
    .unreq      strAddr
    .unreq      ch
    .unreq      charW
    .unreq      charH
    .unreq      x
    .unreq      y

    pop         x10
    pop         x9
    pop         x8
    pop         x7
    pop         x6
    pop         x5
    pop         x30

    ret

// ----------------------------------------------------------------------
// Draws an image
//
// Arguments:
//   x0 - image address
//   w1 - x
//   w2 - y
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawimage:
    push        x30
    push        x3
    push        x4
    push        x5
    push        x6
    push        x7
    push        x8
    push        x9
    push        x10

    // we clobber w0, w1, w2 below, so save them
    push        x0
    push        x1
    push        x2

    img         .req    x0
    width       .req    w3
    height      .req    w4
    i           .req    w5
    j           .req    w6
    curPixel    .req    w7
    curAddr     .req    x8
    x           .req    w9
    y           .req    w10

    mov         x, w1                   // save initial x
    mov         y, w2                   // save initial y

    mov         curAddr, img            // curAddr = imgAddr

    ldr         width, [curAddr], #4    // read width, then increment
    ldr         height, [curAddr], #4   // read height, then increment

    mov         i, wzr                  // i = 0

1:  // x loop, for (int i = 0; i < width; i++)
    cmp         i, width
    bge         end                     // i < width

    mov         j, wzr                  // j = 0

2:  // y loop, for (int j = 0; j < height; j++)
    cmp         j, height
    bge         3f                      // j < height

    // curPixel is 0xAABBGGRR aka our color format
    ldr         curPixel, [curAddr], #4 // read current pixel

    // call draw pixel (x, y, col)
    mov         w0, x                   // w0 = x
    add         w0, w0, i               // w0 += i

    mov         w1, y                   // w1 = y
    add         w1, w1, j               // w1 += y

    mov         w2, curPixel            // col = curPixel
    bl          fb_drawpixel            // drawpixel(x, y, pixel)

    add         j, j, #1                // j++
    b           2b

3:
    add         i, i, #1                // i++
    b           1b

end:
    .unreq      img
    .unreq      width
    .unreq      height
    .unreq      i
    .unreq      j
    .unreq      curPixel
    .unreq      curAddr
    .unreq      x
    .unreq      y


    pop         x2
    pop         x1
    pop         x0

    pop         x10
    pop         x9
    pop         x8
    pop         x7
    pop         x6
    pop         x5
    pop         x4
    pop         x3

    pop         x30
    ret

// ----------------------------------------------------------------------
// Draws a filled rectangle
//
// Arguments:
//   w0 - x1
//   w1 - y1
//   w2 - width
//   w3 - height
//   w4 - color
//
// Returns:
//
// ----------------------------------------------------------------------
fb_drawfilledrect:
    // push x0-x3 to prevent clobber

    push        x30
    pushp       x0, x1
    pushp       x2, x3
    pushp       x10, x11
    pushp       x12, x13
    pushp       x14, x15
    push        x16

    x           .req    w0
    y           .req    w11
    width       .req    w12
    height      .req    w13
    right       .req    w15
    bottom      .req    w16

    //mov         x, w0
    mov         y, w1
    mov         width, w2
    mov         height, w3

    // tl (x, y)
    // tr (x+w, y)
    // bl (x, y+h)
    // br (x+w, y+h)

    add         right, x, width         // right = x+w
    add         bottom, y, height       // bottom = y+h

    mov         w2, w4

1:  
    cmp         x, right
    bgt         4f

    mov         w1, y                   // y = initial
2:
    cmp         w1, bottom
    bgt         3f

    bl          fb_drawpixel

    add         w1, w1, #1                // y++
    b           2b
    
3:
    add         x, x, #1
    b           1b

4:
    .unreq      x
    .unreq      y
    .unreq      width
    .unreq      height
    .unreq      right
    .unreq      bottom

    // restore clobbered regs

    pop         x16
    popp        x14, x15
    popp        x12, x13
    popp        x10, x11
    popp        x2, x3
    popp        x0, x1
    pop         x30

    ret
