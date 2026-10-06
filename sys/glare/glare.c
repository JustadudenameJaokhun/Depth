#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <time.h>
#include <signal.h>
#include <fcntl.h>

#define MAX_WINDOWS 4

typedef struct {
    int id;
    char title[64];
    int x, y, w, h;
    int visible;
    int focused;
    int is_dragging;
    int drag_ox, drag_oy;
    int app_type;
} Window;

static struct termios orig_termios;
static int term_cols = 80;
static int term_rows = 25;
static Window windows[MAX_WINDOWS];
static int active_win_idx = 0;
static int running = 1;

static void disable_raw_mode(void) {
    printf("\033[?1000l\033[?1002l\033[?1006l");
    printf("\033[?25h\033[0m\033[2J\033[H");
    fflush(stdout);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

static void enable_raw_mode(void) {
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(disable_raw_mode);
    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_iflag &= ~(IXON | ICRNL);
    raw.c_oflag &= ~(OPOST);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);

    printf("\033[?1000h\033[?1002h\033[?1006h");
    printf("\033[?25l");
    fflush(stdout);
}

static void update_termsize(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) {
        term_cols = ws.ws_col;
        term_rows = ws.ws_row;
    } else {
        term_cols = 80;
        term_rows = 25;
    }
}

static void init_windows(void) {
    windows[0].id = 1;
    strncpy(windows[0].title, "Mozilla Firefox 156.0 - Glare Engine", sizeof(windows[0].title));
    windows[0].x = 4;
    windows[0].y = 3;
    windows[0].w = 72;
    windows[0].h = 17;
    windows[0].visible = 1;
    windows[0].focused = 1;
    windows[0].is_dragging = 0;
    windows[0].app_type = 1;

    windows[1].id = 2;
    strncpy(windows[1].title, "depth-hinux ~/ [Terminal]", sizeof(windows[1].title));
    windows[1].x = 38;
    windows[1].y = 8;
    windows[1].w = 38;
    windows[1].h = 12;
    windows[1].visible = 1;
    windows[1].focused = 0;
    windows[1].is_dragging = 0;
    windows[1].app_type = 2;

    windows[2].id = 3;
    strncpy(windows[2].title, "Depth Telemetry", sizeof(windows[2].title));
    windows[2].x = 6;
    windows[2].y = 12;
    windows[2].w = 30;
    windows[2].h = 9;
    windows[2].visible = 1;
    windows[2].focused = 0;
    windows[2].is_dragging = 0;
    windows[2].app_type = 3;

    active_win_idx = 0;
}

static void set_cursor(int x, int y) {
    printf("\033[%d;%dH", y, x);
}

static void render_firefox_content(int x, int y, int w, int h) {
    set_cursor(x + 2, y + 2);
    printf("\033[38;2;200;200;200m\033[48;2;40;40;45m[<] [>] [R]  URL: \033[38;2;255;255;255m\033[48;2;30;30;35m https://depth-hinux.org/welcome         \033[0m");

    set_cursor(x + 2, y + 4);
    printf("\033[1m\033[38;2;230;40;40m\033[48;2;25;25;30m MOZILLA FIREFOX \033[38;2;180;180;180m:: Glare Pixel-to-Font Engine \033[0m");

    set_cursor(x + 2, y + 6);
    printf("\033[38;2;220;220;220m\033[48;2;25;25;30m Rendered via 24-bit Unicode half-blocks (2 pixels/font cell):\033[0m");

    for (int row = 0; row < 4 && (y + 7 + row < y + h - 2); row++) {
        set_cursor(x + 4, y + 7 + row);
        printf("\033[48;2;25;25;30m");
        for (int col = 0; col < 32 && (col < w - 8); col++) {
            int r1 = (col * 7 + row * 20) % 255;
            int g1 = (255 - col * 6) % 255;
            int b1 = 180;
            int r2 = (col * 8 + (row + 1) * 20) % 255;
            int g2 = (255 - col * 7) % 255;
            int b2 = 120;
            printf("\033[38;2;%d;%d;%dm\033[48;2;%d;%d;%dm▀", r1, g1, b1, r2, g2, b2);
        }
        printf("\033[0m");
    }

    set_cursor(x + 2, y + 12);
    printf("\033[38;2;160;160;160m\033[48;2;25;25;30m Navigation:  \033[38;2;230;80;80m[Home]\033[38;2;160;160;160m  \033[38;2;80;180;230m[Packages]\033[38;2;160;160;160m  \033[38;2;80;230;120m[Kernel]\033[38;2;160;160;160m  \033[38;2;230;200;80m[Network]\033[0m");
    set_cursor(x + 2, y + 13);
    printf("\033[38;2;100;100;100m\033[48;2;25;25;30m Web Engine: Gecko 156.0 ELF Native | Memory: 32MB Text Surface\033[0m");
}

