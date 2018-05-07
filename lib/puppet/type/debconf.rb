# debconf.rb --- The debconf type

Puppet::Type.newtype(:debconf) do
  desc <<-EOT
    Manage debconf database entries on Debian based systems. This type
    can either set or remove a value for a debconf database entry. It
    uses multiple programs from the 'debconf' package.

    Examples:

        debconf { 'tzdata/Areas':
          type  => 'select',
          value => 'Europe',
        }

        debconf { 'dash/sh':
          type  => 'boolean',
          value => 'true',
        }

        debconf { 'libraries/restart-without-asking':
          package => 'libc6',
          type    => 'boolean',
          value   => 'true',
          seen    => true,
        }
  EOT

  def munge_boolean(value)
    case value
    when true, 'true', :true
      :true
    when false, 'false', :false
      :false
    else
      raise(Puppet::Error, 'munge_boolean only takes booleans')
    end
  end

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:item, namevar: true) do
    desc "The item name. This string must have the following format: the
      package name, a literal slash char and the name of the question (e.g.
      'tzdata/Areas')."

    newvalues(%r{^[a-z0-9][a-z0-9:.+-]+\/[a-zA-Z0-9\/_.+-]+$})
  end

  newparam(:package) do
    desc "The package the item belongs to. The default is the first part (up
      to the first '/') of the item parameter (e.g. 'tzdata')."

    newvalues(%r{^[a-z0-9][a-z0-9:.+-]+$})
    defaultto { @resource[:item].split('/', 2).first }
  end

  newparam(:type) do
    desc "The type of the item. This can only be one of the following
      values: string, boolean, select, multiselect, note, text, password,
      title."

    newvalues(:string, :boolean, :select, :multiselect,
              :note, :text, :password, :title)
  end

  newproperty(:value) do
    desc "The value for the item (e.g. 'Europe')."

    newvalues(%r{\S})
    munge { |value| value.strip } # Remove leading and trailing spaces
  end

  newproperty(:seen, boolean: true) do
    desc "The value of the 'seen' flag. This can be left undefined or be one
      of the boolean values true or false."

    newvalues(:true, :false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  validate do
    unless self[:type]
      unless self[:ensure].to_s == 'absent'
        raise(Puppet::Error, 'type is a required attribute')
      end
    end
  end
end
