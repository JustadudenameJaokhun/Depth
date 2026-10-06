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
    strncpy(windows[0].title, "Mozilla Firefox 156.0 - Glare Browser", sizeof(windows[0].title));
    windows[0].x = 3;
    windows[0].y = 2;
    windows[0].w = 74;
    windows[0].h = 15;
    windows[0].visible = 1;
    windows[0].is_dragging = 0;
    windows[0].app_type = 0;

    windows[1].id = 1;
    strncpy(windows[1].title, "depth-hinux [Terminal]", sizeof(windows[1].title));
    windows[1].x = 38;
    windows[1].y = 7;
    windows[1].w = 39;
    windows[1].h = 13;
    windows[1].visible = 1;
    windows[1].is_dragging = 0;
    windows[1].app_type = 1;

    windows[2].id = 2;
    strncpy(windows[2].title, "Depth Telemetry", sizeof(windows[2].title));
    windows[2].x = 4;
    windows[2].y = 9;
    windows[2].w = 32;
    windows[2].h = 10;
    windows[2].visible = 1;
    windows[2].is_dragging = 0;
    windows[2].app_type = 2;

    win_zorder[0] = 1;
    win_zorder[1] = 2;
    win_zorder[2] = 0;
    active_win_id = 0;
}

static void render_desktop_background(void) {
    for (int r = 0; r < term_rows; r++) {
        for (int c = 0; c < term_cols; c++) {
            if ((r + c) % 12 == 0) {
                set_cell(r, c, ".", 40, 40, 48, 14, 14, 18, 0);
            } else {
                set_cell(r, c, " ", 0, 0, 0, 14, 14, 18, 0);
            }
        }
    }

    for (int c = 0; c < term_cols; c++) {
        set_cell(0, c, " ", 0, 0, 0, 18, 18, 23, 0);
    }
    draw_text(0, 1, "\xe2\x97\xac DEPTH GLARE", 230, 30, 30, 18, 18, 23, 1, -1);
    draw_text(0, 17, "[1: Firefox]", active_win_id == 0 ? 255 : 160, active_win_id == 0 ? 255 : 160, active_win_id == 0 ? 255 : 170, 18, 18, 23, active_win_id == 0 ? 1 : 0, -1);
    draw_text(0, 31, "[2: Terminal]", active_win_id == 1 ? 255 : 160, active_win_id == 1 ? 255 : 160, active_win_id == 1 ? 255 : 170, 18, 18, 23, active_win_id == 1 ? 1 : 0, -1);
    draw_text(0, 46, "[3: Telemetry]", active_win_id == 2 ? 255 : 160, active_win_id == 2 ? 255 : 160, active_win_id == 2 ? 255 : 170, 18, 18, 23, active_win_id == 2 ? 1 : 0, -1);

    time_t t = time(NULL);
    struct tm *tm = localtime(&t);
    char time_str[16];
    if (tm) {
        snprintf(time_str, sizeof(time_str), "%02d:%02d:%02d", tm->tm_hour, tm->tm_min, tm->tm_sec);
    } else {
        strncpy(time_str, "12:00:00", sizeof(time_str));
    }
    draw_text(0, term_cols - 10, time_str, 200, 200, 210, 18, 18, 23, 0, -1);

    int bot_r = term_rows - 1;
    for (int c = 0; c < term_cols; c++) {
        set_cell(bot_r, c, " ", 0, 0, 0, 22, 22, 28, 0);
    }
    draw_text(bot_r, 1, " [Drag Titlebar: Move]  [Tab: Switch]  [1-3: Focus]  [F: Web]  [T: Term]  [Q: Exit] ", 180, 180, 190, 22, 22, 28, 0, -1);
}

