#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <time.h>
#include <signal.h>
#include <fcntl.h>

#define MAX_COLS 160
#define MAX_ROWS 60
#define MAX_WINDOWS 3

typedef struct {
    char ch[8];
    uint8_t fg_r, fg_g, fg_b;
    uint8_t bg_r, bg_g, bg_b;
    uint8_t bold;
} Cell;

typedef struct {
    int id;
    char title[64];
    int x, y, w, h;
    int visible;
    int is_dragging;
    int drag_ox, drag_oy;
    int app_type;
} Window;

static struct termios orig_termios;
static Cell grid[MAX_ROWS][MAX_COLS];
static int term_cols = 80;
static int term_rows = 25;
static Window windows[MAX_WINDOWS];
static int win_zorder[MAX_WINDOWS];
static int active_win_id = 0;
static int menu_open = 0;
static int running = 1;

static void disable_raw_mode(void) {
    printf("\033[?1000l\033[?1002l\033[?1006l");
    printf("\033[?25h\033[0m\033[2J\033[H\033[3J");
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
        if (term_cols > MAX_COLS) term_cols = MAX_COLS;
        if (term_rows > MAX_ROWS) term_rows = MAX_ROWS;
    } else {
        term_cols = 80;
        term_rows = 25;
    }
}

static void set_cell(int r, int c, const char *glyph, uint8_t fr, uint8_t fg, uint8_t fb, uint8_t br, uint8_t bg, uint8_t bb, uint8_t bold) {
    if (r < 0 || r >= term_rows || c < 0 || c >= term_cols) return;
    strncpy(grid[r][c].ch, glyph, sizeof(grid[r][c].ch) - 1);
    grid[r][c].ch[sizeof(grid[r][c].ch) - 1] = '\0';
    grid[r][c].fg_r = fr;
    grid[r][c].fg_g = fg;
    grid[r][c].fg_b = fb;
    grid[r][c].bg_r = br;
    grid[r][c].bg_g = bg;
    grid[r][c].bg_b = bb;
    grid[r][c].bold = bold;
}

static void draw_text(int r, int c, const char *str, uint8_t fr, uint8_t fg, uint8_t fb, uint8_t br, uint8_t bg, uint8_t bb, uint8_t bold, int max_len) {
    int len = 0;
    while (*str && (max_len < 0 || len < max_len)) {
        if (c + len >= term_cols) break;
        char buf[2] = {*str, '\0'};
        set_cell(r, c + len, buf, fr, fg, fb, br, bg, bb, bold);
        str++;
        len++;
    }
}

static void bring_to_front(int win_idx) {
    int found = -1;
    for (int i = 0; i < MAX_WINDOWS; i++) {
        if (win_zorder[i] == win_idx) {
            found = i;
            break;
        }
    }
    if (found >= 0) {
        for (int i = found; i < MAX_WINDOWS - 1; i++) {
            win_zorder[i] = win_zorder[i + 1];
        }
        win_zorder[MAX_WINDOWS - 1] = win_idx;
    }
    active_win_id = win_idx;
    windows[win_idx].visible = 1;
}

static void init_windows(void) {
    windows[0].id = 0;
    strncpy(windows[0].title, "Nemo 6.6 - /root", sizeof(windows[0].title));
    windows[0].x = 4;
    windows[0].y = 2;
    windows[0].w = 40;
    windows[0].h = 13;
    windows[0].visible = 1;
    windows[0].is_dragging = 0;
    windows[0].app_type = 0;

    windows[1].id = 1;
    strncpy(windows[1].title, "Mozilla Firefox 156.0 - Cinnamon", sizeof(windows[1].title));
    windows[1].x = 22;
    windows[1].y = 4;
    windows[1].w = 54;
    windows[1].h = 14;
    windows[1].visible = 1;
    windows[1].is_dragging = 0;
    windows[1].app_type = 1;

    windows[2].id = 2;
    strncpy(windows[2].title, "depth-hinux [Terminal]", sizeof(windows[2].title));
    windows[2].x = 36;
    windows[2].y = 9;
    windows[2].w = 41;
    windows[2].h = 13;
    windows[2].visible = 1;
    windows[2].is_dragging = 0;
    windows[2].app_type = 2;

    win_zorder[0] = 0;
    win_zorder[1] = 1;
    win_zorder[2] = 2;
    active_win_id = 2;
}

