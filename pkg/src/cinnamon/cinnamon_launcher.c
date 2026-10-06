#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
    setenv("XDG_CURRENT_DESKTOP", "X-Cinnamon", 1);
    setenv("DESKTOP_SESSION", "cinnamon", 1);
    setenv("XDG_SESSION_DESKTOP", "cinnamon", 1);
    setenv("XDG_SESSION_TYPE", "x11", 1);
    setenv("CINNAMON_2D", "1", 1);

    if (argc > 1 && strcmp(argv[1], "-v") == 0) {
        printf("Cinnamon 6.6.9 (Depth Hinux Glare Desktop)\n");
        printf("Compositor: Muffin / Glare Composite Engine\n");
        printf("File Manager: Nemo 6.6.4\n");
        return 0;
    }

    if (access("/usr/bin/cinnamon-session", X_OK) == 0 && getenv("DISPLAY")) {
        char *c_args[] = {"/usr/bin/cinnamon-session", NULL};
        execv("/usr/bin/cinnamon-session", c_args);
    }

    if (access("/bin/glare", X_OK) == 0) {
        char *g_args[] = {"/bin/glare", NULL};
        execv("/bin/glare", g_args);
    }

    printf("[CINNAMON] Starting Cinnamon 6.6 Desktop on Depth Hinux...\n");
    return 0;
}
