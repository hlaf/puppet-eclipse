# Class: eclipse::install::download
#
# This module installs Eclipse using packages
#
# Sample Usage:
#
#  include eclipse::install::download
#
class eclipse::install::download (
  $package           = 'standard',
  $release_name      = 'kepler',
  $service_release   = 'SR1',
  $mirror            = 'https://archive.eclipse.org',
  $owner_group       = undef,
  $ensure            = present,
  $create_menu_entry = true,
) {

  include eclipse::params
  include ::archive

  $archsuffix = $::architecture ? {
    /i.86/           => '',
    /(amd64|x86_64)/ => '-x86_64',
    default          => "-${::architecture}"
  }

  $platform_tag = $::operatingsystem ? {
    windows => 'win32',
    Darwin  => 'macosx-cocoa',
    default => 'linux-gtk',
  }

  $filename = "eclipse-${package}-${release_name}-${service_release}-${platform_tag}${archsuffix}.tar.gz"
  $url = "${mirror}/technology/epp/downloads/release/${release_name}/${service_release}/${filename}"
  $archive_path = "/var/tmp/source/${filename}"

  if $owner_group and $ensure == 'present' {
    exec { 'eclipse ownership':
      command     => "chgrp -R '${owner_group}' '${eclipse::params::target_dir}/eclipse'",
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
    exec { 'eclipse group permissions':
      command     => "find '${eclipse::params::target_dir}/eclipse' -type d -exec chmod g+s {} \\;",
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
    exec { 'eclipse write permissions':
      command     => "chmod -R g+w '${eclipse::params::target_dir}/eclipse'",
      refreshonly => true,
      subscribe   => Archive[$archive_path]
    }
  }

  file { '/usr/share/applications/opt-eclipse.desktop':
    ensure  => $create_menu_entry ? { false => absent, default => $ensure },
    content => template('eclipse/opt-eclipse.desktop.erb'),
    mode    => 644,
    require => Archive[$archive_path]
  }

  # per https://forge.puppet.com/puppet/archive
  archive { $archive_path:
    ensure       => $ensure,
    source       => $url,
    extract      => true,
    extract_path => $eclipse::params::target_dir,
    creates      => "${eclipse::params::target_dir}/eclipse",
  }

}
