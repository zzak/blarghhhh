# blarghhhhhhhhhhhh

So you've found my little blogging application have you?

Kudos to you for being so intuitive. I assure that this tiny sinatra app is
more than meets the eye.

`blarghhhh` relies entirely upon [github](http://develop.github.com/) to
provide an interface for you to enjoy my writing in an efficient manner.

You can see that all of my articles are easily drawn from an [entirely separate
repository](http://github.com/zzak/blog.zacharyscott.net).

This allows me to easily add new posts and update existing ones directly from
the [editor of my choice](http://www.vim.org/). All of the articles are just
plain text files in [markdown
format](http://daringfireball.net/projects/markdown/).

## what you see is what you get

`blarghhhh` gets some help from [nokogiri](http://nokogiri.org/),
[pygments](http://pygments.org/) via
[albino](https://github.com/github/albino), and
[redcarpet](https://github.com/tanoku/redcarpet) to properly render the
markdown text and even highlight any code blocks included in the article. Just
like you see when reading the article directly on github. Having legible code
on my blog is a priority and I'm going to assume you know why.

## everyone's got a blarghhhh these days

You can try to set up a `blarghhhh` of your own if you have any familiarity
with [Sinatra](http://www.sinatrarb.com/). There shouldn't be any problem
getting it to run on [heroku](http://www.heroku.com/) as that's my platform of
choice. All of the configurables can be hard coded directly in the source or
using `ENV`'s with the help of [heroku's `config`
command](http://devcenter.heroku.com/articles/config-vars).

## make it so

Customizing your own is a different story however, as all the views are inline
the source for my own sake. Although, all the data is drawn from the api of the
target repository, the design is written inline using
[haml](http://haml-lang.com/) and [sass](http://sass-lang.com/). At the moment,
I don't have any plans to add theme support or anything fancy like that, but
feel free to [fork away](https://github.com/zzak/blarghhhh/fork) and make any
improvements you'd like.
