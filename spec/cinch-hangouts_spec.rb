require 'spec_helper'

describe Cinch::Plugins::Hangouts do
  include Cinch::Test

  before(:all) do
    @bot = make_bot(Cinch::Plugins::Hangouts, { :filename => '/dev/null',
                                                :response_type => :channel })
  end

  it 'should return an errohangout links matching' do
    msg = make_message(@bot, '!hangouts')
    get_replies(msg).first.should == "No hangouts have been linked recently!"
  end
end
