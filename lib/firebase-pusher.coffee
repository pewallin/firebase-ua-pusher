_ = require "underscore"
Firebase = require "firebase"
UA = require "urban-airship"
FirebaseTokenGenerator = require("firebase-token-generator")
WorkQueue = require "./vendor/WorkQueue"

ua = new UA(process.env.UA_KEY, process.env.UA_SECRET, process.env.UA_MASTERSECRET)

# http://stackoverflow.com/questions/1199352
truncate = (string, n, useWordBoundary) ->
  tooLong = string.length > n
  s_ = if tooLong then string.substr(0, n - 1) else string
  s_ = if useWordBoundary and tooLong then s_.
  substr(0, s_.lastIndexOf(" ")) else s_
  if tooLong then s_ + "&hellip;" else s_


# Authenticate as admin (full read/write permissions)
authenticateFirebase = (firebaseToken, firebaseRef) ->
  firebaseRef.auth firebaseToken, (err, result) ->
    return console.log "Firebase authentication failed!", err  if err

    expiresAt = new Date(result.expires * 1000)
    console.log "Firebase authenticated. Auth expires at:", expiresAt
    
    expiresIn = expiresAt - Date.now()

    setTimeout(->
      authenticateFirebase(firebaseToken, firebaseRef)
    , expiresIn)

  return firebaseRef


sendPushMessageToUser = (message) ->
  # userIds = array of user ids
  # 107 = Maximum characters in a UIAlertView
  payload =
    "device_token": [message.device_token]
    "aliases": [message.alias]
    "aps": 
      "badge": message.badge or "+1"
      "alert": truncate(message.alert, 107, false)
      "sound": message.sound or "default"
  # console.log "Sending", payload
  ua.pushNotification "/api/push/", payload, (err) ->
    return console.log "Error sending push: " + err if err
    console.log "Push sent to user(s)"


firebaseCallback = (snapshot) ->
  console.log "Sending message(s) on behalf of: " + snapshot.name()
  snapshot.ref().on "child_added", (snapshot) ->
    message = snapshot.val()
    try
      snapshot.ref().remove()
      sendPushMessageToUser message
      # TODO: WorkQueue!
    catch e
      console.log "Error: " + e.message

module.exports = (options) ->

  defaultOptions = 
    firebaseUrl: process.env.FIREBASE_URL
    firebaseSecret: process.env.FIREBASE_SECRET
    uaKey: process.env.UA_KEY
    uaSecret: process.env.UA_SECRET
    uaMasterSecret: process.env.UA_MASTERSECRET
    baseRef: "messages/push"
    firebaseCallback: firebaseCallback

  if typeof options == "object"
    options = _.extend(defaultOptions, options)
  else
    options = defaultOptions
  
  mainRef = new Firebase(options.firebaseUrl)
  tokenGenerator = new FirebaseTokenGenerator(options.firebaseSecret)
  token = tokenGenerator.createToken {}, admin:true

  ref = authenticateFirebase(token, mainRef)

  ref.child(options.baseRef).on "child_added", (snapshot) ->
    options.firebaseCallback(snapshot)  if snapshot



