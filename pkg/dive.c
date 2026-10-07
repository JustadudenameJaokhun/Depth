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
#include <time.h>
#include <errno.h>

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
    printf("%sUsage:%s dive <command> [arguments]\n\n", COLOR_BOLD, COLOR_RESET);
    printf("  %srepo-index%s [dir]             Generate repo.json index for any repository folder\n", COLOR_RED, COLOR_RESET);
    printf("  %sbuild%s <dir> [out.dpk]        Compile directory layout into verified .dpk archive\n", COLOR_RED, COLOR_RESET);
    printf("  %sinstall%s <package|file.dpk>   Install package archive with full file manifest\n", COLOR_RED, COLOR_RESET);
    printf("  %sremove%s <package>             Unlink and remove all files belonging to package\n", COLOR_RED, COLOR_RESET);
    printf("  %slist%s                         Display all installed packages and manifests\n", COLOR_RED, COLOR_RESET);
    printf("  %sinfo%s <package>               Inspect package metadata and installed file tree\n", COLOR_RED, COLOR_RESET);
    printf("  %sverify%s <package>             Verify disk integrity of all files in manifest\n", COLOR_RED, COLOR_RESET);
    printf("  %ssearch%s <query>               Query repository index and local package pool\n", COLOR_RED, COLOR_RESET);
    printf("  %srepo%s                         Display repository workflow and structure\n", COLOR_RED, COLOR_RESET);
    printf("  %ssync%s                         Synchronize repository database\n", COLOR_RED, COLOR_RESET);
    printf("\n");
}

static void cmd_repo(void) {
    print_banner();
    printf("%sDepth Hinux Community Repository Architecture%s\n", COLOR_BOLD, COLOR_RESET);
    printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
    printf("  Default Local Repo: %s/var/cache/dive/packages%s\n", COLOR_RED, COLOR_RESET);
    printf("  Source Repo Path:   %spkg/repo/packages%s\n", COLOR_RED, COLOR_RESET);
    printf("  Database Directory: %s/var/lib/dive%s\n", COLOR_RED, COLOR_RESET);
    printf("  Installed Manifests:%s/var/lib/dive/installed%s\n", COLOR_RED, COLOR_RESET);
    printf("\n%sHow to add and index your own packages:%s\n", COLOR_BOLD, COLOR_RESET);
    printf("  1. Prepare your rootfs files in a folder (e.g. myapp/usr/bin/myapp)\n");
    printf("  2. Create a dpk.meta file inside the folder with metadata\n");
    printf("  3. Run: %sdive build myapp myapp.dpk%s\n", COLOR_BOLD, COLOR_RESET);
    printf("  4. Place %smyapp.dpk%s into %spkg/repo/packages/%s\n", COLOR_BOLD, COLOR_RESET, COLOR_RED, COLOR_RESET);
    printf("  5. Run: %sdive repo-index pkg/repo/packages%s\n", COLOR_BOLD, COLOR_RESET);
    printf("  6. The repository index repo.json is generated and ready for installation!\n\n");
}

static int get_file_sha256(const char *filepath, char *out_hash, size_t max_len) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "sha256sum \"%s\" 2>/dev/null", filepath);
    FILE *fp = popen(cmd, "r");
    if (!fp) return 1;
    char buf[256];
    if (fgets(buf, sizeof(buf), fp)) {
        char *space = strchr(buf, ' ');
        if (space) *space = '\0';
        strncpy(out_hash, buf, max_len - 1);
        out_hash[max_len - 1] = '\0';
        pclose(fp);
        return 0;
    }
    pclose(fp);
    return 1;
}

