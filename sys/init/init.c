#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <termios.h>

#define COLOR_RED "\033[38;2;230;25;25m"
#define COLOR_DARK "\033[38;2;140;20;20m"
#define COLOR_DIM "\033[38;2;100;100;100m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RESET "\033[0m"

static void setup_console(void) {
    setsid();
    close(0);
    close(1);
    close(2);
    int fd = -1;
    FILE *cmd = fopen("/proc/cmdline", "r");
    char buf[512];
    int use_serial = 0;
    if (cmd) {
        if (fgets(buf, sizeof(buf), cmd)) {
            char *last_c = NULL;
            char *p = buf;
            while ((p = strstr(p, "console=")) != NULL) {
                last_c = p;
                p += 8;
            }
            if (last_c && strstr(last_c, "ttyS")) {
                use_serial = 1;
            }
        }
        fclose(cmd);
    }
    if (use_serial) {
        fd = open("/dev/ttyS0", O_RDWR);
    } else {
        fd = open("/dev/tty1", O_RDWR);
        if (fd < 0) fd = open("/dev/tty0", O_RDWR);
    }
    if (fd < 0) {
        fd = open("/dev/console", O_RDWR);
    }
    if (fd >= 0) {
        ioctl(fd, TIOCSCTTY, 1);
        dup2(fd, 0);
        dup2(fd, 1);
        dup2(fd, 2);
        if (fd > 2) close(fd);
    }
}

static void print_banner(void) {
    printf("%s%s", COLOR_BOLD, COLOR_RED);
    printf("    ███▄\n");
    printf("    ██████▄\n");
    printf("    █████████▄\n");
    printf("    ████████████▄\n");
    printf("    ██████████████▄\n");
    printf("    ███████████████▌     DEPTH HINUX [x86_64]\n");
    printf("    ███████████████▌     Dimensions Node | Bedrock Architecture\n");
    printf("    ██████████████▀      86.6%% Pure ASM Core | Zero GNU Bloat\n");
    printf("    ████████████▀        Kernel: Linux ABI | Toolset: Hinux Native\n");
    printf("    █████████▀           Raw Silicon. Built From Scratch.\n");
    printf("    ██████▀\n");
    printf("    ███▀\n");
    printf("%s\n", COLOR_RESET);
}

static void spawn_cmd(const char *path, char *const argv[]) {
    pid_t pid = fork();
    if (pid == 0) {
        execv(path, argv);
        exit(1);
    } else if (pid > 0) {
        int st;
        waitpid(pid, &st, 0);
    }
}

int main(void) {
    mkdir("/dev", 0755);
    mkdir("/proc", 0755);
    mkdir("/sys", 0755);
    mkdir("/tmp", 0777);
    mkdir("/run", 0755);
    mkdir("/etc", 0755);
    mkdir("/root", 0700);

    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);

    int mod_fd = open("/lib/modules/e1000.ko", O_RDONLY);
    if (mod_fd >= 0) {
        syscall(SYS_finit_module, mod_fd, "", 0);
        close(mod_fd);
    }

    sethostname("dimensions", 10);

    FILE *fhost = fopen("/etc/hostname", "w");
    if (fhost) {
        fputs("dimensions\n", fhost);
        fclose(fhost);
    }

    FILE *fpw = fopen("/etc/passwd", "w");
    if (fpw) {
        fputs("root:x:0:0:root:/root:/bin/sh\n", fpw);
        fclose(fpw);
    }

    FILE *fsh = fopen("/etc/shadow", "w");
    if (fsh) {
        fputs("root:$6$W/s2mWJtU2KDanVG$AxeYjt/g9d/qubvOm3eYCQikRlC2zaNLCF6RGeFiXkqiNGZhD8.H6FuUVox8V9aIbaBW9vUdUtVcfUfN8bi4/0:19800:0:99999:7:::\n", fsh);
        fclose(fsh);
    }

    FILE *fresolv = fopen("/etc/resolv.conf", "w");
    if (fresolv) {
        fputs("nameserver 10.0.2.3\nnameserver 1.1.1.1\nnameserver 8.8.8.8\n", fresolv);
        fclose(fresolv);
    }

    setup_console();
    print_banner();

    printf("%s[HINUX INIT]%s Testing standalone pure ASM binaries...\n", COLOR_RED, COLOR_RESET);
    char *echo_args[] = {"/bin/echo", "Depth Hinux pure ASM echo operational on bare metal.", NULL};
    spawn_cmd("/bin/echo", echo_args);

    if (access("/bin/fastfetch", X_OK) == 0) {
        printf("\n%s[HINUX INIT]%s Launching Fastfetch System Telemetry...\n", COLOR_RED, COLOR_RESET);
        char *ff_args[] = {"/bin/fastfetch", "-c", "/etc/fastfetch/config.jsonc", NULL};
        spawn_cmd("/bin/fastfetch", ff_args);
    }

    printf("\n%s[HINUX INIT]%s Starting bedrock interactive shell...\n", COLOR_RED, COLOR_RESET);
    setenv("PATH", "/bin:/usr/bin", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "root", 1);
    setenv("LOGNAME", "root", 1);
    setenv("HOSTNAME", "dimensions", 1);
    setenv("TERM", "linux", 1);
    setenv("PS1", "\033[38;2;230;25;25mdepth-hinux\033[0m:\033[38;2;140;20;20m~#\033[0m ", 1);

    pid_t shell_pid = fork();
    if (shell_pid == 0) {
        char *sh_args[] = {"/bin/sh", NULL};
        execv("/bin/sh", sh_args);
        exit(1);
    } else if (shell_pid > 0) {
        int status;
        waitpid(shell_pid, &status, 0);
    }

    printf("\n%s[HINUX INIT]%s Shell session terminated. Powering off system.\n", COLOR_RED, COLOR_RESET);
    sync();
    reboot(RB_POWER_OFF);
    return 0;
}
