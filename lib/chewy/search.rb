require 'chewy/query'
require 'chewy/search/request'
require 'chewy/search/response'
require 'chewy/search/parameters'
require 'chewy/search/pagination/kaminari'
require 'chewy/search/pagination/will_paginate'

module Chewy
  module Search
    extend ActiveSupport::Concern

    module ClassMethods
      def all
        search_class.scopes.last || search_class.new(self)
      end

      def search_string(query, options = {})
        options = options.merge(
          index: all._indexes.map(&:index_name),
          type: all._types.map(&:type_name),
          q: query
        )
        Chewy.client.search(options)
      end

      def method_missing(name, *args, &block)
        if Chewy.search_class.delegated_methods.include?(name)
          all.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _)
        Chewy.search_class.delegated_methods.include?(name) || super
      end

    private

      def search_class
        @search_class ||= begin
          search_class = Class.new(Chewy.search_class)
          if self < Chewy::Type
            index_scopes = index.scopes - scopes

            delegate_scoped index, search_class, index_scopes
            delegate_scoped index, self, index_scopes
          end
          delegate_scoped self, search_class, scopes
          const_set('Query', search_class)
        end
      end

      def delegate_scoped(source, destination, methods)
        methods.each do |method|
          destination.class_eval do
            define_method method do |*args, &block|
              scoping { source.public_send(method, *args, &block) }
            end
          end
        end
      end
    end
  end
end