static void render_desktop_background(void) {
    for (int r = 0; r < term_rows; r++) {
        for (int c = 0; c < term_cols; c++) {
            if ((r + c) % 14 == 0) {
                set_cell(r, c, ".", 35, 40, 48, 18, 20, 24, 0);
            } else {
                set_cell(r, c, " ", 0, 0, 0, 18, 20, 24, 0);
            }
        }
    }
}

static void render_cinnamon_panel(void) {
    int p_row = term_rows - 1;
    for (int c = 0; c < term_cols; c++) {
        set_cell(p_row, c, " ", 0, 0, 0, 22, 25, 30, 0);
    }

    if (menu_open) {
        draw_text(p_row, 0, " [ Menu ] ", 255, 255, 255, 118, 184, 82, 1, -1);
    } else {
        draw_text(p_row, 0, " [ Menu ] ", 118, 184, 82, 22, 25, 30, 1, -1);
    }

    draw_text(p_row, 11, "[1: Nemo]", active_win_id == 0 ? 255 : 170, active_win_id == 0 ? 255 : 170, active_win_id == 0 ? 255 : 180, active_win_id == 0 ? 55 : 22, active_win_id == 0 ? 60 : 25, active_win_id == 0 ? 70 : 30, active_win_id == 0 ? 1 : 0, -1);
    draw_text(p_row, 22, "[2: Firefox]", active_win_id == 1 ? 255 : 170, active_win_id == 1 ? 255 : 170, active_win_id == 1 ? 255 : 180, active_win_id == 1 ? 55 : 22, active_win_id == 1 ? 60 : 25, active_win_id == 1 ? 70 : 30, active_win_id == 1 ? 1 : 0, -1);
    draw_text(p_row, 36, "[3: Terminal]", active_win_id == 2 ? 255 : 170, active_win_id == 2 ? 255 : 170, active_win_id == 2 ? 255 : 180, active_win_id == 2 ? 55 : 22, active_win_id == 2 ? 60 : 25, active_win_id == 2 ? 70 : 30, active_win_id == 2 ? 1 : 0, -1);

    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    char time_str[32] = "12:00:00";
    if (tm_info) {
        strftime(time_str, sizeof(time_str), "%H:%M:%S", tm_info);
    }

    char tray_str[64];
    snprintf(tray_str, sizeof(tray_str), "[NET] [VOL]  %s  [Q]", time_str);
    int tray_len = strlen(tray_str);
    draw_text(p_row, term_cols - tray_len - 1, tray_str, 200, 205, 215, 22, 25, 30, 0, -1);
}

static void render_cinnamon_menu(void) {
    if (!menu_open) return;
    int mw = 32;
    int mh = 10;
    int mx = 1;
    int my = term_rows - 1 - mh;
    if (my < 1) my = 1;

    for (int r = my; r < my + mh; r++) {
        for (int c = mx; c < mx + mw; c++) {
            set_cell(r, c, " ", 0, 0, 0, 28, 32, 40, 0);
        }
    }

    draw_text(my, mx + 1, "+--- Cinnamon 6.6 ---+", 118, 184, 82, 28, 32, 40, 1, mw - 2);
    draw_text(my + 1, mx + 2, "[1] Nemo File Manager", 220, 225, 235, 28, 32, 40, 0, mw - 4);
    draw_text(my + 2, mx + 2, "[2] Mozilla Firefox", 220, 225, 235, 28, 32, 40, 0, mw - 4);
    draw_text(my + 3, mx + 2, "[3] Depth Terminal", 220, 225, 235, 28, 32, 40, 0, mw - 4);
    draw_text(my + 4, mx + 2, "[4] Cinnamon Settings", 220, 225, 235, 28, 32, 40, 0, mw - 4);
    draw_text(my + 5, mx + 2, "[5] Dive Package Hub", 220, 225, 235, 28, 32, 40, 0, mw - 4);
    draw_text(my + 6, mx + 2, "---------------------", 60, 65, 75, 28, 32, 40, 0, mw - 4);
    draw_text(my + 7, mx + 2, "[X] Launch X11 Session", 100, 200, 255, 28, 32, 40, 1, mw - 4);
    draw_text(my + 8, mx + 2, "[Q] Shutdown System", 240, 70, 70, 28, 32, 40, 1, mw - 4);
}

