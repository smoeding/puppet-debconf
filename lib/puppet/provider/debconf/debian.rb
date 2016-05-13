# debian.rb --- Debian provider for debconf type

Puppet::Type.type(:debconf).provide(:debian) do
  desc %q{Manage debconf database entries on Debian based systems.}

  confine :osfamily => :debian
  defaultfor :osfamily => :debian

  commands :debconf_show => "/usr/bin/debconf-show"

  def initialize(value = {})
    super(value)
    @properties = Hash.new
  end

  # The regular expression used to parse the debconf-show output
  DEBCONF_REGEXP = Regexp.new(
    "^(.) " +                 # seen marker
    "([a-z0-9.+-]+)" +        # package name
    "\/" +                    # literal '/'
    "([a-zA-Z0-9\/_.+-]+)" +  # item name
    ":\s*" +                  # literal ':' and space
    "(.*)?" +                 # value (optional)
    "\s*$"                    # optional trailing spaces
  )

  # Fetch all items and their values for a package
  def fetch
    Puppet.debug("Debconf: caching data for #{resource[:name]}")
    Puppet.debug("Debconf: getting items for package #{resource[:package]}")

    debconf_show(resource[:package]).split("\n").each do |line|
      if DEBCONF_REGEXP.match(line)
        pkg, key, val = $2, $3, $4

        Puppet.debug("Debconf: item #{pkg}/#{key} => #{val}")
        @properties["#{pkg}/#{key}"] = val
      else
        Puppet.warning("Debconf: entry not parsed (#{line})")
      end
    end
  end

  # Call debconf-set-selections to store the item value
  def update
    Puppet.debug("Debconf: updating #{resource[:name]}")

    # Build the string to send
    args = [:package, :item, :type, :value].map { |e| resource[e] }.join(' ')

    IO.popen('/usr/bin/debconf-set-selections', 'w+') do |pipe|
      pipe.puts(args)
      pipe.close_write

      # Ignore all we can read
      pipe.read.split("\n").each { |l| }
    end
  end

  def create
    Puppet.debug("Debconf: calling create #{resource[:name]}")
    fetch if @properties.empty?

    update
  end

  def destroy
    Puppet.debug("Debconf: calling destroy for #{resource[:name]}")
    fetch if @properties.empty?

    IO.popen("/usr/bin/debconf-communicate #{resource[:package]}", 'w+') do |pipe|
      pipe.puts("UNREGISTER #{resource[:package]}/#{resource[:item]}")
      pipe.close_write

      # Parse return code
      pipe.read.split("\n").each do |l|
        fail("Debconf: debconf-communicate failed (#{l})") unless l =~ /^0+$/
      end
    end
  end

  def exists?
    Puppet.debug("Debconf: calling exists? for #{resource[:name]}")
    fetch if @properties.empty?
    @properties.has_key?(resource[:item])
  end

  def value
    Puppet.debug("Debconf: get #{resource[:item]}")
    fetch if @properties.empty?

    @properties[resource[:item]]
  end

  def value=(val)
    Puppet.debug("Debconf: set #{resource[:item]} to #{val}")
    fetch if @properties.empty?

    @properties[resource[:item]] = val
    update
  end
end
