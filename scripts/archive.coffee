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
          slug = sluggify title
          filename = "#{slug}.md"

          room = msg.message.room
          user = msg.message.user.name
          pr_title = "Archive #{filename}"
          pr_body = ''
          pr_body += "This pull request was created automatically by the "
          pr_body += "[`archive` command of our chatbot](https://github.com/patcon/hyphacoop-chatbot/tree/master/README.md#archive),"
          pr_body += " kicked off by user `#{user}` in `#{room}`."

          markdown_url = getMarkdownUrl(html_url)

          robot.http(markdown_url)
            .get() (err, res, body) ->
              if err
                robot.logger.error "Encountered an error :( #{err}"
                return

              mkdn_content = body
              # Convert tabs to 4 spaces
              mkdn_content = mkdn_content.replace /\t/g, '    '

              ghrepo = client.repo config.archive_repo
              ghrepo.info (err, payload, header) ->
                if err
                  robot.logger.error "Encountered an error getting repo info :( #{err}"
                  return

                repo = payload
                ghrepo.branch repo.default_branch, (err, payload, header) ->
                  head_commit = payload.commit.sha
                  pr_branch = slug
                  ghrepo.createReference pr_branch, head_commit, (err, payload, header) ->
                    if err
                      robot.logger.error "Encountered an error creating reference :( #{err}"
                      msg.send "Seems there's already a branch created for these notes.\nSee: https://github.com/#{config.archive_repo}/pull/\n(Delete branch to start fresh.)"
                      return

                    ghrepo.createContents filename, "Created #{filename}", mkdn_content, pr_branch, (err, payload, header) ->
                      if err
                        msg.send "Could not create file #{filename}"
                        robot.logger.error "Encountered an error creating file :( #{err}"
                        return

                      pr_data =
                        title: pr_title
                        body: pr_body
                        head: "#{repo.owner.login}:#{pr_branch}"
                        base: repo.default_branch

                      ghrepo.pr pr_data, (err, payload, header) ->
                        if err
                          msg.send "Could not create pull request for #{filename}"
                          robot.logger.error "Encountered an error creating file :( #{err}"
                          return

                        msg.send "Yay! Archiving in progress!\nWaiting for public review at #{payload.html_url}"

getMarkdownUrl = (html_url) ->
  url = Url.parse html_url
  if url.hostname == 'hackmd.io'
    return "#{url.protocol}//#{url.host}#{url.pathname}/download"

  return null

sluggify = (string) ->
  # Remove all except alphanumeric, spaces, and hyphens.
  string = string.replace /[^a-z0-9\ \-]/gi, ''
  # Convert 1+ consecutive spaces to a single hyphen.
  string = string.replace /[ ]+/g, '-'
  string = string.toLowerCase()
  return string
