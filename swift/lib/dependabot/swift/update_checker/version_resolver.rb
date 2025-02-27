# frozen_string_literal: true

require "dependabot/update_checkers/base"
require "dependabot/swift/file_parser/dependency_parser"
require "dependabot/swift/file_updater/lockfile_updater"

module Dependabot
  module Swift
    class UpdateChecker < Dependabot::UpdateCheckers::Base
      class VersionResolver
        def initialize(dependency:, manifest:, repo_contents_path:, credentials:)
          @dependency         = dependency
          @manifest           = manifest
          @credentials        = credentials
          @repo_contents_path = repo_contents_path
        end

        def latest_resolvable_version
          @latest_resolvable_version ||= fetch_latest_resolvable_version
        end

        private

        def fetch_latest_resolvable_version
          updated_lockfile_content = FileUpdater::LockfileUpdater.new(
            dependencies: [dependency],
            manifest: manifest,
            repo_contents_path: repo_contents_path,
            credentials: credentials
          ).updated_lockfile_content

          lockfile = DependencyFile.new(
            name: "Package.resolved",
            content: updated_lockfile_content
          )

          dependency_parser(manifest, lockfile).parse.find do |parsed_dep|
            parsed_dep.name == dependency.name
          end.version
        end

        def dependency_parser(manifest, lockfile)
          FileParser::DependencyParser.new(
            dependency_files: [manifest, lockfile],
            repo_contents_path: repo_contents_path,
            credentials: credentials
          )
        end

        attr_reader :dependency, :manifest, :repo_contents_path, :credentials
      end
    end
  end
end
