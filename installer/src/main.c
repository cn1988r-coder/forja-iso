#include <gtk/gtk.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#define INSTALLER "/usr/lib/venom/venom-install"
typedef struct {
 GtkWidget *window,*disks,*fullname,*username,*password,*confirm_password,*status,*install_button;
 GSubprocess *process; char *password_file;
} Installer;
static void message(GtkWindow *parent,const char *title,const char *detail){
 GtkAlertDialog *d=gtk_alert_dialog_new("%s",title); gtk_alert_dialog_set_detail(d,detail);
 gtk_alert_dialog_show(d,parent); g_object_unref(d);
}
static char *selected_disk(Installer *a){
 guint n=gtk_drop_down_get_selected(GTK_DROP_DOWN(a->disks));
 GtkStringList *m=GTK_STRING_LIST(gtk_drop_down_get_model(GTK_DROP_DOWN(a->disks)));
 const char *s=gtk_string_list_get_string(m,n); if(!s)return NULL;
 const char *e=strchr(s,' '); return e?g_strndup(s,e-s):g_strdup(s);
}
static void refresh_disks(Installer *a){
 const char *argv[]={"lsblk","-dnpo","NAME,SIZE,TYPE,RM,MODEL",NULL};
 gchar *out=NULL,*errout=NULL; gint status=0; GError *error=NULL;
 GtkStringList *items=gtk_string_list_new(NULL);
 if(g_spawn_sync(NULL,(gchar **)argv,NULL,G_SPAWN_SEARCH_PATH,NULL,NULL,&out,&errout,&status,&error)){
  gchar **lines=g_strsplit(out?out:"","\n",-1);
  for(guint i=0;lines[i];i++){
   gchar *line=g_strstrip(lines[i]); if(!*line)continue;
   gchar **raw=g_strsplit_set(line," \t",-1); GPtrArray *tok=g_ptr_array_new();
   for(guint j=0;raw[j];j++)if(*raw[j])g_ptr_array_add(tok,raw[j]);
   guint n=tok->len;
   if(n>=4 && g_str_equal(g_ptr_array_index(tok,2),"disk") && g_str_equal(g_ptr_array_index(tok,3),"0"))
    gtk_string_list_append(items,line);
   g_ptr_array_unref(tok); g_strfreev(raw);
  }
  g_strfreev(lines);
 }else message(GTK_WINDOW(a->window),"Falha ao listar discos",error?error->message:"lsblk não executou.");
 g_clear_error(&error); g_free(out); g_free(errout);
 gtk_drop_down_set_model(GTK_DROP_DOWN(a->disks),G_LIST_MODEL(items));
 if(g_list_model_get_n_items(G_LIST_MODEL(items))) {
  gtk_drop_down_set_selected(GTK_DROP_DOWN(a->disks),0);
  gtk_label_set_text(GTK_LABEL(a->status),"Selecione o disco. Todo o conteúdo dele será apagado.");
 } else gtk_label_set_text(GTK_LABEL(a->status),"Nenhum disco interno compatível foi encontrado.");
 g_object_unref(items);
}
static void busy(Installer *a,gboolean b){
 gtk_widget_set_sensitive(a->disks,!b); gtk_widget_set_sensitive(a->fullname,!b);
 gtk_widget_set_sensitive(a->username,!b); gtk_widget_set_sensitive(a->password,!b);
 gtk_widget_set_sensitive(a->confirm_password,!b); gtk_widget_set_sensitive(a->install_button,!b);
}
static void finished(GObject *src,GAsyncResult *res,gpointer data){
 (void)src; Installer *a=data; GError *e=NULL;
 gboolean ok=g_subprocess_wait_check_finish(G_SUBPROCESS(a->process),res,&e); busy(a,FALSE);
 if(a->password_file){g_unlink(a->password_file);g_clear_pointer(&a->password_file,g_free);}
 if(ok){gtk_label_set_text(GTK_LABEL(a->status),"Instalação concluída. Remova o pendrive e reinicie.");
  message(GTK_WINDOW(a->window),"VENOM OS instalada","A instalação terminou. Remova o pendrive e reinicie o computador.");
 }else{gtk_label_set_text(GTK_LABEL(a->status),"Falha na instalação. Consulte /var/log/venom-installer.log.");
  message(GTK_WINDOW(a->window),"Falha na instalação",e?e->message:"Consulte /var/log/venom-installer.log.");}
 g_clear_error(&e); g_clear_object(&a->process);
}
static void begin_install(Installer *a,const char *disk){
 const char *name=gtk_editable_get_text(GTK_EDITABLE(a->fullname));
 const char *user=gtk_editable_get_text(GTK_EDITABLE(a->username));
 const char *pass=gtk_editable_get_text(GTK_EDITABLE(a->password));
 const char *confirm=gtk_editable_get_text(GTK_EDITABLE(a->confirm_password));
 GError *e=NULL; int fd=-1;
 if(!disk||!*disk){message(GTK_WINDOW(a->window),"Disco não selecionado","Escolha um disco.");return;}
 if(!*name||!g_regex_match_simple("^[a-z_][a-z0-9_-]{0,30}$",user,0,0)){
  message(GTK_WINDOW(a->window),"Dados inválidos","Informe o nome completo e um usuário válido (letras minúsculas, números, _ ou -).");return;}
 if(strlen(pass)<8||!g_str_equal(pass,confirm)){
  message(GTK_WINDOW(a->window),"Senha inválida","As senhas devem ser iguais e ter pelo menos 8 caracteres.");return;}
 if(!g_file_open_tmp("/tmp/venom-password-XXXXXX",&a->password_file,&e,&fd)){
  message(GTK_WINDOW(a->window),"Erro",e?e->message:"Não foi possível preparar a senha.");g_clear_error(&e);return;}
 (void)fchmod(fd,0600);
 gchar *payload=g_strdup_printf("%s\n",pass); gsize payload_len=strlen(payload);
 ssize_t written=write(fd,payload,payload_len); close(fd); g_free(payload);
 if(written!=(ssize_t)payload_len){g_unlink(a->password_file);g_clear_pointer(&a->password_file,g_free);
  message(GTK_WINDOW(a->window),"Erro","Não foi possível preparar a senha.");return;}
 gtk_editable_set_text(GTK_EDITABLE(a->password),"");
 gtk_editable_set_text(GTK_EDITABLE(a->confirm_password),"");
 a->process=g_subprocess_new(G_SUBPROCESS_FLAGS_NONE,&e,"sudo","-n",INSTALLER,disk,user,name,a->password_file,NULL);
 if(!a->process){g_unlink(a->password_file);g_clear_pointer(&a->password_file,g_free);
  message(GTK_WINDOW(a->window),"Erro ao iniciar",e?e->message:"Backend indisponível.");g_clear_error(&e);return;}
 busy(a,TRUE); gtk_label_set_text(GTK_LABEL(a->status),"Instalando a VENOM OS. Não desligue o computador.");
 g_subprocess_wait_check_async(a->process,NULL,finished,a);
}
static void confirmed(GObject *src,GAsyncResult *res,gpointer data){
 Installer *a=data; GError *e=NULL; int response=gtk_alert_dialog_choose_finish(GTK_ALERT_DIALOG(src),res,&e);
 if(e){g_clear_error(&e);return;} if(response==1){char *d=selected_disk(a);begin_install(a,d);g_free(d);}
}
static void install_clicked(GtkButton *b,gpointer data){
 (void)b; Installer *a=data; char *disk=selected_disk(a);
 if(!disk){message(GTK_WINDOW(a->window),"Nenhum disco","Conecte um disco e atualize a lista.");return;}
 GtkAlertDialog *d=gtk_alert_dialog_new("Apagar e instalar no disco %s?",disk);
 gtk_alert_dialog_set_detail(d,"Todos os arquivos, partições e sistemas existentes nesse disco serão apagados.");
 const char *buttons[]={"Cancelar","Apagar e instalar",NULL}; gtk_alert_dialog_set_buttons(d,buttons);
 gtk_alert_dialog_set_cancel_button(d,0); gtk_alert_dialog_set_default_button(d,0);
 gtk_alert_dialog_choose(d,GTK_WINDOW(a->window),NULL,confirmed,a); g_object_unref(d); g_free(disk);
}
static GtkWidget *label(const char *s){GtkWidget *w=gtk_label_new(s);gtk_widget_set_halign(w,GTK_ALIGN_START);return w;}
static void activate(GtkApplication *app,gpointer data){
 (void)data; Installer *a=g_new0(Installer,1); a->window=gtk_application_window_new(app);
 gtk_window_set_title(GTK_WINDOW(a->window),"Instalador VENOM OS");gtk_window_set_default_size(GTK_WINDOW(a->window),620,610);
 GtkWidget *box=gtk_box_new(GTK_ORIENTATION_VERTICAL,10);gtk_widget_set_margin_top(box,24);
 gtk_widget_set_margin_bottom(box,24);gtk_widget_set_margin_start(box,28);gtk_widget_set_margin_end(box,28);
 gtk_window_set_child(GTK_WINDOW(a->window),box);
 GtkWidget *title=label("VENOM OS");gtk_widget_add_css_class(title,"title-1");gtk_box_append(GTK_BOX(box),title);
 gtk_box_append(GTK_BOX(box),label("Instalação simples do sistema"));
 gtk_box_append(GTK_BOX(box),label("Disco de destino"));a->disks=gtk_drop_down_new(NULL,NULL);gtk_box_append(GTK_BOX(box),a->disks);
 GtkWidget *refresh=gtk_button_new_with_label("Atualizar discos");gtk_widget_set_halign(refresh,GTK_ALIGN_START);
 g_signal_connect_swapped(refresh,"clicked",G_CALLBACK(refresh_disks),a);gtk_box_append(GTK_BOX(box),refresh);
 gtk_box_append(GTK_BOX(box),label("Nome completo"));a->fullname=gtk_entry_new();gtk_entry_set_placeholder_text(GTK_ENTRY(a->fullname),"Seu nome");gtk_box_append(GTK_BOX(box),a->fullname);
 gtk_box_append(GTK_BOX(box),label("Nome de usuário"));a->username=gtk_entry_new();gtk_entry_set_placeholder_text(GTK_ENTRY(a->username),"usuario");gtk_box_append(GTK_BOX(box),a->username);
 gtk_box_append(GTK_BOX(box),label("Senha"));a->password=gtk_password_entry_new();gtk_password_entry_set_show_peek_icon(GTK_PASSWORD_ENTRY(a->password),TRUE);gtk_box_append(GTK_BOX(box),a->password);
 gtk_box_append(GTK_BOX(box),label("Confirme a senha"));a->confirm_password=gtk_password_entry_new();gtk_password_entry_set_show_peek_icon(GTK_PASSWORD_ENTRY(a->confirm_password),TRUE);gtk_box_append(GTK_BOX(box),a->confirm_password);
 GtkWidget *warning=label("A instalação apaga o disco escolhido e exige conexão com a internet.");gtk_label_set_wrap(GTK_LABEL(warning),TRUE);gtk_widget_add_css_class(warning,"warning");gtk_box_append(GTK_BOX(box),warning);
 a->status=label("Detectando discos...");gtk_label_set_wrap(GTK_LABEL(a->status),TRUE);gtk_box_append(GTK_BOX(box),a->status);
 a->install_button=gtk_button_new_with_label("Instalar VENOM OS");gtk_widget_add_css_class(a->install_button,"suggested-action");
 g_signal_connect(a->install_button,"clicked",G_CALLBACK(install_clicked),a);gtk_box_append(GTK_BOX(box),a->install_button);
 refresh_disks(a);gtk_window_present(GTK_WINDOW(a->window));
}
int main(int argc,char **argv){
 GtkApplication *app=gtk_application_new("org.venomos.installer",G_APPLICATION_DEFAULT_FLAGS);
 g_signal_connect(app,"activate",G_CALLBACK(activate),NULL);int status=g_application_run(G_APPLICATION(app),argc,argv);
 g_object_unref(app);return status;
}