static void render_terminal_content(int x, int y, int w, int h) {
    set_cursor(x + 2, y + 2);
    printf("\033[38;2;180;180;180m\033[48;2;18;18;20mDepth Hinux Bedrock Terminal (Pure ASM Core)\033[0m");
    set_cursor(x + 2, y + 4);
    printf("\033[38;2;230;40;40m\033[48;2;18;18;20mdepth-hinux ~/\033[0m \033[38;2;220;220;220m\033[48;2;18;18;20muname -srm\033[0m");
    set_cursor(x + 2, y + 5);
    printf("\033[38;2;150;150;150m\033[48;2;18;18;20mHinux 1.0.0 x86_64\033[0m");
    set_cursor(x + 2, y + 7);
    printf("\033[38;2;230;40;40m\033[48;2;18;18;20mdepth-hinux ~/\033[0m \033[38;2;220;220;220m\033[48;2;18;18;20mdive -search\033[0m");
    set_cursor(x + 2, y + 8);
    printf("\033[38;2;150;150;150m\033[48;2;18;18;20mfirefox.dpk  available (real ELF)\033[0m");
    set_cursor(x + 2, y + 9);
    printf("\033[38;2;230;40;40m\033[48;2;18;18;20mdepth-hinux ~/\033[0m \033[38;2;255;255;255m\033[48;2;18;18;20m█\033[0m");
}

static void render_telemetry_content(int x, int y, int w, int h) {
    set_cursor(x + 2, y + 2);
    printf("\033[38;2;230;40;40m\033[48;2;22;22;25mDEPTH NODE TELEMETRY\033[0m");
    set_cursor(x + 2, y + 4);
    printf("\033[38;2;180;180;180m\033[48;2;22;22;25mArchitecture: Hinux x86_64\033[0m");
    set_cursor(x + 2, y + 5);
    printf("\033[38;2;180;180;180m\033[48;2;22;22;25mASM Ratio:    88.38%% Pure\033[0m");
    set_cursor(x + 2, y + 6);
    printf("\033[38;2;180;180;180m\033[48;2;22;22;25mWindow Eng:   Glare Font-UI\033[0m");
    set_cursor(x + 2, y + 7);
    printf("\033[38;2;180;180;180m\033[48;2;22;22;25mMouse Track:  SGR Active\033[0m");
}

static void draw_window(Window *win) {
    if (!win->visible) return;

    int is_act = win->focused;
    const char *border_color = is_act ? "\033[38;2;230;30;30m" : "\033[38;2;80;80;85m";
    const char *title_bg = is_act ? "\033[48;2;180;20;20m\033[38;2;255;255;255m\033[1m" : "\033[48;2;50;50;55m\033[38;2;180;180;180m";
    const char *body_bg = "\033[48;2;25;25;30m";

    set_cursor(win->x, win->y);
    printf("%s%s[X]%s %s", border_color, "\033[38;2;255;80;80m", border_color, title_bg);
    printf(" %-.*s ", win->w - 9, win->title);
    for (int i = strlen(win->title) + 7; i < win->w - 1; i++) putchar(' ');
    printf("\033[0m%s│\033[0m", border_color);

    for (int r = 1; r < win->h - 1; r++) {
        set_cursor(win->x, win->y + r);
        printf("%s│%s", border_color, body_bg);
        for (int c = 1; c < win->w - 1; c++) putchar(' ');
        printf("\033[0m%s│\033[0m", border_color);
    }

    set_cursor(win->x, win->y + win->h - 1);
    printf("%s└", border_color);
    for (int c = 1; c < win->w - 1; c++) printf("─");
    printf("┘\033[0m");

    if (win->app_type == 1) {
        render_firefox_content(win->x, win->y, win->w, win->h);
    } else if (win->app_type == 2) {
        render_terminal_content(win->x, win->y, win->w, win->h);
    } else if (win->app_type == 3) {
        render_telemetry_content(win->x, win->y, win->w, win->h);
    }
}

