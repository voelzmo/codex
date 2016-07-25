## Gitbook Usage

Yo dawg, I heard you like documentation that tells you how to make documentation.
So we wrote a doc to explain how we doc, so you can doc, while you doc.

Anyway...

We will show you how to use Gitbook for documentation.

### What is Gitbook?

GitBook is an online platform for writing and hosting documentation. On the other hand, gitbook is a publishing platform that, once a repository is configured and conforms to the configuration, the files in the repository can be rendered through a build pipeline that outputs to a number of destinations.

Destinations like:

- A static website that is searchable and displays a TOC.
- Downloadable PDF, ePub and MOBI formats for eBOOK and computer reading anywhere.

In codex project, we use github to host the repository, use Gitbook to publish different formats of codex book. You can go to [codex Gitbook][codex-gitbook] to read codex book, click **READ** in the blue box on the right, or download different formats of codex book.

### How to update Gitbook for codex?

It is pretty easy to update Gitbook for codex. You can just make your changes, commit and push to the master branch of codex repository, the changes will be automaticlly built by Gitbook pipeline. Once the building completed, you can see the changes in all the formats of codex Gitbook.

Note: When we make changes to the headings in markdown doc, the table of content is not updated until you make correspoding changes in `TOC.md`. 

### Accounts Setting and Login

We created two accounts.  A GitHub account `snw-gitbook` and a Gitbook account `starkandwayne`.  Both are in the Stark & Wayne 1Password vault in Dropbox.

If you’re already signed into Gitbook with another account, sign out. Then go
to https://www.gitbook.com/ and click on SIGN IN. Type in the username: `starkandwayne` and put in the password from 1Password. 

To set a source repository for codex Gitbook, we need to configure a Github account. Here we  use our `snw-gitbook` Github account for the purpose.

### Collaborators

When signed in to Gitbook, and you know the username or email address to add
someone, use the collaborator link to add users.

[codex-gitbook]:   https://www.gitbook.com/book/starkandwayne/codex/details
