# -*- encoding : utf-8 -*-
# Class to handle user subscriptions
class Subscription < Cinch::Plugins::Hangouts
  attr_accessor :nick, :all_links

  def initialize(nick, files)
    @nick = nick
    @all_links = false
    @files = files
    save
  end

  def save
    subs = Subscription.storage(@files)
    subs.data[@nick] = self
    subs.save
  end

  def destroy
    subs = Subscription.storage(@files)
    subs.data.delete(@nick)
    subs.save
  end

  def self.for_user(nick, files)
    nicks = list(files)
    return nil unless nicks.key?(nick)
    Subscription.new(nick[nick], files)
  end

  def self.list(files)
    storage(files).data
  end

  def self.notify(hangout_id, bot, type, files)
    nick = Hangout.find_by_id(hangout_id, files).nick
    list(files).each_value do |s|
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

  def self.storage(files)
    fail "No Subscription filename passed" unless files.key?(:subscriptions)
    Cinch::Storage.new(files[:subscriptions])
  end
end