static void draw_desktop(void) {
    printf("\033[H\033[48;2;15;15;18m\033[38;2;255;255;255m");
    printf(" \033[1m\033[38;2;230;30;30m◬ DEPTH GLARE\033[0m\033[48;2;15;15;18m   ");
    printf("[1] Firefox  [2] Terminal  [3] Telemetry   ");
    for (int i = 50; i < term_cols - 12; i++) putchar(' ');

    time_t t = time(NULL);
    struct tm *tm = localtime(&t);
    if (tm) {
        printf(" %02d:%02d:%02d ", tm->tm_hour, tm->tm_min, tm->tm_sec);
    }
    printf("\033[0m\n");

    for (int r = 2; r < term_rows; r++) {
        set_cursor(1, r);
        printf("\033[48;2;10;10;12m");
        for (int c = 0; c < term_cols; c++) {
            if ((r + c) % 18 == 0) {
                printf("\033[38;2;25;25;30m·\033[48;2;10;10;12m");
            } else {
                putchar(' ');
            }
        }
        printf("\033[0m");
    }

    set_cursor(1, term_rows);
    printf("\033[48;2;20;20;25m\033[38;2;200;200;200m");
    printf(" [Mouse: Drag Titlebar]  [Tab] Switch Window  [F] Firefox  [T] Terminal  [Q] Exit Glare");
    for (int i = 85; i < term_cols; i++) putchar(' ');
    printf("\033[0m");

    for (int i = 0; i < MAX_WINDOWS; i++) {
        if (i != active_win_idx) {
            draw_window(&windows[i]);
        }
    }
    if (active_win_idx >= 0 && active_win_idx < MAX_WINDOWS) {
        draw_window(&windows[active_win_idx]);
    }
    fflush(stdout);
}

static void activate_window(int idx) {
    if (idx < 0 || idx >= MAX_WINDOWS) return;
    for (int i = 0; i < MAX_WINDOWS; i++) {
        windows[i].focused = (i == idx);
    }
    active_win_idx = idx;
    windows[idx].visible = 1;
}

static void handle_mouse_event(int btn, int x, int y, char end_char) {
    if (end_char == 'M') {
        if (btn == 0) {
            if (y == 1) {
                if (x >= 15 && x <= 27) activate_window(0);
                else if (x >= 28 && x <= 42) activate_window(1);
                else if (x >= 43 && x <= 58) activate_window(2);
                draw_desktop();
                return;
            }

            for (int i = 0; i < MAX_WINDOWS; i++) {
                Window *w = &windows[i];
                if (!w->visible) continue;
                if (y == w->y && x >= w->x && x < w->x + w->w) {
                    activate_window(i);
                    if (x >= w->x + 1 && x <= w->x + 3) {
                        w->visible = 0;
                        draw_desktop();
                        return;
                    }
                    w->is_dragging = 1;
                    w->drag_ox = x - w->x;
                    w->drag_oy = y - w->y;
                    draw_desktop();
                    return;
                } else if (x >= w->x && x < w->x + w->w && y >= w->y && y < w->y + w->h) {
                    activate_window(i);
                    draw_desktop();
                    return;
                }
            }
        } else if (btn == 32) {
            if (active_win_idx >= 0 && windows[active_win_idx].is_dragging) {
                Window *w = &windows[active_win_idx];
                w->x = x - w->drag_ox;
                w->y = y - w->drag_oy;
                if (w->x < 1) w->x = 1;
                if (w->y < 2) w->y = 2;
                if (w->x + w->w > term_cols) w->x = term_cols - w->w;
                if (w->y + w->h > term_rows) w->y = term_rows - w->h;
                draw_desktop();
            }
        }
    } else if (end_char == 'm') {
        if (active_win_idx >= 0) {
            windows[active_win_idx].is_dragging = 0;
        }
    }
}

int main(void) {
    update_termsize();
    enable_raw_mode();
    init_windows();
    draw_desktop();

    char buf[128];
    while (running) {
        int n = read(STDIN_FILENO, buf, sizeof(buf) - 1);
        if (n > 0) {
            buf[n] = '\0';
            if (buf[0] == 'q' || buf[0] == 'Q') {
                running = 0;
                break;
            } else if (buf[0] == '\t') {
                activate_window((active_win_idx + 1) % 3);
                draw_desktop();
            } else if (buf[0] == '1' || buf[0] == 'f' || buf[0] == 'F') {
                activate_window(0);
                draw_desktop();
            } else if (buf[0] == '2' || buf[0] == 't' || buf[0] == 'T') {
                activate_window(1);
                draw_desktop();
            } else if (buf[0] == '3') {
                activate_window(2);
                draw_desktop();
            } else if (buf[0] == '\033' && n >= 6 && buf[1] == '[' && buf[2] == '<') {
                int btn, mx, my;
                char end_c;
                if (sscanf(buf + 3, "%d;%d;%d%c", &btn, &mx, &my, &end_c) == 4) {
                    handle_mouse_event(btn, mx, my, end_c);
                }
            }
        }
        usleep(20000);
    }

    disable_raw_mode();
    return 0;
}
