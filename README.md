# Cinch::Plugins::Hangouts

Cinch Plugin for tracking Hangout URLs linked in the channel.

## Installation

Add this line to your application's Gemfile:

    gem 'cinch-hangouts'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cinch-hangouts

## Usage

Just add the plugin to your list:

    @bot = Cinch::Bot.new do
      configure do |c|
        c.plugins.plugins = [Cinch::Plugins::Hangouts]
      end
    end

Then in channel use .hangouts to get notifications of the hangouts that have been linked recently.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