static void render_window(Window *w, int is_active) {
    if (!w->visible) return;

    uint8_t t_bg_r = is_active ? 43 : 30;
    uint8_t t_bg_g = is_active ? 48 : 33;
    uint8_t t_bg_b = is_active ? 58 : 39;

    uint8_t t_fg_r = is_active ? 255 : 180;
    uint8_t t_fg_g = is_active ? 255 : 185;
    uint8_t t_fg_b = is_active ? 255 : 190;

    uint8_t b_fg_r = is_active ? 118 : 60;
    uint8_t b_fg_g = is_active ? 184 : 65;
    uint8_t b_fg_b = is_active ? 82 : 75;

    uint8_t in_bg_r = 22;
    uint8_t in_bg_g = 24;
    uint8_t in_bg_b = 29;

    for (int r = w->y; r < w->y + w->h; r++) {
        for (int c = w->x; c < w->x + w->w; c++) {
            if (r == w->y) {
                set_cell(r, c, " ", t_fg_r, t_fg_g, t_fg_b, t_bg_r, t_bg_g, t_bg_b, 0);
            } else if (r == w->y + w->h - 1) {
                if (c == w->x) set_cell(r, c, "+", b_fg_r, b_fg_g, b_fg_b, in_bg_r, in_bg_g, in_bg_b, 1);
                else if (c == w->x + w->w - 1) set_cell(r, c, "+", b_fg_r, b_fg_g, b_fg_b, in_bg_r, in_bg_g, in_bg_b, 1);
                else set_cell(r, c, "-", b_fg_r, b_fg_g, b_fg_b, in_bg_r, in_bg_g, in_bg_b, 0);
            } else {
                if (c == w->x || c == w->x + w->w - 1) {
                    set_cell(r, c, "|", b_fg_r, b_fg_g, b_fg_b, in_bg_r, in_bg_g, in_bg_b, 1);
                } else {
                    set_cell(r, c, " ", 0, 0, 0, in_bg_r, in_bg_g, in_bg_b, 0);
                }
            }
        }
    }

    set_cell(w->y, w->x + 1, "[", 200, 200, 200, t_bg_r, t_bg_g, t_bg_b, 0);
    set_cell(w->y, w->x + 2, "X", 255, 90, 90, t_bg_r, t_bg_g, t_bg_b, 1);
    set_cell(w->y, w->x + 3, "]", 200, 200, 200, t_bg_r, t_bg_g, t_bg_b, 0);

    draw_text(w->y, w->x + 5, w->title, t_fg_r, t_fg_g, t_fg_b, t_bg_r, t_bg_g, t_bg_b, is_active ? 1 : 0, w->w - 7);

    if (w->app_type == 0) {
        draw_text(w->y + 2, w->x + 2, "Path: /root", 118, 184, 82, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 3, w->x + 2, "------------------------------------", 50, 55, 65, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 4);
        draw_text(w->y + 4, w->x + 3, "[DIR]  Desktop", 100, 180, 255, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 5);
        draw_text(w->y + 5, w->x + 3, "[DIR]  Documents", 100, 180, 255, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 5);
        draw_text(w->y + 6, w->x + 3, "[DIR]  Downloads", 100, 180, 255, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 5);
        draw_text(w->y + 7, w->x + 3, "[DIR]  packages", 100, 180, 255, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 5);
        draw_text(w->y + 8, w->x + 3, "[FILE] depth.conf", 220, 220, 230, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 5);
        draw_text(w->y + 9, w->x + 3, "[FILE] welcome.txt", 220, 220, 230, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 5);
        draw_text(w->y + 11, w->x + 2, "Nemo 6.6 | 6 Items | 240 GB Free", 140, 145, 155, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 4);
    } else if (w->app_type == 1) {
        for (int c = w->x + 2; c < w->x + w->w - 2; c++) {
            set_cell(w->y + 2, c, " ", 0, 0, 0, 34, 38, 46, 0);
        }
        draw_text(w->y + 2, w->x + 3, "[<] [>] [R]  URL: https://depth-hinux.org/welcome", 220, 220, 230, 34, 38, 46, 0, w->w - 6);
        draw_text(w->y + 4, w->x + 3, "MOZILLA FIREFOX 156.0", 255, 90, 90, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 6);
        draw_text(w->y + 4, w->x + 26, ":: Cinnamon Glare Edition", 170, 175, 185, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 28);
        draw_text(w->y + 5, w->x + 3, "24-bit half-block surface (2 vertical subpixels/cell):", 160, 165, 175, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 6);

        for (int pr = 0; pr < 3 && (w->y + 6 + pr < w->y + w->h - 3); pr++) {
            for (int pc = 0; pc < 46 && (w->x + 3 + pc < w->x + w->w - 3); pc++) {
                uint8_t r1 = (pc * 5 + pr * 30) % 255;
                uint8_t g1 = (255 - pc * 4) % 255;
                uint8_t b1 = 160;
                uint8_t r2 = (pc * 6 + (pr + 1) * 30) % 255;
                uint8_t g2 = (255 - pc * 5) % 255;
                uint8_t b2 = 100;
                set_cell(w->y + 6 + pr, w->x + 3 + pc, "\xe2\x96\x80", r1, g1, b1, r2, g2, b2, 0);
            }
        }

        draw_text(w->y + 10, w->x + 3, "[ Home ]   [ Packages ]   [ Kernel ]   [ Network ]", 118, 184, 82, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 6);
        draw_text(w->y + 11, w->x + 3, "Gecko 156.0 Native ELF | Status: Online", 130, 135, 145, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 6);
    } else if (w->app_type == 2) {
        draw_text(w->y + 2, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 4);
        draw_text(w->y + 2, w->x + 17, "uname -srm", 220, 220, 220, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 19);
        draw_text(w->y + 3, w->x + 2, "Hinux 1.0.0 x86_64", 160, 160, 170, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 4);

        draw_text(w->y + 5, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 4);
        draw_text(w->y + 5, w->x + 17, "dive -search cinnamon", 220, 220, 220, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 19);
        draw_text(w->y + 6, w->x + 2, "cinnamon.dpk  available (real ELF)", 160, 160, 170, in_bg_r, in_bg_g, in_bg_b, 0, w->w - 4);

        draw_text(w->y + 8, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, w->w - 4);
        set_cell(w->y + 8, w->x + 17, " ", 0, 0, 0, 255, 255, 255, 0);
    }
}

