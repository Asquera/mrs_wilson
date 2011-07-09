# Setup on Heroku

## Create a jabber account at a server you like and trust

I use jabber.ccc.de.

## Create a Heroku app using the cedar stack

    $ heroku create my-cool-app --stack cedar

Configure the following variables, proper config files will follow:
   
    $ heroku config:add WILSON.BOT.ACCOUNT="my_bot@account.de"
    $ heroku config:add WILSON.BOT.PASSWORD="my_bots_password"
    $ heroku config:add WILSON.MASTER.ACCOUNT="your@jabber.account"

To configure Harvest, use:

    $ heroku config:add HARVEST.SUBDOMAIN="yourcompany"
    $ heroku config:add HARVEST.EMAIL="youremail"
    $ heroku config:add HARVEST.PASSWORD="yourpwd"

Push the repository to heroku:

    $ git push git@heroku.com:yourapp.git

Wait for deployment to finish, scale down the webapp and scale up a worker:

    $ heroku scale web=0 mrswilson=1

The bot will contact you.

## And then?

Fork and make this thing clean. British humor preferred.
