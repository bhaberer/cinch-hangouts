# -*- coding: utf-8 -*-
require 'cinch'
require 'cinch/storage'
require 'cinch/toolbox'
require 'time-lord'

module Cinch::Plugins
  # Plugin to track Google Hangout links
  class Hangouts
    include Cinch::Plugin
    HANGOUT_FILENAME = 'yaml/hangouts.yml'
    SUBSCRIPTION_FILENAME = 'yaml/hangout_subscriptions.yml'

    # This is the regex that captures hangout links
    # The regex will need to be updated if the url scheme changes in the future
    HANGOUTS_REGEX = %r((?:_|call)/([a-z0-9]{10,40})(?:\?|$))

    attr_accessor :storage

    self.help = 'Use .hangouts to see the info for any recent hangouts. You ' +
                'can also use .hangouts subscribe to sign up for notifications'

    match(/hangouts\z/, method: :list_hangouts)
    match(/hangouts subscribe/, method: :subscribe)
    match(/hangouts unsubscribe/, method: :unsubscribe)

    listen_to :channel

    def initialize(*args)
      super
      @files = {
        hangouts: config[:hangout_filename] || HANGOUT_FILENAME,
        subscriptions: config[:subscription_filename] || SUBSCRIPTION_FILENAME
      }
      @expire = config[:expire_period] || 120
      @response_type = config[:response_type] || :notice
    end

    def listen(m)
      hangout_id = m.message[HANGOUTS_REGEX, 1]
      process_hangout(hangout_id, m) if hangout_id
    end

    def process_hangout(hangout_id, m)
      if Hangout.find_by_id(hangout_id, @files)
        # If it's an old hangout capture a new expiration time
        hangout = Hangout.find_by_id(hangout_id, @files)
        hangout.time = Time.now
        hangout.save
        debug "Old hangout with id:#{hangout_id} relinked."
      else
        Hangout.new(m.user.nick, hangout_id, Time.now, @files).save
        Subscription.notify(hangout_id, @bot,  @response_type, @files)
        debug "New hangout with id:#{hangout_id} created."
      end
    end

    def subscribe(m)
      nick = m.user.nick
      if Subscription.for_user(nick, @files)
        msg = 'You are already subscribed. '
        debug "#{nick} subscription request failed: Already subscribed."
      else
        sub = Subscription.new(nick, @files)
        sub.save
        msg = 'You are now subscribed. I will let you know when a hangout ' \
              ' is linked. '
        debug "#{nick} subscription request succeeded."
      end
      m.user.notice "#{msg} To unsubscribe use `.hangouts unsubscribe`."
    end

    def unsubscribe(m)
      nick = m.user.nick
      if Subscription.for_user(nick, @files)
        debug Subscription.for_user(nick, @files).to_s
        Subscription.for_user(nick, @files).destroy
        msg = 'You are now unsubscribed, and will no longer receive a messages.'
        debug "#{nick} unsubscription request succeeded."
      else
        msg = 'You are not subscribed.'
        debug "#{nick} unsubscription request failed: Not subscribed."
      end
      m.user.notice "#{msg} To subscribe use `.hangouts subscribe`."
    end

    def list_hangouts(m)
      Hangout.delete_expired(@expire, @files)
      if Hangout.sorted(@files).empty?
        m.user.notice 'No hangouts have been linked recently!'
        return
      end
      m.user.notice 'These hangouts have been linked in the last ' \
                    "#{@expire} minutes. They may or may not still be going."
      hangouts = Hangout.sorted(@files)
      debug "#{m.user.nick} hangouts listing request; Sending #{hangouts.count} hangouts to them."
      hangouts.each do |hangout|
        m.user.notice "#{hangout.nick} started a hangout at " \
                      "#{Hangout.url(hangout.id)} it was last linked " \
                      "#{hangout.time.ago.to_words}"
      end
    end
  end
end
