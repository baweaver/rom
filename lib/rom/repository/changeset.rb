require 'dry/core/class_attributes'
require 'dry/core/cache'

require 'rom/initializer'

module ROM
  # Abstract Changeset class
  #
  # If you inherit from this class you need to configure additional settings
  #
  # @example define a custom changeset using :upsert command
  #
  #   class NewTag < ROM::Changeset[:tags]
  #     def default_command_type
  #       :upsert
  #     end
  #   end
  #
  # @abstract
  class Changeset
    extend Initializer
    extend Dry::Core::Cache
    extend Dry::Core::ClassAttributes

    # @!method self.relation
    #   Get or set changeset relation identifier
    #
    #   @overload relation
    #     Return configured relation identifier for this changeset
    #     @return [Symbol]
    #
    #   @overload relation(identifier)
    #     Set relation identifier for this changeset
    #     @param [Symbol] identifier The relation identifier from the ROM container
    #     @return [Symbol]
    defines :relation

    # @!attribute [r] relation
    #   @return [Relation] The changeset relation
    param :relation

    # @!attribute [r] command_compiler
    #   @return [Proc] a proc that can compile a command (typically provided by a repo)
    option :command_compiler, reader: true, optional: true

    # @!attribute [r] command_type
    #   @return [Symbol] a custom command identifier
    option :command_type, reader: true, optional: true, default: -> changeset { changeset.default_command_type }

    # Create a changeset class preconfigured for a specific relation
    #
    # @example
    #   class NewUserChangeset < ROM::Changeset::Create[:users]
    #   end
    #
    #   user_repo.changeset(NewUserChangeset).data(name: 'Jane')
    #
    # @api public
    def self.[](relation_name)
      fetch_or_store([relation_name, self]) {
        Class.new(self) { relation(relation_name) }
      }
    end

    # Return a new changeset with updated options
    #
    # @example
    #   class NewUser < ROM::Changeset::Create[:users]
    #     option :token_generator, reader: true
    #   end
    #
    #   changeset = user_repo.changeset(NewUser).with(token_generator: my_token_gen)
    #
    # @param [Hash] new_options The new options
    #
    # @return [Changeset]
    #
    # @api public
    def with(new_options)
      self.class.new(relation, options.merge(new_options))
    end

    # Persist changeset
    #
    # @example
    #   changeset = user_repo.changeset(name: 'Jane')
    #   changeset.commit
    #   # => { id: 1, name: 'Jane' }
    #
    # @return [Hash, Array]
    #
    # @api public
    def commit
      command.call
    end

    # Return command result type
    #
    # @return [Symbol]
    #
    # @api private
    def result
      __data__.is_a?(Hash) ? :one : :many
    end

    # Return string representation of the changeset
    #
    # @return [String]
    #
    # @api public
    def inspect
      %(#<#{self.class} relation=#{relation.name.inspect}>)
    end
  end
end

require 'rom/repository/changeset/stateful'
require 'rom/repository/changeset/create'
require 'rom/repository/changeset/update'
require 'rom/repository/changeset/delete'
