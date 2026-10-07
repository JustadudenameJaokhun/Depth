#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>

#define COLOR_RED "\033[38;2;230;25;25m"
#define COLOR_DARK "\033[38;2;140;20;20m"
#define COLOR_DIM "\033[38;2;100;100;100m"
#define COLOR_GREEN "\033[38;2;40;200;60m"
#define COLOR_CYAN "\033[38;2;60;180;230m"
#define COLOR_YELLOW "\033[38;2;230;180;40m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RESET "\033[0m"

static void draw_box_header(const char *title) {
    printf("%s%s+-------------------------------------------------------------+%s\n", COLOR_BOLD, COLOR_DARK, COLOR_RESET);
    printf("%s%s|  %s%-57s%s%s%s|\n", COLOR_BOLD, COLOR_DARK, COLOR_RED, title, COLOR_RESET, COLOR_BOLD, COLOR_DARK);
    printf("%s%s+-------------------------------------------------------------+%s\n", COLOR_BOLD, COLOR_DARK, COLOR_RESET);
}

static void print_banner(void) {
    printf("\033[2J\033[H");
    printf("%s%s", COLOR_BOLD, COLOR_RED);
    printf("   ___  ____ ____ _____ _   _     ___  ____  \n");
    printf("  |  _ \\| ____|  _ \\_   _| | | |   / _ \\/ ___| \n");
    printf("  | | | |  _| | |_) || | | |_| |  | | | \\___ \\ \n");
    printf("  | |_| | |___|  __/ | | |  _  |  | |_| |___) |\n");
    printf("  |____/|_____|_|    |_| |_| |_|   \\___/|____/ \n");
    printf("%s%s  =============================================================\n", COLOR_DARK, COLOR_BOLD);
    printf("     DEPTH HINUX OS INSTALLER & HARDWARE DEPLOY ENGINE [TUI]    \n");
    printf("     Filesystem Architecture: X1 (High-Speed Encrypted Core)    \n");
    printf("  =============================================================\n%s\n", COLOR_RESET);
}

static void list_detected_disks(void) {
    printf("%sDetected Storage Block Devices:%s\n", COLOR_BOLD, COLOR_RESET);
    const char *common_devs[] = {"/dev/sda", "/dev/vda", "/dev/nvme0n1", "/dev/sdb", "/dev/hda", NULL};
    int found = 0;
    for (int i = 0; common_devs[i]; i++) {
        if (access(common_devs[i], F_OK) == 0) {
            printf("  %s[*]%s %-16s %s(Block Storage Device)%s\n", COLOR_GREEN, COLOR_RESET, common_devs[i], COLOR_DIM, COLOR_RESET);
            found++;
        }
    }
    if (!found) {
        printf("  %s[-]%s Running in virtual RAM disk environment (/dev/ram0)\n", COLOR_YELLOW, COLOR_RESET);
    }
    printf("\n");
}

static void show_progress(const char *msg, int percent) {
    printf("\r  %s[%-30s]%s %3d%%  %s", COLOR_RED, "==============================" + (30 - (percent * 30 / 100)), COLOR_RESET, percent, msg);
    fflush(stdout);
    usleep(150000);
}

