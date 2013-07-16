require 'spec_helper'

describe Cinch::Plugins::Hangouts do
  include Cinch::Test

  before(:each) do
    @bot = make_bot(Cinch::Plugins::Hangouts, { :filename => '/dev/null',
                                                :response_type => :channel })
  end

  describe 'handling hangout links' do
    it 'should return an error if no one has linked a hangout' do
      msg = make_message(@bot, '!hangouts')
      get_replies(msg).first.text.
        should == "No hangouts have been linked recently!"
    end

    it 'should not capture a malformed (invalid chars) Hangout link' do
      msg = make_message(@bot, url_for_id('82b5cc7f76b7a%19c180416c2f509027!!d8856d'),
                               { :channel => '#foo' })
      get_replies(msg).should be_empty
      msg = make_message(@bot, '!hangouts')
      get_replies(msg).first.text.
        should == "No hangouts have been linked recently!"
    end

    it 'should not capture a malformed (wrong length) Hangout link' do
      msg = make_message(@bot, url_for_id('82b5cc'),
                               { :channel => '#foo' })
      get_replies(msg).should be_empty
      msg = make_message(@bot, '!hangouts')
      get_replies(msg).first.text.
        should == "No hangouts have been linked recently!"
    end

    it 'should capture a legit Hangout link and store it in @storage' do
      msg = make_message(@bot, url_for_id, { :channel => '#foo' })
      get_replies(msg).should be_empty
      msg = make_message(@bot, '!hangouts')
      get_replies(msg).first.text.
        should_not == "No hangouts have been linked recently!"
    end

    it 'should capture a legit Hangout link and store it in @storage' do
      msg = make_message(@bot, url_for_id, { :channel => '#foo' })
      get_replies(msg).should be_empty
      sleep 1 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      reply = get_replies(msg).last.text
      reply.should include "test started a hangout at"
      reply.should match(/it was last linked \d seconds? ago/)
    end

    it 'should capture a legit Hangout link if it has trailing params' do
      msg = make_message(@bot, url_for_id('82b5cc7f76b7a1019c180416c2f509027bd8856d?hl=en'),
                               { :channel => '#foo' })
      get_replies(msg)
      sleep 1 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      reply = get_replies(msg).last.text
      reply.should include "test started a hangout at"
      reply.should match(/it was last linked \d seconds? ago/)
    end
  end

  describe 'subscriptions' do
    it 'should allow users to subscribe' do
      msg = make_message(@bot, '!hangouts subscribe')
      get_replies(msg).first.text.
        should include("You are now subscribed")
    end

    it 'should allow users to subscribe' do
      msg = make_message(@bot, '!hangouts subscribe')
      get_replies(msg).first.text.
        should include("You are now subscribed")
    end

    it 'should inform users that they already subscribed' do
      get_replies(make_message(@bot, '!hangouts subscribe'))
      msg = make_message(@bot, '!hangouts subscribe')
      get_replies(msg).first.text.
        should include("You are already subscribed")
    end

    it 'should allow users to unsubscribe' do
      get_replies(make_message(@bot, '!hangouts subscribe'))
      msg = make_message(@bot, '!hangouts unsubscribe')
      get_replies(msg).first.text.
        should include("You are now unsubscribed")
    end

    it 'should inform users that they are not subscribed on an unsubscribe' do
      msg = make_message(@bot, '!hangouts unsubscribe')
      get_replies(msg).first.text.
        should include("You are not subscribed.")
    end

    it 'should notify users when a new hangout is linked' do
      get_replies(make_message(@bot, '!hangouts subscribe'), { :channel => '#foo' } )
      msg = make_message(@bot, url_for_id, { :channel => '#foo' })
      get_replies(msg).first.
        should be_nil
    end

    it 'should not notify users when an old hangout is relinked'
    it 'should allow users to elect to get notified on every hangout link'
  end

  def url_for_id(id = '82b5cc7f76b7a1019c180416c2f509027bd8856d')
    "https://plus.google.com/hangouts/_/#{id}"
  end
end
