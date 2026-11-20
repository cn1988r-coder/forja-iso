#include <gtk/gtk.h>
#include <gio/gio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    GtkWidget *window;
    GtkWidget *disk_list;
    GtkWidget *status;
    GtkWidget *install_button;
    GtkWidget *mode_auto;
    GtkWidget *mode_custom;
} Installer;

static void set_status(Installer *app, const char *message) {
    gtk_label_set_text(GTK_LABEL(app->status), message);
}

static char *run_lsblk(void) {
    const char *argv[] = {
        "lsblk", "-dnpo", "NAME,SIZE,MODEL,TYPE", "-e", "7,11", NULL
    };
    gchar *out = NULL, *err = NULL;
    gint status = 0;
    GError *error = NULL;
    if (!g_spawn_sync(NULL, (gchar **)argv, NULL, G_SPAWN_SEARCH_PATH,
                     NULL, NULL, &out, &err, &status, &error)) {
        g_clear_error(&error);
        g_free(err);
        return g_strdup("");
    }
    g_free(err);
    if (!g_spawn_check_wait_status(status, NULL)) {
        g_free(out);
        return g_strdup("");
    }
    return out ? out : g_strdup("");
}

static void refresh_disks(GtkButton *button, gpointer data) {
    (void)button;
    Installer *app = data;
    GtkStringList *items = gtk_string_list_new(NULL);
    char *output = run_lsblk();
    char **lines = g_strsplit(output, "\n", -1);
    for (guint i = 0; lines[i] != NULL; i++) {
        char *line = g_strstrip(lines[i]);
        if (*line == '\0') continue;
        gtk_string_list_append(items, line);
    }
    gtk_drop_down_set_model(GTK_DROP_DOWN(app->disk_list), G_LIST_MODEL(items));
    if (gtk_string_list_get_n_items(items) == 0)
        set_status(app, "Nenhum disco detectado. Verifique a conexão e atualize a lista.");
    else
        set_status(app, "Discos detectados. Confira cuidadosamente o modelo e o tamanho.");
    g_strfreev(lines);
    g_free(output);
    g_object_unref(items);
}

static void install_clicked(GtkButton *button, gpointer data) {
    (void)button;
    Installer *app = data;
    set_status(app,
        "Instalação ainda bloqueada: o backend seguro e os testes em disco virtual "
        "precisam ser concluídos. Nenhuma alteração foi feita nos discos.");
    GtkAlertDialog *dialog = gtk_alert_dialog_new(
        "A instalação ainda não está disponível nesta versão.");
    gtk_alert_dialog_set_detail(dialog,
        "Esta interface é a estrutura inicial do instalador VENOM. "
        "O botão não particiona, formata nem grava em nenhum disco.");
    gtk_alert_dialog_show(dialog, GTK_WINDOW(app->window));
    g_object_unref(dialog);
}

static GtkWidget *section_title(const char *text) {
    GtkWidget *label = gtk_label_new(text);
    gtk_widget_add_css_class(label, "title-3");
    gtk_widget_set_halign(label, GTK_ALIGN_START);
    return label;
}

static void activate(GtkApplication *application, gpointer user_data) {
    (void)user_data;
    Installer *app = g_new0(Installer, 1);

    app->window = gtk_application_window_new(application);
    gtk_window_set_title(GTK_WINDOW(app->window), "Instalador VENOM OS");
    gtk_window_set_default_size(GTK_WINDOW(app->window), 760, 560);

    GtkWidget *root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 18);
    gtk_widget_set_margin_top(root, 28);
    gtk_widget_set_margin_bottom(root, 28);
    gtk_widget_set_margin_start(root, 32);
    gtk_widget_set_margin_end(root, 32);
    gtk_window_set_child(GTK_WINDOW(app->window), root);

    GtkWidget *header = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
    GtkWidget *title = gtk_label_new("VENOM OS");
    gtk_widget_add_css_class(title, "title-1");
    gtk_widget_set_halign(title, GTK_ALIGN_START);
    GtkWidget *subtitle = gtk_label_new("Instalação do sistema");
    gtk_widget_add_css_class(subtitle, "dim-label");
    gtk_widget_set_halign(subtitle, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(header), title);
    gtk_box_append(GTK_BOX(header), subtitle);
    gtk_box_append(GTK_BOX(root), header);

    GtkWidget *disk_section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_box_append(GTK_BOX(disk_section), section_title("Disco de destino"));
    app->disk_list = gtk_drop_down_new(NULL, NULL);
    gtk_widget_set_hexpand(app->disk_list, TRUE);
    gtk_box_append(GTK_BOX(disk_section), app->disk_list);

    GtkWidget *refresh = gtk_button_new_with_label("Atualizar discos");
    g_signal_connect(refresh, "clicked", G_CALLBACK(refresh_disks), app);
    gtk_widget_set_halign(refresh, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(disk_section), refresh);
    gtk_box_append(GTK_BOX(root), disk_section);

    GtkWidget *mode_section = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_box_append(GTK_BOX(mode_section), section_title("Tipo de instalação"));
    app->mode_auto = gtk_check_button_new_with_label("Automática (usar o disco selecionado)");
    app->mode_custom = gtk_check_button_new_with_label("Personalizada (particionamento manual)");
    gtk_check_button_set_group(GTK_CHECK_BUTTON(app->mode_custom),
                               GTK_CHECK_BUTTON(app->mode_auto));
    gtk_check_button_set_active(GTK_CHECK_BUTTON(app->mode_auto), TRUE);
    gtk_box_append(GTK_BOX(mode_section), app->mode_auto);
    gtk_box_append(GTK_BOX(mode_section), app->mode_custom);
    gtk_box_append(GTK_BOX(root), mode_section);

    GtkWidget *notice = gtk_label_new(
        "A instalação automática apagará os dados do disco escolhido. "
        "A versão atual não executa operações destrutivas.");
    gtk_label_set_wrap(GTK_LABEL(notice), TRUE);
    gtk_widget_add_css_class(notice, "warning");
    gtk_widget_set_halign(notice, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(root), notice);

    app->status = gtk_label_new("Aguardando detecção dos discos.");
    gtk_label_set_wrap(GTK_LABEL(app->status), TRUE);
    gtk_widget_set_halign(app->status, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(root), app->status);

    GtkWidget *spacer = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_vexpand(spacer, TRUE);
    gtk_box_append(GTK_BOX(root), spacer);

    app->install_button = gtk_button_new_with_label("Instalar VENOM OS");
    gtk_widget_add_css_class(app->install_button, "suggested-action");
    gtk_widget_set_sensitive(app->install_button, TRUE);
    g_signal_connect(app->install_button, "clicked", G_CALLBACK(install_clicked), app);
    gtk_box_append(GTK_BOX(root), app->install_button);

    refresh_disks(NULL, app);
    gtk_window_present(GTK_WINDOW(app->window));
}

int main(int argc, char **argv) {
    GtkApplication *application = gtk_application_new(
        "org.venomos.installer", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(application, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(application), argc, argv);
    g_object_unref(application);
    return status;
}
