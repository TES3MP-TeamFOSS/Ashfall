const express = require('express');
const translate = require('google-translate-api');
var app = express();
port = 8000;

app.listen(port);
app.get('/', function(req, res) {
  var translateObj = {};
  if(req.query.to && translate.isSupported(req.query.to)){
    translateObj['to'] = req.query.to;
  }
  if(req.query.from && translate.isSupported(req.query.from)){
    translateObj['from'] = req.query.from;
  }
  translate(req.query.text, translateObj).then(result => {
    res.send(result.text);
  }).catch(err => {
    console.error(err);
  });
});