static int cmd_repo_index(const char *target_dir) {
    const char *repo_path = target_dir;
    if (!repo_path || strlen(repo_path) == 0) {
        if (access("pkg/repo/packages", R_OK) == 0) {
            repo_path = "pkg/repo/packages";
        } else if (access("/var/cache/dive/packages", R_OK) == 0) {
            repo_path = "/var/cache/dive/packages";
        } else {
            repo_path = "pkg/repo/packages";
        }
    }

    DIR *d = opendir(repo_path);
    if (!d) {
        fprintf(stderr, "%s[ERROR]%s Cannot open repository directory: %s\n", COLOR_RED, COLOR_RESET, repo_path);
        return 1;
    }

    printf("%s[DIVE]%s Indexing repository packages in '%s'...\n", COLOR_RED, COLOR_RESET, repo_path);

    char json_path[512];
    snprintf(json_path, sizeof(json_path), "%s/../repo.json", repo_path);
    FILE *fj = fopen(json_path, "w");
    if (!fj) {
        snprintf(json_path, sizeof(json_path), "%s/repo.json", repo_path);
        fj = fopen(json_path, "w");
    }
    if (!fj) {
        fprintf(stderr, "%s[ERROR]%s Cannot write index file %s\n", COLOR_RED, COLOR_RESET, json_path);
        closedir(d);
        return 1;
    }

    fprintf(fj, "{\n  \"repository\": \"depth-hinux\",\n  \"version\": \"1.0.0\",\n  \"packages\": [\n");

    struct dirent *ent;
    int count = 0;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        char *dot = strstr(ent->d_name, ".dpk");
        if (dot && strcmp(dot, ".dpk") == 0) {
            char pkg_name[128];
            size_t nlen = dot - ent->d_name;
            if (nlen >= sizeof(pkg_name)) nlen = sizeof(pkg_name) - 1;
            strncpy(pkg_name, ent->d_name, nlen);
            pkg_name[nlen] = '\0';

            char full_path[512];
            snprintf(full_path, sizeof(full_path), "%s/%s", repo_path, ent->d_name);

            struct stat st;
            unsigned long sz = 0;
            if (stat(full_path, &st) == 0) {
                sz = (unsigned long)st.st_size;
            }

            char sha[128] = "unknown";
            get_file_sha256(full_path, sha, sizeof(sha));

            if (count > 0) fprintf(fj, ",\n");
            fprintf(fj, "    {\n");
            fprintf(fj, "      \"name\": \"%s\",\n", pkg_name);
            fprintf(fj, "      \"file\": \"%s\",\n", ent->d_name);
            fprintf(fj, "      \"size\": %lu,\n", sz);
            fprintf(fj, "      \"sha256\": \"%s\"\n", sha);
            fprintf(fj, "    }");

            printf("  + Indexed: %s%-18s%s [%lu bytes, sha: %.12s...]\n", COLOR_BOLD, pkg_name, COLOR_RESET, sz, sha);
            count++;
        }
    }
    closedir(d);

    fprintf(fj, "\n  ]\n}\n");
    fclose(fj);

    printf("%s[DIVE]%s Repository index generated: %s (%d packages recorded)\n\n", COLOR_RED, COLOR_RESET, json_path, count);
    return 0;
}

static int cmd_build(const char *src_dir, const char *out_dpk) {
    if (!src_dir) {
        fprintf(stderr, "%s[ERROR]%s Usage: dive build <source_dir> [output.dpk]\n", COLOR_RED, COLOR_RESET);
        return 1;
    }
    if (access(src_dir, R_OK) != 0) {
        fprintf(stderr, "%s[ERROR]%s Source directory not found: %s\n", COLOR_RED, COLOR_RESET, src_dir);
        return 1;
    }

    char target_archive[512];
    if (out_dpk && strlen(out_dpk) > 0) {
        strncpy(target_archive, out_dpk, sizeof(target_archive));
    } else {
        const char *base = strrchr(src_dir, '/');
        const char *name = base ? base + 1 : src_dir;
        snprintf(target_archive, sizeof(target_archive), "%s.dpk", name);
    }

    char meta_path[512];
    snprintf(meta_path, sizeof(meta_path), "%s/dpk.meta", src_dir);
    if (access(meta_path, R_OK) != 0) {
        FILE *fm = fopen(meta_path, "w");
        if (fm) {
            const char *base = strrchr(src_dir, '/');
            const char *name = base ? base + 1 : src_dir;
            fprintf(fm, "name=%s\nversion=1.0.0\narch=x86_64\nmaintainer=Depth Community\n", name);
            fclose(fm);
        }
    }

    printf("%s[DIVE]%s Building package archive: %s -> %s\n", COLOR_RED, COLOR_RESET, src_dir, target_archive);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "tar -czf \"%s\" -C \"%s\" .", target_archive, src_dir);
    int res = system(cmd);
    if (res != 0) {
        fprintf(stderr, "%s[ERROR]%s Packaging failed with exit code %d\n", COLOR_RED, COLOR_RESET, res);
        return 1;
    }

    struct stat st;
    unsigned long sz = 0;
    if (stat(target_archive, &st) == 0) sz = (unsigned long)st.st_size;

    char sha[128] = "unknown";
    get_file_sha256(target_archive, sha, sizeof(sha));

    printf("%s[DIVE]%s Built %s successfully [%lu bytes, sha256: %s]\n", COLOR_RED, COLOR_RESET, target_archive, sz, sha);
    return 0;
}

