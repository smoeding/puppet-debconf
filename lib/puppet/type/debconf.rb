# exec { 'debconf_dash':
#   command => 'echo "dash dash/sh boolean true"|debconf-set-selections',
#   unless  => 'debconf-show dash|grep -q "dash/sh: *true"',
#   require => Package['dash'],
# }
#
Puppet::Type.newtype(:debconf) do

  desc %q{Manage debconf database entries on Debian based systems.}

  ensurable

  newparam(:item, :namevar => true) do
    desc %{The item to manage.}
    newvalues(/^[a-zA-Z0-9_.+-]+\/[a-zA-Z0-9\/_.+-]+$/)
  end

  newparam(:package) do
    desc %{The package the item belongs to.}

    newvalues(/^[a-zA-Z0-9_.+-]+$/)
    defaultto { @resource[:item].split('/', 2).first }
  end

  newparam(:type) do
    desc %{The type of the item.}
    newvalues(:string, :boolean, :select, :multiselect,
              :note, :text, :password, :title)
  end

  newproperty(:value) do
    desc %{The value for the item.}
  end
end
