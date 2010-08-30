require 'rspec/core'

module Saki
  module AcceptanceHelpers
    extend ActiveSupport::Concern

    def default_factory(name)
      Factory name
    end

    def get_path(path)
      if path.is_a? String
        path
      elsif path.is_a? Symbol
        send path
      else
        path.call(self)
      end
    end

    def add_opts(link, opts)
      if opts[:parent]
        link = "/#{opts[:parent].class.to_s.tableize}/#{opts[:parent].id}" + link
      end
      if opts[:format]
        link = link + ".#{opts[:format]}"
      end
      link
    end

    def has_link(href)
      page.should have_xpath("//a[@href='#{href}']")
    end

    def has_link_for(model, opts = {})
      href = add_opts "/#{model.class.to_s.tableize}/#{model.id}", opts
      page.should have_xpath("//a[@href='#{href}' and not(@rel)]")
    end

    def has_link_for_editing(model, opts = {})
      href = add_opts "/#{model.class.to_s.tableize}/#{model.id}/edit", opts
      has_link href
    end

    def has_link_for_deleting(model, opts = {})
      href = add_opts "/#{model.class.to_s.tableize}/#{model.id}", opts
      page.should have_xpath("//a[@href='#{href}' and @data-method='delete']")
    end

    def has_link_for_creating(model_type, opts = {})
      href = add_opts "/#{model_type.to_s.tableize}/new", opts
      has_link href
    end

    def has_link_for_indexing(model_type, opts = {})
      href = add_opts "/#{model_type.to_s.tableize}", opts
      has_link href
    end  

    def should_be_on(page_name)
      current_path = URI.parse(current_url).path
      if page_name.is_a? String
        current_path.should == page_name
      else
        current_path.should match(page_name)
      end
    end    

    def index_path_for(model)
      "/#{model}"
    end


    module ClassMethods
      def with_existing resource, &block
        context "with exisiting #{resource}" do
          before { eval "@#{resource} = default_factory :#{resource}" }
          module_eval &block
        end
      end

      def on_following_link_to path, &block
        context "on following link" do
          before do
            path = get_path(path)
            has_link(path)
            visit path
          end
          module_eval &block
        end
      end

      def on_visiting path, &block
        context "on visiting" do
          before do
            visit get_path(path)
          end
          module_eval &block
        end
      end

      def add_opts(link, opts, context)
        if opts[:parent]
          "/#{opts[:parent].to_s.pluralize}/#{(context.instance_variable_get('@' + opts[:parent].to_s)).id}" + link
        else
          link
        end
      end

      def edit_path_for(resource, opts = {})
        lambda do |context|
          add_opts "/#{resource.to_s.pluralize}/#{(context.instance_variable_get('@' + resource.to_s)).id}/edit", opts, context
        end
      end
      
      def show_path_for(resource, opts = {})
        lambda do |context|
          add_opts "/#{resource.to_s.pluralize}/#{(context.instance_variable_get('@' + resource.to_s)).id}", opts, context
        end
      end

      def create_path_for(resource, opts = {})
        lambda do |context|
          add_opts "/#{resource.to_s.pluralize}/new", opts, context
        end
      end

      def index_path_for(resource, opts = {})
        lambda do |context|
          add_opts "/#{resource.to_s.pluralize}", opts, context
        end
      end

      def where(executable, *opts, &block)
        context "anonymous closure" do
          before { instance_eval &executable }
          module_eval &block
        end
      end
    end
  end
end

class RSpec::Core::ExampleGroup
      def method_missing(methId)
        str = methId.id2name
        if str.match /(.*)_path/
          index_path_for($1)
        else
          super(methId, [])
        end

      end
end

module RSpec::Core::ObjectExtensions
  def integrate(*args, &block)
    args << {} unless args.last.is_a?(Hash)
    args.last.update :type => :acceptance
    describe(*args, &block)
  end
end



RSpec.configuration.include Saki::AcceptanceHelpers, :type => :acceptance