Spree::Promotion::Rules::Product.class_eval do
  belongs_to :product_group
  preference :products_source, :string, :default => 'manual'
  attr_accessible :preferred_products_source, :product_group_id

  def eligible_products
    (preferred_products_source == 'group' && product_group) ? product_group.products : products
  end

  def products_source=(source)
    if source.to_s == 'manual'
      self.product_group_id = nil
    end
  end

end
