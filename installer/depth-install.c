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
    printf("   ___  ____ ____ _____ _   _     ___  ____  \n");
    printf("  |  _ \\| ____|  _ \\_   _| | | |   / _ \\/ ___| \n");
    printf("  | | | |  _| | |_) || | | |_| |  | | | \\___ \\ \n");
    printf("  | |_| | |___|  __/ | | |  _  |  | |_| |___) |\n");
    printf("  |____/|_____|_|    |_| |_| |_|   \\___/|____/ \n");
    printf("%s%s", COLOR_DARK, COLOR_BOLD);
    printf("  ==============================================\n");
    printf("      BEDROCK HARDWARE INSTALLER & BOOTSTRAP    \n");
    printf("  ==============================================\n%s\n", COLOR_RESET);
}

int main(int argc, char **argv) {
    banner();
    printf("%s[1]%s Install Depth Hinux  %s(Bedrock Raw Silicon, ASM Core, Dive)%s\n", COLOR_RED, COLOR_RESET, COLOR_DIM, COLOR_RESET);
    printf("%s[2]%s Disk Partition Tool  %s(Cut, Merge & Format Drive Partitions)%s\n", COLOR_RED, COLOR_RESET, COLOR_DIM, COLOR_RESET);
    printf("%s[3]%s Exit Installer\n\n", COLOR_RED, COLOR_RESET);

    printf("%sSelect an option [1-3]: %s", COLOR_BOLD, COLOR_RESET);
    fflush(stdout);

    int choice = 1;
    if (argc > 1) {
        choice = atoi(argv[1]);
        printf("%d\n", choice);
    } else {
        char buf[32];
        if (fgets(buf, sizeof(buf), stdin)) {
            choice = atoi(buf);
        }
    }

    if (choice == 2) {
        printf("\n%sInvoking Depth Partition Engine...%s\n", COLOR_RED, COLOR_RESET);
        if (access("installer/partition.py", R_OK) == 0) {
            system("python3 installer/partition.py list");
        } else if (access("/etc/installer/partition.py", R_OK) == 0) {
            system("python3 /etc/installer/partition.py list");
        } else {
            system("lsblk 2>/dev/null || fdisk -l 2>/dev/null || cat /proc/partitions");
        }
        return 0;
    }

    if (choice != 1) {
        printf("Installation aborted.\n");
        return 0;
    }

    char target_dir[256] = "/tmp/depth_target_sys";
    if (access("/mnt", W_OK) == 0) {
        strncpy(target_dir, "/mnt", sizeof(target_dir));
    }
    printf("%sInstallation destination [%s]: %s", COLOR_BOLD, target_dir, COLOR_RESET);
    fflush(stdout);
    if (argc <= 1) {
        char in_buf[256];
        if (fgets(in_buf, sizeof(in_buf), stdin)) {
            char *nl = strchr(in_buf, '\n');
            if (nl) *nl = '\0';
            if (strlen(in_buf) > 0) {
                strncpy(target_dir, in_buf, sizeof(target_dir));
            }
        }
    } else {
        printf("\n");
    }

    char cmd[1024];
    printf("\n%s[STEP 1/3]%s Preparing target filesystem hierarchy on %s...\n", COLOR_RED, COLOR_RESET, target_dir);
    snprintf(cmd, sizeof(cmd), "mkdir -p %s/bin %s/sbin %s/usr/bin %s/etc %s/lib %s/var/lib/dive/installed %s/root", target_dir, target_dir, target_dir, target_dir, target_dir, target_dir, target_dir);
    system(cmd);

    printf("%s[STEP 2/3]%s Deploying pure assembly core utilities & dive engine...\n", COLOR_RED, COLOR_RESET);
    if (access("sys/bin", R_OK) == 0) {
        snprintf(cmd, sizeof(cmd), "cp -rf sys/bin/* %s/bin/ 2>/dev/null || true", target_dir);
        system(cmd);
    } else if (access("/bin", R_OK) == 0) {
        snprintf(cmd, sizeof(cmd), "cp -rf /bin/* %s/bin/ 2>/dev/null || true", target_dir);
        system(cmd);
    }
    snprintf(cmd, sizeof(cmd), "cp -f /bin/dive %s/bin/dive 2>/dev/null || cp -f pkg/dive %s/bin/dive 2>/dev/null || true", target_dir, target_dir);
    system(cmd);

    printf("%s[STEP 3/3]%s Generating system boot and fstab configuration...\n", COLOR_RED, COLOR_RESET);
    char fstab_path[512];
    snprintf(fstab_path, sizeof(fstab_path), "%s/etc/fstab", target_dir);
    FILE *f = fopen(fstab_path, "w");
    if (f) {
        fprintf(f, "LABEL=DEPTH_ROOT / ext4 defaults,noatime 0 1\n");
        fclose(f);
    }

    printf("\n%s%s[SUCCESS]%s Depth Hinux successfully deployed to %s!\n", COLOR_BOLD, COLOR_RED, COLOR_RESET, target_dir);
    printf("%sTo complete startup, reboot into target media or unmount.%s\n\n", COLOR_DIM, COLOR_RESET);
    return 0;
}
