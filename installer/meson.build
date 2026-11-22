project('venom-installer', 'c', version: '0.1.0', default_options: ['c_std=c17', 'warning_level=3', 'werror=true'])

gtk = dependency('gtk4', version: '>=4.10', required: false)
if gtk.found()
  executable(
    'venom-installer',
    'src/main.c',
    dependencies: [gtk],
    install: true,
    install_dir: get_option('bindir'),
  )
endif


# Interface comum do instalador em modo texto, usada no boot direto.
ncurses_dep = dependency('ncursesw')
glib_dep = dependency('glib-2.0')
json_glib_dep = dependency('json-glib-1.0')
gio_dep = dependency('gio-2.0')
executable(
  'venom-installer-tui',
  files('src/tui.c', 'src/disk.c', 'src/plan.c'),
  dependencies: [ncurses_dep, glib_dep, json_glib_dep, gio_dep],
  install: true,
  install_dir: get_option('bindir'),
)


plan_test = executable(
  'test-plan',
  files('tests/test-plan.c', 'src/plan.c'),
  dependencies: [gio_dep],
)
test('validacao do plano Btrfs sem escrita em disco', plan_test)
