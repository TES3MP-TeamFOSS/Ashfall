# BabelFish Google translate API in nodeJS

This API will translate GET queries you provide it. You need LuaSocket to be able to interact with it. It was intended to be used with the [BabelFish](../../modules/BabelFish/) module.

## How to query it

You have 3 variables, one of which is required, the others being optional.
* to (optional)
* from (optional)
* text (required)

`to` is optional. If it isn't set it will default to English.  
`from` is optional. If not set it will autodetect the language.  
`text` is the text you want to translate.  

If you have the nodeJS server running, a normal query would look like this:
```
http://localhost:8000/?to=en&from=nl&text=Het%20werkt!
```
Which will give the plain text response of: `It works!`

## How to set it up

This needs nodejs to run, so install these packages:
* nodejs
* npm

If you are unsure on how to install these packages look here:

[Installing Node.js via package manager](https://nodejs.org/en/download/package-manager/)

Once those packages are installed go into this directory with a terminal. Issue the commands:
```
npm install
npm server.js
```
Then try it out on your localhost:
```
http://localhost:8000/?text=Het%20werkt!
```

## Recommendation

You should be good to go now but if you want to daemonize the api it's highly recommended to install pm2. This needs to be installed globablly so either:
```
sudo npm install -g pm2
```
or:
```
su -c "npm install -g pm2"
```

Once done you can daemonize the server like so:
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
