#include <locale.h>
#include <string.h>
#include <ncursesw/curses.h>
#include <glib.h>
#include "disk.h"
#include "plan.h"

#define BLUE 1
#define SELECTED 2
#define MUTED 3

static void notice(const char *title, const char *line1, const char *line2);

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

static VenomDisk selected_disk = {0};
static gboolean disk_selected = FALSE;

static void clear_selected_disk(void) {
    g_free(selected_disk.path);
    g_free(selected_disk.model);
    memset(&selected_disk, 0, sizeof(selected_disk));
    disk_selected = FALSE;
}

static void select_disk(void) {
    GError *error = NULL;
    GPtrArray *disks = venom_disk_enumerate(&error);
    if (!disks) {
        notice("ERRO AO LER DISCOS", error ? error->message : "Falha ao executar lsblk.", "Nenhum disco foi modificado.");
        g_clear_error(&error);
        return;
    }
    if (disks->len == 0) {
        notice("NENHUM DISCO ENCONTRADO", "Conecte o disco de destino e tente novamente.", "Nenhum disco foi modificado.");
        g_ptr_array_unref(disks);
        return;
    }
    const char **items = g_new0(const char *, disks->len);
    for (guint i = 0; i < disks->len; i++) {
        VenomDisk *d = g_ptr_array_index(disks, i);
        gchar *size = g_format_size(d->size_bytes);
        items[i] = g_strdup_printf("%-12s %-22.22s %10s %s", d->path, d->model, size, d->read_only ? "[SOMENTE LEITURA]" : "");
        g_free(size);
    }
    int choice = menu("ESCOLHA O DISCO DE DESTINO", items, (int)disks->len, 1);
    if (choice >= 0) {
        VenomDisk *d = g_ptr_array_index(disks, (guint)choice);
        clear_selected_disk();
        selected_disk.path = g_strdup(d->path);
        selected_disk.model = g_strdup(d->model);
        selected_disk.size_bytes = d->size_bytes;
        selected_disk.read_only = d->read_only;
        disk_selected = TRUE;
        gchar *size = g_format_size(d->size_bytes);
        gchar *summary = g_strdup_printf("%s | %s | %s", d->path, d->model, size);
        notice("DISCO SELECIONADO", summary, "ATENCAO: todo o conteudo deste disco sera apagado.");
        g_free(summary);
        g_free(size);
    }
    for (guint i = 0; i < disks->len; i++) g_free((gpointer)items[i]);
    g_free(items);
    g_ptr_array_unref(disks);
}


/*
 * Confirma apenas a intenção do usuário. Esta etapa NÃO executa operações
 * de disco: o backend destrutivo permanece desabilitado até ser implementado
 * e testado em máquinas virtuais descartáveis.
 */
static void confirm_wipe_intent(void) {
    GError *error = NULL;
    GPtrArray *disks;
    VenomDisk *current = NULL;
    gchar typed[32] = {0};
    const char *const final_items[] = {
        "SIM, CONFIRMO QUE ESTE DISCO INTEIRO PODE SER APAGADO",
        "CANCELAR E VOLTAR"
    };

    if (!disk_selected) {
        notice("DISCO NAO SELECIONADO",
               "Volte e selecione um disco de destino.",
               "Nenhum disco foi alterado.");
        return;
    }

    /* Reconsulta os dispositivos para impedir confirmar um disco que mudou. */
    disks = venom_disk_enumerate(&error);
    if (disks == NULL) {
        notice("NAO FOI POSSIVEL REVALIDAR O DISCO",
               error ? error->message : "Falha ao consultar lsblk.",
               "A confirmacao foi cancelada por seguranca.");
        g_clear_error(&error);
        return;
    }

    for (guint i = 0; i < disks->len; i++) {
        VenomDisk *candidate = g_ptr_array_index(disks, i);
        if (g_strcmp0(candidate->path, selected_disk.path) == 0) {
            current = candidate;
            break;
        }
    }

    if (current == NULL || current->read_only ||
        current->size_bytes != selected_disk.size_bytes ||
        g_strcmp0(current->model, selected_disk.model) != 0) {
        notice("DISCO MUDOU OU NAO ESTA DISPONIVEL",
               "A identificacao do disco nao confere mais com a selecao.",
               "Selecione novamente. Nenhum disco foi alterado.");
        g_ptr_array_unref(disks);
        return;
    }

    frame("CONFIRMACAO DE APAGAMENTO", 2);
    attron(A_BOLD);
    mvprintw(7, 4, "ATENCAO: A VENOM OS NAO OFERECE DUAL BOOT.");
    mvprintw(9, 4, "O DISCO INTEIRO SERA APAGADO, INCLUINDO TODAS AS PARTICOES.");
    attroff(A_BOLD);
    mvprintw(12, 4, "DISCO: %s", current->path);
    mvprintw(13, 4, "MODELO: %.48s", current->model);
    mvprintw(14, 4, "CAPACIDADE: %s", g_format_size(current->size_bytes));
    mvprintw(17, 4, "Digite APAGAR para continuar ou qualquer outra coisa para cancelar:");
    mvprintw(19, 4, "> ");
    refresh();

    echo();
    curs_set(1);
    move(19, 6);
    getnstr(typed, (int)sizeof(typed) - 1);
    noecho();
    curs_set(0);

    if (g_strcmp0(typed, "APAGAR") != 0) {
        notice("CONFIRMACAO CANCELADA",
               "A palavra APAGAR nao foi digitada exatamente.",
               "Nenhum disco foi alterado.");
        g_ptr_array_unref(disks);
        return;
    }

    int choice = menu("ULTIMA CONFIRMACAO", final_items, 2, 2);
    if (choice != 0) {
        notice("INSTALACAO CANCELADA",
               "Voce escolheu voltar sem apagar o disco.",
               "Nenhum disco foi alterado.");
        g_ptr_array_unref(disks);
        return;
    }

    notice("CONFIRMACAO REGISTRADA",
           "O usuario confirmou a intencao de apagar o disco selecionado.",
           "Instalacao bloqueada: backend ainda nao implementado.");
    g_ptr_array_unref(disks);
}

