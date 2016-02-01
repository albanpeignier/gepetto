# coding: utf-8
require 'rake/tasklib'
require 'net/ping'
require 'tempfile'

class Sandbox < Rake::TaskLib

  def self.default_architecture
    case RUBY_PLATFORM
    when /x86_64/
      "amd64"
    else
      "i386"
    end
  end

  @@images_directory = "/var/tmp"

  def self.images_directory
    @@images_directory
  end

  def self.images_directory=(directory)
    @@images_directory = directory
  end

  def puppet_file(name)
    File.dirname(__FILE__) + "/#{name}.pp"
  end

  attr_reader :name
  attr_accessor :bootstraper, :host_ip_address, :tap_device
  attr_accessor :disk_size, :memory_size, :mount_point
  attr_accessor :architecture

  def initialize(name = "sandbox")
    @name = name

    init
    yield self if block_given?
    define
  end

  def define
    @architecture = Sandbox.default_architecture
    bootstraper = DebianBoostraper.new

    @host_ip_address ||= '10.0.3.1'

    @disk_size ||= '512M'
    @memory_size ||= '128M'

    @mount_point ||= File.join(Sandbox.images_directory, name)
    @tap_device ||= 'tap0'
  end

  def bootstraper=(bootstraper)
    @bootstraper = bootstraper
    sync_architecture
  end

  def architecture=(architecture)
    @architecture = architecture
    sync_architecture
  end

  def sync_architecture
    if self.bootstraper and self.architecture
      self.bootstraper.architecture = self.architecture
    end
  end

  def kernel_architecture
    case self.architecture
    when 'i386'
      '686'
    else
      self.architecture
    end
  end

  def init
    namespace @name do

      desc "Setup local machine to host sandbox"
      task :setup => 'tmp:create' do
        sudo "puppet #{puppet_file(:host)}"
      end

      # Mix between these ways :
      # - http://www.mail-archive.com/qemu-devel@nongnu.org/msg01208.html
      # - http://www.geocities.com/gtalon51/Articles/Minimal_Linux_system/Minimal_Linux_system.html
      # - qemu-make-debian-root
      namespace :create do
        task :image do
          sh "qemu-img create -f raw #{disk_image} #{disk_size}"
          # create the partition table
          sh "echo '63,,L,*' | /sbin/sfdisk --force --no-reread #{disk_image}"
        end

        task :fs do
          # format the filesystem
          with_loop_device do |loop_device|
            # because '/sbin/sfdisk -s /dev/loopX' returns a wrong value :
            linux_partition_info = `/sbin/sfdisk -l #{disk_image}`.scan(%r{#{disk_image}.*Linux}).first
            extract_fs_block_size = linux_partition_info.split[5].to_i

            #  #{extract_fs_block_size}
            sudo "/sbin/mke2fs -jqF -L root #{loop_device}"
          end
        end

        task :system do
          # install a debian base system
          mount do
            bootstraper.bootstrap mount_point

            # Facter package fails to be configured by debootstrap under squeeze
            apt_get_install "puppet"

            begin
              apt_get_install "extlinux"
            rescue
              apt_get_install "syslinux"
            end
          end
        end

        task :kernel do
          mount do
            chroot_sh "echo 'do_initrd = Yes' >> /etc/kernel-img.conf"

            kernel_package =
              case self.bootstraper.version
              when 'hardy'
                'linux-image-2.6.24-16-generic'
              when 'intrepid'
                'linux-image-generic'
              else
                "linux-image-2.6-#{kernel_architecture}"
              end

            apt_get_install kernel_package
          end
        end

        task :syslinux do
          extlinux_dir = "#{mount_point}/boot/extlinux"

          mount do
            sudo "mkdir -p #{extlinux_dir}" unless File.exists?(extlinux_dir)
            Tempfile.open('extlinux_conf') do |f|
              f.puts "DEFAULT linux"
              f.puts "LABEL linux"
              f.puts "SAY Now booting sandbox from syslinux ..."
              f.puts "KERNEL /vmlinuz"
              f.puts "APPEND ro root=#{boot_device} initrd=/initrd.img"
              f.close
              sudo "cp #{f.path} #{extlinux_dir}/extlinux.conf"
            end

            if bootstraper.version == "wheezy"
              sudo "dd if=#{mount_point}/usr/lib/extlinux/mbr.bin of=#{disk_image} bs=440 count=1 conv=notrunc"
            end

            chroot_sh "extlinux --install -H16 -S63 /boot/extlinux"
          end

          unless bootstraper.version == "wheezy"
            sudo "dd if=/usr/lib/syslinux/mbr.bin of=#{disk_image} conv=notrunc"
          end
        end

        def boot_device
          # TODO find boot device by a less stupid way
          self.bootstraper.version != "lenny" ? "/dev/sda1" : "/dev/hda1"
        end

        task :ssh do
          ssh_pubkey = Dir["#{ENV['HOME']}/.ssh/id_*pub"].first
          ssh_dir = "#{mount_point}/root/.ssh"

          mount do
            sudo "mkdir #{ssh_dir}"
            sudo "cp #{ssh_pubkey} #{ssh_dir}/authorized_keys"
          end
        end

        task :update do
          mount do
            chroot_sh "apt-get update"
          end
        end

        task :config do
          Tempfile.open('sandbox_puppet_file') do |sandbox_puppet_file|
            sandbox_puppet_file.puts "$host_ip='#{host_ip_address}'"
            sandbox_puppet_file.puts "$sandbox_name='#{@name}'"
            sandbox_puppet_file.puts IO.read(puppet_file(:sandbox))

            sandbox_puppet_file.close

            # finalize configuration with puppet
            mount do
              sudo "cp #{sandbox_puppet_file.path} #{mount_point}/etc/sandbox.pp"

              Tempfile.open('policy-rc.d') do |f|
                f.puts "exit 101"
                sudo "cp #{f.path} #{mount_point}/usr/sbin/policy-rc.d"
              end
              sudo "chmod +x #{mount_point}/usr/sbin/policy-rc.d"

              begin
                sudo "chroot #{mount_point} puppet /etc/sandbox.pp"
              ensure
                sudo "rm #{mount_point}/usr/sbin/policy-rc.d"
              end
            end
          end
        end

        task :tap_device do
          unless tap_device_exists?
            sudo "tunctl -u #{ENV['USER']} -t #{tap_device}"
          end
        end

        task :snapshot do
          snapshot(:initial)
        end
      end

      desc "Create a fresh image for sandbox"
      task :create => [ 'clean', 'create:image', 'create:fs', 'create:system', 'create:update', 'create:kernel', 'create:syslinux', 'create:config', 'create:ssh', 'create:snapshot' ]

      desc "Destroy sandbox images"
      task :destroy => 'clean' do
        rm_f disk_image
        rm_f disk_image(:initial)
      end

      desc "Start sandbox"
      task :start => ['create:tap_device', 'tmp:create'] do
        start
      end

      desc "Start sandbox from initial image in snapshot"
      task :start_from_initial do
        start :hda => disk_image(:initial), :snapshot => true
      end

      task :wait do
        wait
      end

      desc "Stop sandbox"
      task :stop do
        sh "kill -9 `cat tmp/run/#{name}.pid`"
      end

      desc "Revert to the initial image"
      task :revert => 'puppet:clean' do
        sh "qemu-img convert -O raw #{disk_image(:initial)} #{disk_image}"
      end

      task :mount do
        mount_image ENV['LOOP_DEVICE']
      end

      task :umount do
        umount_image
      end

      task :clean => 'puppet:clean' do
        # clean known_hosts
        known_hosts_file="#{ENV['HOME']}/.ssh/known_hosts"
        sh "sed -i -e '/#{hostname} / d'  #{known_hosts_file}" if File.exists?(known_hosts_file)
      end

      task :status do
        status
      end

      namespace :puppet do

        desc "Run puppetd in sandbox"
        task :run do
          sh "./script/puppetrun --host #{hostname}"
        end

        desc "Sign a request from sandbox"
        task :sign do
          sh "./script/puppetca --sign #{hostname}"
        end

        task :clean do
          # remove pending request
          sh "rm -f ssl/ca/requests/#{hostname}*.pem"
          # remove signed certificat
          sh "./script/puppetca --clean #{hostname} || true"
        end
      end
    end
  end

  def network_interface
    vde_ctl_devices = Dir["/var/run/vde2/*.ctl"]
    unless vde_ctl_devices.empty?
      "vde,sock=#{vde_ctl_devices.first}"
    else
      "tap,ifname=#{tap_device},script=config/qemu-ifup"
    end
  end

  def start(options = {})
    # To make nested VMs :
    # $ echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf

    options = {
      :daemonize => true,
      :snapshot => ENV['SNAPSHOT'],
      :hda => disk_image,
      :nographic => false,
      :"enable-kvm" => true,
      :m => memory_size,
      :cpu => "qemu64,+vmx",
      :net => ["nic", network_interface]
    }.update(options)

    if options[:daemonize]
      options = {
        :pidfile => File.expand_path("tmp/run/#{name}.pid"), :serial => "file:" + File.expand_path("log/#{name}.log")
      }.update(options)
    end

    if File.exists? disk_image(:storage)
      options[:hdb] = disk_image(:storage)
    end

    options_as_string = options.collect do |name,value|
      argument = "-#{name}"

      case value
      when Array
        value.collect { |v| "#{argument} '#{v}'" }
      when true
        argument
      when false
      when nil
      when ''
        nil
      else
        "#{argument} '#{value}'"
      end
    end.compact.join(' ')

    qemu_command =
      case RUBY_PLATFORM
      when /x86_64/
        "qemu-system-x86_64"
      else
        "qemu"
      end

    puts "#{qemu_command} #{options_as_string}" if ENV['VERBOSE']
    sh "#{qemu_command} #{options_as_string}"
  end

  def snapshot(name)
    sh "qemu-img convert -O qcow2 #{disk_image} #{disk_image(name)}"
  end

  def wait(timeout = 30, max_try_count = 5)
    try_count = 5
    try_timeout = timeout / try_count

    5.times do
      if Ping.pingecho(@name, try_timeout)
        return
      else
        sleep try_timeout
      end
    end

    raise "no response from #{hostname} after #{timeout} seconds"
  end

  def try(retries = 2, &block)
    begin
      yield
    rescue
      if (retries -= 1) > 0
        sleep 3
        retry
      end
    end
  end

  def with_loop_device(&block)
    loop_device = `sudo losetup -f`.strip
    begin
      sudo "losetup -o #{fs_offset} #{loop_device} #{disk_image}"
      yield loop_device
    ensure
      sudo "losetup -d #{loop_device}"
    end
  end

  def mount(&block)
    with_loop_device do |loop_device|
      begin
        mount_image loop_device
        yield mount_point
      ensure
        try { umount_image }
      end
    end
  end

  attr_reader :loop_device

  def mount_image(loop_device = nil)
    sudo "mkdir #{mount_point}" unless File.exists? mount_point

    unless loop_device
      sudo "mount -o loop,offset=#{fs_offset} #{disk_image} #{mount_point}"
    else
      sudo "mount #{loop_device} #{mount_point}"
    end

    sudo "mount proc #{mount_point}/proc -t proc" if File.exists? "#{mount_point}/proc"
  end

  def umount_image
    sudo "umount #{mount_point}/proc || true"
    sudo "umount #{mount_point}"
  end

  # TODO to be customizable

  def disk_image(suffix = nil)
    suffix = "-#{suffix}" if suffix
    File.join Sandbox.images_directory, "#{name}#{suffix}.img"
  end

  def fs_offset
    32256
  end

  def hostname
    if name =~ /^sandbox/
      name
    else
      "sandbox-#{name}"
    end
  end

  def tap_device_exists?
    IO.readlines('/proc/net/dev').any? { |l| l =~ /\s+#{tap_device}/ }
  end

  def status
    puts "#{hostname} status:"
    puts self.inspect
  end

  def chroot_sh(cmd)
    sudo "chroot #{mount_point} sh -c \"#{cmd}\""
  end

  def apt_get_install(*packages)
    puts "install #{packages.inspect}"
    chroot_sh "DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes #{packages.join(' ')}"
  end

end

class DebianBoostraper

  attr_accessor :version, :mirror, :include, :exclude, :architecture

  def initialize(&block)
    @include = %w{rsyslog cron}
    @exclude = %w{exim exim exim4 exim4-base exim4-config exim4-daemon-light}

    default_attributes

    yield self if block_given?
  end

  def default_attributes
    @version = 'lenny'
    @mirror = 'http://ftp.debian.org/debian'
    @architecture = Sandbox.default_architecture
    @components = %w{main contrib non-free}
  end

  def bootstrap(root)
    options_as_string = options.collect{|k,v| "--#{k} #{Array(v).join(',')}" unless v.nil? or v.empty? }.compact.join(' ')
    sudo "debootstrap --variant=minbase #{options_as_string} #{version} #{root} #{mirror}"
  end

  def options
    {
      :arch => architecture,
      :exclude => @exclude,
      :include => @include,
      :components => @components
    }
  end

end

class UbuntuBoostraper < DebianBoostraper

  def default_attributes
    super

    @include << "ubuntu-minimal"
    @version = 'intrepid'
    @mirror = 'http://archive.ubuntu.com/ubuntu/'
  end

  def options
    super.update :components => 'main,universe'
  end

end
