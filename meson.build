# Project name, programming language and version
project (
    'com.github.marbetschar.boxes',
    'vala', 'c',
    version: '0.0.1'
)

# GNOME module
gnome = import('gnome')

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# Project resources
asresources = gnome.compile_resources(
    'as-resources',
    'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gee-0.8'),
    dependency ('gtk+-3.0'),
    dependency ('json-glib-1.0'),
]

subdir ('lxd')
subdir ('src')

# Executable
executable (
    meson.project_name (),
    asresources,
    lxd_sources,
    sources,
    dependencies: dependencies,
    install: true
)

subdir ('data')
subdir ('po')

meson.add_install_script ('meson/post_install.py')
