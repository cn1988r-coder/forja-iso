#include <locale.h>
#include <ncursesw/curses.h>
#include <glib.h>
#include "disk.h"
#include "plan.h"

#define BLUE 1
#define SELECTED 2
#define MUTED 3

static void serpent_art(int y, int x) {
    static const char *const art[] = {
        "             /\\       /\\",
        "        ____/  \\_____/  \\____",
        "       /   _  VENOM OS  _      \\",
        "       \\__/\\_________/\\______/ ",
        "           \\  /\\ /\\  /",
        "            \\/  V  \\/"
    };
    attron(COLOR_PAIR(BLUE) | A_BOLD);
    for (int i = 0; i < 6; i++) mvaddnstr(y + i, x, art[i], COLS - x - 2);
    attroff(COLOR_PAIR(BLUE) | A_BOLD);
}

static void frame(const char *section, int step) {
    erase();
    attron(COLOR_PAIR(BLUE) | A_BOLD);
    mvhline(0, 0, ACS_HLINE, COLS);
    mvprintw(1, 3, "V E N O M   O S");
    attroff(COLOR_PAIR(BLUE) | A_BOLD);
    mvprintw(1, COLS - 29, "INSTALADOR OFFLINE  |  TUI");
    mvprintw(2, 3, "%s", section);
    mvhline(3, 2, ACS_HLINE, COLS - 4);
    if (step >= 0) {
        const char *steps[] = {"EDICAO", "DISCO", "REVISAO", "INSTALACAO"};
        int x = 4;
        for (int i = 0; i < 4; i++) {
            if (i == step) attron(COLOR_PAIR(BLUE) | A_BOLD);
            mvprintw(4, x, "%s", steps[i]);
            if (i == step) attroff(COLOR_PAIR(BLUE) | A_BOLD);
            x += 17;
        }
        mvhline(5, 2, ACS_HLINE, COLS - 4);
    }
    mvhline(LINES - 3, 2, ACS_HLINE, COLS - 4);
    attron(COLOR_PAIR(MUTED));
    mvprintw(LINES - 2, 3, "↑/↓ navegar   ENTER selecionar   Q voltar");
    attroff(COLOR_PAIR(MUTED));
}

static int menu(const char *title, const char *const *items, int count, int step) {
    int selected = 0, key;
    while (1) {
        frame(title, step);
        mvprintw(7, 4, "%s", title);
        for (int i = 0; i < count; i++) {
            if (i == selected) attron(A_REVERSE | COLOR_PAIR(SELECTED) | A_BOLD);
            mvprintw(9 + i * 2, 7, "%s", items[i]);
            if (i == selected) attroff(A_REVERSE | COLOR_PAIR(SELECTED) | A_BOLD);
        }
        refresh();
        key = getch();
        if ((key == KEY_UP || key == 'k') && selected > 0) selected--;
        else if ((key == KEY_DOWN || key == 'j') && selected < count - 1) selected++;
        else if (key == '\n' || key == KEY_ENTER) return selected;
        else if (key == 'q' || key == 'Q' || key == 27) return -1;
    }
}

static void welcome(void) {
    frame("BEM-VINDO AO INSTALADOR", -1);
    serpent_art(6, 8);
    attron(A_BOLD);
    mvprintw(14, 5, "INSTALACAO LIMPA. SISTEMA UNICO. SEM DUAL BOOT.");
    attroff(A_BOLD);
    mvprintw(16, 5, "Instalacao preparada para funcionar sem conexao com a internet.");
    mvprintw(18, 5, "Os pacotes e dependencias deverao estar incluidos na midia USB.");
    mvprintw(LINES - 5, 5, "ENTER para iniciar   Q para sair");
    refresh();
    int k = getch();
    (void) k;
}

