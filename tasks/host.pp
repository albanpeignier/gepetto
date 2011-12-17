Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

# install qemu

package { qemu:
  ensure => "latest"
}

# compile kqemu module

package { kqemu-source:
  ensure => "latest",
  require => Package[qemu]
}

if $operatingsystem == Debian {
  # under Ubuntu, dkms does the job
  exec { "modass-kqemu":
    # modass returns 249 with non-inter ...
    command => 'module-assistant --non-inter a-i kqemu || dpkg -l "kqemu-modules-`uname -r`" | grep ^ii',
    unless => 'dpkg -l "kqemu-modules-`uname -r`" | grep ^ii' ,
    require => Package[kqemu-source]
  }

  exec { "add kqemu in /etc/modules":
    command => "echo kqemu >> /etc/modules",
    unless => "grep kqemu /etc/modules",
    require => Exec["modass-kqemu"]
  }
}

exec { "modprobe-kqemu":
  command => "modprobe kqemu",
  unless => "lsmod | grep kqemu",
  require => Package[kqemu-source]
}

file { "/dev/kqemu":
  # default permissions on debian, but not on ubuntu
  mode => 666,
  require => Exec["modprobe-kqemu"]
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

package { debootstrap: }

if $operatingsystem == Debian {
  package { [syslinux-common, extlinux]: }
} else {
  package { syslinux: }
}
