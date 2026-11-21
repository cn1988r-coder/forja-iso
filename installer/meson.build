project('venom-installer', 'c', version: '0.2.0', default_options: ['c_std=c17', 'warning_level=3', 'werror=true'])
gtk = dependency('gtk4', version: '>=4.10')
executable('venom-installer', 'src/main.c', dependencies: [gtk], install: true, install_dir: get_option('bindir'))
install_data('backend/venom-install-backend', install_dir: get_option('libdir') / 'venom', install_mode: 'rwxr-xr-x')
