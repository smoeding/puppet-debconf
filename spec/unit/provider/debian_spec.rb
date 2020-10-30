require 'spec_helper'

provider_class = Puppet::Type.type(:debconf).provider(:debian)

describe provider_class do
  let(:name) { 'foo' }

  let(:resource) do
    Puppet::Type.type(:debconf).new(
      name:     name,
      provider: 'debian',
    )
  end

  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end

  it 'is the default provider on :osfamily => Debian' do
    expect(Facter.fact(:osfamily)).to receive(:value).and_return('Debian')
    expect(described_class).to be_default
  end
end
