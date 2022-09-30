# one-hour-challenge
Web application to aid online composition challenges

## Starting the application

node app.js

## Login

### For users

The token returned from the application after uploading a track serves as a login token. Re-login should only be necessary if your browser does not support cookies or the browser somehow lost the cookie. If this is the case a login link will appear next to the challenge's title. Login via the application is only possible if a challenge is in status "vote".

### Manual login

`<application url>/login/<challenge id>/token/<upload token>`

### For administrators

`<application url>/login/<user>/<pw>`

The admin user and password has to be configured in the application-wide config.json:

```javascript
{
	"user": "<admin user name>",
	"pw": "<admin password>"
}
```

## Setting up a new challenge

Create a new folder in sub-folder challenges/. The folder's name will be used as challenge id and displayed as the challenge's name in the web application. Please create the following folder structure and files:

```
challenges/
  <name of challenge>/
    config.json: describe the challenge
    downloads/
      <file1>, .., <fileN>: downloadable challenge artifacts
    entries/
```

### How to run a challenge

The contents of your challenge's config.json should look something like this

```json
{
    "title": "Sonoj 2019 - One Hour Challenge",
    "info": "Please allow JavaScript and Cookies for the challenge and uploads to work smoothly. Rules can be found here:",
    "url" : "https://www.sonoj.org/challenge/rules.html",
    "status": 1
}
```

Use the status field to switch between challenge states:
1 = announced, 2 = running, 3 = vote, 4 = finished

Set the status to 2 in order to start the challenge: the provided downloads will be made visible as well as the upload form for contest entries.

Once the challenge time is up (i.e. an hour later) set the status to 3. Afterwards, you will find all uploaded tracks together with a respective JSON file in the entries subfolder. Every contestant may then vote for all the tracks. In general, you will want to have a little ceremony where every track is played to the audience and the contestants vote for each track. For every audio track in entries subfolder you should find a respective vote file after everyone has voted.

If all votes are in, set the status to 4. The entered tracks will be ordered by points received in the voting stage.

The administrator always sees the application in state 4 in order to have access to all data.
