#include <errno.h>
#include <gtk/gtk.h>

#include "disk.h"
#include "plan.h"

typedef struct {
    GtkWidget *stack;
    GtkWidget *disk_dropdown;
    GtkWidget *disk_details;
    GtkWidget *install_button;
    GtkWidget *mode_dropdown;
    GtkWidget *custom_options;
    GtkWidget *root_size_entry;
    GtkWidget *swap_size_entry;
    GtkWidget *swap_check;
    GtkWidget *plan_details;
    GtkStringList *disk_model;
    GtkStringList *mode_model;
    GPtrArray *disks;
    VenomInstallPlan *plan;
    VenomFirmwareMode firmware;
} AppState;

static const gchar *page_names[] = {
    "inicio",
    "disco",
    "usuario",
    "resumo"
};

static const gchar *page_titles[] = {
    "Boas-vindas",
    "Disco de destino",
    "Conta de usuário",
    "Revisão"
};

static void
app_state_free(gpointer data)
{
    AppState *state = data;

    if (state == NULL) {
        return;
    }

    g_clear_pointer(&state->disks, g_ptr_array_unref);
    g_clear_pointer(&state->plan, venom_install_plan_free);
    g_clear_object(&state->disk_model);
    g_clear_object(&state->mode_model);
    g_free(state);
}

static GtkWidget *
make_page(const gchar *title, const gchar *description)
{
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 14);
    GtkWidget *heading = gtk_label_new(title);
    GtkWidget *body = gtk_label_new(description);

    gtk_widget_add_css_class(heading, "title-1");
    gtk_label_set_xalign(GTK_LABEL(heading), 0.0f);
    gtk_label_set_xalign(GTK_LABEL(body), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(body), TRUE);
    gtk_widget_add_css_class(body, "description");
    gtk_box_append(GTK_BOX(box), heading);
    gtk_box_append(GTK_BOX(box), body);
    gtk_widget_set_margin_top(box, 20);
    gtk_widget_set_margin_bottom(box, 20);
    gtk_widget_set_margin_start(box, 24);
    gtk_widget_set_margin_end(box, 24);
    return box;
}

static gboolean
parse_gib_entry(GtkWidget *entry, guint64 *size_bytes)
{
    const gchar *text = gtk_editable_get_text(GTK_EDITABLE(entry));
    gchar *end = NULL;
    guint64 gib;

    if (text == NULL || *text == '\0') {
        return FALSE;
    }

    errno = 0;
    gib = g_ascii_strtoull(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' ||
        gib == 0 || gib > G_MAXUINT64 / (1024ULL * 1024ULL * 1024ULL)) {
        return FALSE;
    }

    *size_bytes = gib * 1024ULL * 1024ULL * 1024ULL;
    return TRUE;
}

static const gchar *
partition_role_name(VenomPartitionRole role)
{
    switch (role) {
    case VENOM_PARTITION_EFI:
        return "EFI";
    case VENOM_PARTITION_BIOS_GRUB:
        return "Inicialização BIOS";
    case VENOM_PARTITION_ROOT:
        return "Sistema raiz";
    case VENOM_PARTITION_SWAP:
        return "Swap";
    }
    return "Desconhecida";
}

static const gchar *
filesystem_name(VenomFilesystem filesystem)
{
    switch (filesystem) {
    case VENOM_FILESYSTEM_NONE:
        return "sem formatação";
    case VENOM_FILESYSTEM_FAT32:
        return "FAT32";
    case VENOM_FILESYSTEM_EXT4:
        return "ext4";
    case VENOM_FILESYSTEM_SWAP:
        return "swap";
    }
    return "desconhecido";
}

