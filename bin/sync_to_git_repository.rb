#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'
require 'rugged'
require 'metadata/saml'

class SyncToGitRepository
  include Metadata::SAMLNamespaces

  def initialize(args)
    if args.length != 1
      warn("usage: #{$PROGRAM_NAME} /path/to/config/file")
      exit 1
    end

    @config = YAML.load_file(args[0])
    @md_instance = MetadataInstance[identifier: @config['instance_identifier']]
    @repository = Rugged::Repository.new(@config['repository_path'])
    @committed = false
  end

  def perform
    known_entities = KnownEntity.with_all_tags([@md_instance.primary_tag])
    touched = known_entities.map { |ke| sync(ke) }
    sweep(touched)
    push if @committed
  end

  private

  def credential
    git_auth_conf = @config['git_auth']
    git_auth_type = git_auth_conf['type'] if git_auth_conf
    if git_auth_type == 'sshkey'
      Rugged::Credentials::SshKey.new(username: git_auth_conf['username'],
                                      publickey: git_auth_conf['publickey'],
                                      privatekey: git_auth_conf['privatekey'])
    elsif git_auth_type == 'userpassword'
      Rugged::Credentials::UserPassword.new(username: git_auth_conf['username'],
                                            password: git_auth_conf['password'])
    end
  end

  def find_branch
    @repository.branches.find do |b|
      b.canonical_name == @repository.head.canonical_name
    end
  end

  def push
    branch = find_branch
    remote = @repository.config["branch.#{branch.name}.remote"]
    merge = @repository.config["branch.#{branch.name}.merge"]

    @repository.push(remote, "#{branch.canonical_name}:#{merge}",
                     credentials: credential)
  end

  def sync(ke)
    return if ke.entity_id.nil?

    encoded_entity_id = Base64.urlsafe_encode64(ke.entity_id).delete('=')
    filename = "entities/#{@md_instance.identifier}-#{encoded_entity_id}.xml"

    write_metadata(ke, filename, generate_metadata(ke))

    filename
  end

  def sweep(touched)
    prefix = "entities/#{@md_instance.identifier}-"

    all = @repository.index.map { |e| e[:path] }
                     .select { |p| p.start_with?(prefix) }

    (all - touched).each { |path| remove_stale(path) }
  end

  def write_metadata(ke, filename, xml)
    full_path = File.join(@repository.workdir, filename)
    File.open(full_path, 'w') { |f| f.write(xml) }

    return if @repository.status(filename).empty?

    commit_changes("[sync] #{ke.entity_id}") do |index|
      object_id = @repository.write(xml, :blob)
      index.add(path: filename, oid: object_id, mode: 0o100644)
    end
  end

  def generate_metadata(ke)
    renderer = Metadata::SAML.new(metadata_instance: @md_instance)

    if ke.entity_descriptor.try(:functioning?)
      renderer.entity_descriptor(ke.entity_descriptor, NAMESPACES)
    elsif ke.raw_entity_descriptor.try(:functioning?)
      renderer.raw_entity_descriptor(ke.raw_entity_descriptor, NAMESPACES,
                                     @config['raw_entity_descriptor_root_node'])
    end

    doc = renderer.builder.doc
    doc.to_xml(indent: 2)
  end

  def remove_stale(path)
    full_path = File.join(@repository.workdir, path)
    FileUtils.rm_f(full_path)

    commit_changes('[sync] remove stale entity') do |index|
      index.remove(path)
    end
  end

  def commit_changes(message)
    index = @repository.index
    index.read_tree(@repository.head.target.tree)

    yield index

    index.write

    tree = index.write_tree(@repository)
    commit(tree, message)
  end

  def commit(tree, message)
    author = { name: @config['git_author_name'], time: Time.now.getlocal,
               email: @config['git_author_email'] }

    Rugged::Commit.create(@repository,
                          tree: tree, message: message,
                          author: author, committer: author,
                          parents: [@repository.head.target],
                          update_ref: 'HEAD')

    @committed = true
  end
end

SyncToGitRepository.new(ARGV).perform if $PROGRAM_NAME == __FILE__
