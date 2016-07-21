module ActiveRecordExtensions
  module DetachedCounterCache
    module Base
      extend ActiveSupport::Concern

      included do
        class_attribute :detached_counter_cache_table_names, :detached_counter_cache_placeholders
        self.detached_counter_cache_table_names = []
        self.detached_counter_cache_placeholders = {}

        class << self
          alias_method_chain :update_counters, :detached_counters
          alias_method_chain :belongs_to, :detached_counters
        end
      end

      module ClassMethods
        def belongs_to_with_detached_counters(association_id, options = {})
          if add_detached_counter_cache = options.delete(:detached_counter_cache)
            placeholder = DetachedCounterCachePlaceholder.new
            options[:counter_cache] = true
          end

          belongs_to_without_detached_counters(association_id, options)

          if add_detached_counter_cache
            reflection = reflections[association_id.to_s]
            placeholder.reflection = reflection

            klass = reflection.klass
            klass.detached_counter_cache_table_names += [placeholder.detached_counter_cache_table_name]
            klass.detached_counter_cache_placeholders = klass.detached_counter_cache_placeholders.merge(reflection.counter_cache_column.to_s => placeholder)
          end
        end

        def update_counters_with_detached_counters(id, counters)
          detached_counters = []
          counters.each do |column_name, value|
            if detached_counter_cache_placeholders.has_key? column_name.to_s
              detached_counters << [detached_counter_cache_placeholders[column_name.to_s], value]
              counters.delete(column_name)
            end
          end

          detached_counters.each do |placeholder, value|
            self.connection.execute(<<-SQL
              INSERT INTO `#{placeholder.detached_counter_cache_table_name}` (#{placeholder.reflection.foreign_key}, count) VALUES (#{id}, #{value})
              ON DUPLICATE KEY UPDATE count = count + #{value}
            SQL
            )
          end

          update_counters_without_detached_counters(id, counters) unless counters.blank?
        end
      end
    end

    module HasManyAssociation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :count_records, :detached_counters
      end

      def count_records_with_detached_counters
        potential_table_name = [@owner.class.table_name, @reflection.klass.table_name, 'counts'].join('_')

        if (@owner.class.detached_counter_cache_table_names || []).include?(potential_table_name)
          DetachedCounterCache.count_from_connection(
            @owner.class.connection,
            potential_table_name,
            @reflection.foreign_key,
            @owner.id
          )
        else
          count_records_without_detached_counters
        end
      end
    end

    class DetachedCounterCachePlaceholder
      attr_accessor :reflection

      def detached_counter_cache_table_name
        [reflection.klass.table_name, reflection.active_record.table_name, 'counts'].join('_')
      end
    end

    def self.count_from_connection(connection, potential_table_name, foreign_key, owner_id)
      row = connection.select_all("SELECT count FROM `#{potential_table_name}` WHERE #{foreign_key} = #{owner_id}")[0]
      row.blank? ? 0 : row['count'].to_i
    end
  end
end

ActiveRecord::Base.send( :include, ActiveRecordExtensions::DetachedCounterCache::Base )
ActiveRecord::Associations::HasManyAssociation.send( :include, ActiveRecordExtensions::DetachedCounterCache::HasManyAssociation )
