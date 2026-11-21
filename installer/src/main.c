#include <gtk/gtk.h>
#include <gio/gio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    GtkWidget *window, *disk_list, *username, *hostname, *password, *status, *install_button;
    GSubprocess *process;
    gboolean dialog_pending;
} Installer;

static void set_status(Installer *app, const char *message) {
    gtk_label_set_text(GTK_LABEL(app->status), message);
}
static void show_message(Installer *app, const char *title, const char *detail) {
    GtkAlertDialog *dialog = gtk_alert_dialog_new("%s", title);
    gtk_alert_dialog_set_detail(dialog, detail ? detail : "");
    gtk_alert_dialog_show(dialog, GTK_WINDOW(app->window));
    g_object_unref(dialog);
}
static void refresh_disks(GtkButton *button, gpointer data) {
    (void)button;
    Installer *app = data;
    const char *argv[] = {"lsblk", "-dnpo", "NAME,SIZE,MODEL,TYPE", "-e", "7,11", NULL};
    gchar *out = NULL, *err = NULL;
    gint status = 0;
    GError *error = NULL;
    GtkStringList *items = gtk_string_list_new(NULL);
    if (!g_spawn_sync(NULL, (gchar **)argv, NULL, G_SPAWN_SEARCH_PATH, NULL, NULL,
                      &out, &err, &status, &error) || !g_spawn_check_wait_status(status, NULL)) {
        set_status(app, "Não foi possível consultar os discos.");
        g_clear_error(&error); g_free(out); g_free(err);
        gtk_drop_down_set_model(GTK_DROP_DOWN(app->disk_list), G_LIST_MODEL(items));
        g_object_unref(items); return;
    }
    char **lines = g_strsplit(out ? out : "", "\n", -1);
    for (guint i = 0; lines[i] != NULL; i++) {
        char *line = g_strstrip(lines[i]);
        if (!*line) continue;
        char **parts = g_strsplit_set(line, " \t", -1);
        char *first = NULL, *last = NULL;
        for (guint j = 0; parts[j] != NULL; j++) if (*parts[j]) { if (!first) first = parts[j]; last = parts[j]; }
        if (first && last && g_str_equal(last, "disk")) gtk_string_list_append(items, line);
        g_strfreev(parts);
    }
    gtk_drop_down_set_model(GTK_DROP_DOWN(app->disk_list), G_LIST_MODEL(items));
    if (g_list_model_get_n_items(G_LIST_MODEL(items)) > 0) {
        gtk_drop_down_set_selected(GTK_DROP_DOWN(app->disk_list), 0);
        set_status(app, "Confira modelo e tamanho. Todo o conteúdo do disco selecionado será apagado.");
    } else set_status(app, "Nenhum disco de destino foi detectado.");
    g_strfreev(lines); g_free(out); g_free(err); g_object_unref(items);
}
static void install_finished(GObject *source, GAsyncResult *result, gpointer data) {
    Installer *app = data;
    gchar *stdout_text = NULL, *stderr_text = NULL;
    GError *error = NULL;
    gboolean communicated = g_subprocess_communicate_utf8_finish(G_SUBPROCESS(source), result,
        &stdout_text, &stderr_text, &error);
    gboolean success = communicated && g_subprocess_get_successful(G_SUBPROCESS(source));
    gtk_widget_set_sensitive(app->install_button, TRUE);
    if (success) {
        set_status(app, "Instalação concluída. Remova a mídia e reinicie.");
        show_message(app, "VENOM OS instalada", stdout_text ? stdout_text : "Instalação concluída.");
    } else {
        set_status(app, "Falha na instalação. Consulte /var/log/venom-installer/.");
        const char *detail = error ? error->message :
            (stderr_text && *stderr_text ? stderr_text : (stdout_text ? stdout_text : "Backend encerrou com erro."));
        show_message(app, "Falha na instalação", detail);
    }
    g_clear_error(&error); g_free(stdout_text); g_free(stderr_text); g_clear_object(&app->process);
}
static void start_install(Installer *app, const char *disk) {
    const char *username = gtk_editable_get_text(GTK_EDITABLE(app->username));
    const char *hostname = gtk_editable_get_text(GTK_EDITABLE(app->hostname));
    const char *password = gtk_editable_get_text(GTK_EDITABLE(app->password));
    const char *argv[] = {"/usr/bin/pkexec", "/usr/lib/venom/venom-install-backend", NULL};
    GError *error = NULL;
    gchar *input = g_strdup_printf("%s\n%s\n%s\n%s\nAPAGAR\n", disk, username, hostname, password);
    app->process = g_subprocess_newv(argv, G_SUBPROCESS_FLAGS_STDIN_PIPE |
        G_SUBPROCESS_FLAGS_STDOUT_PIPE | G_SUBPROCESS_FLAGS_STDERR_MERGE, &error);
    if (!app->process) {
        show_message(app, "Não foi possível iniciar o instalador", error ? error->message : "pkexec não iniciou.");
        g_clear_error(&error); g_free(input); return;
    }
    gtk_widget_set_sensitive(app->install_button, FALSE);
    set_status(app, "Instalando VENOM OS offline. Não desligue o computador.");
    g_subprocess_communicate_utf8_async(app->process, input, NULL, install_finished, app);
    gtk_editable_set_text(GTK_EDITABLE(app->password), "");
    memset(input, 0, strlen(input));
    g_free(input);
}
static void confirm_install(GObject *source, GAsyncResult *result, gpointer data) {
    Installer *app = data;
    GError *error = NULL;
    int choice = gtk_alert_dialog_choose_finish(GTK_ALERT_DIALOG(source), result, &error);
    app->dialog_pending = FALSE;
    if (error) { g_clear_error(&error); return; }
    if (choice != 1) return;
    const char *selected = gtk_string_list_get_string(
        GTK_STRING_LIST(gtk_drop_down_get_model(GTK_DROP_DOWN(app->disk_list))),
        gtk_drop_down_get_selected(GTK_DROP_DOWN(app->disk_list)));
    if (!selected) return;
    char **parts = g_strsplit_set(selected, " \t", -1);
    const char *disk = NULL;
    for (guint i = 0; parts[i] != NULL; i++) if (g_str_has_prefix(parts[i], "/dev/")) { disk = parts[i]; break; }
    if (disk) start_install(app, disk);
    g_strfreev(parts);
}
static gboolean valid_field(const char *value, gboolean hostname) {
    if (!value || !*value) return FALSE;
    for (const char *p = value; *p; p++) {
        if (hostname) {
            if (!(g_ascii_isalnum(*p) || *p == '-')) return FALSE;
            if ((p == value || p[1] == '\0') && !g_ascii_isalnum(*p)) return FALSE;
        } else if (!(g_ascii_islower(*p) || g_ascii_isdigit(*p) || *p == '_' || *p == '-')) return FALSE;
    }
    return TRUE;
}
static void install_clicked(GtkButton *button, gpointer data) {
    (void)button;
    Installer *app = data;
    guint selected = gtk_drop_down_get_selected(GTK_DROP_DOWN(app->disk_list));
    guint count = g_list_model_get_n_items(gtk_drop_down_get_model(GTK_DROP_DOWN(app->disk_list)));
    const char *username = gtk_editable_get_text(GTK_EDITABLE(app->username));
    const char *hostname = gtk_editable_get_text(GTK_EDITABLE(app->hostname));
    const char *password = gtk_editable_get_text(GTK_EDITABLE(app->password));
    if (selected == GTK_INVALID_LIST_POSITION || selected >= count) {
        show_message(app, "Selecione um disco", "Nenhum disco de destino foi selecionado."); return;
    }
    if (!valid_field(username, FALSE) || g_str_equal(username, "root") || g_str_equal(username, "nobody") || !valid_field(hostname, TRUE) ||
        strlen(password) < 8 || strchr(password, '\n')) {
        show_message(app, "Dados inválidos", "Informe usuário válido, hostname sem espaços e senha com pelo menos 8 caracteres."); return;
    }
    GtkAlertDialog *dialog = gtk_alert_dialog_new("Apagar o disco selecionado?");
    gtk_alert_dialog_set_detail(dialog, "A instalação automática recriará as partições e apagará TODOS os dados do disco. "
        "O sistema será copiado da própria mídia, sem baixar pacotes. Confira o modelo e o tamanho antes de confirmar.");
    const char *buttons[] = {"Cancelar", "Apagar e instalar", NULL};
    gtk_alert_dialog_set_buttons(dialog, buttons);
    gtk_alert_dialog_set_cancel_button(dialog, 0);
    gtk_alert_dialog_set_default_button(dialog, 0);
    app->dialog_pending = TRUE;
    gtk_alert_dialog_choose(dialog, GTK_WINDOW(app->window), NULL, confirm_install, app);
    g_object_unref(dialog);
}
static GtkWidget *section_title(const char *text) {
    GtkWidget *label = gtk_label_new(text);
    gtk_widget_add_css_class(label, "title-3");
    gtk_widget_set_halign(label, GTK_ALIGN_START);
    return label;
}
static GtkWidget *make_entry(const char *placeholder, gboolean secret) {
    GtkWidget *entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), placeholder);
    gtk_entry_set_visibility(GTK_ENTRY(entry), !secret);
    gtk_entry_set_input_purpose(GTK_ENTRY(entry), secret ? GTK_INPUT_PURPOSE_PASSWORD : GTK_INPUT_PURPOSE_FREE_FORM);
    gtk_widget_set_hexpand(entry, TRUE);
    return entry;
}
static gboolean close_requested(GtkWindow *window, gpointer data) {
    (void)window;
    Installer *app = data;
    if (app->process || app->dialog_pending) {
        show_message(app, "Instalação em andamento", "Não feche o instalador enquanto a operação estiver em andamento.");
        return TRUE;
    }
    return FALSE;
}
static void activate(GtkApplication *application, gpointer user_data) {
    (void)user_data;
    Installer *app = g_new0(Installer, 1);
    app->window = gtk_application_window_new(application);
    g_object_set_data_full(G_OBJECT(app->window), "installer-state", app, g_free);
    gtk_window_set_title(GTK_WINDOW(app->window), "Instalador VENOM OS");
    g_signal_connect(app->window, "close-request", G_CALLBACK(close_requested), app);
    gtk_window_set_default_size(GTK_WINDOW(app->window), 760, 650);
    GtkWidget *root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 14);
    gtk_widget_set_margin_top(root, 26); gtk_widget_set_margin_bottom(root, 26);
    gtk_widget_set_margin_start(root, 32); gtk_widget_set_margin_end(root, 32);
    gtk_window_set_child(GTK_WINDOW(app->window), root);
    GtkWidget *title = gtk_label_new("VENOM OS");
    gtk_widget_add_css_class(title, "title-1"); gtk_widget_set_halign(title, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(root), title);
    GtkWidget *subtitle = gtk_label_new("Instalação offline do sistema");
    gtk_widget_add_css_class(subtitle, "dim-label"); gtk_widget_set_halign(subtitle, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(root), subtitle);
    gtk_box_append(GTK_BOX(root), section_title("Disco de destino"));
    app->disk_list = gtk_drop_down_new(NULL, NULL);
    gtk_widget_set_hexpand(app->disk_list, TRUE); gtk_box_append(GTK_BOX(root), app->disk_list);
    GtkWidget *refresh = gtk_button_new_with_label("Atualizar discos");
    gtk_widget_set_halign(refresh, GTK_ALIGN_START);
    g_signal_connect(refresh, "clicked", G_CALLBACK(refresh_disks), app);
    gtk_box_append(GTK_BOX(root), refresh);
    gtk_box_append(GTK_BOX(root), section_title("Conta do sistema"));
    app->username = make_entry("Nome de usuário (ex.: ricardo)", FALSE);
    app->hostname = make_entry("Nome do computador (ex.: venom-pc)", FALSE);
    app->password = make_entry("Senha (mínimo 8 caracteres)", TRUE);
    gtk_box_append(GTK_BOX(root), app->username); gtk_box_append(GTK_BOX(root), app->hostname);
    gtk_box_append(GTK_BOX(root), app->password);
    GtkWidget *notice = gtk_label_new("A instalação automática apaga integralmente o disco selecionado. "
        "A mídia será copiada para o disco sem baixar pacotes. Mantenha o computador ligado.");
    gtk_label_set_wrap(GTK_LABEL(notice), TRUE); gtk_widget_add_css_class(notice, "warning");
    gtk_widget_set_halign(notice, GTK_ALIGN_START); gtk_box_append(GTK_BOX(root), notice);
    app->status = gtk_label_new("Detectando discos...");
    gtk_label_set_wrap(GTK_LABEL(app->status), TRUE); gtk_widget_set_halign(app->status, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(root), app->status);
    GtkWidget *spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_vexpand(spacer, TRUE); gtk_box_append(GTK_BOX(root), spacer);
    app->install_button = gtk_button_new_with_label("Instalar VENOM OS");
    gtk_widget_add_css_class(app->install_button, "suggested-action");
    g_signal_connect(app->install_button, "clicked", G_CALLBACK(install_clicked), app);
    gtk_box_append(GTK_BOX(root), app->install_button);
    refresh_disks(NULL, app);
    gtk_window_present(GTK_WINDOW(app->window));
}
int main(int argc, char **argv) {
    GtkApplication *application = gtk_application_new("org.venomos.installer", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(application, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(application), argc, argv);
    g_object_unref(application);
    return status;
}
