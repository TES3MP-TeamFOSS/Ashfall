# BabelFish google translate API in nodeJS

This api will translate GET queries you throw against it.
You need LUA sockets to be able to interact with it.

## How to query it

You have 3 variables of which one is actually needed.
* to (optional)
* from (optional)
* text (needed)

To is optional if it is not set it will default to English.
From is optional if not set it will autodetect language.
Text is the text you want to translate

If you have the nodeJS server running a normally query would look like this:
```
http://localhost:8000/?to=en&from=nl&text=Het%20werkt!
```

Which will give a plain text response of:
It works.

## How to set it up

This is needs to run on nodejs so install these packages:
* nodejs
* npm

If you are unsure on how to install these packages look here:
https://nodejs.org/en/download/package-manager/

Once those packages are installed go into this directory with a terminal.
issue the commands:
```
npm install
npm server.js
```
Then try it out on your localhost:
```
http://localhost:8000/?text=Het%20werkt!
```

## Reccomendation

You should be good to go now but if you want to daemonize the api it's highly recommended to install pm2.
This is needed to be installed globablly so either:
```
sudo npm install -g pm2
```
or:
```
su -c "npm install -g pm2"
```

Once done you can daeomonize the server like so:
```
pm2 start server.js --name BabelFish API
```
This starts a pm2 process based on server.js with the name `BabelFish API`

You can monitor pm2 via:
```
pm2 monit
```

Or simply list all the apps that pm2 is running with:
```
pm2 list
```

More on pm2:
http://pm2.keymetrics.io/

## Node modules used to make this work:
* google-translate-api - https://www.npmjs.com/package/google-translate-api
* express - https://www.npmjs.com/package/express