static void render_window(Window *w, int is_active) {
    if (!w->visible) return;

    uint8_t t_bg_r = is_active ? 185 : 42;
    uint8_t t_bg_g = is_active ? 25 : 42;
    uint8_t t_bg_b = is_active ? 25 : 48;
    uint8_t t_fg_r = is_active ? 255 : 180;
    uint8_t t_fg_g = is_active ? 255 : 180;
    uint8_t t_fg_b = is_active ? 255 : 190;

    uint8_t b_fg_r = is_active ? 220 : 65;
    uint8_t b_fg_g = is_active ? 30 : 65;
    uint8_t b_fg_b = is_active ? 30 : 75;

    uint8_t in_bg_r = 22;
    uint8_t in_bg_g = 22;
    uint8_t in_bg_b = 27;

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

    set_cell(w->y, w->x + 1, "[", 255, 80, 80, t_bg_r, t_bg_g, t_bg_b, 1);
    set_cell(w->y, w->x + 2, "X", 255, 255, 255, t_bg_r, t_bg_g, t_bg_b, 1);
    set_cell(w->y, w->x + 3, "]", 255, 80, 80, t_bg_r, t_bg_g, t_bg_b, 1);
    draw_text(w->y, w->x + 5, w->title, t_fg_r, t_fg_g, t_fg_b, t_bg_r, t_bg_g, t_bg_b, is_active ? 1 : 0, w->w - 7);

    if (w->app_type == 0) {
        for (int c = w->x + 2; c < w->x + w->w - 2; c++) {
            set_cell(w->y + 2, c, " ", 0, 0, 0, 32, 32, 38, 0);
        }
        draw_text(w->y + 2, w->x + 3, "[<] [>] [R]  URL: https://depth-hinux.org/welcome", 220, 220, 230, 32, 32, 38, 0, w->w - 6);

        draw_text(w->y + 4, w->x + 3, "MOZILLA FIREFOX 156.0", 240, 50, 50, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 4, w->x + 26, ":: Glare Pixel-to-Font Engine", 170, 170, 180, in_bg_r, in_bg_g, in_bg_b, 0, -1);

        draw_text(w->y + 5, w->x + 3, "24-bit half-block surface (2 vertical subpixels/cell):", 160, 160, 170, in_bg_r, in_bg_g, in_bg_b, 0, -1);

        for (int pr = 0; pr < 4 && (w->y + 6 + pr < w->y + w->h - 3); pr++) {
            for (int pc = 0; pc < 44 && (w->x + 3 + pc < w->x + w->w - 3); pc++) {
                uint8_t r1 = (pc * 6 + pr * 25) % 255;
                uint8_t g1 = (255 - pc * 5) % 255;
                uint8_t b1 = 180;
                uint8_t r2 = (pc * 7 + (pr + 1) * 25) % 255;
                uint8_t g2 = (255 - pc * 6) % 255;
                uint8_t b2 = 120;
                set_cell(w->y + 6 + pr, w->x + 3 + pc, "\xe2\x96\x80", r1, g1, b1, r2, g2, b2, 0);
            }
        }

        draw_text(w->y + 11, w->x + 3, "[ Home ]   [ Packages ]   [ Kernel ]   [ Network ]", 90, 180, 240, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 12, w->x + 3, "Gecko 156.0 Native ELF | SGR Mouse Active | Status: Online", 120, 120, 130, in_bg_r, in_bg_g, in_bg_b, 0, -1);
    } else if (w->app_type == 1) {
        draw_text(w->y + 2, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 2, w->x + 17, "uname -srm", 220, 220, 220, in_bg_r, in_bg_g, in_bg_b, 0, -1);
        draw_text(w->y + 3, w->x + 2, "Hinux 1.0.0 x86_64", 160, 160, 170, in_bg_r, in_bg_g, in_bg_b, 0, -1);

        draw_text(w->y + 5, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 5, w->x + 17, "dive -search", 220, 220, 220, in_bg_r, in_bg_g, in_bg_b, 0, -1);
        draw_text(w->y + 6, w->x + 2, "firefox.dpk  available (real ELF)", 160, 160, 170, in_bg_r, in_bg_g, in_bg_b, 0, -1);

        draw_text(w->y + 8, w->x + 2, "depth-hinux ~/", 230, 30, 30, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        set_cell(w->y + 8, w->x + 17, " ", 0, 0, 0, 255, 255, 255, 0);
    } else if (w->app_type == 2) {
        draw_text(w->y + 2, w->x + 2, "Architecture: Hinux x86_64", 180, 180, 190, in_bg_r, in_bg_g, in_bg_b, 0, -1);
        draw_text(w->y + 3, w->x + 2, "ASM Core:     85.07% Pure", 240, 50, 50, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 4, w->x + 2, "Window Eng:   Glare Font-UI", 180, 180, 190, in_bg_r, in_bg_g, in_bg_b, 0, -1);
        draw_text(w->y + 5, w->x + 2, "Network IP:   eth0 10.0.2.15", 80, 220, 120, in_bg_r, in_bg_g, in_bg_b, 1, -1);
        draw_text(w->y + 6, w->x + 2, "Memory State: 512 MB Active", 180, 180, 190, in_bg_r, in_bg_g, in_bg_b, 0, -1);
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

static void redraw_all(void) {
    render_desktop_background();
    for (int i = 0; i < MAX_WINDOWS; i++) {
        int wid = win_zorder[i];
        render_window(&windows[wid], wid == active_win_id);
    }
    flush_grid();
}

static void handle_mouse_event(int btn, int x, int y, char end_char) {
    int row = y - 1;
    int col = x - 1;

    if (end_char == 'M') {
        if (btn == 0) {
            if (row == 0) {
                if (col >= 17 && col <= 29) bring_to_front(0);
                else if (col >= 31 && col <= 44) bring_to_front(1);
                else if (col >= 46 && col <= 60) bring_to_front(2);
                redraw_all();
                return;
            }

            for (int i = MAX_WINDOWS - 1; i >= 0; i--) {
                int wid = win_zorder[i];
                Window *w = &windows[wid];
                if (!w->visible) continue;

                if (row == w->y && col >= w->x && col < w->x + w->w) {
                    bring_to_front(wid);
                    if (col >= w->x + 1 && col <= w->x + 3) {
                        w->visible = 0;
                        redraw_all();
                        return;
                    }
                    w->is_dragging = 1;
                    w->drag_ox = col - w->x;
                    w->drag_oy = row - w->y;
                    redraw_all();
                    return;
                } else if (col >= w->x && col < w->x + w->w && row >= w->y && row < w->y + w->h) {
                    bring_to_front(wid);
                    redraw_all();
                    return;
                }
            }
        } else if (btn == 32) {
            if (active_win_id >= 0 && windows[active_win_id].is_dragging) {
                Window *w = &windows[active_win_id];
                w->x = col - w->drag_ox;
                w->y = row - w->drag_oy;
                if (w->x < 0) w->x = 0;
                if (w->y < 1) w->y = 1;
                if (w->x + w->w > term_cols) w->x = term_cols - w->w;
                if (w->y + w->h > term_rows - 1) w->y = term_rows - 1 - w->h;
                redraw_all();
            }
        }
    } else if (end_char == 'm') {
        if (active_win_id >= 0) {
            windows[active_win_id].is_dragging = 0;
        }
    }
}

int main(void) {
    update_termsize();
    enable_raw_mode();
    init_windows();
    redraw_all();

    char buf[128];
    while (running) {
        int n = read(STDIN_FILENO, buf, sizeof(buf) - 1);
        if (n == 0) {
            running = 0;
            break;
        }
        if (n > 0) {
            buf[n] = '\0';
            if (buf[0] == 'q' || buf[0] == 'Q') {
                running = 0;
                break;
            } else if (buf[0] == '\t') {
                bring_to_front((active_win_id + 1) % MAX_WINDOWS);
                redraw_all();
            } else if (buf[0] == '1' || buf[0] == 'f' || buf[0] == 'F') {
                bring_to_front(0);
                redraw_all();
            } else if (buf[0] == '2' || buf[0] == 't' || buf[0] == 'T') {
                bring_to_front(1);
                redraw_all();
            } else if (buf[0] == '3') {
                bring_to_front(2);
                redraw_all();
            } else if (buf[0] == '\033' && n >= 6 && buf[1] == '[' && buf[2] == '<') {
                int btn, mx, my;
                char end_c;
                if (sscanf(buf + 3, "%d;%d;%d%c", &btn, &mx, &my, &end_c) == 4) {
                    handle_mouse_event(btn, mx, my, end_c);
                }
            }
        }
        usleep(15000);
    }

    disable_raw_mode();
    return 0;
}
