SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)

ASRCS = $(wildcard *.s */*.s)
AOBJS = $(ASRCS:.s=.o)

CFLAGS = -Wall -O2 -ffreestanding -nostdinc -nostdlib -nostartfiles

all: clean kernel8.img

%.o: %.s
	aarch64-none-elf-gcc $(CFLAGS) -c $< -o $@

%.o: %.c
	aarch64-none-elf-gcc $(CFLAGS) -c $< -o $@

kernel8.img: $(AOBJS) $(OBJS)
	aarch64-none-elf-ld -nostdlib $(AOBJS) $(OBJS) -T link.ld -o kernel8.elf
	aarch64-none-elf-objcopy -O binary kernel8.elf kernel8.img

clean:
	DEL  "kernel8.elf" "*.o"

run:
	qemu-system-aarch64 -M raspi3b -cpu cortex-a53 -kernel kernel8.img -serial null -serial stdio