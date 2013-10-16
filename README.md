# Firebase / Urban Airship push notifications queue

Use a Firebase queue hosted on Heroku for delivering push notifications through Urban Airship.

* Task queue: Firebase WorkQueue.js

# Installation

## Local dev environment (OSX, but Linux should be similar)

Add to .bash_profile

    export FIREBASE_URL="firebase-url"
    export FIREBASE_SECRET="firebase-secret"
    export UA_KEY="urban-airship-key"
    export UA_SECRET="urban-airship-secret"
    export UA_MASTERSECRET="urban-airship-mastersecret"

Install dependencies

    npm install


## Deploy to Heroku

Install Heroku toolbelt and:

    heroku create XXX
    heroku config add FIREBASE_URL="firebase-url"
    heroku config add FIREBASE_SECRET="firebase-secret"
    heroku config add UA_KEY="urban-airship-key"
    heroku config add UA_SECRET="urban-airship-secret"
    heroku config add UA_MASTERSECRET="urban-airship-mastersecret"
    git push heroku master


# Usage

## Default callback
Expects the Firebase push messages to be added as 

    baseRef ("/messages/push")
        |
        `- Sender id
            |
            `- Message id
                |
                `- Message

Message should have the following Urban Airship fields:

Mandatory
    alias or device_token
    alert

Optional
    Badge
    Sound


## BYO callback

Override the function that gets called when a new message has been received from Firebase by setting options.firebaseCallback(snapshot).  The overriding function needs to call `sendPushToUser(message)` and remove the Firebase reference `snapshot.ref().remove()`.