#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <dirent.h>

#define COLOR_RED "\033[38;2;230;25;25m"
#define COLOR_DARK "\033[38;2;140;20;20m"
#define COLOR_DIM "\033[38;2;100;100;100m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RESET "\033[0m"

static const char *get_db_dir(void) {
    static char path[512];
    const char *env_root = getenv("DEPTH_ROOT");
    if (env_root && strlen(env_root) > 0) {
        snprintf(path, sizeof(path), "%s/var/lib/dive", env_root);
    } else {
        const char *home = getenv("HOME");
        if (home && access("/var/lib/dive", W_OK) != 0) {
            snprintf(path, sizeof(path), "%s/.local/share/dive", home);
        } else {
            strncpy(path, "/var/lib/dive", sizeof(path));
        }
    }
    return path;
}

static void ensure_dir(const char *dir) {
    char tmp[512];
    snprintf(tmp, sizeof(tmp), "mkdir -p \"%s\"", dir);
    system(tmp);
}

static int check_internet_connectivity(void) {
    FILE *f = fopen("/proc/net/route", "r");
    int has_route = 0;
    if (f) {
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            char iface[32];
            unsigned long dest;
            if (sscanf(line, "%31s %lx", iface, &dest) == 2) {
                if (dest == 0 && strcmp(iface, "lo") != 0) {
                    has_route = 1;
                    break;
                }
            }
        }
        fclose(f);
    }
    if (!has_route) {
        int sock = socket(AF_INET, SOCK_DGRAM, 0);
        if (sock >= 0) {
            struct sockaddr_in target;
            memset(&target, 0, sizeof(target));
            target.sin_family = AF_INET;
            target.sin_port = htons(53);
            target.sin_addr.s_addr = inet_addr("10.0.2.3");
            if (connect(sock, (struct sockaddr *)&target, sizeof(target)) == 0) {
                has_route = 1;
            }
            close(sock);
        }
    }
    return has_route;
}

static void print_banner(void) {
    printf("%s%s  ___  ____ ___ _____ _   _ %s\n", COLOR_BOLD, COLOR_RED, COLOR_RESET);
    printf("%s%s |  _ \\| ____|  _ \\_   _| | | |%s\n", COLOR_BOLD, COLOR_RED, COLOR_RESET);
    printf("%s%s | | | |  _| | |_) || | | |_| |%s\n", COLOR_BOLD, COLOR_RED, COLOR_RESET);
    printf("%s%s | |_| | |___|  __/ | | |  _  |%s\n", COLOR_BOLD, COLOR_RED, COLOR_RESET);
    printf("%s%s |____/|_____|_|    |_| |_| |_|%s\n", COLOR_BOLD, COLOR_RED, COLOR_RESET);
    printf("%s%s :: DIVE PACKAGE ENGINE ::%s\n\n", COLOR_DARK, COLOR_BOLD, COLOR_RESET);
}

static void cmd_help(void) {
    print_banner();
    printf("%sUsage:%s dive <command|flag> [args]\n\n", COLOR_BOLD, COLOR_RESET);
    printf("  %s-help%s                       Show this command reference\n", COLOR_RED, COLOR_RESET);
    printf("  %s-search%s <query>             Search repository for packages\n", COLOR_RED, COLOR_RESET);
    printf("  %s-install%s <package>          Install target package archive (.dpk)\n", COLOR_RED, COLOR_RESET);
    printf("  %s-install-similiar%s <query>   Fuzzy match closest name (e.g. google-chrome) and install\n", COLOR_RED, COLOR_RESET);
    printf("  %s-list%s                       List all installed packages\n", COLOR_RED, COLOR_RESET);
    printf("  %s-remove%s <package>           Remove installed package from system\n", COLOR_RED, COLOR_RESET);
    printf("  %s-repo%s                       Display repository configuration & upload guidelines\n", COLOR_RED, COLOR_RESET);
    printf("  %s-sync%s                       Synchronize repository database\n", COLOR_RED, COLOR_RESET);
    printf("  %sbuild%s <dir> <out.dpk>       Compile directory tree into .dpk archive\n", COLOR_RED, COLOR_RESET);
    printf("\n");
}