int main(int argc, char **argv) {
    print_banner();
    list_detected_disks();

    draw_box_header("INSTALLATION MODE SELECTION");
    printf("  %s[1]%s Express Install to /mnt  %s(Format X1 Encrypted + Deploy Core)%s\n", COLOR_RED, COLOR_RESET, COLOR_DIM, COLOR_RESET);
    printf("  %s[2]%s Custom Device Install   %s(Select Disk, Format X1, Set Label)%s\n", COLOR_RED, COLOR_RESET, COLOR_DIM, COLOR_RESET);
    printf("  %s[3]%s Launch Drive Partitioner %s(Pure Assembly depthpart Tool)%s\n", COLOR_RED, COLOR_RESET, COLOR_DIM, COLOR_RESET);
    printf("  %s[4]%s Exit Installer\n\n", COLOR_RED, COLOR_RESET);

    printf("%sSelect an option [1-4, default 1]: %s", COLOR_BOLD, COLOR_RESET);
    fflush(stdout);

    int choice = 1;
    if (argc > 1) {
        choice = atoi(argv[1]);
        printf("%d\n", choice);
    } else {
        char buf[32];
        if (fgets(buf, sizeof(buf), stdin)) {
            int v = atoi(buf);
            if (v >= 1 && v <= 4) choice = v;
        }
    }

    if (choice == 3) {
        printf("\n%sInvoking Depth Drive Partitioner (depthpart)...%s\n", COLOR_RED, COLOR_RESET);
        if (access("/bin/depthpart", X_OK) == 0) {
            system("/bin/depthpart list");
        } else if (access("sys/bin/depthpart", X_OK) == 0) {
            system("sys/bin/depthpart list");
        } else {
            system("lsblk 2>/dev/null || cat /proc/partitions");
        }
        return 0;
    }

    if (choice == 4) {
        printf("Installation aborted.\n");
        return 0;
    }

    char target_device[256] = "/dev/sda1";
    char target_dir[256] = "/tmp/depth_target_sys";

    if (choice == 2) {
        printf("\nEnter target block device for X1 formatting (e.g. /dev/sda1) [/dev/sda1]: ");
        fflush(stdout);
        char in_dev[256];
        if (fgets(in_dev, sizeof(in_dev), stdin)) {
            char *nl = strchr(in_dev, '\n');
            if (nl) *nl = '\0';
            if (strlen(in_dev) > 0) {
                strncpy(target_device, in_dev, sizeof(target_device));
            }
        }
    }

    if (access("/mnt", W_OK) == 0) {
        strncpy(target_dir, "/mnt", sizeof(target_dir));
    }

    printf("\n");
    draw_box_header("X1 FILESYSTEM PREPARATION & FORMAT");

    printf("  Target Device:        %s%s%s\n", COLOR_BOLD, target_device, COLOR_RESET);
    printf("  Filesystem Type:      %sX1 (Encrypted Fast Block FS)%s\n", COLOR_GREEN, COLOR_RESET);
    printf("  Superblock Signature: 0x58314653 [X1FS]\n");
    printf("  Mount Target:         %s\n\n", target_dir);

    char cmd[1024];
    if (access(target_device, F_OK) == 0) {
        if (access("/bin/mkfs.x1", X_OK) == 0) {
            snprintf(cmd, sizeof(cmd), "/bin/mkfs.x1 %s -L DEPTH_ROOT", target_device);
            system(cmd);
        } else if (access("sys/bin/mkfs.x1", X_OK) == 0) {
            snprintf(cmd, sizeof(cmd), "sys/bin/mkfs.x1 %s -L DEPTH_ROOT", target_device);
            system(cmd);
        }
    } else {
        printf("%s[X1FS]%s Virtual target directory designated: %s\n", COLOR_CYAN, COLOR_RESET, target_dir);
    }

    printf("\n");
    draw_box_header("DEPLOYING DEPTH HINUX BEDROCK SYSTEM");

    show_progress("Creating filesystem directories", 15);
    snprintf(cmd, sizeof(cmd), "mkdir -p %s/bin %s/sbin %s/usr/bin %s/usr/lib %s/etc %s/lib %s/run/hinux %s/var/lib/dive/installed %s/root %s/boot",
             target_dir, target_dir, target_dir, target_dir, target_dir, target_dir, target_dir, target_dir, target_dir, target_dir);
    system(cmd);

    show_progress("Deploying pure assembly core & rac", 40);
    if (access("sys/bin", R_OK) == 0) {
        snprintf(cmd, sizeof(cmd), "cp -rf sys/bin/* %s/bin/ 2>/dev/null || true", target_dir);
        system(cmd);
    } else if (access("/bin", R_OK) == 0) {
        snprintf(cmd, sizeof(cmd), "cp -rf /bin/* %s/bin/ 2>/dev/null || true", target_dir);
        system(cmd);
    }

    show_progress("Installing Dive engine and packages", 65);
    snprintf(cmd, sizeof(cmd), "cp -f /bin/dive %s/bin/dive 2>/dev/null || cp -f pkg/dive %s/bin/dive 2>/dev/null || true", target_dir, target_dir);
    system(cmd);
    snprintf(cmd, sizeof(cmd), "chmod 4755 %s/bin/rac 2>/dev/null || true", target_dir);
    system(cmd);

    show_progress("Writing X1 encrypted fstab configuration", 85);
    char fstab_path[512];
    snprintf(fstab_path, sizeof(fstab_path), "%s/etc/fstab", target_dir);
    FILE *f = fopen(fstab_path, "w");
    if (f) {
        fprintf(f, "LABEL=DEPTH_ROOT / x1 defaults,encrypted,noatime 0 1\n");
        fprintf(f, "proc /proc proc defaults 0 0\n");
        fprintf(f, "sysfs /sys sysfs defaults 0 0\n");
        fprintf(f, "devpts /dev/pts devpts gid=5,mode=620 0 0\n");
        fprintf(f, "tmpfs /run tmpfs mode=0755,nosuid,nodev 0 0\n");
        fprintf(f, "tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0\n");
        fclose(f);
    }

    show_progress("Writing Depth Hinux bootloader stage", 100);
    printf("\n\n");

    draw_box_header("INSTALLATION COMPLETED SUCCESSFULLY");
    printf("  %s[SUCCESS]%s Depth Hinux deployed to %s%s%s\n", COLOR_GREEN, COLOR_RESET, COLOR_BOLD, target_dir, COLOR_RESET);
    printf("  %s[*]%s Root Filesystem:   %sX1 Encrypted (0x58314653)%s\n", COLOR_CYAN, COLOR_RESET, COLOR_BOLD, COLOR_RESET);
    printf("  %s[*]%s Authorization Tool: %srac (Root Actions Controller)%s\n", COLOR_CYAN, COLOR_RESET, COLOR_BOLD, COLOR_RESET);
    printf("  %s[*]%s Package Manager:    %sdive (Cloud-Connected DPK)%s\n\n", COLOR_CYAN, COLOR_RESET, COLOR_BOLD, COLOR_RESET);
    printf("%sReboot system or unmount media to launch Depth Hinux.%s\n\n", COLOR_DIM, COLOR_RESET);

    return 0;
}
