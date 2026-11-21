#include <gtk/gtk.h>

#include "disk.h"

typedef struct {
    GtkWidget *stack;
    GtkWidget *disk_dropdown;
    GtkWidget *disk_details;
    GtkWidget *install_button;
    GtkStringList *disk_model;
    GPtrArray *disks;
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
    g_clear_object(&state->disk_model);
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

static void
update_disk_details(AppState *state)
{
    guint selected;
    VenomDisk *disk;
    gchar *size_text;
    gchar *details;

    if (state->disks == NULL || state->disks->len == 0) {
        gtk_label_set_text(GTK_LABEL(state->disk_details),
                           "Nenhum disco local foi detectado.");
        return;
    }

    selected = gtk_drop_down_get_selected(
        GTK_DROP_DOWN(state->disk_dropdown));
    if (selected >= state->disks->len) {
        gtk_label_set_text(GTK_LABEL(state->disk_details),
                           "Selecione um disco para consultar os detalhes.");
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

    gtk_css_provider_load_from_data(provider, css, -1);
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

    (void) user_data;

    state->disk_model = gtk_string_list_new(NULL);
    state->disks = g_ptr_array_new_with_free_func(venom_disk_free);
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
        "Escolha o disco",
        "A lista abaixo é obtida do sistema e serve apenas para identificação. "
        "O particionamento automático e personalizado será habilitado após "
        "a conclusão e os testes do mecanismo de instalação."
    );
    state->disk_dropdown = gtk_drop_down_new(
        G_LIST_MODEL(state->disk_model), NULL);
    gtk_box_append(GTK_BOX(page), state->disk_dropdown);

    refresh_button = gtk_button_new_with_label("Atualizar lista de discos");
    gtk_widget_set_halign(refresh_button, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(page), refresh_button);

    state->disk_details = gtk_label_new(
        "Consultando os dispositivos disponíveis..."
    );
    gtk_label_set_xalign(GTK_LABEL(state->disk_details), 0.0f);
    gtk_label_set_wrap(GTK_LABEL(state->disk_details), TRUE);
    gtk_box_append(GTK_BOX(page), state->disk_details);
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