static void show_disks(void) {
    GError *error = NULL;
    GPtrArray *disks = venom_disk_enumerate(&error);
    frame("SELECAO DO DISCO", 1);
    mvprintw(7, 4, "O disco selecionado sera APAGADO integralmente.");
    mvprintw(8, 4, "Nenhuma operacao de gravacao esta habilitada neste prototipo.");
    if (!disks) {
        mvprintw(11, 4, "Erro ao consultar discos: %s",
                 error ? error->message : "erro desconhecido");
    } else if (disks->len == 0) {
        mvprintw(11, 4, "Nenhum disco local encontrado.");
    } else {
        for (guint i = 0; i < disks->len && i < (guint)(LINES - 15); i++) {
            VenomDisk *d = g_ptr_array_index(disks, i);
            gchar *size = g_format_size(d->size_bytes);
            mvprintw(11 + (int)i, 5, "%-14s %-24.24s %10s %s",
                     d->path, d->model, size,
                     d->read_only ? "[SOMENTE LEITURA]" : "");
            g_free(size);
        }
    }
    mvprintw(LINES - 2, 4, "ENTER/Q para voltar");
    refresh();
    getch();
    if (disks) g_ptr_array_unref(disks);
    g_clear_error(&error);
}

static void notice(const char *title, const char *line1, const char *line2) {
    frame(title, 2);
    mvprintw(8, 5, "%s", line1);
    mvprintw(10, 5, "%s", line2);
    mvprintw(13, 5, "Este prototipo nao executa particionamento nem formatacao.");
    mvprintw(LINES - 2, 4, "Pressione uma tecla para voltar");
    refresh();
    getch();
}

int main(void) {
    const char *const editions[] = {"VENOM OS XFCE", "VENOM OS MATE"};
    const char *const actions[] = {
        "Escolher edicao", "Selecionar disco (instalacao limpa)",
        "Idioma e teclado", "Requisitos da instalacao offline",
        "INICIAR INSTALACAO", "Sair"
    };
    const char *const locales[] = {"Portugues do Brasil (pt_BR.UTF-8)", "English (US)"};
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
        init_pair(BLUE, COLOR_CYAN, -1);
        init_pair(SELECTED, COLOR_WHITE, COLOR_BLUE);
        init_pair(MUTED, COLOR_CYAN, -1);
    }

    welcome();
    while (1) {
        int choice = menu("PAINEL PRINCIPAL", actions, 6, 0);
        if (choice < 0 || choice == 5) break;
        if (choice == 0) {
            int selected = menu("ESCOLHA A EDICAO", editions, 2, 0);
            if (selected >= 0) edition = selected;
            notice("EDICAO SELECIONADA",
                   editions[edition],
                   "A mesma selecao de aplicativos sera mantida nas duas edicoes.");
        } else if (choice == 1) {
            show_disks();
            notice("INSTALACAO LIMPA",
                   "Modo definido: apagar o disco inteiro e instalar a VENOM OS.",
                   "Nao existe fluxo de dual boot neste projeto.");
        } else if (choice == 2) {
            int lang = menu("IDIOMA", locales, 2, 0);
            if (lang >= 0) {
                int kb = menu("LAYOUT DO TECLADO", keyboards, 2, 0);
                if (kb >= 0)
                    notice("PREFERENCIAS",
                           lang == 0 ? "Idioma: Portugues do Brasil." : "Idioma: English (US).",
                           kb == 0 ? "Teclado: Brasil ABNT2." : "Teclado: English US.");
            }
        } else if (choice == 3) {
            notice("INSTALACAO OFFLINE",
                   "A USB precisa conter repositorio local assinado, chaves e dependencias.",
                   "A instalacao real ainda nao esta implementada neste prototipo.");
        } else if (choice == 4) {
            notice("INSTALACAO AINDA BLOQUEADA",
                   "O fluxo de instalacao foi selecionado, mas o backend nao esta pronto.",
                   "Nenhum disco sera alterado nesta versao de desenvolvimento.");
        }
    }
    endwin();
    g_print("Edicao selecionada nesta sessao: %s\n", editions[edition]);
    return 0;
}