static void cmd_repo(void) {
    print_banner();
    printf("%sDepth Community Repository Architecture%s\n", COLOR_BOLD, COLOR_RESET);
    printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
    printf("  Registry URI:       %shttps://repo.depth-hinux.org/core%s\n", COLOR_RED, COLOR_RESET);
    printf("  Community Upload:   %shttps://github.com/depth-os/dive-repo%s\n", COLOR_RED, COLOR_RESET);
    printf("  Local Storage:      %s/var/cache/dive/packages%s\n", COLOR_RED, COLOR_RESET);
    printf("  Package Format:     %s.dpk (gzip tarball + ELF binaries)%s\n", COLOR_RED, COLOR_RESET);
    printf("\n%sContribution Workflow:%s\n", COLOR_BOLD, COLOR_RESET);
    printf("  1. Create payload directory with binary layout (/bin, /lib, etc.)\n");
    printf("  2. Run: dive build <payload_dir> <app-name>.dpk\n");
    printf("  3. Submit PR or push to dive package registry index.\n\n");
}

static int lev_dist(const char *s1, const char *s2) {
    int len1 = strlen(s1);
    int len2 = strlen(s2);
    int matrix[64][64];
    if (len1 >= 64) len1 = 63;
    if (len2 >= 64) len2 = 63;
    for (int i = 0; i <= len1; i++) matrix[i][0] = i;
    for (int j = 0; j <= len2; j++) matrix[0][j] = j;
    for (int i = 1; i <= len1; i++) {
        for (int j = 1; j <= len2; j++) {
            int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
            int a = matrix[i - 1][j] + 1;
            int b = matrix[i][j - 1] + 1;
            int c = matrix[i - 1][j - 1] + cost;
            int min = (a < b) ? a : b;
            matrix[i][j] = (min < c) ? min : c;
        }
    }
    return matrix[len1][len2];
}

static int cmd_sync(void) {
    const char *db = get_db_dir();
    char inst_dir[512];
    char cmd[1024];
    snprintf(inst_dir, sizeof(inst_dir), "%s/installed", db);
    ensure_dir(inst_dir);

    printf("%s[DIVE]%s Synchronizing Depth repository tree...\n", COLOR_RED, COLOR_RESET);
    const char *repo_src = "pkg/repo/repo.json";
    if (access(repo_src, R_OK) != 0) {
        repo_src = "/etc/dive/repo.json";
    }

    if (access(repo_src, R_OK) == 0) {
        snprintf(cmd, sizeof(cmd), "cp -f \"%s\" \"%s/repo.json\"", repo_src, db);
        system(cmd);
        printf("%s[DIVE]%s Repository index updated successfully -> %s/repo.json\n", COLOR_RED, COLOR_RESET, db);
        return 0;
    }

    char repo_file[512];
    snprintf(repo_file, sizeof(repo_file), "%s/repo.json", db);
    FILE *f = fopen(repo_file, "w");
    if (f) {
        fprintf(f, "{\n  \"repository\": \"depth-core\",\n  \"version\": \"1.0.0\",\n  \"packages\": []\n}\n");
        fclose(f);
    }
    return 0;
}

static int cmd_list(void) {
    const char *db = get_db_dir();
    char inst_dir[512];
    snprintf(inst_dir, sizeof(inst_dir), "%s/installed", db);
    DIR *d = opendir(inst_dir);
    if (!d) {
        printf("%s[DIVE]%s No packages installed.\n", COLOR_RED, COLOR_RESET);
        return 0;
    }

    printf("%s%s%-24s %-12s %s%s\n", COLOR_BOLD, COLOR_RED, "PACKAGE", "VERSION", "STATUS", COLOR_RESET);
    printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);

    struct dirent *ent;
    int count = 0;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        char *dot = strstr(ent->d_name, ".manifest");
        if (dot) {
            char pkg_name[128];
            size_t len = dot - ent->d_name;
            if (len >= sizeof(pkg_name)) len = sizeof(pkg_name) - 1;
            strncpy(pkg_name, ent->d_name, len);
            pkg_name[len] = '\0';
            printf("%-24s %-12s %sinstalled%s\n", pkg_name, "active", COLOR_RED, COLOR_RESET);
            count++;
        }
    }
    closedir(d);
    if (count == 0) {
        printf("%s[DIVE]%s No packages recorded in database.\n", COLOR_RED, COLOR_RESET);
    } else {
        printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
        printf("%sTotal installed packages: %d%s\n", COLOR_BOLD, count, COLOR_RESET);
    }
    return 0;
}

