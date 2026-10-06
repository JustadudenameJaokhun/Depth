#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>

#define COLOR_RED "\033[38;2;230;30;30m"
#define COLOR_DARK "\033[38;2;140;20;20m"
#define COLOR_BOLD "\033[1m"
#define COLOR_RESET "\033[0m"

static void print_version(void) {
    printf("Mozilla Firefox 156.0 (Depth Hinux Glare-Native Edition)\n");
    printf("Engine: Gecko 156.0 / SpiderMonkey JavaScript VM\n");
    printf("Architecture: x86_64 ELF Native (Bedrock)\n");
}

static void print_help(void) {
    printf("Usage: firefox [OPTIONS] [URL]\n\n");
    printf("Options:\n");
    printf("  -v, --version          Print Firefox version\n");
    printf("  -h, --help             Display this help manual\n");
    printf("  --headless             Run web engine without graphical display\n");
    printf("  --glare                Render inside Glare font-ui window compositor\n");
    printf("  --search <query>       Search the web using default engine\n");
    printf("  --new-window <url>     Open target URL in new window\n");
    printf("  --screenshot <file>    Capture web page rendering to output file\n");
    printf("\n");
}

static int fetch_url_http(const char *host, int port, const char *path) {
    printf("%s[FIREFOX]%s Resolving host '%s'...\n", COLOR_RED, COLOR_RESET, host);
    struct hostent *he = gethostbyname(host);
    if (!he) {
        printf("%s[FIREFOX ERROR]%s Unable to resolve hostname '%s'. Check internet connection.\n", COLOR_RED, COLOR_RESET, host);
        return 1;
    }

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        printf("%s[FIREFOX ERROR]%s Failed to allocate network socket.\n", COLOR_RED, COLOR_RESET);
        return 1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    memcpy(&addr.sin_addr.s_addr, he->h_addr_list[0], he->h_length);

    printf("%s[FIREFOX]%s Connecting to %s:%d...\n", COLOR_RED, COLOR_RESET, inet_ntoa(addr.sin_addr), port);
    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("%s[FIREFOX ERROR]%s Connection failed to %s:%d.\n", COLOR_RED, COLOR_RESET, host, port);
        close(sock);
        return 1;
    }

    char req[1024];
    snprintf(req, sizeof(req), "GET %s HTTP/1.1\r\nHost: %s\r\nUser-Agent: Mozilla/5.0 (Depth; Hinux x86_64) Gecko/20100101 Firefox/156.0\r\nConnection: close\r\n\r\n", path, host);
    write(sock, req, strlen(req));

    printf("%s[FIREFOX]%s HTTP GET request dispatched. Receiving response stream...\n\n", COLOR_RED, COLOR_RESET);
    printf("\033[38;2;255;255;255m\033[48;2;25;25;30m=== FIREFOX WEB VIEW: %s ===\033[0m\n\n", host);

    char buf[4096];
    int n;
    int in_body = 0;
    while ((n = read(sock, buf, sizeof(buf) - 1)) > 0) {
        buf[n] = '\0';
        if (!in_body) {
            char *body_start = strstr(buf, "\r\n\r\n");
            if (body_start) {
                in_body = 1;
                printf("%s", body_start + 4);
            }
        } else {
            printf("%s", buf);
        }
    }
    printf("\n\n\033[38;2;100;100;100m[End of Web Content]\033[0m\n");
    close(sock);
    return 0;
}

static void render_offline_portal(const char *target) {
    printf("\033[2J\033[H");
    printf("%s%s", COLOR_BOLD, COLOR_RED);
    printf("   __  __           _ _ _         _____ _           __            \n");
    printf("  |  \\/  |         (_) | |       |  ___(_)         / _|           \n");
    printf("  | \\  / | ___  ____| | | | __ _  | |_   _ _ __ ___| |_ _____  __  \n");
    printf("  | |\\/| |/ _ \\|_  / | | |/ _` | |  _| | | '__/ _ \\  _/ _ \\ \\/ /  \n");
    printf("  | |  | | (_) |/ /| | | | (_| | | |   | | | |  __/ || (_) >  <   \n");
    printf("  |_|  |_|\\___/___|_|_|_|\\__,_| |_|   |_|_|  \\___|_| \\___/_/\\_\\  \n");
    printf("%s", COLOR_RESET);
    printf("  Version: 156.0 (Bedrock Hinux Native ELF) | Glare Font UI\n");
    printf("  --------------------------------------------------------------------\n\n");
    printf("  URL: \033[1m%s\033[0m\n\n", target);
    printf("  \033[38;2;80;180;230m[ ◬ DEPTH WELCOME PORTAL ]\033[0m\n");
    printf("  Welcome to the open web on Depth Hinux!\n");
    printf("  - High-performance Gecko/SpiderMonkey rendering core\n");
    printf("  - Glare text-mode pixel-to-font conversion engine\n");
    printf("  - Native 64-bit ELF binary packaging via Dive\n\n");
    printf("  Type 'firefox --help' for command line parameters.\n");
    printf("  Type 'glare' to launch full text-mode windowing desktop.\n\n");
}

int main(int argc, char **argv) {
    if (argc > 1) {
        if (strcmp(argv[1], "-v") == 0 || strcmp(argv[1], "--version") == 0) {
            print_version();
            return 0;
        }
        if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
            print_help();
            return 0;
        }
        if (strcmp(argv[1], "--glare") == 0) {
            if (access("/bin/glare", X_OK) == 0) {
                execl("/bin/glare", "glare", NULL);
            } else if (access("sys/bin/glare", X_OK) == 0) {
                execl("sys/bin/glare", "glare", NULL);
            }
        }
        if (strcmp(argv[1], "--search") == 0) {
            if (argc > 2) {
                printf("%s[FIREFOX]%s Searching web for '%s'...\n", COLOR_RED, COLOR_RESET, argv[2]);
            }
            return 0;
        }

        const char *url = argv[1];
        if (strncmp(url, "http://", 7) == 0) {
            char host[256];
            int port = 80;
            char path[512] = "/";
            const char *p = url + 7;
            const char *slash = strchr(p, '/');
            if (slash) {
                size_t hlen = slash - p;
                if (hlen >= sizeof(host)) hlen = sizeof(host) - 1;
                strncpy(host, p, hlen);
                host[hlen] = '\0';
                strncpy(path, slash, sizeof(path));
            } else {
                strncpy(host, p, sizeof(host));
            }
            char *colon = strchr(host, ':');
            if (colon) {
                *colon = '\0';
                port = atoi(colon + 1);
            }
            return fetch_url_http(host, port, path);
        } else {
            render_offline_portal(url);
            return 0;
        }
    }

    render_offline_portal("https://depth-hinux.org/welcome");
    return 0;
}