static void
update_plan_preview(AppState *state)
{
    guint selected;
    VenomDisk *disk;
    GError *error = NULL;
    GString *summary;

    g_clear_pointer(&state->plan, venom_install_plan_free);

    if (state->disks == NULL || state->disks->len == 0) {
        gtk_label_set_text(GTK_LABEL(state->plan_details),
                           "A prévia do particionamento aparecerá quando um disco for detectado.");
        return;
    }

    selected = gtk_drop_down_get_selected(
        GTK_DROP_DOWN(state->disk_dropdown));
    if (selected >= state->disks->len) {
        gtk_label_set_text(GTK_LABEL(state->plan_details),
                           "Selecione um disco para montar a prévia.");
        return;
    }

    disk = g_ptr_array_index(state->disks, selected);
    if (gtk_drop_down_get_selected(GTK_DROP_DOWN(state->mode_dropdown)) == 0) {
        state->plan = venom_install_plan_automatic(
            disk, state->firmware, &error);
    } else {
        VenomPartitionInput inputs[3];
        gsize count = 0;
        guint64 root_size;
        guint64 swap_size;

        if (state->firmware == VENOM_FIRMWARE_UEFI) {
            inputs[count++] = (VenomPartitionInput) {
                VENOM_PARTITION_EFI, 1024ULL * 1024ULL * 1024ULL
            };
        } else {
            inputs[count++] = (VenomPartitionInput) {
                VENOM_PARTITION_BIOS_GRUB, 2ULL * 1024ULL * 1024ULL
            };
        }

        if (!parse_gib_entry(state->root_size_entry, &root_size)) {
            gtk_label_set_text(GTK_LABEL(state->plan_details),
                               "Informe o tamanho da partição raiz em GiB, usando um número inteiro.");
            return;
        }
        inputs[count++] = (VenomPartitionInput) {
            VENOM_PARTITION_ROOT, root_size
        };

        if (gtk_check_button_get_active(GTK_CHECK_BUTTON(state->swap_check))) {
            if (!parse_gib_entry(state->swap_size_entry, &swap_size)) {
                gtk_label_set_text(GTK_LABEL(state->plan_details),
                                   "Informe o tamanho da partição swap em GiB, usando um número inteiro.");
                return;
            }
            inputs[count++] = (VenomPartitionInput) {
                VENOM_PARTITION_SWAP, swap_size
            };
        }

        state->plan = venom_install_plan_custom(
            disk, state->firmware, inputs, count, &error);
    }

    if (state->plan == NULL) {
        gtk_label_set_text(GTK_LABEL(state->plan_details),
                           error != NULL ? error->message
                                         : "Não foi possível criar a prévia.");
        g_clear_error(&error);
        return;
    }

    summary = g_string_new(NULL);
    g_string_append_printf(
        summary,
        "Modo: %s\nInicialização detectada: %s\nTabela: GPT\n"
        "Disco: %s\n\nPartições propostas:\n",
        state->plan->mode == VENOM_INSTALL_AUTOMATIC
            ? "Automático" : "Personalizado",
        state->firmware == VENOM_FIRMWARE_UEFI ? "UEFI" : "BIOS",
        state->plan->disk_path
    );

    for (guint i = 0; i < state->plan->partitions->len; i++) {
        VenomPartition *partition =
            g_ptr_array_index(state->plan->partitions, i);
        gchar *size_text = g_format_size(partition->size_bytes);

        g_string_append_printf(
            summary, "• %s: %s, %s",
            partition_role_name(partition->role),
            size_text,
            filesystem_name(partition->filesystem)
        );
        if (partition->mount_point != NULL) {
            g_string_append_printf(summary, ", montagem %s",
                                   partition->mount_point);
        }
        g_string_append(summary,
                        partition->format ? ", será formatada\n"
                                          : ", sem formatação\n");
        g_free(size_text);
    }

    g_string_append(
        summary,
        "\nEsta proposta é somente uma prévia. Nenhuma partição será criada ou formatada."
    );
    gtk_label_set_text(GTK_LABEL(state->plan_details), summary->str);
    g_string_free(summary, TRUE);
}

static void
update_disk_details(AppState *state)
{
    guint selected;
    VenomDisk *disk;
    gchar *size_text;
    gchar *details;

    gtk_widget_set_visible(
        state->custom_options,
        gtk_drop_down_get_selected(GTK_DROP_DOWN(state->mode_dropdown)) == 1
    );

    if (state->disks == NULL || state->disks->len == 0) {
        gtk_label_set_text(GTK_LABEL(state->disk_details),
                           "Nenhum disco local foi detectado.");
        update_plan_preview(state);
        return;
    }

    selected = gtk_drop_down_get_selected(
        GTK_DROP_DOWN(state->disk_dropdown));
    if (selected >= state->disks->len) {
        gtk_label_set_text(GTK_LABEL(state->disk_details),
                           "Selecione um disco para consultar os detalhes.");
        update_plan_preview(state);
        return;
    }

    disk = g_ptr_array_index(state->disks, selected);
    size_text = g_format_size(disk->size_bytes);
    details = g_strdup_printf(
        "Dispositivo: %s\nModelo: %s\nTamanho: %s\nEstado: %s",
        disk->path,
        disk->model,
        size_text,
        disk->read_only ? "Somente leitura" : "Gravável"
    );
    gtk_label_set_text(GTK_LABEL(state->disk_details), details);
    g_free(details);
    g_free(size_text);
    update_plan_preview(state);
}

