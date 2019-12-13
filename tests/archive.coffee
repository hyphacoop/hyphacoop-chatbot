Helper = require('hubot-test-helper')
expect = require('chai').expect
nock = require('nock')

process.env.HUBOT_ARCHIVE_REPO = 'myorg/myrepo'

# helper loads a specific script if it's a file
helper = new Helper('./../scripts/archive.coffee')

describe 'archive', ->
  room = null

  beforeEach ->
    room = helper.createRoom(httpd: false)
    do nock.disableNetConnect
    nock('https://hackmd.io')
      .get('/xxxxxxxxxxxxxxxxxxxxxx').query(true)
      .reply 200, '<title>This is a test</title>'
      .get('/xxxxxxxxxxxxxxxxxxxxxx/download')
      .reply 200, '# This is a test'
      .get('/@someuser/xxxxxxxxx')
      .reply 200, '<title>This is a test</title>'
      .get('/@someuser/xxxxxxxxx/download')
      .reply 200, '# This is a test'

    nock('https://api.github.com')
      .get("/repos/#{process.env.HUBOT_ARCHIVE_REPO}")
      .reply 200, {commit: "xxxx"}

  afterEach ->
    room.destroy()
    nock.cleanAll()

  context 'user archives dynamic hackmd split link', ->
    link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
    beforeEach (done) ->
      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100

    it 'should reply to user', ->
      expect(room.messages).to.eql [
        ['alice', "hubot archive #{link}"]
        ['hubot', 'Yay! Archiving in progress!\nWaiting for public review at https://example.com']
      ]

  context 'user archives dynamic hackmd split link', ->
    link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx#deeplink'
    beforeEach (done) ->
      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100

    it 'should reply to user', ->
      expect(room.messages).to.eql [
        ['alice', "hubot archive #{link}"]
        ['hubot', 'Yay! Archiving in progress!\nWaiting for public review at https://example.com']
      ]

  context 'user archives dynamic hackmd view link', ->
    link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx?view'
    beforeEach (done) ->
      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100

    it 'should reply to user', ->
      expect(room.messages).to.eql [
        ['alice', "hubot archive #{link}"]
        ['hubot', 'Yay! Archiving in progress!\nWaiting for public review at https://example.com']
      ]

  context 'user archives static hackmd link', ->
    link = 'https://hackmd.io/@someuser/xxxxxxxxx'
    beforeEach (done) ->
      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100


    it 'should reply to user', ->
      expect(room.messages).to.eql [
        ['alice', "hubot archive #{link}"]
        ['hubot', 'Yay! Archiving in progress!\nWaiting for public review at https://example.com']
      ]
