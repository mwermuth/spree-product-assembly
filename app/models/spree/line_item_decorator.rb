module Spree
  LineItem.class_eval do
    scope :assemblies, -> { joins(:variant => :parts).uniq }

    def any_units_shipped?
      OrderInventoryAssembly.new(self).inventory_units.any? do |unit|
        unit.shipped?
      end
    end

    def assemblies_parts
      AssembliesPart.where(assembly_id: [variant.id, product.master.id])
    end

    # Destroy and verify inventory so that units are restocked back to the
    # stock location
    def destroy_along_with_units
      self.quantity = 0
      OrderInventoryAssembly.new(self).verify
      self.destroy
    end

    # The parts that apply to this particular LineItem. Usually `product#parts`, but
    # provided as a hook if you want to override and customize the parts for a specific
    # LineItem.
    def parts
      if variant.is_master?
        variant.parts
      else
        product.parts + variant.parts
      end
    end

    # The number of the specified variant that make up this LineItem. By default, calls
    # `product#count_of`, but provided as a hook if you want to override and customize
    # the parts available for a specific LineItem. Note that if you only customize whether
    # a variant is included in the LineItem, and don't customize the quantity of that part
    # per LineItem, you shouldn't need to override this method.
    def count_of(variant)
      variant.count_of(variant)
    end

    private
      def update_inventory
        if self.variant.assembly? && order.completed?
          OrderInventoryAssembly.new(self).verify(target_shipment)
        else
          OrderInventory.new(self.order).verify(self, target_shipment)
        end
      end
  end
end