static void
refresh_disks(AppState *state)
{
    GError *error = NULL;
    GPtrArray *disks = venom_disk_enumerate(&error);
    guint old_count;

    if (disks == NULL) {
        gchar *message = g_strdup_printf(
            "Não foi possível consultar os discos.\n%s",
            error != NULL ? error->message : "Erro desconhecido."
        );
        gtk_label_set_text(GTK_LABEL(state->disk_details), message);
        g_free(message);
        g_clear_error(&error);
        return;
    }

    g_clear_pointer(&state->disks, g_ptr_array_unref);
    state->disks = disks;

    old_count = g_list_model_get_n_items(G_LIST_MODEL(state->disk_model));
    gtk_string_list_splice(state->disk_model, 0, old_count, NULL);

    for (guint i = 0; i < state->disks->len; i++) {
        VenomDisk *disk = g_ptr_array_index(state->disks, i);
        gchar *size_text = g_format_size(disk->size_bytes);
        gchar *label = g_strdup_printf(
            "%s  |  %s  |  %s%s",
            disk->path,
            disk->model,
            size_text,
            disk->read_only ? "  |  Somente leitura" : ""
        );
        gtk_string_list_append(state->disk_model, label);
        g_free(label);
        g_free(size_text);
    }

    if (state->disks->len > 0) {
        gtk_drop_down_set_selected(GTK_DROP_DOWN(state->disk_dropdown), 0);
    } else {
        gtk_drop_down_set_selected(GTK_DROP_DOWN(state->disk_dropdown),
                                   GTK_INVALID_LIST_POSITION);
    }

    update_disk_details(state);
}

static void
on_refresh_clicked(GtkButton *button, gpointer user_data)
{
    (void) button;
    refresh_disks(user_data);
}

static void
on_disk_changed(GObject *object, GParamSpec *pspec, gpointer user_data)
{
    (void) object;
    (void) pspec;
    update_disk_details(user_data);
}

static void
on_mode_changed(GObject *object, GParamSpec *pspec, gpointer user_data)
{
    (void) object;
    (void) pspec;
    update_disk_details(user_data);
}

static void
on_custom_value_changed(GtkWidget *widget, gpointer user_data)
{
    AppState *state = user_data;
    (void) widget;
    update_plan_preview(state);
}

static void
on_next_clicked(GtkButton *button, gpointer user_data)
{
    AppState *state = user_data;
    const gchar *current = gtk_stack_get_visible_child_name(
        GTK_STACK(state->stack));

    (void) button;

    for (guint i = 0; i + 1 < G_N_ELEMENTS(page_names); i++) {
        if (g_strcmp0(current, page_names[i]) == 0) {
            gtk_stack_set_visible_child_name(GTK_STACK(state->stack),
                                             page_names[i + 1]);
            return;
        }
    }
}

static void
on_back_clicked(GtkButton *button, gpointer user_data)
{
    AppState *state = user_data;
    const gchar *current = gtk_stack_get_visible_child_name(
        GTK_STACK(state->stack));

    (void) button;

    for (guint i = 1; i < G_N_ELEMENTS(page_names); i++) {
        if (g_strcmp0(current, page_names[i]) == 0) {
            gtk_stack_set_visible_child_name(GTK_STACK(state->stack),
                                             page_names[i - 1]);
            return;
        }
    }
}

