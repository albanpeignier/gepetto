require 'rake/tasklib'
require 'ping'
require 'tempfile'

class Sandbox < Rake::TaskLib

  @@images_directory = "/var/tmp"

  def self.images_directory
    @@images_directory
  end

  def self.images_directory=(directory)
    @@images_directory = directory
  end

  @@puppet_file = File.dirname(__FILE__) + '/sandbox.pp'

  attr_reader :name
  attr_accessor :bootstraper, :ip_address, :host_ip_address, :tap_device
  attr_accessor :disk_size, :memory_size, :mount_point

  def initialize(name = "sandbox")
    @name = name

    init
    yield self if block_given?
    define
  end

  def define
    @bootstraper ||= DebianBoostraper.new

    @ip_address ||= '172.20.0.2'
    @host_ip_address ||= @ip_address.gsub(/\.[0-9]+$/,'.1')

    @disk_size ||= '512M'
    @memory_size ||= '128M'

    @mount_point ||= "/mnt/#{name}"
    @tap_device ||= 'tap0'
  end

  def init
    namespace @name do

      desc "Setup local machine to host sandbox"
      task :setup => 'tmp:create' do
        # experimental qemu required to work with kqemu
        sudo "apt-get install -t experimental qemu"

        sudo "apt-get install module-assistant"
        sudo "module-assistant a-i kqemu"

        sudo "apt-get install uml-utilities"

        puts <<EOF 

You need to route network traffic between your sandbox and your local network. 

For example in your /etc/qemu-ifup:

/sbin/ifconfig $1 #{host_ip_address}
iptables -t nat -A POSTROUTING -s #{host_ip_address}/24 -o eth0 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1

EOF
      end

      # Mix between these ways :
      # - http://www.mail-archive.com/qemu-devel@nongnu.org/msg01208.html
      # - http://www.geocities.com/gtalon51/Articles/Minimal_Linux_system/Minimal_Linux_system.html
      # - qemu-make-debian-root
      namespace :create do
        task :image do
          sh "qemu-img create -f raw #{disk_image} #{disk_size}"
          # create the partition table
          sh "echo '63,' | /sbin/sfdisk --no-reread -uS -H16 -S63 #{disk_image}"
        end

        task :fs do 
          # format the filesystem
          begin
            sudo "losetup -o #{fs_offset} /dev/loop0 #{disk_image}"
            
            # because '/sbin/sfdisk -s /dev/loop0' returns a wrong value :
            extract_fs_block_size = "/sbin/sfdisk -l #{disk_image} 2> /dev/null | awk '/img1/ { print gensub(\"+\", \"\", \"\", $5) }'"
            
            sudo "/sbin/mke2fs -jqF /dev/loop0 `#{extract_fs_block_size}`"
          ensure
            sudo "losetup -d /dev/loop0"
          end
        end
        
        task :system do
          # install a debian base system
          mount do 
            bootstraper.bootstrap mount_point
          end
        end

        task :kernel do
          # TODO : install a kernel and a boot loader grub
          # mount do
          #   sudo "chroot #{mount_point} sh -c \"echo 'do_initrd = Yes' >> /etc/kernel-img.conf && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes grub linux-image-2.6-686\""
          # end
        end

        task :config do
          Tempfile.open('sandbox_puppet_file') do |sandbox_puppet_file|
            sandbox_puppet_file.puts "$host_ip='#{host_ip_address}'"            
            sandbox_puppet_file.puts "$sandbox_ip='#{ip_address}'"            
            sandbox_puppet_file.puts IO.read(@@puppet_file)

            sandbox_puppet_file.close

            # finalize configuration with puppet
            mount do
              sudo "cp #{sandbox_puppet_file.path} #{mount_point}/etc/sandbox.pp"
              sudo "chroot #{mount_point} puppet /etc/sandbox.pp"
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
      task :create => [ 'clean', 'create:image', 'create:fs', 'create:system', 'create:kernel', 'create:config', 'create:snapshot' ]

      desc "Destroy sandbox images"
      task :destroy => 'clean' do
        rm_f disk_image
        rm_f disk_image(:initial)
      end

      desc "Start sandbox"
      task :start => 'create:tap_device' do
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

      task :revert do
        sh "qemu-img convert -O raw #{disk_image(:initial)} #{disk_image}"
      end

      task :mount do
        mount_image
      end

      task :umount do
        umount_image
      end

      task :clean => 'puppet:clean' do
        # clean known_hosts
        known_hosts_file="#{ENV['HOME']}/.ssh/known_hosts"
        sh "sed -i '/#{hostname},#{ip_address}/ d' #{known_hosts_file}" if File.exists?(known_hosts_file)
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

  def start(options = {})
    options = {
      :daemonize => true,
      :snapshot => ENV['SNAPSHOT'],
      :hda => disk_image,
      :initrd => '/initrd.img',
      :kernel => '/vmlinuz',
      :append => 'console=ttyS0 root=/dev/hda1 ro',
      :nographic => true,
      :m => memory_size,
      :net => ["nic", "tap,ifname=#{tap_device}"]
    }.update(options)

    if options[:daemonize]
      options = {
        :pidfile => "tmp/run/#{name}.pid", :serial => "file:log/#{name}.log"        
      }.update(options)
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

    sh "qemu #{options_as_string}"
  end

  def snapshot(name)
    sh "qemu-img convert -O qcow2 #{disk_image} #{disk_image(name)}"
  end

  def wait(timeout = 30, max_try_count = 5)
    try_count = 5
    try_timeout = timeout / try_count

    5.times do
      if Ping.pingecho(ip_address, try_timeout)
        return
      else
        sleep try_timeout
      end
    end

    raise "no response from #{hostname} after #{timeout} seconds"
  end

  def mount(&block)
    begin
      mount_image
      yield mount_point
    ensure
      umount_image
    end
  end

  def mount_image
    sudo "mkdir #{mount_point}" unless File.exists? mount_point
    sudo "mount -o loop,offset=#{fs_offset} #{disk_image} #{mount_point}"
    
    sudo "mount proc #{mount_point}/proc -t proc" if File.exists? "#{mount_point}/proc"
  end

  def umount_image
    [ "#{mount_point}/proc", mount_point ].each do |mount|
      sudo "umount #{mount} || true"
    end
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

end

class DebianBoostraper

  attr_accessor :version, :mirror

  def initialize(&block)
    @version = 'lenny'
    @mirror = 'http://ftp.debian.org/debian'

    yield self if block_given?
  end

  def bootstrap(root)
    options = {
      :arch => 'i386',
      :exclude => debootstrap_excludes,
      :include => %w{puppet ssh}
    }
    
    options_as_string = options.collect{|k,v| "--#{k} #{Array(v).join(',')}"}.join(' ')
    sudo "debootstrap #{options_as_string} #{version} #{root} #{mirror}"
  end

  def debootstrap_excludes
    # excluded by qemu-make-debian-root
    %w{syslinux at exim mailx libstdc++2.10-glibc2.2 mbr setserial fdutils info ipchains iptables lilo pcmcia-cs ppp pppoe pppoeconf pppconfig wget telnet cron logrotate exim4 exim4-base exim4-config exim4-daemon-light pciutils modconf tasksel}
  end

end
