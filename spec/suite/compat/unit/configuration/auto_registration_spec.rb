# frozen_string_literal: true

require "rom/compat"

RSpec.describe ROM::Configuration, "#auto_registration" do
  subject(:configuration) do
    ROM::Configuration.new
  end

  let!(:loaded_features) { $LOADED_FEATURES.dup }

  # RUBY RUBY RUBY LALALA
  around do |example|
    class Object
      def config
        ROM.config
      end
      def components
        []
      end
    end

    example.run

    class Object
      undef :config
      undef :components
    end
  end

  after do
    %i[Persistence Users CreateUser UserList My XMLSpace].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end

    $LOADED_FEATURES.replace(loaded_features)
  end

  context "with default component_dirs" do
    context "with namespace turned on" do
      before do
        configuration.auto_registration(SPEC_ROOT.join("suite/compat/fixtures/lib/persistence").to_s)
      end

      describe "#relations" do
        it "loads files and returns constants" do
          expect(configuration.relation_classes).to eql([Persistence::Relations::Users])
        end
      end

      describe "#commands" do
        it "loads files and returns constants" do
          expect(configuration.command_classes).to eql([Persistence::Commands::CreateUser])
        end
      end

      describe "#mappers" do
        it "loads files and returns constants" do
          expect(configuration.mapper_classes).to eql([Persistence::Mappers::UserList])
        end
      end
    end

    context "with namespace turned off" do
      before do
        configuration.auto_registration(SPEC_ROOT.join("suite/compat/fixtures/app"), namespace: false)
      end

      describe "#relations" do
        it "loads files and returns constants" do
          expect(configuration.relation_classes).to eql([Users])
        end
      end

      describe "#commands" do
        it "loads files and returns constants" do
          expect(configuration.command_classes).to eql([CreateUser])
        end
      end

      describe "#mappers" do
        it "loads files and returns constants" do
          expect(configuration.mapper_classes).to eql([UserList])
        end
      end
    end
  end

  context "with custom component_dirs" do
    context "with namespace turned on" do
      before do
        configuration.auto_registration(
          SPEC_ROOT.join("suite/compat/fixtures/lib/persistence").to_s,
          component_dirs: {
            relations: :my_relations,
            mappers: :my_mappers,
            commands: :my_commands
          }
        )
      end

      describe "#relations" do
        it "loads files and returns constants" do
          expect(configuration.relation_classes).to eql([Persistence::MyRelations::Users])
        end
      end

      describe "#commands" do
        it "loads files and returns constants" do
          expect(configuration.command_classes).to eql([Persistence::MyCommands::CreateUser])
        end
      end

      describe "#mappers" do
        it "loads files and returns constants" do
          expect(configuration.mapper_classes).to eql([Persistence::MyMappers::UserList])
        end
      end
    end

    context "with namespace turned off" do
      before do
        configuration.auto_registration(
          SPEC_ROOT.join("suite/compat/fixtures/app"),
          component_dirs: {
            relations: :my_relations,
            mappers: :my_mappers,
            commands: :my_commands
          },
          namespace: false
        )
      end

      describe "#relations" do
        it "loads files and returns constants" do
          expect(configuration.relation_classes).to eql([Users])
        end
      end

      describe "#commands" do
        it "loads files and returns constants" do
          expect(configuration.command_classes).to eql([CreateUser])
        end
      end

      describe "#mappers" do
        it "loads files and returns constants" do
          expect(configuration.mapper_classes).to eql([UserList])
        end
      end
    end

    describe "custom namespace" do
      context "when namespace has subnamespace" do
        before do
          configuration.auto_registration(
            SPEC_ROOT.join("suite/compat/fixtures/custom_namespace"),
            component_dirs: {
              relations: :relations,
              mappers: :mappers,
              commands: :commands
            },
            namespace: "My::Namespace"
          )
        end

        describe "#relations" do
          it "loads files and returns constants" do
            expect(configuration.relation_classes).to eql([My::Namespace::Relations::Customers])
          end
        end

        describe "#commands" do
          it "loads files and returns constants" do
            expect(configuration.command_classes).to eql([My::Namespace::Commands::CreateCustomer])
          end
        end

        describe "#mappers" do
          it "loads files and returns constants" do
            expect(configuration.mapper_classes).to eql([My::Namespace::Mappers::CustomerList])
          end
        end

        context "with possibly clashing namespace" do
          before do
            module My
              module Namespace
                module Customers
                end
              end
            end
          end

          it "starts with the deepest constant" do
            expect(configuration.relation_classes).to eql([My::Namespace::Relations::Customers])
          end
        end
      end

      context "when namespace has wrong subnamespace" do
        subject(:registration) do
          configuration.auto_registration(
            SPEC_ROOT.join("suite/compat/fixtures/wrong"),
            component_dirs: {
              relations: :relations,
              mappers: :mappers,
              commands: :commands
            },
            namespace: "My::NewNamespace"
          )
        end

        describe "#relations" do
          specify { expect { registration }.to raise_exception NameError }
        end

        describe "#commands" do
          specify { expect { registration }.to raise_exception NameError }
        end

        describe "#mappers" do
          specify { expect { registration }.to raise_exception NameError }
        end
      end

      context "when namespace does not implement subnamespace" do
        before do
          configuration.auto_registration(
            SPEC_ROOT.join("suite/compat/fixtures/custom"),
            component_dirs: {
              relations: :relations,
              mappers: :mappers,
              commands: :commands
            },
            namespace: "My::Namespace"
          )
        end

        describe "#relations" do
          # FIXME: this is flaky
          xit "loads files and returns constants" do
            expect(configuration.relation_classes).to eql([My::Namespace::Users])
          end
        end

        describe "#commands" do
          # FIXME: this is flaky
          xit "loads files and returns constants" do
            expect(configuration.command_classes).to eql([My::Namespace::CreateUser])
          end
        end

        describe "#mappers" do
          # FIXME: this is flaky
          xit "loads files and returns constants" do
            expect(configuration.mapper_classes).to eql([My::Namespace::UserList])
          end
        end
      end

      context "when custom inflector" do
        let(:inflector) do
          Dry::Inflector.new do |i|
            i.acronym("XML")
          end
        end

        before do
          configuration.inflector = inflector
          configuration.auto_registration(
            SPEC_ROOT.join("suite/compat/fixtures/xml_space"),
            component_dirs: {
              relations: :xml_relations,
              mappers: :xml_mappers,
              commands: :xml_commands
            }
          )
        end

        describe "#relations" do
          it "loads files and returns constants" do
            expect(configuration.relation_classes).to eql([XMLSpace::XMLRelations::Customers])
          end
        end

        describe "#commands" do
          it "loads files and returns constants" do
            expect(configuration.command_classes).to eql([XMLSpace::XMLCommands::CreateCustomer])
          end
        end

        describe "#mappers" do
          it "loads files and returns constants" do
            expect(configuration.mapper_classes).to eql([XMLSpace::XMLMappers::CustomerList])
          end
        end
      end
    end
  end
end