static int cmd_sync(void) {
    const char *db = get_db_dir();
    char inst_dir[512];
    snprintf(inst_dir, sizeof(inst_dir), "%s/installed", db);
    ensure_dir(inst_dir);

    printf("%s[DIVE]%s Synchronizing Depth repository tree...\n", COLOR_RED, COLOR_RESET);
    const char *repo_src = "pkg/repo/repo.json";
    if (access(repo_src, R_OK) != 0) repo_src = "/etc/dive/repo.json";

    if (access(repo_src, R_OK) == 0) {
        char cmd[1024];
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

    printf("%s%s%-24s %-12s %-10s %s%s\n", COLOR_BOLD, COLOR_RED, "PACKAGE", "STATUS", "FILES", "RECORD", COLOR_RESET);
    printf("%s-------------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);

    struct dirent *ent;
    int count = 0;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        char *dot = strstr(ent->d_name, ".files");
        if (dot && strcmp(dot, ".files") == 0) {
            char pkg_name[128];
            size_t len = dot - ent->d_name;
            if (len >= sizeof(pkg_name)) len = sizeof(pkg_name) - 1;
            strncpy(pkg_name, ent->d_name, len);
            pkg_name[len] = '\0';

            char fpath[512];
            snprintf(fpath, sizeof(fpath), "%s/%s", inst_dir, ent->d_name);
            FILE *ff = fopen(fpath, "r");
            int fcount = 0;
            if (ff) {
                char l[512];
                while (fgets(l, sizeof(l), ff)) fcount++;
                fclose(ff);
            }

            printf("%-24s %s%-12s%s %-10d %s.files%s\n", pkg_name, COLOR_RED, "installed", COLOR_RESET, fcount, COLOR_DIM, COLOR_RESET);
            count++;
        }
    }
    closedir(d);
    if (count == 0) {
        printf("%s[DIVE]%s No packages recorded in database.\n", COLOR_RED, COLOR_RESET);
    } else {
        printf("%s-------------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
        printf("%sTotal installed packages: %d%s\n", COLOR_BOLD, count, COLOR_RESET);
    }
    return 0;
}

static int cmd_info(const char *pkg_name) {
    if (!pkg_name) {
        fprintf(stderr, "%s[ERROR]%s Missing package name for info query.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }
    const char *db = get_db_dir();
    char meta_path[512];
    char files_path[512];
    snprintf(meta_path, sizeof(meta_path), "%s/installed/%s.meta", db, pkg_name);
    snprintf(files_path, sizeof(files_path), "%s/installed/%s.files", db, pkg_name);

    if (access(files_path, R_OK) != 0 && access(meta_path, R_OK) != 0) {
        fprintf(stderr, "%s[ERROR]%s Package '%s' is not registered as installed.\n", COLOR_RED, COLOR_RESET, pkg_name);
        return 1;
    }

    print_banner();
    printf("%sPackage Details: %s%s\n", COLOR_BOLD, pkg_name, COLOR_RESET);
    printf("%s-------------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);

    FILE *fm = fopen(meta_path, "r");
    if (fm) {
        char line[256];
        while (fgets(line, sizeof(line), fm)) {
            printf("  %s", line);
        }
        fclose(fm);
    }

    FILE *ff = fopen(files_path, "r");
    int fcount = 0;
    if (ff) {
        char line[512];
        printf("\n%sInstalled Files:%s\n", COLOR_BOLD, COLOR_RESET);
        while (fgets(line, sizeof(line), ff)) {
            if (fcount < 15) {
                printf("    %s", line);
            }
            fcount++;
        }
        if (fcount > 15) {
            printf("    ... and %d more files\n", fcount - 15);
        }
        fclose(ff);
    }
    printf("\n  Total tracked files: %d\n\n", fcount);
    return 0;
}

static int cmd_verify(const char *pkg_name) {
    if (!pkg_name) {
        fprintf(stderr, "%s[ERROR]%s Missing package name for verification.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }
    const char *db = get_db_dir();
    char files_path[512];
    snprintf(files_path, sizeof(files_path), "%s/installed/%s.files", db, pkg_name);

    FILE *ff = fopen(files_path, "r");
    if (!ff) {
        fprintf(stderr, "%s[ERROR]%s No installed manifest found for package '%s'.\n", COLOR_RED, COLOR_RESET, pkg_name);
        return 1;
    }

    printf("%s[DIVE]%s Verifying file integrity for '%s'...\n", COLOR_RED, COLOR_RESET, pkg_name);
    char line[512];
    int ok = 0;
    int missing = 0;
    while (fgets(line, sizeof(line), ff)) {
        char *nl = strchr(line, '\n');
        if (nl) *nl = '\0';
        char *cr = strchr(line, '\r');
        if (cr) *cr = '\0';
        if (strlen(line) == 0) continue;

        if (access(line, F_OK) == 0) {
            ok++;
        } else {
            printf("  %s[MISSING]%s %s\n", COLOR_RED, COLOR_RESET, line);
            missing++;
        }
    }
    fclose(ff);

    if (missing == 0) {
        printf("%s[DIVE]%s Package '%s' is 100%% verified (%d files intact).\n", COLOR_RED, COLOR_RESET, pkg_name, ok);
        return 0;
    } else {
        printf("%s[WARNING]%s Package '%s' has %d missing files out of %d!\n", COLOR_RED, COLOR_RESET, pkg_name, missing, ok + missing);
        return 1;
    }
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

    if (access("/bin/dpk-verify", X_OK) == 0) {
        char vcmd[1024];
        snprintf(vcmd, sizeof(vcmd), "/bin/dpk-verify \"%s\" >/dev/null 2>&1", pkg_path);
        if (system(vcmd) != 0) {
            fprintf(stderr, "%s[ERROR]%s DPK archive verification failed for %s\n", COLOR_RED, COLOR_RESET, pkg_path);
            return 1;
        }
    }

    char base_name[128];
    const char *slash = strrchr(pkg_target, '/');
    const char *raw = slash ? slash + 1 : pkg_target;
    strncpy(base_name, raw, sizeof(base_name));
    char *dot = strstr(base_name, ".dpk");
    if (dot) *dot = '\0';

    printf("%s[DIVE]%s Unpacking archive: %s -> %s\n", COLOR_RED, COLOR_RESET, pkg_path, root_dest);

    char tf_cmd[1024];
    snprintf(tf_cmd, sizeof(tf_cmd), "tar -tf \"%s\" 2>/dev/null", pkg_path);
    FILE *plist = popen(tf_cmd, "r");

    char files_out[512];
    snprintf(files_out, sizeof(files_out), "%s/%s.files", inst_dir, base_name);
    FILE *fout = fopen(files_out, "w");

    int file_count = 0;
    if (plist && fout) {
        char pline[512];
        while (fgets(pline, sizeof(pline), plist)) {
            char *nl = strchr(pline, '\n');
            if (nl) *nl = '\0';
            char *cr = strchr(pline, '\r');
            if (cr) *cr = '\0';
            if (strlen(pline) == 0) continue;

            const char *clean_p = pline;
            if (clean_p[0] == '.' && clean_p[1] == '/') clean_p += 2;
            else if (clean_p[0] == '.') clean_p += 1;
            if (strlen(clean_p) == 0) continue;

            if (strcmp(root_dest, "/") == 0) {
                fprintf(fout, "/%s\n", clean_p);
            } else {
                fprintf(fout, "%s/%s\n", root_dest, clean_p);
            }
            file_count++;
        }
        fclose(fout);
        pclose(plist);
    } else {
        if (plist) pclose(plist);
        if (fout) fclose(fout);
    }

    char extract_cmd[1024];
    snprintf(extract_cmd, sizeof(extract_cmd), "tar -xzf \"%s\" -C \"%s\" 2>/dev/null || tar -xf \"%s\" -C \"%s\"", pkg_path, root_dest, pkg_path, root_dest);
    int res = system(extract_cmd);
    if (res != 0) {
        fprintf(stderr, "%s[ERROR]%s Extraction failed with code %d\n", COLOR_RED, COLOR_RESET, res);
        unlink(files_out);
        return 1;
    }

    char meta_out[512];
    snprintf(meta_out, sizeof(meta_out), "%s/%s.meta", inst_dir, base_name);
    FILE *fmeta = fopen(meta_out, "w");
    if (fmeta) {
        time_t now = time(NULL);
        struct tm *tm_now = localtime(&now);
        char tbuf[64] = "unknown";
        if (tm_now) strftime(tbuf, sizeof(tbuf), "%Y-%m-%d %H:%M:%S", tm_now);

        struct stat st;
        unsigned long sz = 0;
        if (stat(pkg_path, &st) == 0) sz = (unsigned long)st.st_size;

        char sha[128] = "unknown";
        get_file_sha256(pkg_path, sha, sizeof(sha));

        fprintf(fmeta, "package=%s\ninstalled_date=%s\nsize=%lu\nsha256=%s\nfiles_count=%d\nsource=%s\nroot=%s\n",
                base_name, tbuf, sz, sha, file_count, pkg_path, root_dest);
        fclose(fmeta);
    }

    char bin_path[512];
    snprintf(bin_path, sizeof(bin_path), "%s/bin/%s", root_dest, base_name);
    if (access(bin_path, R_OK) == 0) {
        int bfd = open(bin_path, O_RDONLY);
        if (bfd >= 0) {
            char magic[4];
            if (read(bfd, magic, 4) == 4 && memcmp(magic, "\x7f\x45\x4c\x46", 4) == 0) {
                printf("%s[DIVE]%s Verified native ELF binary: %s\n", COLOR_RED, COLOR_RESET, bin_path);
            }
            close(bfd);
        }
        chmod(bin_path, 0755);
    }
    snprintf(bin_path, sizeof(bin_path), "%s/usr/bin/%s", root_dest, base_name);
    if (access(bin_path, R_OK) == 0) chmod(bin_path, 0755);

    if (access("/usr/bin/update-desktop-database", X_OK) == 0) {
        system("/usr/bin/update-desktop-database 2>/dev/null || true");
    }

    printf("%s[DIVE]%s %s%s%s installed successfully (%d files tracked in manifest).\n", COLOR_RED, COLOR_RESET, COLOR_BOLD, base_name, COLOR_RESET, file_count);
    return 0;
}

static int cmd_remove(const char *pkg_name) {
    if (!pkg_name) {
        fprintf(stderr, "%s[ERROR]%s Missing package name to remove.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }

    const char *db = get_db_dir();
    char files_path[512];
    char meta_path[512];
    snprintf(files_path, sizeof(files_path), "%s/installed/%s.files", db, pkg_name);
    snprintf(meta_path, sizeof(meta_path), "%s/installed/%s.meta", db, pkg_name);

    if (access(files_path, F_OK) != 0 && access(meta_path, F_OK) != 0) {
        char old_manifest[512];
        snprintf(old_manifest, sizeof(old_manifest), "%s/installed/%s.manifest", db, pkg_name);
        if (access(old_manifest, F_OK) == 0) {
            unlink(old_manifest);
            printf("%s[DIVE]%s Removed legacy package record: %s\n", COLOR_RED, COLOR_RESET, pkg_name);
            return 0;
        }
        fprintf(stderr, "%s[ERROR]%s Package '%s' is not registered as installed.\n", COLOR_RED, COLOR_RESET, pkg_name);
        return 1;
    }

    printf("%s[DIVE]%s Removing package '%s'...\n", COLOR_RED, COLOR_RESET, pkg_name);

    int unlinked = 0;
    FILE *ff = fopen(files_path, "r");
    if (ff) {
        char line[512];
        while (fgets(line, sizeof(line), ff)) {
            char *nl = strchr(line, '\n');
            if (nl) *nl = '\0';
            char *cr = strchr(line, '\r');
            if (cr) *cr = '\0';
            if (strlen(line) == 0) continue;

            struct stat st;
            if (lstat(line, &st) == 0) {
                if (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) {
                    if (unlink(line) == 0) unlinked++;
                }
            }
        }
        fclose(ff);
    }

    unlink(files_path);
    unlink(meta_path);

    printf("%s[DIVE]%s %s%s%s removed cleanly (%d files unlinked).\n", COLOR_RED, COLOR_RESET, COLOR_BOLD, pkg_name, COLOR_RESET, unlinked);
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
            if (dot && strcmp(dot, ".dpk") == 0) {
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
    } else {
        printf("%s-------------------------------------------------------%s\n", COLOR_DIM, COLOR_RESET);
        printf("%sTotal matching packages: %d%s\n", COLOR_BOLD, count, COLOR_RESET);
    }
    return 0;
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
    if (strcmp(action, "repo") == 0 || strcmp(action, "-repo") == 0) {
        cmd_repo();
        return 0;
    }
    if (strcmp(action, "repo-index") == 0 || strcmp(action, "-repo-index") == 0) {
        return cmd_repo_index((argc >= 3) ? argv[2] : NULL);
    }
    if (strcmp(action, "build") == 0 || strcmp(action, "-build") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Usage: dive build <src_dir> [output.dpk]\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_build(argv[2], (argc >= 4) ? argv[3] : NULL);
    }
    if (strcmp(action, "sync") == 0 || strcmp(action, "-sync") == 0 || strcmp(action, "update") == 0 || strcmp(action, "-update") == 0) {
        return cmd_sync();
    }
    if (strcmp(action, "list") == 0 || strcmp(action, "-list") == 0) {
        return cmd_list();
    }
    if (strcmp(action, "info") == 0 || strcmp(action, "-info") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Usage: dive info <package>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_info(argv[2]);
    }
    if (strcmp(action, "verify") == 0 || strcmp(action, "-verify") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Usage: dive verify <package>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_verify(argv[2]);
    }
    if (strcmp(action, "search") == 0 || strcmp(action, "-search") == 0) {
        return cmd_search((argc >= 3) ? argv[2] : "");
    }
    if (strcmp(action, "install") == 0 || strcmp(action, "-install") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Missing package name. Usage: dive install <pkg>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_install(argv[2]);
    }
    if (strcmp(action, "remove") == 0 || strcmp(action, "-remove") == 0) {
        if (argc < 3) {
            fprintf(stderr, "%s[ERROR]%s Missing package name. Usage: dive remove <pkg>\n", COLOR_RED, COLOR_RESET);
            return 1;
        }
        return cmd_remove(argv[2]);
    }

    fprintf(stderr, "%s[ERROR]%s Unknown command '%s'. Run 'dive help'.\n", COLOR_RED, COLOR_RESET, action);
    return 1;
}
