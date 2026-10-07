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
#include <errno.h>

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
    chown("/root", 0, 0);

    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);
    mount("tmpfs", "/run", "tmpfs", 0, "mode=0755");
    mkdir("/run/hinux", 0755);
    mount("tmpfs", "/tmp", "tmpfs", 0, "mode=1777");
    mkdir("/dev/shm", 01777);
    mount("tmpfs", "/dev/shm", "tmpfs", 0, "mode=1777");
    mkdir("/dev/pts", 0755);
    mount("devpts", "/dev/pts", "devpts", 0, NULL);

    int mod_fd = open("/lib/modules/e1000.ko", O_RDONLY);
    if (mod_fd >= 0) {
        syscall(SYS_finit_module, mod_fd, "", 0);
        close(mod_fd);
    }

    int drm_fd = open("/lib/modules/bochs.ko", O_RDONLY);
    if (drm_fd >= 0) {
        syscall(SYS_finit_module, drm_fd, "", 0);
        close(drm_fd);
    }

    sethostname("dimensions", 10);

    FILE *fhost = fopen("/etc/hostname", "w");
    if (fhost) {
        fputs("dimensions\n", fhost);
        fclose(fhost);
    }

    FILE *fpw = fopen("/etc/passwd", "w");
    if (fpw) {
        fputs("root:x:0:0:root:/root:/bin/sh\ndbus:x:81:81:System Message Bus:/:/usr/bin/nologin\n", fpw);
        fclose(fpw);
    }

    FILE *fgrp = fopen("/etc/group", "w");
    if (fgrp) {
        fputs("root:x:0:\ndbus:x:81:\n", fgrp);
        fclose(fgrp);
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

    FILE *fhosts = fopen("/etc/hosts", "w");
    if (fhosts) {
        fputs("127.0.0.1\tlocalhost dimensions\n::1\tlocalhost ip6-localhost ip6-loopback\n", fhosts);
        fclose(fhosts);
    }

    FILE *fnss = fopen("/etc/nsswitch.conf", "w");
    if (fnss) {
        fputs("passwd: files\ngroup: files\nshadow: files\nhosts: files dns\nnetworks: files\nprotocols: files\nservices: files\nethers: files\nrpc: files\n", fnss);
        fclose(fnss);
    }

    system("/bin/ip link set lo up 2>/dev/null || true");
    system("/bin/ip link set eth0 up 2>/dev/null || true");
    system("/bin/ip addr add 10.0.2.15/24 dev eth0 2>/dev/null || true");
    system("/bin/ip route add default via 10.0.2.2 dev eth0 2>/dev/null || true");

    mkdir("/run/user", 0755);
    mkdir("/run/user/0", 0700);
    chown("/run/user", 0, 0);
    chown("/run/user/0", 0, 0);
    chmod("/run/user/0", 0700);

    setup_console();
    print_welcome();

    setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "root", 1);
    setenv("LOGNAME", "root", 1);
    setenv("HOSTNAME", "dimensions", 1);
    setenv("TERM", "linux", 1);
    setenv("LANG", "C.UTF-8", 1);
    setenv("LC_ALL", "C.UTF-8", 1);
    setenv("PS1", "\033[1;31mdepth-hinux \033[0;31m~/\033[1;31m # \033[0m ", 1);

    FILE *fmid = fopen("/etc/machine-id", "w");
    if (fmid) {
        fputs("9b8f2a1e0d3c4b5a6978123456789abc\n", fmid);
        fclose(fmid);
    }
    mkdir("/var/lib", 0755);
    mkdir("/var/lib/dbus", 0755);
    FILE *fdbusmid = fopen("/var/lib/dbus/machine-id", "w");
    if (fdbusmid) {
        fputs("9b8f2a1e0d3c4b5a6978123456789abc\n", fdbusmid);
        fclose(fdbusmid);
    }

    const char *bashrc_content = "export PS1=\"\\[\\033[1;31m\\]depth-hinux \\[\\033[0;31m\\]\\w\\[\\033[1;31m\\] # \\[\\033[0m\\] \"\nalias sudo=\"rac\"\n";
    FILE *fbrc = fopen("/etc/bash.bashrc", "w");
    if (fbrc) { fputs(bashrc_content, fbrc); fclose(fbrc); }
    FILE *frtc = fopen("/root/.bashrc", "w");
    if (frtc) { fputs(bashrc_content, frtc); fclose(frtc); }

    FILE *fprof = fopen("/etc/profile", "w");
    if (fprof) {
        fputs("export PATH=/bin:/sbin:/usr/bin:/usr/sbin\n", fprof);
        fputs("export HOME=/root\n", fprof);
        fputs("export LANG=C.UTF-8\n", fprof);
        fputs("export LC_ALL=C.UTF-8\n", fprof);
        fputs("export PS1=\"\\[\\033[1;31m\\]depth-hinux \\[\\033[0;31m\\]\\w\\[\\033[1;31m\\] # \\[\\033[0m\\] \"\n", fprof);
        fputs("export TERM=linux\n", fprof);
        fputs("alias sudo=\"rac\"\n", fprof);
        fclose(fprof);
    }

    FILE *fmode = fopen("/etc/depth-mode", "r");
    char mode_buf[32] = "";
    if (fmode) {
        if (fgets(mode_buf, sizeof(mode_buf), fmode)) {
            char *cr = strchr(mode_buf, '\r');
            if (cr) *cr = '\0';
            char *nl = strchr(mode_buf, '\n');
            if (nl) *nl = '\0';
        }
        fclose(fmode);
    }

    if (strncmp(mode_buf, "glare", 5) == 0 && access("/bin/glare", X_OK) == 0) {
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