static void flush_grid(void) {
    char out_buf[65536];
    int pos = 0;

    pos += snprintf(out_buf + pos, sizeof(out_buf) - pos, "\033[H");

    int last_fr = -1, last_fg = -1, last_fb = -1;
    int last_br = -1, last_bg = -1, last_bb = -1;
    int last_bold = -1;

    for (int r = 0; r < term_rows; r++) {
        for (int c = 0; c < term_cols; c++) {
            Cell *cl = &grid[r][c];

            int color_changed = (cl->fg_r != last_fr || cl->fg_g != last_fg || cl->fg_b != last_fb ||
                                 cl->bg_r != last_br || cl->bg_g != last_bg || cl->bg_b != last_bb ||
                                 cl->bold != last_bold);

            if (color_changed) {
                pos += snprintf(out_buf + pos, sizeof(out_buf) - pos,
                                "\033[%d;38;2;%d;%d;%dm\033[48;2;%d;%d;%dm",
                                cl->bold ? 1 : 22,
                                cl->fg_r, cl->fg_g, cl->fg_b,
                                cl->bg_r, cl->bg_g, cl->bg_b);
                last_fr = cl->fg_r; last_fg = cl->fg_g; last_fb = cl->fg_b;
                last_br = cl->bg_r; last_bg = cl->bg_g; last_bb = cl->bg_b;
                last_bold = cl->bold;
            }

            const char *glyph = cl->ch[0] ? cl->ch : " ";
            int glen = strlen(glyph);
            if (pos + glen + 16 < (int)sizeof(out_buf)) {
                memcpy(out_buf + pos, glyph, glen);
                pos += glen;
            }
        }
        if (r < term_rows - 1 && pos + 4 < (int)sizeof(out_buf)) {
            out_buf[pos++] = '\n';
        }
    }

    pos += snprintf(out_buf + pos, sizeof(out_buf) - pos, "\033[0m");
    write(STDOUT_FILENO, out_buf, pos);
}

static void draw_all(void) {
    update_termsize();
    render_desktop_background();
    for (int i = 0; i < MAX_WINDOWS; i++) {
        int win_idx = win_zorder[i];
        render_window(&windows[win_idx], win_idx == active_win_id);
    }
    render_cinnamon_panel();
    render_cinnamon_menu();
    flush_grid();
}

