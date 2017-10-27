require 'spec_helper'

describe Cinch::Plugins::Hangouts do
  include Cinch::Test

  before(:each) do
    @files = { hangout_filename: '/tmp/hangout.yml',
               subscription_filename: '/tmp/subscription.yml' }
    @files.values.each { |file| File.delete(file) if File.exist?(file) }
    @bot = make_bot(Cinch::Plugins::Hangouts, @files)
  end

  describe 'requesting hangout links (!hangouts)' do
    it 'return an error if no one has linked a hangout' do
      msg = get_replies(make_message(@bot, '!hangouts', { channel: '#foo' })).first
      expect(msg.text).to eql('No hangouts have been linked recently!')
    end
  end

  describe 'posting a valid hangout link' do
    it 'captures the the link and stores it in @storage' do
      msg = make_message(@bot, Hangout.url(random_hangout_id), { channel: '#foo' })
      get_replies(msg)
      sleep 2
      reply = get_replies(make_message(@bot, '!hangouts')).last.text
      expect(reply).to include('test started a hangout at')
      expect(reply).to match(/it was last linked \d seconds? ago/)
    end

    it 'captures the the new link and stores it in @storage' do
      msg = make_message(@bot, "https://hangouts.google.com/call/KqOHTbdRWNPen5pQJ5zAAAEE",
                         { channel: '#foo' })
      get_replies(msg)
      sleep 2
      reply = get_replies(make_message(@bot, '!hangouts')).last.text
      expect(reply).to include('test started a hangout at')
      expect(reply).to match(/it was last linked \d seconds? ago/)
    end

    it 'captures even if it has trailing params' do
      msg = make_message(@bot, Hangout.url(random_hangout_id + '?hl=en'),
                               { channel: '#foo' })
      get_replies(msg)
      sleep 2 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      reply = get_replies(msg).last.text
      expect(reply).to include('test started a hangout at')
      expect(reply).to match(/it was last linked \d seconds? ago/)
    end

    it 'recaptures a link' do
      id = random_hangout_id
      msg = make_message(@bot, Hangout.url(id), { channel: '#foo' })
      get_replies(msg)
      sleep 2 # hack until 'time-lord' fix gets released
      get_replies(msg)
      sleep 2 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      expect(get_replies(msg).length).to eq(2)
    end

    it 'capture a new short Hangout link and store it in @storage' do
      msg = make_message(@bot, Hangout.url('7acpjrpcmgl00u0b665mu25b1g'), { channel: '#foo' })
      expect(get_replies(msg)).to be_empty
      sleep 2 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      reply = get_replies(msg).last.text
      expect(reply).to include('test started a hangout at')
      expect(reply).to match(/it was last linked \d seconds? ago/)
    end


    it 'capture a link and return it' do
      url = Hangout.url(random_hangout_id)
      msg = make_message(@bot, url, { channel: '#foo' })
      expect(get_replies(msg)).to be_empty
      sleep 2 # hack until 'time-lord' fix gets released
      msg = make_message(@bot, '!hangouts')
      reply = get_replies(msg).last.text
      expect(reply).to include(url)
      puts reply
      # expect(reply).to match(/it was last linked \d seconds? ago/)
    end
  end

  describe 'posting an invalid hangout link does not log' do
    it 'when it is malformed (invalid chars)' do
      msg = make_message(@bot, Hangout.url('82b5cc7f76b7a%19c180416c2f509027!!d8856d'),
                         { channel: '#foo' })
      expect(get_replies(msg)).to be_empty
      msg = make_message(@bot, '!hangouts')
      message = get_replies(msg).first.text
      expect(message).to eq('No hangouts have been linked recently!')
    end

    it 'when it is malformed (wrong length)' do
      msg = make_message(@bot, Hangout.url('82b5cc'), { channel: '#foo' })
      expect(get_replies(msg)).to be_empty
      msg = make_message(@bot, '!hangouts')
      expect(get_replies(msg).first.text).to eq('No hangouts have been linked recently!')
    end
  end

  describe 'subscriptions' do
    it 'should allow users to subscribe' do
      msg = get_replies(make_message(@bot, '!hangouts subscribe'))
      expect(msg.first.text).to include('You are now subscribed')
    end

    it 'should allow users to subscribe' do
      get_replies(make_message(@bot, '!hangouts subscribe'))
      expect(Cinch::Plugins::Hangouts::Subscription.list({ subscriptions: @files[:subscription_filename] }).length).to eq(1)
    end

    it 'should inform users that they already subscribed' do
      get_replies(make_message(@bot, '!hangouts subscribe'))
      msg = make_message(@bot, '!hangouts subscribe')
      expect(get_replies(msg).first.text).to include('You are already subscribed')
    end

    it 'should allow users to unsubscribe' do
      get_replies(make_message(@bot, '!hangouts subscribe'))
      get_replies(make_message(@bot, '!hangouts unsubscribe'))
      expect(Cinch::Plugins::Hangouts::Subscription.list({ subscriptions: @files[:subscription_filename] }).length).to eq(0)
    end

    it 'should inform users that they are not subscribed on an unsubscribe' do
      msg = make_message(@bot, '!hangouts unsubscribe')
      expect(get_replies(msg).first.text).to include('You are not subscribed.')
    end

    #it 'should notify users when a new hangout is linked' do
    #  get_replies(make_message(@bot, '!hangouts subscribe'), { channel: '#foo', nick: 'joe' } )
    #  msgs = get_replies(make_message(@bot, Hangout.url(random_hangout_id), { channel: '#foo', nick: 'josh' }))
    #  msgs.first.should_not be_nil
    #end

    it 'should not notify users when an old hangout is relinked' do
      get_replies(make_message(@bot, '!hangouts subscribe'), { channel: '#foo' } )
      get_replies(make_message(@bot, Hangout.url(random_hangout_id), { channel: '#foo' }))
      msg = make_message(@bot, Hangout.url(random_hangout_id), { channel: '#foo' })
      expect(get_replies(msg)).to be_empty
    end
  end

  def random_hangout_id(len = 27)
    chars = ('a'..'z').to_a + ('0'..'9').to_a + ('A'..'Z').to_a + ['_']
    string = ''
    len.times { string << chars[rand(chars.length)] }
    string
  end
end
