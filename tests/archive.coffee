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

default_pad_data =
  link: 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
  title: 'This is a test'
  title_slug: 'this-is-a-test'
  frontmatter: ''

generate_hackmd_mock = (data) ->
  content_html = "<title>#{data.title}<title>"
  content_md = """
    ---
    #{data.frontmatter}
    ---
    # #{data.title}
    """
  nock('https://hackmd.io')
    .get('/xxxxxxxxxxxxxxxxxxxxxx')
    .reply 200, content_html
    .get('/xxxxxxxxxxxxxxxxxxxxxx/download')
    .reply 200, content_md

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
    beforeEach (done) ->
      generate_hackmd_mock(default_pad_data)
      room.user.say 'alice', "hubot archive #{default_pad_data.link}"
      setTimeout done, 100

    it 'should create pull request', ->
      hubot_reply = room.messages[1][1]
      expect(hubot_reply).to.include affirmative_response

  context 'archiving notes with various titles', (done) ->
    context 'simple title', (done) ->

      beforeEach (done) ->
        generate_hackmd_mock(default_pad_data)
        generate_github_mock(archive_repo, title_slug)

        room.user.say 'alice', "hubot archive #{default_pad_data.link}"
        setTimeout done, 100

  context 'archiving private notes', (done) ->

    context 'private flag is set true', (done) ->
      pad_data = Object.assign {}, default_pad_data
      pad_data.frontmatter = 'private: true'

      beforeEach (done) ->
        generate_hackmd_mock(pad_data)
        room.user.say 'alice', "hubot archive #{pad_data.link}"
        setTimeout done, 100

      it 'should not create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include negative_response

    context 'private flag is set false', (done) ->
      pad_data = Object.assign {}, default_pad_data
      pad_data.frontmatter = 'private: false'

      beforeEach (done) ->
        generate_hackmd_mock(pad_data)
        room.user.say 'alice', "hubot archive #{pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is set null', (done) ->
      pad_data = Object.assign {}, default_pad_data
      pad_data.frontmatter = 'private: null'

      beforeEach (done) ->
        generate_hackmd_mock(pad_data)
        room.user.say 'alice', "hubot archive #{pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is missing', (done) ->
      pad_data = Object.assign {}, default_pad_data
      pad_data.frontmatter = ''

      beforeEach (done) ->
        generate_hackmd_mock(pad_data)
        room.user.say 'alice', "hubot archive #{pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response
