# crushserver

A collection of Capistrano tasks we use at Crush + Lovely as part of our deployment routine.

## Usage

Add `require 'crushserver/recipes'` to the top of your `deploy.rb`.

Ideally, you should be deploying via Bundler to ensure your gem dependencies are correct.  We typically have a `deploy` group in our Gemfile that looks like this:

``` ruby
group :deploy do
  gem 'capistrano', '2.9.0'
  gem 'capistrano-ext'
  gem 'crushserver', '1.0.0'
end
```

If you want to take advantage of the built-in HipChat deploy notifications, you'll need a `.crushserver.yml` in your home folder with the appropriate configuration variables.