# Cinch::Plugins::Hangouts

[![Gem Version](https://badge.fury.io/rb/cinch-hangouts.png)](http://badge.fury.io/rb/cinch-hangouts)
[![Dependency Status](https://gemnasium.com/bhaberer/cinch-hangouts.png)](https://gemnasium.com/bhaberer/cinch-hangouts)
[![Build Status](https://travis-ci.org/bhaberer/cinch-hangouts.png?branch=master)](https://travis-ci.org/bhaberer/cinch-hangouts)
[![Coverage Status](https://coveralls.io/repos/bhaberer/cinch-hangouts/badge.png?branch=master)](https://coveralls.io/r/bhaberer/cinch-hangouts?branch=master)
[![Code Climate](https://codeclimate.com/github/bhaberer/cinch-hangouts.png)](https://codeclimate.com/github/bhaberer/cinch-hangouts)

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
