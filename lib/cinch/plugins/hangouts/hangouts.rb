# -*- coding: utf-8 -*-
require 'cinch'
require 'cinch-storage'
require 'cinch-toolbox'
require 'time-lord'

module Cinch::Plugins
  class Hangouts
    include Cinch::Plugin

    self.help = "Use .hangouts to see the info for any recent hangouts. You can also use .hangouts subscribe to sign up for notifications."

    match /hangouts\z/,           method: :list_hangouts
    match /hangouts subscribe/,   method: :subscribe
    match /hangouts unsubscribe/, method: :unsubscribe

    listen_to :channel

    # This is the regex that captures hangout links in the following format:
    #   https://plus.google.com/hangouts/_/fbae432b70a47bdf7786e53a16f364895c09d9f8
    #
    # The regex will need to be updated if the url scheme changes in the future.
    HANGOUTS_REGEX = /plus.google.com\/hangouts\/_\/([^\/?]{40})/

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/hangouts.yml')
      @storage.data[:hangouts] ||= {}
      @storage.data[:subscriptions] ||= []

      @expire_period = config[:expire_period] || 120
      @response_type = config[:response_type] || :notice
    end

    def listen(m)
      if hangout_id = m.message[HANGOUTS_REGEX, 1]
        # If it's a new hangout capture the first linker's name
        @storage.data[:hangouts][hangout_id] ||= { :user => m.user.nick }

        notify_subscribers(m.user.nick, hangout_id,
                           @storage.data[:hangouts][hangout_id].key?(:time))

        # Record the current time for purposes of auto expiration
        @storage.data[:hangouts][hangout_id][:time] = Time.now

        @storage.synced_save(@bot)
      end
    end

    private

    def notify_subscribers(nick, hangout_id, new)
      @storage.data[:subscriptions].each do |sub|
        unless nick == sub[:nick]
          Cinch::User.new(user, @bot).
            notice "#{nick} just linked a new hangout at: #{hangout_url(hangout_id)}"
        end
      end
    end

    def list_hangouts(m)
      hangouts = sort_and_expire

      if hangouts.empty?
        respond m, "No hangouts have been linked recently!"
      else
        respond m, "These hangouts have been linked in the last #{@expire_period} minutes. " +
                   "They may or may not still be going."
        hangouts.each do |hangout|
          respond m, "#{hangout[:user]} started a hangout at #{hangout_url(hangout[:id])} " +
                     "it was last linked #{hangout[:time].ago.to_words}"
        end
      end
    end

    def subscribe(m)
      nick = m.user.nick
      if @storage.data[:subscriptions].include?(nick)
        msg = "You are already subscribed. "
      else
        @storage.data[:subscriptions] << nick
        @storage.synced_save(@bot)
        msg = "You are now subscribed. I will let you know when a hangout is linked. "
      end
      respond m, msg + "To unsubscribe use `.hangouts unsubscribe`."
    end

    def unsubscribe(m)
      nick = m.user.nick
      if @storage.data[:subscriptions].include?(nick)
        @storage.data[:subscriptions].delete(nick)
        @storage.synced_save(@bot)
        msg = "You are now unsubscribed, and will no longer receive a messages. "
      else
        msg = "You are not subscribed. "
      end
      respond m, msg + "To subscribe use `.hangouts subscribe`."
    end

    def sort_and_expire
      @storage.data[:hangouts].delete_if { |id, h| (Time.now - h[:time]) > (@expire_period * 60) }
      @storage.synced_save(@bot)

      hangouts = @storage.data[:hangouts].each_pair.map { |x,y| y[:id] = x;y }
      hangouts.sort! { |x,y| y[:time] <=> x[:time] }
      return hangouts
    end

    def hangout_url(id)
      return Cinch::Toolbox.shorten("https://plus.google.com/hangouts/_/#{id}")
    end

    def respond(m, message)
      case @response_type
      when :notice
        m.user.notice message
      when :pm
        m.user.send message
      else
        m.reply message
      end
    end
  end
end
