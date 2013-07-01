require 'spec_helper'

describe Cinch::Plugins::Hangouts do
  include Cinch::Test

  before(:each) do
    @bot = make_bot(Cinch::Plugins::Hangouts, { :filename => '/dev/null',
                                                :response_type => :channel })
  end

  it 'should return an error if no one has linked a hangout' do
    msg = make_message(@bot, '!hangouts')
    get_replies(msg).first.should == "No hangouts have been linked recently!"
  end

  it 'should not capture a malformed (invalid chars) Hangout link' do
    msg = make_message(@bot, url_for_id('82b5cc7f76b7a%19c180416c2f509027!!d8856d'),
                             { :channel => '#foo' })
    get_replies(msg).should be_empty
    msg = make_message(@bot, '!hangouts')
    get_replies(msg).first.should == "No hangouts have been linked recently!"
  end

  it 'should not capture a malformed (wrong length) Hangout link' do
    msg = make_message(@bot, url_for_id('82b5cc'),
                             { :channel => '#foo' })
    get_replies(msg).should be_empty
    msg = make_message(@bot, '!hangouts')
    get_replies(msg).first.should == "No hangouts have been linked recently!"
  end

  it 'should capture a legit Hangout link and store it in @storage' do
    msg = make_message(@bot, url_for_id, { :channel => '#foo' })
    get_replies(msg).should be_empty
    msg = make_message(@bot, '!hangouts')
    get_replies(msg).first.should_not == "No hangouts have been linked recently!"
  end

  it 'should capture a legit Hangout link and store it in @storage' do
    msg = make_message(@bot, url_for_id, { :channel => '#foo' })
    get_replies(msg).should be_empty
    sleep 1 # hack until 'time-lord' fix gets released
    msg = make_message(@bot, '!hangouts')
    reply = get_replies(msg).last
    reply.should include "test started a hangout at"
    reply.should match(/it was last linked \d seconds? ago/)
  end

  it 'should capture a legit Hangout link f it has trailing params' do
    msg = make_message(@bot, url_for_id('82b5cc7f76b7a1019c180416c2f509027bd8856d?pqs=1&authuser=0&hl=en'))
    get_replies(msg, :channel)
    sleep 1 # hack until 'time-lord' fix gets released
    msg = make_message(@bot, '!hangouts')
    reply = get_replies(msg).last
    reply.should include "test started a hangout at"
    reply.should match(/it was last linked \d seconds? ago/)
  end

  def url_for_id(id = '82b5cc7f76b7a1019c180416c2f509027bd8856d')
    "https://plus.google.com/hangouts/_/#{id}"
  end
end
