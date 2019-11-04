# Folder layout
#       challenges/
#         <name of challenge>/
#           config.json describing challenge
#           downloads/
#             <file1>, .., <fileN>: downloadable challenge artifacts
#           entries/
#           votes/

express = require 'express'
session = require 'express-session'
FileStore = require('session-file-store') session
fs = require 'fs'
sep = require('path').sep
formidable = require 'formidable'

app = do express
app.use session
    store: new FileStore,
    secret: 'keyboard cat', # TODO
    resave: true,
    saveUninitialized: true

# TODO: session tests
# See https://github.com/expressjs/session
# See https://github.com/valery-barysok/session-file-store/tree/master/examples/express-example
app.get '/session', (req, res) ->
  if req.session.views
    req.session.views++
    res.setHeader 'Content-Type', 'text/html'
    res.write '<p>views: ' + req.session.views + '</p>'
    do res.end
  else
    req.session.views = 1
    res.end 'Welcome to the file session demo. Refresh page!'

# Get challenges listing
# For REST info, see https://en.wikipedia.org/wiki/Representational_state_transfer
app.get '/challenges', (req, res) ->
  fs.readdir __dirname + '/challenges', (error, files) ->
    if not error?
      # See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error
      res.json files
    else
      res.end error.toString()

getChallenge = (id, isAdmin) ->
  # Get information for challenge <id>
  # TODO: use asynchronous file read?
  challenge = JSON.parse fs.readFileSync __dirname + '/challenges/' + id + '/config.json'
  challenge.id = id
  challenge.status = 4 if isAdmin
  challenge

# Get challenge information
# Use  a status field: 1 = announced, 2 = running, 3 = vote, 4 = finished (default 0 = auto) to switch between states disregarding provided start and end times
app.get '/challenges/:id', (req, res) ->
  challenge = getChallenge req.params.id, req.session.isAdmin

  # TODO: use asynchronous file read
  challenge.downloads = fs.readdirSync __dirname + '/challenges/' + req.params.id + '/downloads' if challenge.status > 1

  challenge.uploadId = req.session.uploadId

  # Available competition tracks are all files in the entries directory
  # We have an audio file + .json file for each entry
  # TODO: add current user's votes
  fs.readdir __dirname + '/challenges/' + req.params.id + '/entries', (error, files) ->
    challenge.entries = []
    challenge.votes = {}
    if not error? and challenge.status > 2
      # See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error
      files.forEach (file, index) ->
        if file.endsWith '.json'
          # Add entry data
          entry = JSON.parse fs.readFileSync __dirname + '/challenges/' + req.params.id + '/entries/' + file
          challenge.entries.push
            path: entry.path
            artist: if challenge.status > 3 then entry.artist else ''
            title: entry.title
            uploadId: entry.uploadId
        if file.endsWith('.vote') and challenge.status > 3
          # Add artist's votes
          vote = JSON.parse fs.readFileSync __dirname + '/challenges/' + req.params.id + '/entries/' + file
          for e, v of vote
            challenge.votes[e] = (challenge.votes[e] || 0) + Number v

      # Sort entries by vote if challenge.status > 3
      if challenge.status > 3
        challenge.entries.sort (a, b) ->
          (challenge.votes[b.uploadId] || 0) - (challenge.votes[a.uploadId] || 0)
      else
        challenge.entries.sort (a, b) ->
          if a.uploadId < b.uploadId
            -1
          else if b.uploadId < a.uploadId
            1
          else
            0

      res.json challenge
    else
      console.log error if error?
#     TODO: res.end error.toString()
      res.json challenge

# Download challenge artifact
# See https://arjunphp.com/download-file-node-js-express-js/
# TODO: only provide downloads after the challenge has started
app.get '/challenges/:id/downloads/:name(*)', (req, res) ->
  path = __dirname + '/challenges/' + req.params.id + '/downloads/' + req.params.name
  res.download path, req.params.name

# Download entry
# See https://arjunphp.com/download-file-node-js-express-js/
# TODO: only provide downloads after the challenge has started
app.get '/challenges/:id/entries/:name(*)', (req, res) ->
  path = __dirname + '/challenges/' + req.params.id + '/entries/' + req.params.name
  res.download path, req.params.name

# Use Formidable to handle (file) uploads
# https://github.com/felixge/node-formidable
app.post '/challenges/:id/upload', (req, res) ->
  form = new formidable.IncomingForm
  form.keepExtensions = true;
  form.uploadDir = __dirname + '/challenges/' + req.params.id + '/entries/'

  # Only allow uploads after the challenge has started (status == 2)
  challenge = getChallenge req.params.id, req.session.isAdmin

  return res.json { message: 'Challenge is not running. Uploads are not possible.' } unless challenge.status == 2

  form.on 'fileBegin', (field, file) ->
    # Remove 'upload_' prefix from file path's and care for previous upload session
    path = file.path.split sep
    comp = path[path.length - 1].substr(7).split('.')
    path[path.length - 1] = (req.session.uploadId || comp[0]) + '.' + comp[1]
    file.path = path.join sep
    console.log 'receiving: ' + file.path

  form.parse req, (error, fields, files) ->
    console.log error if error?
    # TODO: use fields.uploadId (if present) to overwrite existing entry
    path = files.file.path.split sep
    data =
      artist: fields.artist
      title: fields.title
      path: path[path.length - 1]
      uploadId: path[path.length - 1].split('.')[0]

    # Keep the uploadId as session info in order to allow uploading and voting again
    req.session.uploadId = data.uploadId
    
    path[path.length - 1] = path[path.length - 1].split('.')[0] + '.json'
    fs.writeFile path.join(sep), JSON.stringify(data), (error) ->
      console.log error if error?

    res.json data

app.post '/challenges/:id/vote', (req, res) ->
  form = new formidable.IncomingForm

  form.parse req, (error, fields, files) ->
    console.log error if error?

    return res.json { success: false } unless req.session.uploadId?

    path = __dirname + '/challenges/' + req.params.id + '/entries/' + req.session.uploadId + '.vote'
    fs.writeFile path, JSON.stringify(fields), (error) ->
      console.log error if error?
    res.json { success: true }

# Allow login as admin and using artist / uploadId
app.get '/login/:id?/:user/:pw', (req, res) ->
  result = { success: false, message: 'This upload token does not seem to be valid for the challenge.' }
  req.session.isAdmin = req.params.user is config.user && req.params.pw is config.pw

  if req.session.isAdmin
    result = { success: true, message: 'Welcome admin!' }
  else if req.params.id?
    # Try to load config file
    entry = JSON.parse fs.readFileSync __dirname + '/challenges/' + req.params.id + '/entries/' + req.params.pw + '.json'
    req.session.uploadId = entry.uploadId
    result = { success: true, message: 'Welcome ' + entry.artist + '!' } if entry.artist?

  res.json result

# Serve the frontend from subfolder www
app.use express.static __dirname + '/www'

server = app.listen 62416, () ->
  host = server.address().address
  port = server.address().port
  console.log 'One hour challenge tool listening at http://%s:%s', host, port

# Startup code
try
  # TODO: use asynchronous file read
  config = fs.readFileSync __dirname + '/config.json'
  config = JSON.parse config
  console.log config
catch e
  console.log "Error reading config: ", e
  config =
    user: 'admin'
    pw: 'admin'
