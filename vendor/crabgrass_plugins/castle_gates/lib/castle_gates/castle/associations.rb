#
# Castle Associations
#

module CastleGates
module Castle
module Associations

def self.included(base)
  base.class_eval do

    ##
    ## FINDERS
    ##

    #
    # search for castle's with particular access.
    #
    # e.g. Fort.with_access(:public => :gate)
    #
    scope(:with_access, lambda {|args|
      holder, gates = args.first
      subselect = subselect_for_holder_and_gates(holder, gates)
      where("#{self.quoted_table_name}.id IN (#{subselect})")
    })

    ##
    ## KEYS
    ##

    has_many :keys,
             :class_name => "CastleGates::Key",
             :as => :castle,
             :dependent => :delete_all do

      #
      # finds a key for a holder, initializing it in memory if it does not exist.
      #
      def find_by_holder(holder)
        holder = Holder[holder]
        key = find_or_initialize_by_holder_code(holder.code)
        if key.new_record?
          castle = proxy_owner
          key.gate_bitfield |= castle.gate_set.default_bits(castle, holder)
        end
        key
      end

      def select_holder_codes
        castle = proxy_owner
        sti_type = castle.store_full_sti_class ? castle.class.name : castle.class.base_class.name
        self.connection.select_values("SELECT DISTINCT `castle_gates_keys`.`holder_code` FROM `castle_gates_keys` WHERE `castle_gates_keys`.`castle_type` = '%s' AND `castle_gates_keys`.`castle_id` = %s" % [sti_type, castle.id])
      end

    end

    ##
    ## CURRENT USER KEYS
    ##

    #
    # This uses ActiveRecord magic to allow you to pre-load the keys for current_user:
    #
    #   @pages = Page.find... :include => {:owner => :current_user_keys}
    #
    # has_many :current_user_keys,
    #          :class_name => "CastleGates::Key",
    #          :conditions => 'holder_code IN (#{User.current.access_codes.join(", ")})',
    #          :as => :castle do
    #   def open?(locks)
    #     proxy_owner.class.keys_open_locks?(self, locks)
    #   end
    #   def gate_bitfield
    #     if ActiveRecord::Base.connection.adapter_name == 'SQLite'
    #       self.inject(0) {|prior, key| prior | key.gate_bitfield}
    #     else
    #       self.calculate(:bit_or, :gate_bitfield)
    #     end
    #   end
    # end
  end
end

end
end
end
