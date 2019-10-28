# Hypha Co-op Chatbot: Roobot

> **Note:** For now, we're pretending the name of the chatbot is
> `roobot`, but that is up for debate. Consider it a placeholder.

Roobot is a friendly helper robot that lives in Hypha's chat rooms. It
helps us carry out routine tasks that we teach it to perform.

## Commands

The following commands can be run in chat via messages that address the
chatbot.

### `archive`

This command is used for archiving HackMD documentings in GitHub repos.

```
henry: hey all, how do we archive our public meetings now?
maria: @roobot archive https://hackmd.io/ERa1OsfKRranY-2sM1BcNQ
roboot: Yay! Archiving in progress!
        Waiting for public review at https://github.com/hyphacoop/organizing/pull/123
```

**Notice:** For here on, these features of the `archive` command are
_not yet implemented_.

It can even be used to archiving private meetings, with `private:
true` in the YAML front-matter.

```
henry: what about when we have a private meeting like that last one?
maria: @roobot archive https://hackmd.io/uogV1UljQT633Vi6FfLK6g
roboot: Great! Archiving in progress!
roobot: Awaiting private review at https://gitlab.com/patcon/archive-demo-private/merge_requests/1
```

But what about when your meeting has public and private content? No
problem! You can just add a :lock: `:lock:` icon to each line in
question, and any content with a strikethrough on that line will be
censored from the public copy, and a full private backup will be created as
well.

```
henry: what about this meeting with sensitive parts?
maria: @roobot archive https://hackmd.io/RN8nBcqtS_CdcLycfD6cXQ
roboot: Great! Archiving in progress!
roobot: Awaiting public review at https://github.com/patcon/archive-demo/pull/2
roobot: Awaiting private review at https://gitlab.com/patcon/archive-demo-private/merge_requests/2
```
