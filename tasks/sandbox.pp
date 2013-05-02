# Minimal settings to boot sandbox image with qemu

# These variables are defined by rake task
#$host_ip='172.20.0.1'
#$sandbox_name='sandbox'

Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

file { "/etc/fstab":
  content => "LABEL=root / ext3 errors=remount-ro 0 1
proc /proc proc defaults 0 0
"
}

# Console on ttyS0 not tty1
exec { "inittab-ttyS0-getty":
  command => "sed -i '/getty 38400 tty1/ s/tty1/ttyS0/' /etc/inittab",
  unless => "grep 'getty 38400 ttyS0' /etc/inittab"
}

# and no other gettys
exec { "inittab-no-tty-gettys":
  command => "sed -i '/getty 38400 tty[23456]/ d' /etc/inittab",
  onlyif => "grep 'getty 38400 tty[23456]' /etc/inittab"
}

file { ["/etc/hostname", "/etc/mailname"]:
  content => "$sandbox_name"
}

file {  "/etc/default/locale":
  content => "LANG=en_US.UTF-8"
}

# an host object doesn't find a provider
file { "/etc/hosts":
  content => "127.0.0.1 localhost
127.0.1.1 $sandbox_name
$host_ip	puppet
"
}

# root's password is 'root'
user { root:
  password => '$1$aybpiIGf$cB7iFDNZvViQtQjEZ5HFQ0'
}

package { [console-common,console-tools,console-data,base-config,man-db,manpages]:
  ensure => absent
}

# if network configuration changes, eth0 is renamed by udev :-/
file { "/etc/udev/rules.d/70-persistent-net.rules":
  ensure => absent
}

file { "/etc/network/interfaces":
  content => "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
",
  require => Package[dhcp3-client]
}

package { dhcp3-client: }

exec { "add-dhcp-host-name":
  command => "echo 'send host-name \"hyppo\";' >> /etc/dhcp3/dhclient.conf",
  require => Package[dhcp3-client]
}

# puppet configuration

file { "/etc/default/puppet":
  content => "START=yes\nDAEMON_OPTS='-w 5\n'"
}

file { "/etc/puppet/namespaceauth.conf":
  content => "[puppetrunner]\nallow $host_ip\n"
}

file { "/etc/puppet/puppet.conf":
  content => "[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
pluginsync=false
color=false

[puppetd]
certname=$sandbox_name
report=true
# run puppetd .. every day
runinterval = 86400
listen=true
"
}

exec { "syslog-to-ttyS0":
  command => "echo '*.*		-/dev/ttyS0' >> /etc/rsyslog.conf",
  unless => 'grep /dev/ttyS0 /etc/rsyslog.conf'
}

package { [ssh,nano,udev,resolvconf,debian-archive-keyring,lsb-release]: }

