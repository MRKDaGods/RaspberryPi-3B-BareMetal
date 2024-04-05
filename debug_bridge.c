// debugger stuff
unsigned long dbg_regs[37];
char cmd[256], dbg_running=0;

void dbg_decodeexc(unsigned long type)
{
}

void dbg_getline()
{
}

unsigned long dbg_getoffs(int i)
{
    return 0;
}

void dbg_main()
{
}

void printf(char *fmt, ...);

void LOLXDD() {
}

void LOLX() {
}

void Error(int where) {
    printf("Error at: %d\n", where);
}

void ASMDBG(int step) {
    printf("Assembly Step [%d]\n", step);
}

void PrintInt(unsigned int value) {
    printf("Value: 0x%x\n", value);
}

void PrintLong(unsigned long value) {
    printf("LValue: 0x%x\n", value);
}

void PrintChar(char c) {
    printf("C: %c\n", c);
}

void PrintBuffer(unsigned int* buf, int size) {
    for (int i = 0; i < size; i++) {
        printf("[%d] Value: 0x%x\n", buf[i]);
    }
}

void printf(char *fmt, ...) {
}