#include <locale.h>
#include <ncursesw/curses.h>
#include <glib.h>
#include "disk.h"
#include "plan.h"

static void banner(void) {
    erase();
    attron(COLOR_PAIR(1) | A_BOLD);
    mvprintw(1, 3, "V E N O M   O S");
    attroff(COLOR_PAIR(1) | A_BOLD);
    mvprintw(2, 3, "INSTALADOR OFFLINE  |  MODO TEXTO");
    mvhline(3, 2, ACS_HLINE, COLS - 4);
}

static int menu(const char *title, const char *const *items, int count) {
    int selected = 0, key;
    while (1) {
        banner();
        mvprintw(5, 4, "%s", title);
        for (int i = 0; i < count; i++) {
            if (i == selected) attron(A_REVERSE | COLOR_PAIR(2));
            mvprintw(7 + i * 2, 6, "%s", items[i]);
            if (i == selected) attroff(A_REVERSE | COLOR_PAIR(2));
        }
        mvhline(LINES - 3, 2, ACS_HLINE, COLS - 4);
        mvprintw(LINES - 2, 4, "↑/↓ navegar   ENTER selecionar   Q voltar/sair");
        refresh();
        key = getch();
        if (key == KEY_UP && selected > 0) selected--;
        else if (key == KEY_DOWN && selected < count - 1) selected++;
        else if (key == '\n' || key == KEY_ENTER) return selected;
        else if (key == 'q' || key == 'Q') return -1;
    }
}

static void message(const char *title, const char *body) {
    int key;
    banner();
    mvprintw(5, 4, "%s", title);
    mvprintw(7, 4, "%s", body);
    mvprintw(LINES - 2, 4, "Pressione qualquer tecla para continuar");
    refresh();
    key = getch();
    (void) key;
}

static void show_disks(void) {
    GError *error = NULL;
    GPtrArray *disks = venom_disk_enumerate(&error);
    banner();
    mvprintw(5, 4, "DISCOS DETECTADOS (SOMENTE LEITURA)");
    if (disks == NULL) {
        mvprintw(7, 4, "Falha ao consultar discos: %s",
                 error ? error->message : "erro desconhecido");
    } else if (disks->len == 0) {
        mvprintw(7, 4, "Nenhum disco local encontrado.");
    } else {
        for (guint i = 0; i < disks->len && i < (guint)(LINES - 11); i++) {
            VenomDisk *d = g_ptr_array_index(disks, i);
            gchar *size = g_format_size(d->size_bytes);
            mvprintw(7 + (int)i, 4, "%-14s %-24s %10s %s",
                     d->path, d->model, size,
                     d->read_only ? "[SOMENTE LEITURA]" : "");
            g_free(size);
        }
    }
    mvprintw(LINES - 2, 4, "Nenhum disco foi alterado. Pressione uma tecla.");
    refresh();
    getch();
    if (disks) g_ptr_array_unref(disks);
    g_clear_error(&error);
}

int main(void) {
    const char *const editions[] = {"VENOM OS XFCE", "VENOM OS MATE"};
    const char *const actions[] = {
        "Selecionar edição", "Detectar discos", "Idioma e teclado",
        "Sobre a instalação offline", "Sair"
    };
    const char *const locales[] = {
        "Português do Brasil (pt_BR.UTF-8)", "English (US)"
    };
    const char *const keyboards[] = {"Brasil ABNT2", "English US"};
    int edition = 1;
    setlocale(LC_ALL, "");
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(0);
    if (has_colors()) {
        start_color();
        use_default_colors();
        init_pair(1, COLOR_CYAN, -1);
        init_pair(2, COLOR_WHITE, COLOR_BLUE);
    }

    while (1) {
        int choice = menu("PAINEL PRINCIPAL", actions, 5);
        if (choice < 0 || choice == 4) break;
        if (choice == 0) {
            int selected = menu("ESCOLHA A EDICAO", editions, 2);
            if (selected >= 0) edition = selected;
        } else if (choice == 1) {
            show_disks();
        } else if (choice == 2) {
            int lang = menu("IDIOMA", locales, 2);
            if (lang >= 0) {
                int kb = menu("LAYOUT DO TECLADO", keyboards, 2);
                if (kb >= 0)
                    message("PREFERENCIAS", lang == 0 && kb == 0
                        ? "Português do Brasil + ABNT2 selecionados."
                        : "Preferencias selecionadas para esta sessao de demonstracao.");
            }
        } else if (choice == 3) {
            message("INSTALACAO OFFLINE",
                "A midia devera conter o repositorio local assinado e todas as dependencias.\n"
                "Esta etapa ainda nao instala pacotes nem grava no disco.");
        }
    }
    endwin();
    g_print("Edicao selecionada nesta sessao: %s\n",
            editions[edition]);
    return 0;
}
