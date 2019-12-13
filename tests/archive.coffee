Helper = require('hubot-test-helper')
expect = require('chai').expect
nock = require('nock')

process.env.HUBOT_ARCHIVE_REPO = 'myorg/myrepo'

# helper loads a specific script if it's a file
helper = new Helper('./../scripts/archive.coffee')

describe 'archive', ->
  room = null
  archive_repo = process.env.HUBOT_ARCHIVE_REPO

  beforeEach ->
    room = helper.createRoom(httpd: false)

    do nock.disableNetConnect
    nock('https://hackmd.io')
      .get('/xxxxxxxxxxxxxxxxxxxxxx/download')
      .reply 200, '# This is a test'
      .get('/xxxxxxxxxxxxxxxxxxxxxx')
      .reply 200, '<title>This is a test</title>'

    nock('https://api.github.com')
      .get("/repos/#{archive_repo}")
      .reply 200, {default_branch: 'master', owner: {login: 'myorg'}}
      .get("/repos/#{archive_repo}/branches/master")
      .reply 200, {commit: {sha: '1234567890abcdef'}}
      .post("/repos/#{archive_repo}/git/refs")
      .reply 201, {}
      .put("/repos/#{archive_repo}/contents/this-is-a-test.md")
      .reply 201, {}
      .post("/repos/#{archive_repo}/pulls")
      .reply 201, {html_url: "https://github.com/#{archive_repo}/pull/123"}

  afterEach ->
    room.destroy()

  context 'user archives dynamic hackmd split link', (done) ->
    link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
    beforeEach (done) ->
      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100

    afterEach ->
      nock.cleanAll()

    it 'should successfully create pull request', ->
      hubot_reply = room.messages[1][1]
      expect(hubot_reply).to.include "Yay! Archiving in progress!\nWaiting for public review at https://github.com/#{archive_repo}/pull/123"
