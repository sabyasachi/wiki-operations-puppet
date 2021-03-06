# == Class pybal::web
#
# Sets up the virtualhost and the other resources for serving the pybal configs.
#
# == Parameters
#
# [*chostname*]
# The ServerAlias hostname to add to the virtual host.
#

class pybal::web ($ensure = 'present', $vhostnames = ['pybal-config.eqiad.wmnet']) {

    apache::site { 'pybal-config':
        ensure   => $ensure,
        priority => 50,
        content  => template('pybal/config-vhost.conf.erb'),
        notify   => Service['apache2'],
        require  => File['/srv/pybal-config'],
    }

    file { '/srv/pybal-config':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $conftool_dir = '/srv/pybal-config/conftool'
    $datacenters = hiera('datacenters')
    $dc_dirs = prefix($datacenters, "${conftool_dir}/")

    file { $conftool_dir:
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # All the subdirectories
    file { $dc_dirs:
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/pybal-eval-check':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }

    pybal::web::dc_pools { $datacenters: }

}
