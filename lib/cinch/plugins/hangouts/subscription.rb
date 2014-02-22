# -*- encoding : utf-8 -*-
# Class to handle user subscriptions
class Subscription < Cinch::Plugins::Hangouts
  attr_accessor :nick, :all_links

  def initialize(nick)
    @nick = nick
    @all_links = false
    save
  end

  def save
    subs = Subscription.storage
    subs.data[nick] = self
    subs.save
  end

  def delete
    subs = Subscription.storage
    subs.data.delete(nick)
    subs.save
  end

  def self.for_user(nick)
    return nil unless list.key?(nick)
    list[nick]
  end

  def self.list
    storage.data
  end

  def self.notify(hangout_id, bot, type)
    nick = Hangout.find_by_id(hangout_id).nick
    list.each_value do |s|
      # Don't link the person who linked it.
      unless nick == s.nick
        user = Cinch::User.new(s.nick, bot)
        message = "#{nick} just linked a new hangout at: " +
                  Hangout.url(hangout_id)
        respond(user, message, type)
      end
    end
  end

  def self.respond(user, message, type)
    case type
    when :notice
      user.notice message
    when :pm
      user.send message
    end
  end

  private

  def self.storage
    Cinch::Storage.new(@@subscription_filename)
  end
end
