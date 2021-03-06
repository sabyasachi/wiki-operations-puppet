# Class: role::installserver
#
# A WMF role class used to install all the install_server stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       ready
#
# Requires:
#
#   Class['install_server::apt_repository']
#   Class['install_server::preseed_server']
#   Class['install_server::tftp_server']
#   Class['install_server::web_server']
#   Class['install_server::dhcp_server']
#   Define['backup::set']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver

class role::installserver {
    system::role { 'role::install_server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include base::firewall
    include role::backup::host
    include install_server::apt_repository
    include install_server::preseed_server

    # mirrors stuff. these should be moved to their own role class eventually
    include mirrors::serve
    include mirrors::ubuntu
    nrpe::monitor_service {'check_ubuntu_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/ubuntu',
    }

    include mirrors::debian
    nrpe::monitor_service {'check_debian_mirror':
        description  => 'Debian mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/mirrors/debian',
    }

    include install_server::tftp_server
    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }

    class { 'squid3':
        config_source => 'puppet:///files/caching-proxy/squid3-apt-proxy.conf',
    }

    cron { 'squid-logrotate':
        ensure  => 'present',
        command => '/usr/sbin/squid3 -k rotate',
        user    => 'root',
        hour    => '17',
        minute  => '15',
    }

    ferm::rule { 'proxy':
        rule => 'proto tcp dport 8080 { saddr $ALL_NETWORKS ACCEPT; }'
    }

    include install_server::web_server
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }

    include install_server::dhcp_server
    ferm::rule { 'dhcp':
        rule => 'proto udp dport bootps { saddr $ALL_NETWORKS ACCEPT; }'
    }

    # Backup
    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
              'srv-wikimedia',
            ]
    backup::set { $sets : }

    # Monitoring
    monitoring::service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }
    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

# Class: role::install_server::tftp_server
#
# A WMF role class used to install all the install_server TFTP stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       TFTP server ready
#
# Requires:
#
#   Class['install-_server::tftp_server']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver::tftp_server

class role::installserver::tftp_server {
    system::role { 'role::install_server::tftp_server':
        description => 'WMF TFTP server',
    }

    include base::firewall
    include install_server::tftp_server

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }
}
