#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <termios.h>

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

static void print_welcome(void) {
    printf("\033[2J\033[H\033[3J");
    fflush(stdout);
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    char time_str[64];
    if (tm_info) {
        strftime(time_str, sizeof(time_str), "%H:%M:%S", tm_info);
    } else {
        snprintf(time_str, sizeof(time_str), "12:00:00");
    }
    printf("Welcome To Depth!\n");
    printf("%s \033[40m   \033[41m   \033[42m   \033[43m   \033[44m   \033[45m   \033[46m   \033[47m   \033[0m\n", time_str);
    fflush(stdout);
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
    print_welcome();

    setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "root", 1);
    setenv("LOGNAME", "root", 1);
    setenv("HOSTNAME", "dimensions", 1);
    setenv("TERM", "linux", 1);
    setenv("PS1", "\033[1;31mdepth-hinux \033[0;31m~/\033[0m ", 1);

    FILE *fprof = fopen("/etc/profile", "w");
    if (fprof) {
        fputs("export PATH=/bin:/sbin:/usr/bin:/usr/sbin\n", fprof);
        fputs("export HOME=/root\n", fprof);
        fputs("export PS1=\"\\033[1;31mdepth-hinux \\033[0;31m~/\\033[0m \"\n", fprof);
        fputs("export TERM=linux\n", fprof);
        fclose(fprof);
    }

    FILE *fmode = fopen("/etc/depth-mode", "r");
    char mode_buf[32] = "";
    if (fmode) {
        if (fgets(mode_buf, sizeof(mode_buf), fmode)) {
            char *nl = strchr(mode_buf, '\n');
            if (nl) *nl = '\0';
        }
        fclose(fmode);
    }

    if (strcmp(mode_buf, "glare") == 0 && access("/bin/glare", X_OK) == 0) {
        pid_t glare_pid = fork();
        if (glare_pid == 0) {
            char *glare_args[] = {"/bin/glare", NULL};
            execv("/bin/glare", glare_args);
            exit(1);
        } else if (glare_pid > 0) {
            int status;
            waitpid(glare_pid, &status, 0);
        }
    }

    while (1) {
        pid_t shell_pid = fork();
        if (shell_pid == 0) {
            char *sh_args[] = {"/bin/sh", NULL};
            execv("/bin/sh", sh_args);
            exit(1);
        } else if (shell_pid > 0) {
            int status;
            waitpid(shell_pid, &status, 0);
        }
        if (access("/tmp/poweroff", F_OK) == 0 || access("/tmp/shutdown", F_OK) == 0) {
            break;
        }
        printf("\n[HINUX] Shell session closed. Type 'shutdown' to halt Depth Hinux.\n\n");
    }

    sync();
    reboot(RB_POWER_OFF);
    return 0;
}
