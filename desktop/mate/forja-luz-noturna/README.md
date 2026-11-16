# Forja Luz Noturna (experimental)

Aplicativo GTK3 próprio para controlar a temperatura de cor em sessões MATE/X11.

## O que contém

- Interface GTK compacta com liga/desliga, temperatura noturna e horários.
- Ícone na área de notificação quando iniciado em segundo plano.
- Ativação automática por faixa de horário (padrão: 20:00–07:00).
- Configuração persistida em `~/.config/forja/luz-noturna.json`.
- Backend independente que aplica a rampa de gama por meio de `xrandr`.

## Dependências

- `python`
- `python-gobject`
- `gtk3`
- `xorg-xrandr`

## Teste de cálculo

```sh
python desktop/mate/forja-luz-noturna/forja-luz-noturna.py --self-test
```

Para abrir a interface:

```sh
python desktop/mate/forja-luz-noturna/forja-luz-noturna.py
```

Para iniciar minimizado na área de notificação:

```sh
python desktop/mate/forja-luz-noturna/forja-luz-noturna.py --background
```

## Limitações conhecidas

Este primeiro protótipo **não reutiliza diretamente o backend do GNOME**. O modo noturno do GNOME depende da integração entre gnome-settings-daemon e Mutter; Marco não oferece a mesma API. Em vez de instalar Mutter ou o GNOME Shell, este protótipo usa XRandR diretamente.

É necessário que o driver gráfico aceite alterações de gamma via XRandR. Isso ainda precisa ser testado em hardware real e em uma sessão MATE. Em Wayland não funciona. A área de notificação também depende de um tray compatível.

O agendamento inicial usa horário local fixo, não nascer/pôr do sol. O módulo ainda não deve ser tratado como funcional/validado nem incluído numa ISO de produção antes dos testes de integração.
