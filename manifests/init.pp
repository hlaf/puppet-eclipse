# Class: eclipse
#
# This module installs Eclipse
#
# Sample Usage:
#
#  include eclipse
#
class eclipse (
  $package                  = 'standard',
  $release_name             = 'kepler',
  $service_release          = 'SR2',
  $method                   = 'package',
  $owner_group              = undef,
  $ensure                   = present,
  $create_menu_entry        = true,
  $target_dir               = undef,
  $download_extract_command = undef,
) {

  include eclipse::params

  $repository = "http://download.eclipse.org/releases/${release_name}"

  case $method {
    download: {
      eclipse::install::download { "${package}@${release_name}@${service_release}":
        package           => $package,
        release_name      => $release_name,
        service_release   => $service_release,
        owner_group       => $owner_group,
        ensure            => $ensure,
        create_menu_entry => $create_menu_entry,
        target_dir        => $target_dir,
        extract_command   => $download_extract_command,
      }
      $bin = $eclipse::params::download_bin
    }
    package: {
      class { 'eclipse::install::package':
        ensure => $ensure
      }
      $bin = $eclipse::params::package_bin
    }
    default: {
      fail("Installation method ${method} is not supported")
    }
  }

}