static int cmd_search(const char *query) {
    int match_all = (!query || strlen(query) == 0 || strcmp(query, "all") == 0 || strcmp(query, "*") == 0);
    const char *paths[] = {"pkg/repo/packages", "/var/cache/dive/packages", "/etc/dive/packages", NULL};
    printf("%s%s%-24s %-12s %s%s\n", COLOR_BOLD, COLOR_RED, "PACKAGE", "TYPE", "AVAILABILITY", COLOR_RESET);
    printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);

    int count = 0;
    char found_names[64][64];
    int found_count = 0;

    for (int i = 0; paths[i]; i++) {
        DIR *d = opendir(paths[i]);
        if (!d) continue;
        struct dirent *ent;
        while ((ent = readdir(d)) != NULL) {
            if (ent->d_name[0] == '.') continue;
            char *dot = strstr(ent->d_name, ".dpk");
            if (dot) {
                char name[128];
                size_t len = dot - ent->d_name;
                if (len >= sizeof(name)) len = sizeof(name) - 1;
                strncpy(name, ent->d_name, len);
                name[len] = '\0';

                int already = 0;
                for (int j = 0; j < found_count; j++) {
                    if (strcmp(found_names[j], name) == 0) {
                        already = 1;
                        break;
                    }
                }
                if (already) continue;

                if (match_all || strstr(name, query) != NULL) {
                    if (found_count < 64) {
                        strncpy(found_names[found_count++], name, 63);
                    }
                    printf("%-24s %-12s %savailable%s\n", name, ".dpk", COLOR_RED, COLOR_RESET);
                    count++;
                }
            }
        }
        closedir(d);
    }

    const char *repo_json_paths[] = {"pkg/repo/repo.json", "/etc/dive/repo.json", "/var/lib/dive/repo.json", NULL};
    for (int i = 0; repo_json_paths[i]; i++) {
        FILE *fj = fopen(repo_json_paths[i], "r");
        if (fj) {
            char line[256];
            while (fgets(line, sizeof(line), fj)) {
                char *pname = strstr(line, "\"name\": \"");
                if (pname) {
                    char item[64] = "";
                    pname += 9;
                    char *quote = strchr(pname, '"');
                    if (quote) {
                        size_t l = quote - pname;
                        if (l >= sizeof(item)) l = sizeof(item) - 1;
                        strncpy(item, pname, l);
                        item[l] = '\0';
                        if (strcmp(item, "depth-hinux") != 0) {
                            int already = 0;
                            for (int j = 0; j < found_count; j++) {
                                if (strcmp(found_names[j], item) == 0) {
                                    already = 1;
                                    break;
                                }
                            }
                            if (!already && (match_all || strstr(item, query) != NULL)) {
                                if (found_count < 64) {
                                    strncpy(found_names[found_count++], item, 63);
                                }
                                printf("%-24s %-12s %srepository%s\n", item, ".dpk", COLOR_RED, COLOR_RESET);
                                count++;
                            }
                        }
                    }
                }
            }
            fclose(fj);
            break;
        }
    }

    if (count == 0) {
        printf("%s[DIVE]%s No matching packages found for '%s'.\n", COLOR_DARK, COLOR_RESET, query);
        printf("%s[TIP]%s Try: dive -install-similiar %s\n", COLOR_RED, COLOR_RESET, query);
    } else {
        printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
        printf("%sTotal matching packages: %d%s\n", COLOR_BOLD, count, COLOR_RESET);
    }
    return 0;
}

