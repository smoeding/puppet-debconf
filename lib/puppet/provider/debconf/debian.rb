# debian.rb --- Debian provider for debconf type
Puppet::Type.type(:debconf).provide(:debian) do
  desc "Debian debconf management."

  confine :osfamily => :debian

  defaultfor :osfamily => :debian

  commands :debconf_show => "/usr/bin/debconf-show"

  def initialize(value = {})
    super(value)
    @properties = Hash.new
  end

  # Return the regular expression used to parse the debconf-show output
  def regexp
    Regexp.new(
      "^(.) " +                       # Seen marker
      "(?<pkg>[a-zA-Z0-9_.+-]+)" +    # Package name
      "\/" +                          # Literal '/'
      "(?<key>[a-zA-Z0-0\/_.+-]+):" + # Item name
      "\s+" +                         # Space
      "(?<val>.*?)\s*$")              # Value
  end

  # Fetch all items and their values for a package
  def fetch
    Puppet.debug("Debconf: caching data for #{resource[:item]}")
    Puppet.debug("Debconf: getting items for package #{resource[:package]}")

    debconf_show(resource[:package]).split("\n").each do |line|
      m = regexp.match(line)
      if m
        Puppet.debug("Debconf: item #{m[:pkg]}/#{m[:key]} => #{m[:val]}")
        @properties["#{m[:pkg]}/#{m[:key]}"] = m[:val]
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
      pipe.read.split("\n").each { |l| }
    end
  end

  def create
    Puppet.debug("Debconf: create #{resource[:name]}")
    fetch if @properties.empty?

    update
  end

  def destroy
    Puppet.debug("Debconf: calling destroy for #{resource[:name]}")
    fetch if @properties.empty?

    IO.popen("/usr/bin/debconf-communicate #{resource[:package]}", 'w+') do |pipe|
      pipe.puts("UNREGISTER #{resource[:item]}")
      pipe.close_write
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
    Puppet.debug("Debconf: getting #{resource[:item]}")
    fetch if @properties.empty?

    @properties[resource[:item]]
  end

  def value=(val)
    Puppet.debug("Debconf: setting #{resource[:item]} to #{val}")
    fetch if @properties.empty?

    @properties[resource[:item]] = val
    update
  end
end
