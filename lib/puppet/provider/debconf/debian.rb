# debian.rb --- Debian provider for debconf type

Puppet::Type.type(:debconf).provide(:debian) do
  desc 'Manage debconf database entries on Debian based systems.'

  confine osfamily: :debian
  defaultfor osfamily: :debian

  class Debconf < IO
    # A private class to communicate with the debconf database

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
    end
  end

  #
  # The Debian debconf provider
  #

  def initialize(value = {})
    super(value)
    @properties = {}
  end

  # Fetch item properties
  def fetch
    Puppet.debug("Debconf: fetch #{resource[:item]} for #{resource[:package]}")

    Debconf.communicate(resource[:package]) do |debconf|
      value = debconf.get(resource[:item])

      if value
        Puppet.debug("Debconf: #{resource[:item]} = '#{value}'")
        @properties[:exists] = true
        @properties[:value] = value

        # Fetch 'seen' flag if type parameter is set
        unless resource[:seen].nil?
          seen = debconf.seen?(resource[:item])
          Puppet.debug("Debconf: #{resource[:item]} seen flag is '#{seen}'")
          @properties[:seen] = seen
        end
      else
        @properties[:exists] = false
      end
    end
  end

  # Call debconf-set-selections to store the item value
  def update
    Puppet.debug("Debconf: updating #{resource[:name]}")

    IO.popen('/usr/bin/debconf-set-selections', 'w+') do |pipe|
      args = [resource[:package], resource[:item]]
      args << resource[:type]
      args << resource[:value]

      comm = args.join(' ')
      Puppet.debug("Debconf: debconf-set-selections #{comm}")
      pipe.puts(comm)

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
  end

  def create
    Puppet.debug("Debconf: calling create #{resource[:name]}")
    update
  end

  def destroy
    Puppet.debug("Debconf: calling destroy for #{resource[:name]}")

    Debconf.communicate(resource[:package]) do |debconf|
      debconf.unregister(resource[:item])
    end
  end

  def exists?
    Puppet.debug("Debconf: calling exists? for #{resource[:name]}")
    fetch if @properties.empty?

    @properties[:exists]
  end

  def value
    Puppet.debug("Debconf: calling get #{resource[:item]}")
    fetch if @properties.empty?

    @properties[:value]
  end

  def value=(val)
    Puppet.debug("Debconf: calling set #{resource[:item]} to #{val}")
    update
  end

  def seen
    Puppet.debug("Debconf: calling get seen flag of #{resource[:item]}")
    fetch if @properties.empty?

    @properties[:seen].to_s
  end

  def seen=(val)
    Puppet.debug("Debconf: calling set seen flag of #{resource[:item]} to #{val}")
    update
  end
end
