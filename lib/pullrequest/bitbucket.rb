require 'json'
require 'thor'

module Pullrequest
  class Bitbucket
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def command
      data # ask these questions first
      [
        "curl",
        "-X POST",
        "-H 'Content-Type: application/json'",
        "-u #{username}:#{password}",
        "https://bitbucket.org/api/2.0/repositories/#{dest_repo}/pullrequests",
        "-d '#{data.to_json}'",
      ].join(' ')
    end

    private

    def ask(*args)
      context.ask *args
    end

    def current_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    def current_repo
      `git remote -v`[/bitbucket.org\:([^\.]+)\.git/, 1]
    end

    def data
      @data ||= {
        title: ask("Title of pull request", required: true),
        description: ask("Description of pull request"),
        source: {
          repository: {full_name: source_repo},
          branch: {name: source_branch},
        },
        destination: {
          repository: {full_name: dest_repo},
          branch: {name: dest_branch},
        },
        reviewers: reviewer_usernames.map { |username| {username: username} },
        close_source_branch: true,
      }
    end

    def dest_branch
      ask("Destination branch", default: 'master', required: true)
    end

    def dest_repo
      ask("Destination Bitbucket repo (account_name/report_name)", default: current_repo, required: true)
    end

    def password
      ask("Your Bitbucket password", echo: false, required: true).tap do
        $stdout.puts # force newline
      end
    end

    def source_branch
      ask("Source branch (your local branch)", default: current_branch, required: true)
    end

    def source_repo
      current_repo
    end

    def reviewer_usernames
      ask("Reviewers (enter comma-separated usernames)", default: "<none>").split(',').map(&:strip).reject { |u| u == '' }
    end

    def username
      ask "Your Bitbucket username", required: true
    end
  end
end
