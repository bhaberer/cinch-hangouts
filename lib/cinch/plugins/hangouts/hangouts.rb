# -*- coding: utf-8 -*-
module Cinch::Plugins
  class Hangouts
    include Cinch::Plugin

    self.help = "Use .hangouts to see the info for any recent hangouts. You can also use .hangouts subscribe to sign up for notifications."

    match /hangouts\z/,           method: :list_hangouts
    match /hangouts subscribe/,   method: :subscribe
    match /hangouts unsubscribe/, method: :unsubscribe

    listen_to :channel

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/hangouts.yml')
      @storage.data[:hangouts] ||= {}
      @storage.data[:subscriptions] ||= []
      @expire_period = config[:expire_period] || 120
    end

    def listen(m)
      # This is the regex that captures hangout links in the following format:
      #
      #   https://plus.google.com/hangouts/_/fbae432b70a47bdf7786e53a16f364895c09d9f8
      #
      # The regex will need to be updated if the url scheme changes in the future.
      if m.message.match(/plus.google.com\/hangouts\//)
        hangout_id = m.message[/[^\/?]{40}/, 0]
        unless hangout_id.nil?
          if @storage.data[:hangouts].key?(hangout_id)
            @storage.data[:hangouts][hangout_id][:time] = Time.now
          else
            @storage.data[:hangouts][hangout_id] = {:user => m.user.nick, :time => Time.now}
          end

          synchronize(:hangout_save) do
            @storage.save
          end

         @storage.data[:subscriptions].each do |user|
            unless m.user.nick == user
              Cinch::User.new(user, @bot).notice "#{m.user.nick} just linked a new hangout at #{hangout_url(hangout_id)}!"
            end
          end
        end
      end
    end

    private

    def list_hangouts(m)
      hangouts = sort_and_expire
      if hangouts.empty?
        m.user.notice "No hangouts have been linked recently!"
      else
        m.user.notice "These hangouts have been linked in the last #{@expire_period} minutes. They may or may not still be going."
        hangouts.each do |hangout|
          m.user.notice "#{hangout[:user]} started a hangout #{hangout[:time].ago.to_words} ago at #{hangout_url(hangout[:id])}"
        end
      end
    end

    def subscribe(m)
      nick = m.user.nick
      if @storage.data[:subscriptions].include?(nick)
        m.user.notice "You are already subscribed, to unsubscribe use `.hangouts unsubscribe`"
      else
        @storage.data[:subscriptions] << nick
        synchronize(:hangout_save) do
          @storage.save
        end
        m.user.notice "You are now subscribed, and will receive a message when a *new* hangout is linked. To unsubscribe use `.hangouts unsubscribe`."
      end
    end

    def unsubscribe(m)
      nick = m.user.nick
      if @storage.data[:subscriptions].include?(nick)
        @storage.data[:subscriptions].delete(nick)
        synchronize(:hangout_save) do
          @storage.save
        end
        m.user.notice "You are now unsubscribed, and will no longer receive a messages. To resubscribe use `.hangouts subscribe`."
      else
        m.user.notice "You are not subscribed, to subscribe use `.hangouts subscribe`"
      end
    end

    def sort_and_expire
      hangouts = @storage.data[:hangouts].each_pair.map { |x,y| y[:id] = x;y }
      hangouts.delete_if { |h| Time.now - h[:time] > @expire_period * 60 }
      hangouts.sort! { |x,y| y[:time] <=> x[:time] }
      return hangouts
    end

    def hangout_url(id)
      return Cinch::Toolbox.shorten("https://plus.google.com/hangouts/_/#{id}")
    end
  end
end
