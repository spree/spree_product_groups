# *Spree::ProductScope* is model for storing named scopes with their arguments,
# to be used with Spree::ProductGroups.
#
# Each product Scope can be applied to Spree::Product (or product scope) with #apply_on method
# which returns new combined named scope
#
module Spree
  class ProductScope < ActiveRecord::Base
    # name
    # arguments
    belongs_to :product_group
    serialize :arguments

    validate :check_validity_of_scope

    extend ::Spree::Scopes::Dynamic

    attr_accessible :name, :arguments

    # Get all products with this scope
    def products
      if Product.respond_to?(name)
        # Since IDs are comma seperated in the first argument we need to correctly pass the ID array to the with_ids scope.
        if name == 'with_ids'
          Product.with_ids(arguments.first.split(','))
        else
          Product.send(name, *arguments)
        end
      end
    end

    # Applies product scope on Spree::Product model or another named scope
    def apply_on(another_scope)
      array = Array.wrap(self.arguments)
      unless another_scope.class == ActiveRecord::Relation
        another_scope = another_scope.send(:relation)
      end
      if Product.respond_to?(self.name.intern)
        if (array.blank? || array.size < 2)
          if Product.method(self.name.intern).arity == 0
            another_scope.send(self.name.intern)
          else
            # Since IDs are comma seperated in the first argument we need to correctly pass the ID array to the with_ids scope.
            if self.name == 'with_ids'
              another_scope.with_ids(array.first.split(','))
            else
              another_scope.send(self.name.intern, array.try(:first))
            end
          end
        else
          another_scope.send(self.name.intern, *array)
        end
      else
        another_scope.ransack({ self.name.intern => array.join("") }).result
      end
    end

    # checks validity of the named scope (if its safe and can be applied on Spree::Product)
    def check_validity_of_scope
      errors.add(:name, 'is not a valid scope name') unless Product.respond_to?(self.name.intern)
      apply_on(Product).limit(0) != nil
    rescue Exception => e
      unless Rails.env.production?

        puts "name: #{self.name}"
        puts "arguments: #{self.arguments.inspect}"
        puts e.message
        puts e.backtrace
      end
      errors.add(:arguments, 'are incorrect')
    end

    # test ordering scope by looking for name pattern or missed arguments
    def is_ordering?
      name =~ /^(ascend_by|descend_by)/ || arguments.blank?
    end

    def to_sentence
      result = I18n.t(:sentence, :scope => [:product_scopes, :scopes, self.name], :default => '')
      result = I18n.t(:name, :scope => [:product_scopes, :scopes, self.name]) if result.blank?
      result % [*self.arguments]
    end

    def to_s
      to_sentence
    end
  end
end

require_dependency 'spree/product_scope/scopes'
