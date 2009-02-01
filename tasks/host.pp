Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

# install qemu

package { qemu: 
  ensure => installed
}

# compile kqemu module 

package { module-assistant: 
  ensure => installed
}

exec { "modass-kqemu":
  command => "module-assistant a-i kqemu",
  unless => 'dpkg -l "kqemu-modules-`uname -r`"',
  require => Package[module-assistant]
}

exec { "add kqemu in /etc/modules":
  command => "echo kqemu >> /etc/modules",
  unless => "grep kqemu /etc/modules",
  require => Exec["modass-kqemu"]
}

file { "/dev/kqemu":
  # default permissions on debian, but not on ubuntu
  mode => 666
}

# install uml-utilities for tunctl 

package { uml-utilities: }

exec { "add tun in /etc/modules":
  command => "echo tun >> /etc/modules",
  unless => "grep tun /etc/modules"
}

exec { "modprobe tun":
  unless => "lsmod | grep tun"
}

file { "/dev/net/tun":
  mode => 666
}

# provide a basic qemu-ifup

file { "/etc/qemu-ifup":
  mode => 755,
  content => '#!/bin/sh -x

if [ "$USER" != "root" -o "$1" != "sudo" ]; then
  exec sudo -p "Password for $0:" $0 sudo $1
fi

[ "$1" = "sudo" ] && shift

/sbin/ifconfig $1 172.20.0.1
iptables -t nat -A POSTROUTING -s 172.20.0.1/24 -o eth0 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1
'
}
