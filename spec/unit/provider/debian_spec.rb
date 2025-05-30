require 'spec_helper'

provider_class = Puppet::Type.type(:debconf).provider(:debian)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:debconf).new(
      name:     'foo',
      provider: 'debian',
    )
  end

  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end

  it 'is the default provider on :osfamily => Debian' do
    expect(Facter.fact('os.family')).to receive(:value).and_return('Debian')
    expect(described_class).to be_default
  end
end
