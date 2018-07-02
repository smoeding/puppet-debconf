# debian.rb --- Debian provider for debconf type

Puppet::Type.type(:debconf).provide(:debian) do
  desc 'Manage debconf database entries on Debian based systems.'

  confine osfamily: :debian
  defaultfor osfamily: :debian

  # A private class to communicate with the debconf database
  class Debconf < IO
    # The regular expression used to parse the debconf-communicate output
    DEBCONF_COMMUNICATE = Regexp.new(
      '^([0-9]+)' +             # error code
      '\s*' +                   # whitespace
      '(.*)' +                  # return value
      '\s*$'                    # optional trailing spaces
    )

    def initialize(pipe)
      # The pipe to the debconf-communicate program
      @pipe = pipe
    end

    # Open communication channel with the debconf database
    def self.communicate(package)
      Puppet.debug("Debconf: open pipe to debconf-communicate for #{package}")

      pipe = IO.popen("/usr/bin/debconf-communicate #{package}", 'w+')

      raise(Puppet::Error, 'Debconf: failed to open pipe to debconf-communicate') unless pipe

      # Call block for pipe
      yield new(pipe) if block_given?

      # Close pipe and finish, ignore remaining output from command
      pipe.close_write
      pipe.read(nil)
      pipe.close_read
      @pipe = nil
    end

    # Send a command to the debconf-communicate pipe and collect response
    def send(command)
      Puppet.debug("Debconf: send #{command}")

      @pipe.puts(command)
      response = @pipe.gets("\n")

      raise(Puppet::Error, 'Debconf: debconf-communicate unexpectedly closed pipe') unless response

      raise(Puppet::Error, "Debconf: debconf-communicate returned (#{response})") unless DEBCONF_COMMUNICATE.match(response)

      # Response is devided into the return code (casted to int) and the
      # result text. Depending on the context the text could be an error
      # message or the value of an item.
      retcode = Regexp.last_match(1).to_i
      retmesg = Regexp.last_match(2)

      [retcode, retmesg]
    end

    # Get an item from the debconf database
    # Return the value of the item or nil if the item is not found
    def get(item)
      resultcode, resultmesg = send("GET #{item}")

      # Check for errors
      case resultcode
      when 0 then resultmesg    # OK
      when 10 then nil          # item doesn't exist
      else
        raise(Puppet::Error, "Debconf: 'GET #{item}' returned #{resultcode}: #{resultmesg}")
      end
    end

    # Get the seen flag for an item from the debconf database
    # Return a boolean true or false
    def seen?(item)
      resultcode, resultmesg = send("FGET #{item} seen")

      # Check for errors
      case resultcode
      when 0 then (resultmesg == 'true')
      when 10 then false
      else
        raise(Puppet::Error, "Debconf: 'FGET #{item} seen' returned #{resultcode}: #{resultmesg}")
      end
    end

    # Unregister an item in the debconf database
    def unregister(item)
      resultcode, resultmesg = send("UNREGISTER #{item}")

      # Check for errors
      raise(Puppet::Error, "Debconf: 'UNREGISTER #{item}' returned #{resultcode}: #{resultmesg}") unless resultcode.zero?

      @property_hash = {}
    end
  end

  #
  # The Debian debconf provider
  #

  def initialize(value = {})
    super(value)
    @property_hash = {}
  end

  # Fetch item properties
  def fetch
    Puppet.debug("Debconf: fetch #{resource[:item]} for #{resource[:package]}")

    Debconf.communicate(resource[:package]) do |debconf|
      value = debconf.get(resource[:item])

      if value
        Puppet.debug("Debconf: #{resource[:item]} = '#{value}'")
        @property_hash[:ensure] = :present
        @property_hash[:value] = value

        seen = debconf.seen?(resource[:item])
        Puppet.debug("Debconf: #{resource[:item]} seen flag is '#{seen}'")
        @property_hash[:seen] = seen
      else
        @property_hash[:ensure] = :absent
      end
    end
  end

  # Call debconf-set-selections to store the item values
  def flush
    Puppet.debug("Debconf: calling flush #{resource[:name]}")

    case @property_hash[:ensure]
    when :present
      IO.popen('/usr/bin/debconf-set-selections', 'w+') do |pipe|
        # Store type/value
        if @property_hash[:value]
          args = [resource[:package], resource[:item]]
          args << resource[:type]
          args << resource[:value]

          comm = args.join(' ')
          Puppet.debug("Debconf: debconf-set-selections #{comm}")
          pipe.puts(comm)
        end

        # Store seen flag
        unless resource[:seen].nil?
          args = [resource[:package], resource[:item]]
          args << 'seen'
          args << resource[:seen].to_s

          comm = args.join(' ')
          Puppet.debug("Debconf: debconf-set-selections #{comm}")
          pipe.puts(comm)
        end

        # Ignore remaining output from command
        pipe.close_write
        pipe.read(nil)
      end
    when :absent
      Debconf.communicate(resource[:package]) do |debconf|
        debconf.unregister(resource[:item])
      end
    end
  end

  def create
    Puppet.debug("Debconf: calling create #{resource[:name]}")

    @property_hash[:ensure] = resource[:ensure]
    @property_hash[:value]  = resource[:value]
    @property_hash[:seen]   = resource[:seen] if resource[:seen]
  end

  def destroy
    Puppet.debug("Debconf: calling destroy for #{resource[:name]}")

    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Debconf: calling exists? for #{resource[:name]}")
    fetch if @property_hash.empty?

    @property_hash[:ensure] == :present
  end

  def value
    Puppet.debug("Debconf: calling get #{resource[:item]}")
    fetch if @property_hash.empty?

    @property_hash[:value]
  end

  def value=(val)
    Puppet.debug("Debconf: calling set #{resource[:item]} to #{val}")
    @property_hash[:item] = val
  end

  def seen
    Puppet.debug("Debconf: calling get seen flag of #{resource[:item]}")
    fetch if @property_hash.empty?

    @property_hash[:seen].to_s
  end

  def seen=(val)
    Puppet.debug("Debconf: calling set seen flag of #{resource[:item]} to #{val}")
    @property_hash[:seen] = val
  end
end
