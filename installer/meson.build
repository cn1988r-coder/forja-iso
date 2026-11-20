project('venom-installer', 'c', version: '0.1.0', default_options: ['c_std=c17', 'warning_level=3', 'werror=true'])

gtk = dependency('gtk4', version: '>=4.10')
executable(
  'venom-installer',
  'src/main.c',
  dependencies: [gtk],
  install: true,
  install_dir: get_option('bindir'),
)
