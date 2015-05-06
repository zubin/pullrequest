require 'fileutils'
require 'json'
require 'thor'
require 'yaml'

module Pullrequest
  class Bitbucket
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def command
      @command ||= generate_command
    end

    def review
      @data = nil
      @command = nil
    end

    private

    def ask(question, options = {})
      cache_key = question.dup
      if cached_answers[cache_key]
        options.merge! default: cached_answers[cache_key]
      end
      context.ask(question, options).tap do |answer|
        cached_answers[cache_key] = answer
      end
    end

    def cached_answers
      @cached_answers ||= {}
    end

    def current_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    def current_repo
      `git remote -v`[/bitbucket.org\:([^\.]+)\.git/, 1]
    end

    def data
      @data ||= {
        title: title,
        description: description,
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

    def description
      ask("Description of pull request")
    end

    def dest_branch
      ask("Destination branch", default: 'master', required: true)
    end

    def dest_repo
      ask("Destination Bitbucket repo (account_name/report_name)", default: current_repo, required: true)
    end

    def generate_command
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

    def password
      return stored_credentials[:password] if stored_credentials?
      ask("Your Bitbucket password", echo: false, required: true).tap do |password|
        $stdout.puts # force newline
        if yes? "Store credentials for next time? (in #{stored_credentials_path})"
          @password = password
          write_credentials
        end
      end
    end

    def source_branch
      ask("Source branch (your local branch)", default: current_branch, required: true)
    end

    def source_repo
      current_repo
    end

    def stored_credentials
      return {} unless File.exists?(stored_credentials_path)
      @stored_credentials ||= YAML.load(File.read(stored_credentials_path))
    end

    def stored_credentials?
      stored_credentials.key?(:username) && stored_credentials.key?(:password)
    end

    def stored_credentials_path
      File.join(Dir.home, '.config/pullrequest/bitbucket.yml')
    end

    def title
      ask("Title of pull request", required: true)
    end

    def reviewer_usernames
      ask("Reviewers (enter comma-separated usernames)", default: "<none>").split(',').map(&:strip).reject { |u| u == '' }
    end

    def username
      return stored_credentials[:username] if stored_credentials?
      @username = ask("Your Bitbucket username", required: true)
    end

    def write_credentials
      FileUtils.mkdir_p(File.dirname(stored_credentials_path))
      File.open(stored_credentials_path, 'w', 0600) do |f|
        f.write({username: @username, password: @password}.to_yaml)
      end
    end

    def yes?(*args)
      context.yes? *args
    end
  end
end
