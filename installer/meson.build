project(
  'venom-installer',
  'c',
  version: '0.3.0',
  default_options: ['c_std=c17', 'warning_level=3']
)

ncurses_dep = dependency('ncursesw')
glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
json_glib_dep = dependency('json-glib-1.0')

executable(
  'venom-installer',
  files('src/tui.c', 'src/disk.c', 'src/plan.c'),
  dependencies: [ncurses_dep, glib_dep, gio_dep, json_glib_dep],
  install: true,
  install_dir: get_option('bindir')
)

disk_test = executable(
  'test-disk',
  files('tests/test-disk.c', 'src/disk.c'),
  dependencies: [json_glib_dep, gio_dep]
)
test('leitura segura de discos', disk_test)

plan_test = executable(
  'test-plan',
  files('tests/test-plan.c', 'src/plan.c'),
  dependencies: [glib_dep, gio_dep]
)
test('validacao de planos sem escrita', plan_test)