static void handle_mouse_event(int b, int x, int y, char state) {
    if (state == 'm') {
        for (int i = 0; i < MAX_WINDOWS; i++) {
            if (windows[i].is_dragging) {
                windows[i].x = x - windows[i].drag_ox;
                windows[i].y = y - windows[i].drag_oy;
                if (windows[i].x < 0) windows[i].x = 0;
                if (windows[i].y < 0) windows[i].y = 0;
                if (windows[i].x + windows[i].w > term_cols) windows[i].x = term_cols - windows[i].w;
                if (windows[i].y + windows[i].h > term_rows - 1) windows[i].y = term_rows - 1 - windows[i].h;
            }
        }
        return;
    }

    if (state == 'M') {
        for (int i = 0; i < MAX_WINDOWS; i++) {
            windows[i].is_dragging = 0;
        }
        return;
    }

    if (b == 0 && state == 'M') {
        return;
    }

    if (y == term_rows - 1) {
        if (x < 10) {
            menu_open = !menu_open;
            return;
        } else if (x >= 11 && x < 21) {
            bring_to_front(0);
            return;
        } else if (x >= 22 && x < 35) {
            bring_to_front(1);
            return;
        } else if (x >= 36 && x < 50) {
            bring_to_front(2);
            return;
        }
    }

    if (menu_open) {
        menu_open = 0;
    }

    for (int i = MAX_WINDOWS - 1; i >= 0; i--) {
        int win_idx = win_zorder[i];
        Window *w = &windows[win_idx];
        if (!w->visible) continue;

        if (x >= w->x && x < w->x + w->w && y >= w->y && y < w->y + w->h) {
            bring_to_front(win_idx);
            if (y == w->y) {
                if (x >= w->x + 1 && x <= w->x + 3) {
                    w->visible = 0;
                } else {
                    w->is_dragging = 1;
                    w->drag_ox = x - w->x;
                    w->drag_oy = y - w->y;
                }
            }
            return;
        }
    }
}

int main(int argc, char **argv) {
    if (argc > 1 && strcmp(argv[1], "--x11") == 0) {
        if (getenv("DISPLAY") && access("/usr/bin/cinnamon-session", X_OK) == 0) {
            char *cin_args[] = {"/usr/bin/cinnamon-session", NULL};
            execv("/usr/bin/cinnamon-session", cin_args);
        }
    }

    enable_raw_mode();
    init_windows();
    draw_all();

    char buf[128];
    while (running) {
        int n = read(STDIN_FILENO, buf, sizeof(buf) - 1);
        if (n <= 0) break;
        buf[n] = '\0';

        int idx = 0;
        while (idx < n) {
            if (buf[idx] == '\033' && idx + 2 < n && buf[idx + 1] == '[' && buf[idx + 2] == '<') {
                int end = idx + 3;
                while (end < n && buf[end] != 'm' && buf[end] != 'M') end++;
                if (end < n) {
                    char term_type = buf[end];
                    buf[end] = '\0';
                    int mb, mx, my;
                    if (sscanf(buf + idx + 3, "%d;%d;%d", &mb, &mx, &my) == 3) {
                        handle_mouse_event(mb, mx - 1, my - 1, term_type);
                        draw_all();
                    }
                    idx = end + 1;
                    continue;
                }
            }

            char c = buf[idx];
            if (c == 'q' || c == 'Q') {
                running = 0;
            } else if (c == 't' || c == 'T' || c == 9) {
                active_win_id = (active_win_id + 1) % MAX_WINDOWS;
                bring_to_front(active_win_id);
                draw_all();
            } else if (c == 'm' || c == 'M') {
                menu_open = !menu_open;
                draw_all();
            } else if (c >= '1' && c <= '3') {
                bring_to_front(c - '1');
                draw_all();
            } else if (c == 'x' || c == 'X') {
                if (access("/usr/bin/cinnamon-session", X_OK) == 0) {
                    disable_raw_mode();
                    char *c_args[] = {"/usr/bin/cinnamon-session", NULL};
                    execv("/usr/bin/cinnamon-session", c_args);
                }
            }
            idx++;
        }
    }

    disable_raw_mode();
    return 0;
}
