project(
  'venom-installer',
  'c',
  version: '0.2.0',
  default_options: ['c_std=c17', 'warning_level=3', 'werror=true']
)

gtk4_dep = dependency('gtk4', version: '>=4.10')
gio_dep = dependency('gio-2.0')

executable(
  'venom-installer',
  'src/main.c',
  dependencies: [gtk4_dep, gio_dep],
  install: true,
  install_dir: get_option('bindir'),
)

install_data(
  'venom-installer.desktop',
  install_dir: get_option('datadir') / 'applications',
)
