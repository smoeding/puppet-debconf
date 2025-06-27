# frozen_string_literal: true

require 'spec_helper'

describe 'the debconf provider' do
  on_supported_os.each do |os, facts|
    context "on #{os} with defaults" do
      let(:facts) { facts }

      it 'loads' do
        expect(Puppet::Type.type(:debconf).provide(:debian)).not_to be_nil
      end
    end
  end
end