static void review_installation(void) {
    GError *error = NULL;
    if (!disk_selected) {
        notice("FALTA SELECIONAR O DISCO", "Volte ao menu e escolha o disco de destino.", "A instalacao limpa apagara o disco inteiro.");
        return;
    }
    VenomFirmwareMode firmware = g_file_test("/sys/firmware/efi", G_FILE_TEST_IS_DIR) ? VENOM_FIRMWARE_UEFI : VENOM_FIRMWARE_BIOS;
    VenomInstallPlan *plan = venom_install_plan_automatic(&selected_disk, firmware, &error);
    if (!plan) {
        notice("NAO FOI POSSIVEL MONTAR O PLANO", error ? error->message : "Disco ou firmware invalido.", "Escolha outro disco ou verifique o equipamento.");
        g_clear_error(&error);
        return;
    }
    frame("REVISAO ANTES DA INSTALACAO", 2);
    gchar *size = g_format_size(plan->disk_size_bytes);
    mvprintw(7, 4, "DISCO: %s | %s | %s", plan->disk_path, selected_disk.model, size);
    mvprintw(9, 4, "MODO: INSTALACAO LIMPA, DISCO INTEIRO");
    mvprintw(11, 4, "ARQUIVOS: BTRFS | SNAPSHOTS: TIMESHIFT + GRUB-BTRFS");
    mvprintw(10, 4, "FIRMWARE: %s", firmware == VENOM_FIRMWARE_UEFI ? "UEFI / GPT" : "BIOS / GPT");
    mvprintw(13, 4, "PARTICOES PLANEJADAS:");
    for (guint i = 0; i < plan->partitions->len; i++) {
        VenomPartition *p = g_ptr_array_index(plan->partitions, i);
        gchar *part_size = g_format_size(p->size_bytes);
        const char *role = p->role == VENOM_PARTITION_EFI ? "EFI FAT32 /boot/efi" : p->role == VENOM_PARTITION_BIOS_GRUB ? "BIOS GRUB" : "RAIZ BTRFS / (subvolume @; /home em @home)";
        mvprintw(15 + (int)i, 6, "%s  %s", role, part_size);
        g_free(part_size);
    }
    mvprintw(18, 4, "Subvolumes: @ (/) e @home (/home). GRUB continua como bootloader.");
    attron(A_BOLD);
    mvprintw(LINES - 5, 4, "ATENCAO: O DISCO INTEIRO SERA APAGADO.");
    attroff(A_BOLD);
    mvprintw(LINES - 2, 4, "ENTER para voltar. A instalacao ainda esta bloqueada.");
    refresh();
    getch();
    g_free(size);
    venom_install_plan_free(plan);
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
            select_disk();
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
            review_installation();
            confirm_wipe_intent();
            notice("INSTALACAO AINDA BLOQUEADA",
                   "A interface e a confirmacao estao em desenvolvimento.",
                   "Nenhum disco sera particionado, formatado ou alterado.");
        }
    }
    endwin();
    g_print("Edicao selecionada nesta sessao: %s\n", editions[edition]);
    return 0;
}
