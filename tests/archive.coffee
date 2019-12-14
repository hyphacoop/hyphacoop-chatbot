Helper = require('hubot-test-helper')
expect = require('chai').expect
nock = require('nock')

archive_repo =
  user: 'myorg'
  name: 'myrepo'
  slug: 'myorg/myrepo'
  default_branch:
    name: 'master'
    sha: '1234567890abcdef'

generate_github_mock = (repo, title_slug) ->
  nock('https://api.github.com')
    .persist()
    .get("/repos/#{repo.slug}")
    .reply 200, {default_branch: repo.default_branch.name, owner: {login: repo.user}}
    .get("/repos/#{repo.slug}/branches/#{repo.default_branch.name}")
    .reply 200, {commit: {sha: repo.default_branch.sha}}
    .post("/repos/#{repo.slug}/git/refs")
    .reply 201, {}
    .put("/repos/#{repo.slug}/contents/#{title_slug}.md")
    .reply 201, {}
    .post("/repos/#{repo.slug}/pulls")
    .reply 201, {html_url: "https://github.com/#{repo.slug}/pull/123"}

process.env.HUBOT_ARCHIVE_REPO = archive_repo.slug

# helper loads a specific script if it's a file
helper = new Helper('./../scripts/archive.coffee')

describe 'archive', ->
  room = null

  before ->
    do nock.disableNetConnect
    generate_github_mock(archive_repo, 'this-is-a-test')

  after ->
    nock.cleanAll()

  beforeEach ->
    room = helper.createRoom(httpd: false)

  afterEach ->
    room.destroy()

  affirmative_response = """
    Yay! Archiving in progress!
    Waiting for public review at https://github.com/#{archive_repo.slug}/pull/123
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

  context 'archiving notes with various titles', (done) ->
    context 'simple title', (done) ->
      title = 'This is a test'
      title_slug = 'this-is-a-test'
      link = 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
      beforeEach (done) ->
        nock('https://hackmd.io')
          .get('/xxxxxxxxxxxxxxxxxxxxxx/download')
          .reply 200, "# #{title}"
          .get('/xxxxxxxxxxxxxxxxxxxxxx')
          .reply 200, "<title>#{title}</title>"
        generate_github_mock(archive_repo, title_slug)

        room.user.say 'alice', "hubot archive #{link}"
        setTimeout done, 100

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
