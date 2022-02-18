# Class: eclipse::install::download
#
# This module installs Eclipse using packages
#
# Sample Usage:
#
#  include eclipse::install::download
#
define eclipse::install::download (
  $package             = 'standard',
  $release_name        = 'kepler',
  $service_release     = 'SR1',
  $mirror              = 'https://archive.eclipse.org',
  $owner_group         = undef,
  $ensure              = present,
  $target_dir          = undef,
  $extract_command     = undef,
  $create_menu_entry   = true,
  $init_archive_module = true,
) {

  include eclipse::params
  if $init_archive_module == true {
    include ::archive
  }

  $archsuffix = $::architecture ? {
    /i.86/               => '',
    /(amd64|x86_64|x64)/ => '-x86_64',
    default              => "-${::architecture}"
  }

  $platform_tag = $::operatingsystem ? {
    windows => 'win32',
    Darwin  => 'macosx-cocoa',
    default => 'linux-gtk',
  }

  $file_ext = $::operatingsystem ? { 'windows' => 'zip', default => 'tar.gz' }
  $eclipse_exe = $::operatingsystem ? { 'windows' => 'eclipse.exe', default => 'eclipse' }
  $filename = "eclipse-${package}-${release_name}-${service_release}-${platform_tag}${archsuffix}.${file_ext}"
  $url = "${mirror}/technology/epp/downloads/release/${release_name}/${service_release}/${filename}"
  $archive_path = path_join(get_system_temp_dir(), $filename)
  $target_dir_ = $target_dir ? {
    undef   => $eclipse::params::target_dir,
    default => $target_dir
  }

  if $owner_group and $ensure == 'present' {
    exec { 'eclipse ownership':
      command     => "chgrp -R '${owner_group}' '${target_dir_}'",
      path        => $::path,
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
    exec { 'eclipse group permissions':
      command     => "find '${target_dir_}' -type d -exec chmod g+s {} \\;",
      path        => $::path,
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
    exec { 'eclipse write permissions':
      command     => "chmod -R g+w '${target_dir_}'",
      path        => $::path,
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
  }

  if $::operatingsystem != 'windows' {
    file { '/usr/share/applications/opt-eclipse.desktop':
      ensure  => $create_menu_entry ? { false => absent, default => $ensure },
      content => template('eclipse/opt-eclipse.desktop.erb'),
      mode    => 644,
      require => Archive[$archive_path]
    }
  }

  exec { "create_install_path_${target_dir_}" :
    command => "mkdir -p ${target_dir_}",
    path    => $::path,
    creates => $target_dir_,
  }
  ->
  # per https://forge.puppet.com/puppet/archive
  archive { $archive_path:
    ensure          => $ensure,
    source          => $url,
    extract         => true,
    extract_path    => $target_dir_,
    creates         => "${target_dir_}/${eclipse_exe}",
    extract_command => $extract_command,
  }

}
