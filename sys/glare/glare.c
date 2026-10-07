#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

static void set_depth_wallpaper(void) {
    Display *dpy = NULL;
    for (int i = 0; i < 20; i++) {
        dpy = XOpenDisplay(":0");
        if (dpy) break;
        usleep(50000);
    }
    if (!dpy) return;
    int scr = DefaultScreen(dpy);
    Window root = RootWindow(dpy, scr);
    int w = DisplayWidth(dpy, scr);
    int h = DisplayHeight(dpy, scr);
    if (w <= 0 || h <= 0) {
        w = 1024;
        h = 768;
    }
    int d = DefaultDepth(dpy, scr);
    Visual *vis = DefaultVisual(dpy, scr);
    Pixmap pm = XCreatePixmap(dpy, root, w, h, d);
    GC gc = XCreateGC(dpy, pm, 0, NULL);
    XImage *img = XCreateImage(dpy, vis, d, ZPixmap, 0, NULL, w, h, 32, 0);
    if (!img) {
        XFreeGC(dpy, gc);
        XFreePixmap(dpy, pm);
        XCloseDisplay(dpy);
        return;
    }
    img->data = malloc(img->bytes_per_line * h);
    if (!img->data) {
        XDestroyImage(img);
        XFreeGC(dpy, gc);
        XFreePixmap(dpy, pm);
        XCloseDisplay(dpy);
        return;
    }
    for (int y = 0; y < h; y++) {
        float yr = (float)y / (float)(h > 1 ? h - 1 : 1);
        for (int x = 0; x < w; x++) {
            float xr = (float)x / (float)(w > 1 ? w - 1 : 1);
            float t = (xr + yr) * 0.5f;
            int r = (int)((1.0f - t) * 220.0f + t * 8.0f);
            int g = (int)((1.0f - t) * 20.0f + t * 8.0f);
            int b = (int)((1.0f - t) * 20.0f + t * 12.0f);
            unsigned long pixel = ((unsigned long)(r & 0xff) << 16) |
                                  ((unsigned long)(g & 0xff) << 8) |
                                  ((unsigned long)(b & 0xff));
            XPutPixel(img, x, y, pixel);
        }
    }
    XPutImage(dpy, pm, gc, img, 0, 0, 0, 0, w, h);
    XDestroyImage(img);
    XFreeGC(dpy, gc);
    Atom p_root = XInternAtom(dpy, "_XROOTPMAP_ID", False);
    Atom p_eset = XInternAtom(dpy, "ESETROOT_PMAP_ID", False);
    XChangeProperty(dpy, root, p_root, XA_PIXMAP, 32, PropModeReplace, (unsigned char *)&pm, 1);
    XChangeProperty(dpy, root, p_eset, XA_PIXMAP, 32, PropModeReplace, (unsigned char *)&pm, 1);
    XSetWindowBackgroundPixmap(dpy, root, pm);
    XClearWindow(dpy, root);
    XSetCloseDownMode(dpy, RetainPermanent);
    XFlush(dpy);
    XCloseDisplay(dpy);
}

