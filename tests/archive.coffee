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

DEFAULT_PAD_DATA =
  link: 'https://hackmd.io/xxxxxxxxxxxxxxxxxxxxxx'
  title: 'This is a test - HackMD'
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

  beforeEach ->
    generate_github_mock(archive_repo, DEFAULT_PAD_DATA.title_slug)
    room = helper.createRoom(httpd: false)

  afterEach ->
    room.destroy()
    nock.cleanAll()

  affirmative_response = """
    Yay! Archiving in progress!
    Waiting for public review at https://github.com/#{archive_repo.slug}/pull/123
    """
  negative_response = "Sorry, no can do: document is marked 'private'"

  context 'user archives dynamic hackmd split link', (done) ->
    beforeEach (done) ->
      generate_hackmd_mock(DEFAULT_PAD_DATA)
      room.user.say 'alice', "hubot archive #{DEFAULT_PAD_DATA.link}"
      setTimeout done, 100

    it 'should create pull request', ->
      hubot_reply = room.messages[1][1]
      expect(hubot_reply).to.include affirmative_response

  context 'archiving notes with various titles', (done) ->
    beforeEach ->
      this.pad_data = Object.assign {}, DEFAULT_PAD_DATA

    context 'simple title', (done) ->

      beforeEach (done) ->
        this.pad_data.title = "Testing - HackMD"
        this.pad_data.title_slug = 'testing'

        generate_hackmd_mock(this.pad_data)
        generate_github_mock(archive_repo, this.pad_data.title_slug)

        room.user.say 'alice', "hubot archive #{DEFAULT_PAD_DATA.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'hypha-specific title filtering', (done) ->

      beforeEach (done) ->
        this.pad_data.title = "2019-01-01 Hypha Worker Co-op: Test Meeting - HackMD"
        this.pad_data.title_slug = '2019-01-01-test-meeting'

        generate_hackmd_mock(this.pad_data)
        generate_github_mock(archive_repo, this.pad_data.title_slug)

        room.user.say 'alice', "hubot archive #{DEFAULT_PAD_DATA.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'non-standard word separators', (done) ->

      beforeEach (done) ->
        this.pad_data.title = "Test Title/Heading with plus+signs - HackMD"
        this.pad_data.title_slug = 'test-title-heading-with-plus-signs'

        generate_hackmd_mock(this.pad_data)
        generate_github_mock(archive_repo, this.pad_data.title_slug)

        room.user.say 'alice', "hubot archive #{DEFAULT_PAD_DATA.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'ampersand in title', (done) ->

      beforeEach (done) ->
        this.pad_data.title = "Test Title & Ampersands - HackMD"
        this.pad_data.title_slug = 'test-title-ampersands'

        generate_hackmd_mock(this.pad_data)
        generate_github_mock(archive_repo, this.pad_data.title_slug)

        room.user.say 'alice', "hubot archive #{DEFAULT_PAD_DATA.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

  context 'archiving private notes', (done) ->
    beforeEach ->
      this.pad_data = Object.assign {}, DEFAULT_PAD_DATA

    context 'private flag is set true', (done) ->
      beforeEach (done) ->
        this.pad_data.frontmatter = 'private: true'

        generate_hackmd_mock(this.pad_data)
        room.user.say 'alice', "hubot archive #{this.pad_data.link}"
        setTimeout done, 100

      it 'should not create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include negative_response

    context 'private flag is set false', (done) ->
      beforeEach (done) ->
        this.pad_data.frontmatter = 'private: false'

        generate_hackmd_mock(this.pad_data)
        room.user.say 'alice', "hubot archive #{this.pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is set null', (done) ->

      beforeEach (done) ->
        this.pad_data.frontmatter = 'private: null'

        generate_hackmd_mock(this.pad_data)
        room.user.say 'alice', "hubot archive #{this.pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response

    context 'private flag is missing', (done) ->
      beforeEach (done) ->
        this.pad_data.frontmatter = ''

        generate_hackmd_mock(this.pad_data)
        room.user.say 'alice', "hubot archive #{this.pad_data.link}"
        setTimeout done, 100

      it 'should create pull request', ->
        hubot_reply = room.messages[1][1]
        expect(hubot_reply).to.include affirmative_response
