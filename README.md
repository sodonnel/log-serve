# Install

    gem install log-serve

# Run

Switch to a directory containing log files you want to view and then run log-serve. It will start a webserver on port 3000:

    log-serve
    [2016-11-01 21:17:47] INFO  WEBrick 1.3.1
    [2016-11-01 21:17:47] INFO  ruby 2.2.1 (2015-02-26) [x86_64-darwin14]
    [2016-11-01 21:17:47] INFO  WEBrick::HTTPServer#start: pid=74826 port=3000

# Development

The application is currently split into two seperate gems - log-serve, this gem, which is a Sinatra application built in a modular style and log-merge, which is used to read the log files and merge multiple files together. The log-merge gem really needs renamed to something more sensible, but I will get to that eventually.

If you install log-serve as a gem, it will install log-merge as a dependency and you don't need to worry about it any further. However, if you want to develop both gems then you will want to have them both checked out locally.

To manage the local gems bundler is used. Notice in the Gemfile that the path to log-merge is git:

    gem 'log-merge', github: "sodonnel/log-merge", branch: "master"

With that in place, you can then tell bundler to use a local resource for the log-merge gem:

    bundle config --local local.log-merge /path/to/log-merge

If you later want to delete this local resource, you can do it with:

    bundle config --delete local.log-merge

More info on this technique [here](https://rossta.net/blog/how-to-specify-local-ruby-gems-in-your-gemfile.html)

## Running in Development

To run the application in development, use bundle exec:

    bundle install

    bundle exec rerun rackup
