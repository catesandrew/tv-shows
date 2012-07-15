=== TVShows

TVShows is a Mac OS X application that automatically downloads your favourite shows. You don't need anymore to
manually download torrent files, TVShows does it for you. Manage your subscriptions and preferences from within
the TVShows application, and TVShows takes care of the rest: a background process is automatically launched at
a regular interval to check for new episodes.

== Goals

The goals of this project were to keep it simple and lightweight. I always liked the simplicity of the original
application and how light weight it was. However, the services it used stopped working well so I set off on
updating the scripts. I chose the excellent web scraping tools from NodeJS's arsenal and started over. Instead
of searching for new episodes for each subscription, n times, now we download the latest list every interval,
scurb it, and see if any match one from the subscribed list. 

It runs well without the application frontend if one were so inclined. 

== Building

First clone this repo, then init the git submodules and update them. This will put the scripts into TVShowsScript
folder. Then you will have to run `npm link` in the TVShowsScript folder to get the node_modules folder populated.

Node is required for running npm I think and for you to play around with the scripts if you would like. However,
a binary of node is included so the final application is not dependent on it.
