Helper = require('hubot-test-helper')
expect = require('chai').expect
nock = require('nock')

process.env.HUBOT_ARCHIVE_REPO = 'myorg/myrepo'

# helper loads a specific script if it's a file
helper = new Helper('./../scripts/archive.coffee')

describe 'archive', ->
  room = null
  archive_repo = process.env.HUBOT_ARCHIVE_REPO

  before ->
    do nock.disableNetConnect
    nock('https://api.github.com')
      .persist()
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

  after ->
    nock.cleanAll()

  beforeEach ->
    room = helper.createRoom(httpd: false)

  afterEach ->
    room.destroy()

  affirmative_response = """
    Yay! Archiving in progress!
    Waiting for public review at https://github.com/#{archive_repo}/pull/123
    """
  negative_response = "Sorry, no can do: document is marked 'private'"

  context 'user archives dynamic hackmd split link', (done) ->
    title = 'This is a test'
    link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
    beforeEach (done) ->
      nock('https://hackmd.io')
        .get('/xxxxxxxxxxxxxxxxxxxxxx/download')
        .reply 200, "# #{title}"
        .get('/xxxxxxxxxxxxxxxxxxxxxx')
        .reply 200, "<title>#{title}</title>"

      room.user.say 'alice', "hubot archive #{link}"
      setTimeout done, 100

    it 'should create pull request', ->
      hubot_reply = room.messages[1][1]
      expect(hubot_reply).to.include affirmative_response

  context 'archiving private notes', (done) ->
    before ->
      nock('https://hackmd.io')
        .get('/private-true')
        .reply 200, '<title>This is a test</title>'
        .get('/private-true/download')
        .reply 200, """
          ---
          private: true
          ---
          # This is a test
          """
        .get('/private-false')
        .reply 200, '<title>This is a test</title>'
        .get('/private-false/download')
        .reply 200, """
          ---
          private: false
          ---
          # This is a test
          """
        .get('/private-null')
        .reply 200, '<title>This is a test</title>'
        .get('/private-null/download')
        .reply 200, """
          ---
          private: null
          ---
          # This is a test
          """
        .get('/private-missing')
        .reply 200, '<title>This is a test</title>'
        .get('/private-missing/download')
        .reply 200, """
          ---
          ---
          # This is a test
          """

    context 'private flag is set true', (done) ->
      link = 'https://hackmd.io/private-true'
      beforeEach (done) ->
        room.user.say 'alice', "hubot archive #{link}"
        setTimeout done, 100

      it 'should not create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include negative_response

    context 'private flag is set false', (done) ->
      link = 'https://hackmd.io/private-false'
      beforeEach (done) ->
        room.user.say 'alice', "hubot archive #{link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is set null', (done) ->
      link = 'https://hackmd.io/private-null'
      beforeEach (done) ->
        room.user.say 'alice', "hubot archive #{link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is missing', (done) ->
      link = 'https://hackmd.io/private-missing'
      beforeEach (done) ->
        room.user.say 'alice', "hubot archive #{link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response
