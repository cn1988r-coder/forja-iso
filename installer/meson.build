project(
  'venom-installer',
  'c',
  version: '0.2.0',
  default_options: ['c_std=c11', 'warning_level=3']
)

gtk4_dep = dependency('gtk4', version: '>=4.12')
json_glib_dep = dependency('json-glib-1.0')
gio_dep = dependency('gio-2.0')

installer_sources = files('src/main.c', 'src/disk.c', 'src/plan.c')

executable(
  'venom-installer',
  installer_sources,
  dependencies: [gtk4_dep, json_glib_dep, gio_dep],
  install: true
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
  dependencies: [gio_dep]
)
test('validação de planos de partição sem escrita', plan_test)

install_data(
  'venom-installer.desktop',
  install_dir: get_option('datadir') / 'applications'
)
