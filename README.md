# README

This repository contains an implementation of the Obé Software Engineer Tech Task - Variant D.

It was built with Ruby 3.2.0. It involves a Whenever task for cache cleanup, but is otherwise very simple, so as long as the correct version of Ruby is installed, it should run after running `bundle install` and `bundle exec whenever --update-crontab --set environment='development'`. Most of the relevant code can be found in `app/controllers/characters_controller.rb`, although `config/schedule.rb` and `lib/tasks/rickmorty.rake` also contain a little code I wrote. Everything else in the whole system is boilerplate generated by Rails when I created this project.

I worked on this project in fits and starts between other interview tasks and parenting, but overall I'd say the 3-hour estimate was roughly accurate. The Rick & Morty API was relatively easy to work with (its tendency to throw an error whenever it didn't find results was a bit annoying, but easily accounted for), and mapping episodes to season numbers was pretty easy as well. The cache itself was also easy to set up, as it's a built-in Ruby feature, but as I had not implemented it before myself, I had to address questions like cleanup, and keeping it up-to-date.

TV shows tend to run on a weekly basis, so I considered our data "good" for a period of 1 week. If 1 week has elapsed since data was retrieved on a character, it's possible that a new episode might have aired featuring them, which would make their data outdated. Therefore, I gave every cache entry a 1-week expiration period, and set up a Cron job via Whenever which runs `Rails.cache.cleanup` once per week to ensure that these values are removed from the cache once they expire.

The nature of caching is such that the cache is emptied every time the server reboots, which makes sense when you're developing it, because the "correct" shape of your data might change depending on what you're working on. In production, theoretically this service would reboot much more infrequently, unless it grew into a more actively-maintained codebase (like most professionally-maintained ones). In that eventuality, you'd probably want to switch from a simple cache to a NoSQL-style datastore such as MongoDB, to ensure that the cache survives across reboots and ensure continued performance.

A traditional relational database, set up via ActiveModel as you'd usually find in a Rails app like this one, actually isn't called for in this particular instance, wherein you just want to map a query (or key) to a set of data (or value) with a specific expiration date. Now, if the object of this code test was to CLONE the Rick & Morty API rather than simply query it and transform the data a little bit, and we were storing character data for the long term and editing it manually every time a new episode aired, I'd want to set up a full relational database (probably in PostgreSQL), but that's out of scope for this assignment as written. I would also want to write unit tests, but since these were not requested for the assignment, I also considered them out of scope.
