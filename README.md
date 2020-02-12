# one-hour-challenge
Web application to aid online composition challenges

## Starting the application

node app.js

## Login

### For users

The token returned from the application after uploading a track serves as a login token. Re-login should only be necessary if your browser does not support cookies or the browser somehow lost the cookie. If this is the case a login link will appear next to the challenge's title. Login via the application is only possible if a challenge is in status "vote".

#### Manual login

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

Create a new folder in sub-folder challenges/. The folder's name will be used as challenge id and displayed as the challenge's name in the web application.

### Challenge config.json

Use the status field  in order to switch between states disregarding provided start and end times:
1 = announced, 2 = running, 3 = vote, 4 = finished (default 0 = auto)

The administrator always sees the application in state 4 in order to have access to all data.