static void
install_style(void)
{
    static const gchar css[] =
        "window { background: #0b0d11; color: #edf1f7; }"
        ".title-1 { color: #f4f6fa; font-weight: 700; }"
        ".description { color: #b8c0cc; }"
        "button.suggested-action { background: #174f83; }"
        "entry, dropdown { background: #171b22; color: #edf1f7; }";

    GtkCssProvider *provider = gtk_css_provider_new();
    GdkDisplay *display = gdk_display_get_default();

    gtk_css_provider_load_from_string(provider, css);
    if (display != NULL) {
        gtk_style_context_add_provider_for_display(
            display,
            GTK_STYLE_PROVIDER(provider),
            GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
    g_object_unref(provider);
}

static void
on_activate(GtkApplication *application, gpointer user_data)
{
    AppState *state = g_new0(AppState, 1);
    GtkWidget *window;
    GtkWidget *header;
    GtkWidget *brand;
    GtkWidget *root;
    GtkWidget *body;
    GtkWidget *sidebar;
    GtkWidget *footer;
    GtkWidget *back_button;
    GtkWidget *next_button;
    GtkWidget *close_button;
    GtkWidget *page;
    GtkWidget *label;
    GtkWidget *refresh_button;
    GtkWidget *account_box;
    GtkWidget *entry;
    GtkWidget *warning;
    GtkWidget *mode_label;
    GtkWidget *firmware_label;
    GtkWidget *root_size_label;
    GtkWidget *swap_size_label;

    (void) user_data;

    state->disk_model = gtk_string_list_new(NULL);
    state->mode_model = gtk_string_list_new(
        (const gchar *[]) { "Automático", "Personalizado", NULL });
    state->disks = g_ptr_array_new_with_free_func(venom_disk_free);
    state->firmware = g_file_test("/sys/firmware/efi", G_FILE_TEST_IS_DIR)
                          ? VENOM_FIRMWARE_UEFI
                          : VENOM_FIRMWARE_BIOS;
    g_object_set_data_full(G_OBJECT(application), "venom-state",
                           state, app_state_free);

    window = gtk_application_window_new(application);
    gtk_window_set_title(GTK_WINDOW(window), "Instalador VENOM OS");
    gtk_window_set_default_size(GTK_WINDOW(window), 920, 620);

    header = gtk_header_bar_new();
    brand = gtk_label_new("VENOM OS");
    gtk_widget_add_css_class(brand, "title-2");
    gtk_header_bar_set_title_widget(GTK_HEADER_BAR(header), brand);
    gtk_window_set_titlebar(GTK_WINDOW(window), header);

    root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_window_set_child(GTK_WINDOW(window), root);

    body = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 18);
    gtk_widget_set_vexpand(body, TRUE);
    gtk_box_append(GTK_BOX(root), body);

    state->stack = gtk_stack_new();
    gtk_stack_set_transition_type(GTK_STACK(state->stack),
                                  GTK_STACK_TRANSITION_TYPE_CROSSFADE);
    gtk_widget_set_hexpand(state->stack, TRUE);
    gtk_widget_set_vexpand(state->stack, TRUE);

    page = make_page(
        "Instale a VENOM OS",
        "Uma distribuição baseada no Arch Linux oficial, com ambiente MATE "
        "e gerenciador de sessão LightDM. O idioma desta edição é Português "
        "do Brasil e o teclado padrão é Brasil ABNT2."
    );
    label = gtk_label_new(
        "Esta versão inicial do instalador consulta os discos em modo somente "
        "leitura. Nenhuma partição será criada, formatada ou alterada."
    );
    gtk_label_set_xalign(GTK_LABEL(label), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(label), TRUE);
    gtk_widget_add_css_class(label, "description");
    gtk_box_append(GTK_BOX(page), label);
    gtk_stack_add_titled(GTK_STACK(state->stack), page,
                         page_names[0], page_titles[0]);

    page = make_page(
        "Escolha o disco e o modo",
        "A detecção de discos é somente leitura. Escolha um modo para visualizar "
        "uma proposta de particionamento. O firmware de inicialização é detectado "
        "pela sessão atual e a tabela proposta é GPT."
    );
    state->disk_dropdown = gtk_drop_down_new(
        G_LIST_MODEL(state->disk_model), NULL);
    gtk_box_append(GTK_BOX(page), state->disk_dropdown);

    refresh_button = gtk_button_new_with_label("Atualizar lista de discos");
    gtk_widget_set_halign(refresh_button, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(page), refresh_button);

    mode_label = gtk_label_new("Modo de instalação");
    gtk_label_set_xalign(GTK_LABEL(mode_label), 0.0f);
    gtk_box_append(GTK_BOX(page), mode_label);
    state->mode_dropdown = gtk_drop_down_new(
        G_LIST_MODEL(state->mode_model), NULL);
    gtk_drop_down_set_selected(GTK_DROP_DOWN(state->mode_dropdown), 0);
    gtk_box_append(GTK_BOX(page), state->mode_dropdown);

    firmware_label = gtk_label_new(
        state->firmware == VENOM_FIRMWARE_UEFI
            ? "Inicialização detectada: UEFI"
            : "Inicialização detectada: BIOS"
    );
    gtk_label_set_xalign(GTK_LABEL(firmware_label), 0.0f);
    gtk_box_append(GTK_BOX(page), firmware_label);

    state->custom_options = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
    root_size_label = gtk_label_new("Tamanho da partição raiz (GiB)");
    gtk_label_set_xalign(GTK_LABEL(root_size_label), 0.0f);
    gtk_box_append(GTK_BOX(state->custom_options), root_size_label);
    state->root_size_entry = gtk_entry_new();
    gtk_editable_set_text(GTK_EDITABLE(state->root_size_entry), "12");
    gtk_entry_set_input_purpose(GTK_ENTRY(state->root_size_entry),
                                GTK_INPUT_PURPOSE_NUMBER);
    gtk_box_append(GTK_BOX(state->custom_options), state->root_size_entry);

    state->swap_check = gtk_check_button_new_with_label(
        "Criar partição swap");
    gtk_box_append(GTK_BOX(state->custom_options), state->swap_check);
    swap_size_label = gtk_label_new("Tamanho da swap (GiB)");
    gtk_label_set_xalign(GTK_LABEL(swap_size_label), 0.0f);
    gtk_box_append(GTK_BOX(state->custom_options), swap_size_label);
    state->swap_size_entry = gtk_entry_new();
    gtk_editable_set_text(GTK_EDITABLE(state->swap_size_entry), "2");
    gtk_entry_set_input_purpose(GTK_ENTRY(state->swap_size_entry),
                                GTK_INPUT_PURPOSE_NUMBER);
    gtk_box_append(GTK_BOX(state->custom_options), state->swap_size_entry);
    gtk_widget_set_visible(state->custom_options, FALSE);
    gtk_box_append(GTK_BOX(page), state->custom_options);

    state->disk_details = gtk_label_new(
        "Consultando os dispositivos disponíveis..."
    );
    gtk_label_set_xalign(GTK_LABEL(state->disk_details), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(state->disk_details), TRUE);
    gtk_box_append(GTK_BOX(page), state->disk_details);

    state->plan_details = gtk_label_new(
        "Preparando a prévia do particionamento..."
    );
    gtk_label_set_xalign(GTK_LABEL(state->plan_details), 0.0f);
    gtk_label_set_yalign(GTK_LABEL(state->plan_details), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(state->plan_details), TRUE);
    gtk_widget_add_css_class(state->plan_details, "description");
    gtk_box_append(GTK_BOX(page), state->plan_details);

    gtk_stack_add_titled(GTK_STACK(state->stack), page,
                         page_names[1], page_titles[1]);

    page = make_page(
        "Conta de usuário",
        "A criação da conta e a configuração de senha ainda não são enviadas "
        "ao sistema. Os campos abaixo são apenas a estrutura visual da próxima "
        "etapa e não armazenam dados."
    );
    account_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Nome completo");
    gtk_box_append(GTK_BOX(account_box), entry);
    entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Nome de usuário");
    gtk_box_append(GTK_BOX(account_box), entry);
    entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Senha");
    gtk_entry_set_visibility(GTK_ENTRY(entry), FALSE);
    gtk_entry_set_input_purpose(GTK_ENTRY(entry), GTK_INPUT_PURPOSE_PASSWORD);
    gtk_box_append(GTK_BOX(account_box), entry);
    entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Confirmar senha");
    gtk_entry_set_visibility(GTK_ENTRY(entry), FALSE);
    gtk_entry_set_input_purpose(GTK_ENTRY(entry), GTK_INPUT_PURPOSE_PASSWORD);
    gtk_box_append(GTK_BOX(account_box), entry);
    gtk_box_append(GTK_BOX(page), account_box);
    gtk_stack_add_titled(GTK_STACK(state->stack), page,
                         page_names[2], page_titles[2]);

    page = make_page(
        "Revisão da instalação",
        "Idioma: Português do Brasil\nTeclado: Brasil ABNT2\n"
        "Ambiente gráfico: MATE\nGerenciador de sessão: LightDM"
    );
    warning = gtk_label_new(
        "A instalação está bloqueada nesta versão inicial. O mecanismo "
        "offline, o particionamento seguro, a configuração do sistema e a "
        "instalação do carregador de inicialização ainda precisam ser "
        "implementados e testados."
    );
    gtk_label_set_xalign(GTK_LABEL(warning), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(warning), TRUE);
    gtk_widget_add_css_class(warning, "description");
    gtk_box_append(GTK_BOX(page), warning);

    state->install_button = gtk_button_new_with_label("Instalar VENOM OS");
    gtk_widget_add_css_class(state->install_button, "suggested-action");
    gtk_widget_set_sensitive(state->install_button, FALSE);
    gtk_widget_set_tooltip_text(
        state->install_button,
        "A instalação será habilitada após a implementação e validação do backend."
    );
    gtk_widget_set_halign(state->install_button, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(page), state->install_button);
    gtk_stack_add_titled(GTK_STACK(state->stack), page,
                         page_names[3], page_titles[3]);

    sidebar = gtk_stack_sidebar_new();
    gtk_stack_sidebar_set_stack(GTK_STACK_SIDEBAR(sidebar),
                                GTK_STACK(state->stack));
    gtk_widget_set_size_request(sidebar, 180, -1);
    gtk_box_append(GTK_BOX(body), sidebar);
    gtk_box_append(GTK_BOX(body), state->stack);

    footer = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
    gtk_widget_set_margin_top(footer, 12);
    gtk_widget_set_margin_bottom(footer, 16);
    gtk_widget_set_margin_start(footer, 20);
    gtk_widget_set_margin_end(footer, 20);

    back_button = gtk_button_new_with_label("Voltar");
    next_button = gtk_button_new_with_label("Avançar");
    close_button = gtk_button_new_with_label("Fechar");
    gtk_widget_add_css_class(next_button, "suggested-action");

    gtk_box_append(GTK_BOX(footer), back_button);
    gtk_box_append(GTK_BOX(footer), next_button);
    gtk_widget_set_hexpand(close_button, TRUE);
    gtk_widget_set_halign(close_button, GTK_ALIGN_END);
    gtk_box_append(GTK_BOX(footer), close_button);
    gtk_box_append(GTK_BOX(root), footer);

    g_signal_connect(refresh_button, "clicked",
                     G_CALLBACK(on_refresh_clicked), state);
    g_signal_connect(state->disk_dropdown, "notify::selected",
                     G_CALLBACK(on_disk_changed), state);
    g_signal_connect(state->mode_dropdown, "notify::selected",
                     G_CALLBACK(on_mode_changed), state);
    g_signal_connect(state->root_size_entry, "changed",
                     G_CALLBACK(on_custom_value_changed), state);
    g_signal_connect(state->swap_size_entry, "changed",
                     G_CALLBACK(on_custom_value_changed), state);
    g_signal_connect(state->swap_check, "toggled",
                     G_CALLBACK(on_custom_value_changed), state);
    g_signal_connect(next_button, "clicked",
                     G_CALLBACK(on_next_clicked), state);
    g_signal_connect(back_button, "clicked",
                     G_CALLBACK(on_back_clicked), state);
    g_signal_connect_swapped(close_button, "clicked",
                             G_CALLBACK(gtk_window_close), window);

    install_style();
    refresh_disks(state);
    gtk_window_present(GTK_WINDOW(window));
}

int
main(int argc, char **argv)
{
    GtkApplication *application;
    int status;

    application = gtk_application_new(
        "org.venom.os.installer",
        G_APPLICATION_DEFAULT_FLAGS
    );
    g_signal_connect(application, "activate", G_CALLBACK(on_activate), NULL);
    status = g_application_run(G_APPLICATION(application), argc, argv);
    g_object_unref(application);
    return status;
}
