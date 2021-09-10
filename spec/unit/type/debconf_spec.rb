require 'spec_helper'

describe Puppet::Type.type(:debconf) do
  on_supported_os.each do |os, _facts|
    context "on #{os}" do
      before(:each) do
        Facter.clear
      end

      describe 'when validating attributes' do
        [:item, :package, :type].each do |param|
          it "has a #{param} parameter" do
            expect(described_class.attrtype(param)).to eq(:param)
          end
        end
        [:value].each do |prop|
          it "has a #{prop} property" do
            expect(described_class.attrtype(prop)).to eq(:property)
          end
        end
      end

      describe 'namevar validation' do
        it 'has :item as its namevar' do
          expect(described_class.key_attributes).to eq([:name])
        end
      end
    end
  end
end
