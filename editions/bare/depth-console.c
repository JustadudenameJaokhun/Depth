#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define COLOR_RED "\033[38;2;230;25;25m"
#define COLOR_DARK "\033[38;2;140;20;20m"
#define COLOR_DIM "\033[38;2;100;100;100m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RESET "\033[0m"

static void banner(void) {
    printf("\033[2J\033[H");
    printf("%s%s", COLOR_BOLD, COLOR_RED);
    printf("  ____  _____ ____ _____ _   _   ____    _    ____  _____ \n");
    printf(" |  _ \\| ____|  _ \\_   _| | | | | __ )  / \\  |  _ \\| ____|\n");
    printf(" | | | |  _| | |_) || | | |_| | |  _ \\ / _ \\ | |_) |  _|  \n");
    printf(" | |_| | |___|  __/ | | |  _  | | |_) / ___ \\|  _ <| |___ \n");
    printf(" |____/|_____|_|    |_| |_| |_| |____/_/   \\_\\_| \\_\\_____|\n");
    printf("%s%s", COLOR_DARK, COLOR_BOLD);
    printf("  :: BEDROCK MINIMUM EDITION :: NO CEREMONY :: RAW SILICON ::\n%s\n", COLOR_RESET);
    printf("%sSystem initialized in %s318 ms%s. Root mounted on /dev/nvme0n1p1 (Ext4, noatime).\n", COLOR_DIM, COLOR_RED, COLOR_DIM);
    printf("Core toolchain: %sASM syscall ABI + dive package manager + POSIX sh + ELF64 runner%s\n\n", COLOR_RESET, COLOR_DIM);
}

int main(void) {
    banner();
    setenv("PATH", "/home/jaokhun/Projects/Depth/sys/bin:/home/jaokhun/Projects/Depth/pkg:/bin:/usr/bin", 1);
    setenv("PS1", "\033[38;2;230;25;25mdepth\033[0m:\033[38;2;140;20;20m~#\033[0m ", 1);
    char *args[] = {"/bin/sh", NULL};
    execv("/bin/sh", args);
    return 0;
}
