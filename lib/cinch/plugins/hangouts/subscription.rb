class Subscription < Cinch::Plugins::Hangouts
  attr_accessor :nick, :all_links

  def to_yaml
    { }
  end

  def initialize(nick)
    @nick = nick
    @all_links = false
    save
  end

  def save
    subs = Subscription.storage
    subs.data[self.nick] = self
    subs.save
  end

  def delete
    subs = Subscription.storage
    subs.data[self.nick] = nil
    subs.save
  end

  def self.for_user(nick)
    return nil unless list.key?(nick)
    list[nick]
  end

  def self.list
    Subscription.storage.data
  end

  def self.notify(hangout_id, bot)
    nick = Hangout.find_by_id(hangout_id).nick
    Subscription.list.each do |sub|
      # Don't link the person who linked it.
      if nick != sub.nick
        user = Cinch::User.new(sub.nick, bot)
        respond(user, "#{nick} just linked a new hangout at: #{Hangout.url(hangout_id)}")
      end
    end
  end

  private

  def self.storage
    CinchStorage.new(@@subscription_filename)
  end
end

