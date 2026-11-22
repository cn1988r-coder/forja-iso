#include <locale.h>
#include <string.h>
#include <unistd.h>
#include <sys/reboot.h>
#include <curses.h>
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
    static const char *const steps[] = {
        "EDICAO", "DISCO", "IDIOMA", "CONTA", "REVISAO", "INSTALACAO"
    };
    erase();
    attron(COLOR_PAIR(BLUE) | A_BOLD);
    mvhline(0, 0, ACS_HLINE, COLS);
    mvprintw(1, 3, "V E N O M   O S");
    attroff(COLOR_PAIR(BLUE) | A_BOLD);
    if (COLS > 48) mvprintw(1, COLS - 29, "INSTALADOR OFFLINE | TUI");
    mvprintw(2, 3, "%s", section);
    mvhline(3, 2, ACS_HLINE, COLS - 4);
    mvprintw(6, 4, "ETAPAS");
    for (int i = 0; i < 6; i++) {
        int y = 8 + i * 2;
        if (i == step) attron(COLOR_PAIR(BLUE) | A_BOLD);
        mvprintw(y, 4, "%c %s", i == step ? '>' : ' ', steps[i]);
        if (i == step) attroff(COLOR_PAIR(BLUE) | A_BOLD);
    }
    mvvline(5, 25, ACS_VLINE, LINES - 9);
    mvhline(LINES - 3, 2, ACS_HLINE, COLS - 4);
    attron(COLOR_PAIR(MUTED));
    mvprintw(LINES - 2, 3, "↑/↓ navegar   ENTER selecionar   ESC voltar");
    attroff(COLOR_PAIR(MUTED));
}
static int menu(const char *title, const char *const *items, int count, int step) {
    int selected = 0, key;
    while (1) {
        frame(title, step);
        mvprintw(7, 28, "%s", title);
        for (int i = 0; i < count; i++) {
            if (i == selected) attron(A_REVERSE | COLOR_PAIR(SELECTED) | A_BOLD);
            mvprintw(9 + i * 2, 30, "%s", items[i]);
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

static gboolean welcome(void) {
    frame("BEM-VINDO AO INSTALADOR", -1);
    serpent_art(6, COLS > 42 ? (COLS - 42) / 2 : 1);
    attron(A_BOLD);
    mvprintw(14, (COLS - 51) > 1 ? (COLS - 51) / 2 : 1, "INSTALACAO LIMPA. SISTEMA UNICO. SEM DUAL BOOT.");
    attroff(A_BOLD);
    mvprintw(16, (COLS - 65) > 1 ? (COLS - 65) / 2 : 1, "Instalacao preparada para funcionar sem conexao com a internet.");
    mvprintw(18, (COLS - 48) > 1 ? (COLS - 48) / 2 : 1, "Pacotes e dependencias incluidos na midia USB.");
    mvprintw(LINES - 5, (COLS - 30) > 1 ? (COLS - 30) / 2 : 1, "ENTER para iniciar   Q para sair");
    refresh();
    int k = getch();
    return k != 'q' && k != 'Q' && k != 27;
}

static VenomDisk selected_disk = {0};
static gboolean disk_selected = FALSE;
static int selected_edition = 1;
static int selected_locale = 0;
static int selected_keyboard = 0;
static gchar target_username[32] = {0};
static gchar target_password[128] = {0};
static gboolean account_configured = FALSE;

static int choose_edition(void) {
    static const char *const names[] = {
        "VENOM OS  |  XFCE",
        "VENOM OS  |  MATE"
    };
    static const char *const descriptions[] = {
        "XFCE: leve, rapido e configuravel.",
        "MATE: classico, familiar e completo."
    };
    int selected = selected_edition;
    int key;

    for (;;) {
        frame("ESCOLHA A EDICAO", 0);
        attron(COLOR_PAIR(BLUE) | A_BOLD);
        mvprintw(6, 29, "DUAS EDICOES. UMA VENOM.");
        attroff(COLOR_PAIR(BLUE) | A_BOLD);

        /* A ilustração da serpente acompanha a escolha das interfaces. */
        serpent_art(8, 34);

        for (int i = 0; i < 2; i++) {
            int y = 15 + i * 4;
            if (i == selected)
                attron(A_REVERSE | COLOR_PAIR(SELECTED) | A_BOLD);
            mvprintw(y, 30, "%s", names[i]);
            if (i == selected)
                attroff(A_REVERSE | COLOR_PAIR(SELECTED) | A_BOLD);
            mvprintw(y + 1, 32, "%s", descriptions[i]);
        }

        attron(COLOR_PAIR(MUTED));
        mvprintw(23, 30, "As duas incluem os mesmos aplicativos VENOM.");
        attroff(COLOR_PAIR(MUTED));
        refresh();

        key = getch();
        if ((key == KEY_UP || key == 'k') && selected > 0)
            selected--;
        else if ((key == KEY_DOWN || key == 'j') && selected < 1)
            selected++;
        else if (key == '\n' || key == KEY_ENTER)
            return selected;
        else if (key == 27 || key == 'q' || key == 'Q')
            return -1;
    }
}

static void secure_clear(void *memory, size_t length) {
    volatile unsigned char *p = memory;
    while (length--) *p++ = 0;
}

static gboolean valid_username(const gchar *name) {
    if (name == NULL || g_str_equal(name, "root") ||
        (!g_ascii_islower(name[0]) && name[0] != '_'))
        return FALSE;
    for (const gchar *p = name + 1; *p != '\0'; p++) {
        if (!g_ascii_islower(*p) && !g_ascii_isdigit(*p) &&
            *p != '_' && *p != '-')
            return FALSE;
    }
    return strlen(name) <= 31;
}

static void configure_account(void) {
    account_configured = FALSE;
    secure_clear(target_password, sizeof(target_password));
    memset(target_username, 0, sizeof(target_username));
    secure_clear(target_password, sizeof(target_password));
    memset(target_username, 0, sizeof(target_username));
    gchar username[32] = {0};
    gchar password[128] = {0};
    gchar confirmation[128] = {0};

    frame("CRIAR CONTA DO SISTEMA", 3);
    mvprintw(7, 28, "NOME DE USUARIO (minusculas, numeros, _ ou -):");
    mvprintw(9, 28, "> ");
    refresh();
    echo();
    curs_set(1);
    move(9, 30);
    getnstr(username, (int)sizeof(username) - 1);
    noecho();

    if (!valid_username(username)) {
        curs_set(0);
        notice("NOME DE USUARIO INVALIDO",
               "Use ate 31 caracteres: a-z, 0-9, _ ou -.",
               "A primeira posicao deve ser letra minuscula ou _.");
        return;
    }

    frame("CRIAR CONTA DO SISTEMA", 3);
    mvprintw(7, 28, "SENHA (minimo de 8 caracteres):");
    mvprintw(9, 28, "> ");
    refresh();
    curs_set(1);
    move(9, 30);
    getnstr(password, (int)sizeof(password) - 1);

    frame("CONFIRMAR SENHA", 3);
    mvprintw(7, 28, "DIGITE A SENHA NOVAMENTE:");
    mvprintw(9, 28, "> ");
    refresh();
    move(9, 30);
    getnstr(confirmation, (int)sizeof(confirmation) - 1);
    curs_set(0);

    if (strlen(password) < 8 || strcmp(password, confirmation) != 0) {
        secure_clear(password, sizeof(password));
        secure_clear(confirmation, sizeof(confirmation));
        notice("SENHAS INVALIDAS",
               "As senhas precisam ter ao menos 8 caracteres e ser iguais.",
               "A conta nao foi configurada.");
        return;
    }

    g_strlcpy(target_username, username, sizeof(target_username));
    secure_clear(target_password, sizeof(target_password));
    g_strlcpy(target_password, password, sizeof(target_password));
    account_configured = TRUE;
    secure_clear(password, sizeof(password));
    secure_clear(confirmation, sizeof(confirmation));
    notice("CONTA CONFIGURADA",
           "Usuario registrado para a instalacao.",
           "A senha fica somente na memoria durante esta sessao.");
}

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
    mvprintw(7, 28, "ATENCAO: A VENOM OS NAO OFERECE DUAL BOOT.");
    mvprintw(9, 28, "O DISCO INTEIRO SERA APAGADO, INCLUINDO TODAS AS PARTICOES.");
    attroff(A_BOLD);
    mvprintw(12, 28, "DISCO: %s", current->path);
    mvprintw(13, 28, "MODELO: %.48s", current->model);
    mvprintw(14, 28, "CAPACIDADE: %s", g_format_size(current->size_bytes));
    mvprintw(17, 28, "Digite APAGAR para continuar ou qualquer outra coisa para cancelar:");
    mvprintw(19, 28, "> ");
    refresh();

    echo();
    curs_set(1);
    move(19, 30);
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

    g_ptr_array_unref(disks);

    if (!g_file_test("/usr/lib/venom/install-system", G_FILE_TEST_IS_EXECUTABLE) ||
        (!g_file_test("/usr/share/venom/repo/venom.db", G_FILE_TEST_EXISTS) &&
         !g_file_test("/usr/share/venom/repo/venom.db.tar.gz", G_FILE_TEST_EXISTS) &&
         !g_file_test("/usr/share/venom/repo/venom.db.tar.zst", G_FILE_TEST_EXISTS))) {
        notice("MIDIA DE INSTALACAO INCOMPLETA",
               "O backend ou o repositorio offline nao esta presente.",
               "Nenhuma particao foi alterada.");
        return;
    }

    gchar *size_text = g_strdup_printf("%" G_GUINT64_FORMAT,
                                       selected_disk.size_bytes);
    gchar *edition = g_strdup(selected_edition == 0 ? "xfce" : "mate");
    gchar *locale_name = g_strdup(selected_locale == 0 ? "pt_BR.UTF-8" : "en_US.UTF-8");
    gchar *keymap = g_strdup(selected_keyboard == 0 ? "br-abnt2" : "us");
    gchar *firmware_name = g_strdup(g_file_test("/sys/firmware/efi", G_FILE_TEST_IS_DIR) ? "uefi" : "bios");
    gchar *argv[] = {
        "/usr/lib/venom/install-system",
        "--disk", selected_disk.path,
        "--edition", edition,
        "--locale", locale_name,
        "--keymap", keymap,
        "--username", target_username,
        "--firmware", firmware_name,
        "--confirm", "APAGAR",
        NULL
    };
    gchar **env = g_get_environ();
    env = g_environ_setenv(env, "VENOM_EXPECTED_DISK_BYTES", size_text, TRUE);
    gchar *password_input = g_strdup_printf("%s\n", target_password);
    gchar *stdout_text = NULL;
    gchar *stderr_text = NULL;
    gint wait_status = 0;
    GError *spawn_error = NULL;

    endwin();
    g_print("\n[VENOM] Instalando VENOM OS %s. Nao desligue o computador.\n", edition);
    gboolean spawned = g_spawn_sync(NULL, argv, env, G_SPAWN_SEARCH_PATH,
                                     NULL, password_input, &stdout_text,
                                     &stderr_text, &wait_status, &spawn_error);
    secure_clear(target_password, sizeof(target_password));
    account_configured = FALSE;
    secure_clear(password_input, strlen(password_input));
    g_free(password_input);
    g_strfreev(env);

    if (!spawned || !g_spawn_check_wait_status(wait_status, &spawn_error)) {
        g_printerr("\n[VENOM] A instalacao falhou: %s\n%s\n",
                   spawn_error ? spawn_error->message : "erro desconhecido",
                   stderr_text ? stderr_text : "");
        g_printerr("O disco pode ter sido alterado. Nao remova a energia.\n");
        g_clear_error(&spawn_error);
        g_free(stdout_text);
        g_free(stderr_text);
        g_free(size_text);
        g_free(edition);
        g_free(locale_name);
        g_free(keymap);
        g_free(firmware_name);
        g_print("Pressione ENTER para retornar ao instalador.\n");
        (void)getchar();
        refresh();
        return;
    }

    g_print("%s\n", stdout_text ? stdout_text : "");
    g_free(stdout_text);
    g_free(stderr_text);
    g_free(size_text);
    g_free(edition);
    g_free(locale_name);
    g_free(keymap);
    g_free(firmware_name);
    g_print("\nInstalacao concluida. Remova a USB e pressione ENTER para reiniciar.\n");
    (void)getchar();
    sync();
    reboot(RB_AUTOBOOT);
}

static gboolean review_installation(void) {
    GError *error = NULL;
    if (!account_configured) {
        notice("FALTA CONFIGURAR A CONTA",
               "Crie o nome de usuario e a senha antes de continuar.",
               "A instalacao ainda nao foi iniciada.");
        return FALSE;
    }
    if (!disk_selected) {
        notice("FALTA SELECIONAR O DISCO", "Volte ao menu e escolha o disco de destino.", "A instalacao limpa apagara o disco inteiro.");
        return FALSE;
    }
    VenomFirmwareMode firmware = g_file_test("/sys/firmware/efi", G_FILE_TEST_IS_DIR) ? VENOM_FIRMWARE_UEFI : VENOM_FIRMWARE_BIOS;
    VenomInstallPlan *plan = venom_install_plan_automatic(&selected_disk, firmware, &error);
    if (!plan) {
        notice("NAO FOI POSSIVEL MONTAR O PLANO", error ? error->message : "Disco ou firmware invalido.", "Escolha outro disco ou verifique o equipamento.");
        g_clear_error(&error);
        return FALSE;
    }
    frame("REVISAO ANTES DA INSTALACAO", 2);
    gchar *size = g_format_size(plan->disk_size_bytes);
    mvprintw(7, 28, "EDICAO: %s", selected_edition == 0 ? "XFCE" : "MATE");
    mvprintw(8, 28, "IDIOMA: %s", selected_locale == 0 ? "Portugues do Brasil" : "English (US)");
    mvprintw(9, 28, "TECLADO: %s", selected_keyboard == 0 ? "Brasil ABNT2" : "English US");
    mvprintw(10, 28, "USUARIO: %s", target_username);
    mvprintw(11, 28, "DISCO: %s | %s | %s", plan->disk_path, selected_disk.model, size);
    mvprintw(13, 28, "MODO: INSTALACAO LIMPA, DISCO INTEIRO");
    mvprintw(14, 28, "FIRMWARE: %s | GPT", firmware == VENOM_FIRMWARE_UEFI ? "UEFI" : "BIOS");
    mvprintw(15, 28, "ARQUIVOS: BTRFS | SUBVOLUMES @ E @home");
    mvprintw(16, 28, "SNAPSHOTS: TIMESHIFT + GRUB-BTRFS");
    mvprintw(17, 28, "PARTICOES PLANEJADAS:");
    for (guint i = 0; i < plan->partitions->len; i++) {
        VenomPartition *p = g_ptr_array_index(plan->partitions, i);
        gchar *part_size = g_format_size(p->size_bytes);
        const char *role = p->role == VENOM_PARTITION_EFI ? "EFI FAT32 /boot/efi" : p->role == VENOM_PARTITION_BIOS_GRUB ? "BIOS GRUB" : "RAIZ BTRFS / (subvolume @; /home em @home)";
        mvprintw(18 + (int)i, 30, "%s  %s", role, part_size);
        g_free(part_size);
    }
    attron(A_BOLD);
    mvprintw(LINES - 5, 28, "ATENCAO: O DISCO INTEIRO SERA APAGADO.");
    attroff(A_BOLD);
    mvprintw(LINES - 2, 28, "ENTER confirma   ESC volta");
    refresh();
    int key = getch();
    g_free(size);
    venom_install_plan_free(plan);
    return key != 27 && key != 'q' && key != 'Q';
}
static void notice(const char *title, const char *line1, const char *line2) {
    frame(title, 2);
    mvprintw(8, 28, "%s", line1);
    mvprintw(10, 28, "%s", line2);
    mvprintw(13, 28, "Nenhuma operacao de disco e executada nesta versao.");
    mvprintw(LINES - 2, 28, "Pressione uma tecla para voltar");
    refresh();
    getch();
}

int main(void) {
    const char *const editions[] = {"VENOM OS XFCE", "VENOM OS MATE"};
    const char *const actions[] = {
        "Escolher edicao", "Selecionar disco (instalacao limpa)",
        "Idioma e teclado", "Criar usuario e senha",
        "Requisitos da instalacao offline", "INICIAR INSTALACAO", "Sair"
    };
    const char *const locales[] = {"Portugues do Brasil (pt_BR.UTF-8)", "English (US)"};
    const char *const keyboards[] = {"Brasil ABNT2", "English US"};
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

    if (!welcome()) { endwin(); return 0; }
    while (1) {
        int choice = menu("PAINEL PRINCIPAL", actions, 7, 0);
        if (choice < 0 || choice == 6) break;
        if (choice == 0) {
            int selected = choose_edition();
            if (selected >= 0) {
                selected_edition = selected;
                notice("EDICAO SELECIONADA",
                       editions[selected_edition],
                       "A mesma selecao de aplicativos sera mantida nas duas edicoes.");
            }
        } else if (choice == 1) {
            select_disk();
        } else if (choice == 2) {
            int lang = menu("IDIOMA", locales, 2, 0);
            if (lang >= 0) selected_locale = lang;
            int kb = menu("LAYOUT DO TECLADO", keyboards, 2, 0);
            if (kb >= 0) selected_keyboard = kb;
            notice("PREFERENCIAS",
                   selected_locale == 0 ? "Idioma: Portugues do Brasil." : "Idioma: English (US).",
                   selected_keyboard == 0 ? "Teclado: Brasil ABNT2." : "Teclado: English US.");
        } else if (choice == 3) {
            configure_account();
        } else if (choice == 4) {
            notice("INSTALACAO OFFLINE",
                   "A USB precisa conter repositorio local assinado, chaves e dependencias.",
                   "A instalacao real ainda nao esta implementada neste prototipo.");
        } else if (choice == 5) {
            if (review_installation())
                confirm_wipe_intent();
        }
    }
    endwin();
    secure_clear(target_password, sizeof(target_password));
    return 0;
}