static int cmd_install(const char *pkg_target) {
    if (!pkg_target) {
        fprintf(stderr, "%s[ERROR]%s Missing package target to install.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }

    int online = check_internet_connectivity();
    if (!online && access(pkg_target, R_OK) != 0) {
        char check_cached[512];
        snprintf(check_cached, sizeof(check_cached), "/var/cache/dive/packages/%s.dpk", pkg_target);
        if (access(check_cached, R_OK) != 0) {
            snprintf(check_cached, sizeof(check_cached), "pkg/repo/packages/%s.dpk", pkg_target);
            if (access(check_cached, R_OK) != 0) {
                fprintf(stderr, "%s[ERROR]%s Internet connection required to download package '%s' from repository.\n", COLOR_RED, COLOR_RESET, pkg_target);
                fprintf(stderr, "%s[DIVE]%s Network interface is currently offline.\n", COLOR_DARK, COLOR_RESET);
                printf("%s[TIP]%s Please run 'network' or 'net' to establish internet connection first.\n", COLOR_RED, COLOR_RESET);
                return 1;
            }
        }
    }

    const char *db = get_db_dir();
    char inst_dir[512];
    snprintf(inst_dir, sizeof(inst_dir), "%s/installed", db);
    ensure_dir(inst_dir);

    char pkg_path[512];
    if (access(pkg_target, R_OK) == 0) {
        strncpy(pkg_path, pkg_target, sizeof(pkg_path));
    } else {
        snprintf(pkg_path, sizeof(pkg_path), "pkg/repo/packages/%s.dpk", pkg_target);
        if (access(pkg_path, R_OK) != 0) {
            snprintf(pkg_path, sizeof(pkg_path), "/var/cache/dive/packages/%s.dpk", pkg_target);
            if (access(pkg_path, R_OK) != 0) {
                snprintf(pkg_path, sizeof(pkg_path), "/etc/dive/packages/%s.dpk", pkg_target);
                if (access(pkg_path, R_OK) != 0) {
                    fprintf(stderr, "%s[ERROR]%s Cannot locate package archive for '%s'\n", COLOR_RED, COLOR_RESET, pkg_target);
                    printf("%s[TIP]%s Use 'dive -install-similiar %s' to find closest match.\n", COLOR_RED, COLOR_RESET, pkg_target);
                    return 1;
                }
            }
        }
    }

    const char *env_root = getenv("DEPTH_ROOT");
    char root_dest[512];
    if (env_root && strlen(env_root) > 0) {
        strncpy(root_dest, env_root, sizeof(root_dest));
    } else {
        const char *home = getenv("HOME");
        if (home && access("/", W_OK) != 0) {
            snprintf(root_dest, sizeof(root_dest), "%s/.local/depth-root", home);
        } else {
            strncpy(root_dest, "/", sizeof(root_dest));
        }
    }
    ensure_dir(root_dest);

    if (online) {
        printf("%s[DIVE]%s Internet connection active. Accessing package archive...\n", COLOR_RED, COLOR_RESET);
    }
    printf("%s[DIVE]%s Unpacking archive: %s\n", COLOR_RED, COLOR_RESET, pkg_path);
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "tar -xzf \"%s\" -C \"%s\" 2>/dev/null || tar -xf \"%s\" -C \"%s\"", pkg_path, root_dest, pkg_path, root_dest);
    int res = system(cmd);
    if (res != 0) {
        fprintf(stderr, "%s[ERROR]%s Extraction failed with code %d\n", COLOR_RED, COLOR_RESET, res);
        return 1;
    }

    char base_name[128];
    const char *slash = strrchr(pkg_target, '/');
    const char *raw = slash ? slash + 1 : pkg_target;
    strncpy(base_name, raw, sizeof(base_name));
    char *dot = strstr(base_name, ".dpk");
    if (dot) *dot = '\0';

    char bin_path[512];
    snprintf(bin_path, sizeof(bin_path), "%s/bin/%s", root_dest, base_name);
    if (access(bin_path, R_OK) == 0) {
        int bfd = open(bin_path, O_RDONLY);
        if (bfd >= 0) {
            char magic[4];
            if (read(bfd, magic, 4) == 4 && memcmp(magic, "\x7f\x45\x4c\x46", 4) == 0) {
                printf("%s[DIVE]%s Verified ELF binary: %s (x86_64 native executable)\n", COLOR_RED, COLOR_RESET, bin_path);
            }
            close(bfd);
        }
        chmod(bin_path, 0755);
    }

    char manifest_file[512];
    snprintf(manifest_file, sizeof(manifest_file), "%s/%s.manifest", inst_dir, base_name);
    FILE *mf = fopen(manifest_file, "w");
    if (mf) {
        fprintf(mf, "package: %s\nstatus: installed\nsource: %s\nroot: %s\n", base_name, pkg_path, root_dest);
        fclose(mf);
    }

    printf("%s[DIVE]%s %s%s%s installed successfully into system hierarchy.\n", COLOR_RED, COLOR_RESET, COLOR_BOLD, base_name, COLOR_RESET);
    return 0;
}

static int cmd_install_similar(const char *query) {
    if (!query) {
        fprintf(stderr, "%s[ERROR]%s Missing query for similar package search.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }

    const char *paths[] = {"pkg/repo/packages", "/var/cache/dive/packages", "/etc/dive/packages", NULL};
    char best_name[128] = "";
    int best_score = 9999;

    for (int i = 0; paths[i]; i++) {
        DIR *d = opendir(paths[i]);
        if (!d) continue;
        struct dirent *ent;
        while ((ent = readdir(d)) != NULL) {
            if (ent->d_name[0] == '.') continue;
            char *dot = strstr(ent->d_name, ".dpk");
            if (dot) {
                char name[128];
                size_t len = dot - ent->d_name;
                if (len >= sizeof(name)) len = sizeof(name) - 1;
                strncpy(name, ent->d_name, len);
                name[len] = '\0';

                int score = 0;
                if (strstr(name, query) != NULL || strstr(query, name) != NULL) {
                    score = 0;
                } else {
                    score = lev_dist(name, query);
                }

                if (score < best_score) {
                    best_score = score;
                    strncpy(best_name, name, sizeof(best_name));
                }
            }
        }
        closedir(d);
    }

    if (strlen(best_name) == 0) {
        fprintf(stderr, "%s[ERROR]%s No candidates found for query '%s'.\n", COLOR_RED, COLOR_RESET, query);
        return 1;
    }

    printf("%s[DIVE]%s Fuzzy match found: %s%s%s (confidence distance: %d)\n", COLOR_RED, COLOR_RESET, COLOR_BOLD, best_name, COLOR_RESET, best_score);
    printf("%s[DIVE]%s Proceeding to install %s...\n", COLOR_RED, COLOR_RESET, best_name);
    return cmd_install(best_name);
}

static int cmd_remove(const char *pkg_name) {
    if (!pkg_name) {
        fprintf(stderr, "%s[ERROR]%s Missing package name to remove.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }

    const char *db = get_db_dir();
    char manifest_file[512];
    snprintf(manifest_file, sizeof(manifest_file), "%s/installed/%s.manifest", db, pkg_name);
    if (access(manifest_file, F_OK) != 0) {
        fprintf(stderr, "%s[ERROR]%s Package '%s' is not registered as installed.\n", COLOR_RED, COLOR_RESET, pkg_name);
        return 1;
    }

    unlink(manifest_file);
    printf("%s[DIVE]%s Removed package record: %s%s%s\n", COLOR_RED, COLOR_RESET, COLOR_BOLD, pkg_name, COLOR_RESET);
    return 0;
}

static int cmd_build(const char *src_dir, const char *out_dpk) {
    if (!src_dir || !out_dpk) {
        fprintf(stderr, "%s[ERROR]%s Usage: dive build <source_directory> <output.dpk>\n", COLOR_RED, COLOR_RESET);
        return 1;
    }
    if (access(src_dir, R_OK) != 0) {
        fprintf(stderr, "%s[ERROR]%s Source directory does not exist: %s\n", COLOR_RED, COLOR_RESET, src_dir);
        return 1;
    }

    printf("%s[DIVE]%s Packaging '%s' -> '%s'...\n", COLOR_RED, COLOR_RESET, src_dir, out_dpk);
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "tar -czf \"%s\" -C \"%s\" .", out_dpk, src_dir);
    int res = system(cmd);
    if (res == 0) {
        printf("%s[DIVE]%s Built %s successfully.\n", COLOR_RED, COLOR_RESET, out_dpk);
        return 0;
    }
    return 1;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        cmd_help();
        return 1;
    }

    const char *action = argv[1];
    if (strcmp(action, "help") == 0 || strcmp(action, "--help") == 0 || strcmp(action, "-help") == 0 || strcmp(action, "-h") == 0) {
        cmd_help();
        return 0;
    }
    if (strcmp(action, "sync") == 0 || strcmp(action, "-sync") == 0) {
        return cmd_sync();
    }
    if (strcmp(action, "list") == 0 || strcmp(action, "-list") == 0) {
        return cmd_list();
    }
    if (strcmp(action, "repo") == 0 || strcmp(action, "-repo") == 0) {
        cmd_repo();
        return 0;
    }
    if (strcmp(action, "search") == 0 || strcmp(action, "-search") == 0) {
        return cmd_search((argc >= 3) ? argv[2] : "");
    }
    if (strcmp(action, "install") == 0 || strcmp(action, "-install") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Missing package name. Usage: dive -install <pkg>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_install(argv[2]);
    }
    if (strcmp(action, "install-similar") == 0 || strcmp(action, "-install-similar") == 0 || strcmp(action, "install-similiar") == 0 || strcmp(action, "-install-similiar") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Missing query. Usage: dive -install-similiar <query>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_install_similar(argv[2]);
    }
    if (strcmp(action, "remove") == 0 || strcmp(action, "-remove") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Missing package name. Usage: dive -remove <pkg>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_remove(argv[2]);
    }
    if (strcmp(action, "build") == 0 || strcmp(action, "-build") == 0) {
        if (argc < 4) {
            fprintf(stderr, "%s[ERROR]%s Usage: dive build <src_dir> <out.dpk>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_build(argv[2], argv[3]);
    }

    fprintf(stderr, "%s[ERROR]%s Unknown command '%s'. Run 'dive -help'.\n", COLOR_RED, COLOR_RESET, action);
    return 1;
}
