# Description
#   Archives notes in Hypha's organizing GitHub repo.
#
# Configuration:
#   HUBOT_GITHUB_ACCESS_TOKEN
#   HUBOT_ARCHIVE_REPO
#
# Commands:
#   hubot archive <hackmd url> - Creates a pull request from the notes
#
# Dependencies:
#   node-html-parser
#   octonode
#
# Notes:
#   None
#
# Author:
#   patcon@github

github = require 'octonode'
Url = require 'url'
HtmlParser = require 'node-html-parser'

config =
  github_token: process.env.HUBOT_GITHUB_ACCESS_TOKEN
  archive_repo: process.env.HUBOT_ARCHIVE_REPO

client = github.client(config.github_token)

module.exports = (robot) ->
  robot.respond /archive (.+)/i, (msg) ->
    html_url = msg.match[1]

    fetchTitle = (html_url) ->
      robot.http(html_url)
        .get() (err, res, body) ->
            if err
              robot.logger.error "Encountered an error :( #{err}"
              return null

            root = HtmlParser.parse body
            title = root.querySelector('title').innerHTML
            title = title.replace ' - HackMD', ''
            title_re = RegExp ' (Hypha|Toronto)(( Workers?)? Co-op(erative)?)?:', 'i'
            title = title.replace title_re, ''
            title = sluggify title

            room = msg.message.room
            user = msg.message.user.name
            pr_title = "Archive #{title}.md"
            pr_body = ''
            pr_body += "This pull request was created automatically by the "
            pr_body += "[`archive` command of our chatbot](https://github.com/patcon/hyphacoop-chatbot/tree/master/README.md#archive),"
            pr_body += " kicked off by user `#{user}` in `#{room}`."
            msg.send pr_title
            msg.send pr_body

    title = fetchTitle html_url

    markdown_url = getMarkdownUrl(html_url)

    robot.http(markdown_url)
      .get() (err, res, body) ->
        if err
          robot.logger.error "Encountered an error :( #{err}"
          return

        mkdn_content = body

        ghrepo = client.repo config.archive_repo
        filename = 'sample-file.md'
        ghrepo.info (err, payload, header) ->
          if err
            robot.logger.error "Encountered an error getting repo info :( #{err}"
            return

          repo = payload
          ghrepo.branch repo.default_branch, (err, payload, header) ->
            head_commit = payload.commit.sha
            pr_branch = 'new-branch'
            ghrepo.createReference pr_branch, head_commit, (err, payload, header) ->
              if err
                robot.logger.error "Encountered an error creating reference :( #{err}"
                msg.send "Seems there's already a branch created for these notes."
                return

              ghrepo.createContents filename, "Created #{filename}", mkdn_content, pr_branch, (err, payload, header) ->
                if err
                  msg.send "Could not create file #{filename}"
                  robot.logger.error "Encountered an error creating file :( #{err}"
                  return

                ghrepo.pr {title: "Archive #{filename}", body: 'Some message', head: "#{repo.owner.login}:#{pr_branch}", base: repo.default_branch}, (err, payload, header) ->
                  if err
                    msg.send "Could not create pull request for #{filename}"
                    robot.logger.error "Encountered an error creating file :( #{err}"
                    return

                  msg.send "Pull request created for archiving file #{filename}"

getMarkdownUrl = (html_url) ->
  url = ''
  url_data = Url.parse html_url
  if url_data.hostname == 'hackmd.io'
    url = html_url + '/download'
    return url

  return null

sluggify = (string) ->
  string = string.replace ':', ''
  string = string.replace RegExp(' ', 'g'), '-'
  string = string.toLowerCase()
  return string