int main(int argc, char **argv) {
    printf("\n\033[1;32m[GLARE]\033[0m Initializing Cinnamon Desktop Environment on Depth Hinux...\n");
    fflush(stdout);

    setenv("DISPLAY", ":0", 1);
    setenv("XDG_CURRENT_DESKTOP", "X-Cinnamon", 1);
    setenv("DESKTOP_SESSION", "cinnamon", 1);
    setenv("XDG_SESSION_DESKTOP", "cinnamon", 1);
    setenv("XDG_SESSION_TYPE", "x11", 1);
    setenv("XDG_DATA_DIRS", "/usr/share:/usr/local/share", 1);
    setenv("XDG_CONFIG_DIRS", "/etc/xdg", 1);
    setenv("CINNAMON_2D", "1", 1);
    setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
    setenv("GALLIUM_DRIVER", "llvmpipe", 1);
    setenv("LP_NUM_THREADS", "4", 1);
    setenv("MESA_LOADER_DRIVER_OVERRIDE", "kms_swrast", 1);
    setenv("COGL_DRIVER", "gl", 1);
    setenv("CLUTTER_PAINT", "disable-culling", 1);
    setenv("CLUTTER_DEFAULT_FPS", "60", 1);
    setenv("CLUTTER_VBLANK", "none", 1);
    setenv("CINNAMON_SLOWDOWN_FACTOR", "1.0", 1);
    setenv("MUFFIN_NO_SHADOWS", "1", 1);
    setenv("NO_AT_BRIDGE", "1", 1);
    setenv("LANG", "C.UTF-8", 1);
    setenv("LC_ALL", "C.UTF-8", 1);
    setenv("HOME", "/root", 1);
    setenv("USER", "root", 1);
    setenv("LOGNAME", "root", 1);
    setenv("SHELL", "/bin/bash", 1);
    setenv("GI_TYPELIB_PATH", "/usr/lib/cinnamon:/usr/lib/muffin:/usr/lib/cjs/girepository-1.0:/usr/lib/girepository-1.0", 1);
    setenv("LD_LIBRARY_PATH", "/usr/lib/cinnamon:/usr/lib/muffin:/usr/lib:/usr/lib64", 1);
    setenv("PYTHONPATH", "/usr/lib/python3.14:/usr/lib/python3.14/site-packages", 1);
    setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin:/usr/lib/cinnamon-settings-daemon", 1);

    mkdir("/tmp/.X11-unix", 01777);
    chmod("/tmp/.X11-unix", 01777);
    mkdir("/run/user", 0755);
    mkdir("/run/user/0", 0700);
    chmod("/run/user/0", 0700);
    mkdir("/run/user/0/dconf", 0700);
    mkdir("/root/.config", 0755);
    mkdir("/root/.config/cinnamon-session", 0755);
    mkdir("/root/.config/dconf", 0700);
    mkdir("/run/dbus", 0755);
    mkdir("/var/run/dbus", 0755);
    mkdir("/var/lib", 0755);
    mkdir("/var/lib/dbus", 0755);
    if (access("/etc/machine-id", F_OK) != 0) {
        FILE *fmid = fopen("/etc/machine-id", "w");
        if (fmid) {
            fputs("9b8f2a1e0d3c4b5a6978123456789abc\n", fmid);
            fclose(fmid);
        }
    }
    if (access("/var/lib/dbus/machine-id", F_OK) != 0) {
        FILE *fdbusmid = fopen("/var/lib/dbus/machine-id", "w");
        if (fdbusmid) {
            fputs("9b8f2a1e0d3c4b5a6978123456789abc\n", fdbusmid);
            fclose(fdbusmid);
        }
    }
    setenv("XDG_RUNTIME_DIR", "/run/user/0", 1);
    setenv("DBUS_SESSION_BUS_ADDRESS", "unix:path=/run/user/0/bus", 1);

    mkdir("/run/udev", 0755);
    if (access("/usr/lib/systemd/systemd-udevd", X_OK) == 0) {
        pid_t u_pid = fork();
        if (u_pid == 0) {
            char *u_args[] = {"/usr/lib/systemd/systemd-udevd", "--daemon", NULL};
            execv("/usr/lib/systemd/systemd-udevd", u_args);
            exit(0);
        }
        if (u_pid > 0) waitpid(u_pid, NULL, 0);
        usleep(100000);
        if (access("/usr/bin/udevadm", X_OK) == 0) {
            pid_t t_pid = fork();
            if (t_pid == 0) {
                char *t_args[] = {"/usr/bin/udevadm", "trigger", "--action=add", NULL};
                execv("/usr/bin/udevadm", t_args);
                exit(0);
            }
            if (t_pid > 0) waitpid(t_pid, NULL, 0);
            pid_t s_pid = fork();
            if (s_pid == 0) {
                char *s_args[] = {"/usr/bin/udevadm", "settle", "--timeout=2", NULL};
                execv("/usr/bin/udevadm", s_args);
                exit(0);
            }
            if (s_pid > 0) waitpid(s_pid, NULL, 0);
        }
    }

    if (access("/usr/bin/dbus-daemon", X_OK) == 0) {
        if (access("/run/dbus/system_bus_socket", F_OK) != 0) {
            pid_t d_pid = fork();
            if (d_pid == 0) {
                char *d_args[] = {"/usr/bin/dbus-daemon", "--system", "--fork", NULL};
                execv("/usr/bin/dbus-daemon", d_args);
                exit(0);
            }
            if (d_pid > 0) waitpid(d_pid, NULL, 0);
        }
        if (access("/run/user/0/bus", F_OK) != 0) {
            pid_t s_pid = fork();
            if (s_pid == 0) {
                char *s_args[] = {
                    "/usr/bin/dbus-daemon",
                    "--session",
                    "--fork",
                    "--address=unix:path=/run/user/0/bus",
                    NULL
                };
                execv("/usr/bin/dbus-daemon", s_args);
                exit(0);
            }
            if (s_pid > 0) waitpid(s_pid, NULL, 0);
        }
    }

    pid_t xorg_pid = -1;
    if (access("/tmp/.X11-unix/X0", F_OK) != 0) {
        printf("\033[1;34m[GLARE]\033[0m Starting X11 Display Server on /dev/tty1...\n");
        fflush(stdout);
        xorg_pid = fork();
        if (xorg_pid == 0) {
            char *x_args[] = {
                "/usr/lib/Xorg",
                ":0",
                "vt1",
                "-nolisten", "tcp",
                "-noreset",
                "-logfile", "/tmp/Xorg.0.log",
                NULL
            };
            execv("/usr/lib/Xorg", x_args);
            execv("/usr/bin/Xorg", x_args);
            exit(1);
        }
        for (int i = 0; i < 50; i++) {
            usleep(100000);
            if (access("/tmp/.X11-unix/X0", F_OK) == 0) break;
        }
        if (access("/usr/bin/udevadm", X_OK) == 0) {
            pid_t ui_pid = fork();
            if (ui_pid == 0) {
                char *ui_args[] = {"/usr/bin/udevadm", "trigger", "--action=add", "--subsystem-match=input", NULL};
                execv("/usr/bin/udevadm", ui_args);
                exit(0);
            }
            if (ui_pid > 0) waitpid(ui_pid, NULL, 0);
        }
        set_depth_wallpaper();
    }

    usleep(200000);

    if (access("/bin/depth-xsettings", X_OK) == 0) {
        if (fork() == 0) {
            char *csd_args[] = {"/bin/depth-xsettings", NULL};
            execv("/bin/depth-xsettings", csd_args);
            exit(0);
        }
    } else if (access("/usr/lib/cinnamon-settings-daemon/csd-xsettings", X_OK) == 0) {
        if (fork() == 0) {
            char *csd_args[] = {"/usr/lib/cinnamon-settings-daemon/csd-xsettings", NULL};
            execv("/usr/lib/cinnamon-settings-daemon/csd-xsettings", csd_args);
            exit(0);
        }
    }

    if (access("/bin/depth-bgd", X_OK) == 0) {
        if (fork() == 0) {
            char *bg_args[] = {"/bin/depth-bgd", NULL};
            execv("/bin/depth-bgd", bg_args);
            exit(0);
        }
    } else if (access("/usr/lib/cinnamon-settings-daemon/csd-background", X_OK) == 0) {
        if (fork() == 0) {
            char *bg_args[] = {"/usr/lib/cinnamon-settings-daemon/csd-background", NULL};
            execv("/usr/lib/cinnamon-settings-daemon/csd-background", bg_args);
            exit(0);
        }
    }

    if (access("/bin/cinnamon-watchdog", X_OK) == 0) {
        if (fork() == 0) {
            char *wd_args[] = {"/bin/cinnamon-watchdog", NULL};
            execv("/bin/cinnamon-watchdog", wd_args);
            exit(0);
        }
    }

    if (access("/bin/hinux-driverd", X_OK) == 0) {
        if (fork() == 0) {
            char *drv_args[] = {"/bin/hinux-driverd", NULL};
            execv("/bin/hinux-driverd", drv_args);
            exit(0);
        }
    }

    if (access("/usr/lib/dconf-service", X_OK) == 0) {
        if (fork() == 0) {
            char *dc_args[] = {"/usr/lib/dconf-service", NULL};
            execv("/usr/lib/dconf-service", dc_args);
            exit(0);
        }
    }

    if (access("/usr/lib/gnome-terminal-server", X_OK) == 0) {
        if (fork() == 0) {
            char *gt_args[] = {"/usr/lib/gnome-terminal-server", NULL};
            execv("/usr/lib/gnome-terminal-server", gt_args);
            exit(0);
        }
    }

    if (access("/usr/bin/nemo-desktop", X_OK) == 0) {
        if (fork() == 0) {
            char *nemo_args[] = {"/usr/bin/nemo-desktop", NULL};
            execv("/usr/bin/nemo-desktop", nemo_args);
            exit(0);
        }
    }

    set_depth_wallpaper();
    pid_t sess_pid = fork();
    if (sess_pid == 0) {
        if (access("/usr/bin/cinnamon2d", X_OK) == 0) {
            printf("\033[1;32m[GLARE]\033[0m Starting Cinnamon Desktop Shell...\n\n");
            fflush(stdout);
            char *c2d_args[] = {"/usr/bin/cinnamon2d", "--replace", "--x11", "--sm-disable", NULL};
            execv("/usr/bin/cinnamon2d", c2d_args);
            char *cin_args[] = {"/usr/bin/cinnamon", "--replace", "--x11", "--sm-disable", NULL};
            execv("/usr/bin/cinnamon", cin_args);
        } else if (access("/usr/bin/cinnamon", X_OK) == 0) {
            printf("\033[1;32m[GLARE]\033[0m Starting Cinnamon Desktop Environment...\n\n");
            fflush(stdout);
            char *cin_args[] = {"/usr/bin/cinnamon", "--replace", "--x11", "--sm-disable", NULL};
            execv("/usr/bin/cinnamon", cin_args);
        } else if (access("/usr/bin/muffin", X_OK) == 0) {
            printf("\033[1;32m[GLARE]\033[0m Starting Muffin Window Compositor...\n\n");
            fflush(stdout);
            char *muf_args[] = {"/usr/bin/muffin", "--replace", NULL};
            execv("/usr/bin/muffin", muf_args);
        } else {
            printf("\033[1;31m[GLARE]\033[0m Cinnamon desktop packages not found in rootfs.\n");
            printf("Run 'dive -install cinnamon' or compile with 'make glare'.\n\n");
            exit(1);
        }
        exit(1);
    }

    if (sess_pid > 0) {
        int st;
        waitpid(sess_pid, &st, 0);
    }

    if (xorg_pid > 0) {
        kill(xorg_pid, SIGTERM);
        int st;
        waitpid(xorg_pid, &st, 0);
    }

    return 0;
}
