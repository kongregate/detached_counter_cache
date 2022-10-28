module ActiveRecordExtensions
  module DetachedCounterCache
    module Base
      def self.prepended(base)
        base.class_attribute :detached_counter_cache_table_names, :detached_counter_cache_placeholders
        base.detached_counter_cache_table_names = []
        base.detached_counter_cache_placeholders = {}

        class << base
          prepend ClassMethods
        end
      end

      def increment!(*args)
        column, by = args
        placeholder = self.class.detached_counter_cache_placeholders[column]
        return super unless placeholder

        self.class.update_counters(id, column => by)
      end

      module ClassMethods
        def belongs_to(association_id, options = {})
          puts "--> belongs to: #{association_id}"
          puts "---> Options: #{options}"
          if add_detached_counter_cache = options.delete(:detached_counter_cache)
            puts "add detached cache counter == options detached_counter_cache"
            placeholder = DetachedCounterCachePlaceholder.new
            options[:counter_cache] = true
          end

          super
          return unless add_detached_counter_cache

          puts "continue because add_detached_counter_cache is true or exists"
          reflection = reflections[association_id.to_s]
          placeholder.reflection = reflection

          klass = reflection.klass
          klass.detached_counter_cache_table_names += [placeholder.detached_counter_cache_table_name]
          klass.detached_counter_cache_placeholders = klass.detached_counter_cache_placeholders.merge(reflection.counter_cache_column.to_s => placeholder)
        end

        def update_counters(id, counters)
          puts "--> update counters (detached): #{id}/#{counters}"
          updates = counters.delete_if { |k| k == :touch }
          record_id = id.is_a?(ActiveRecord::Relation) ? id.first.id : id
          detached_counters = []
          updates.each do |column_name, value|
            if detached_counter_cache_placeholders.has_key? column_name.to_s
              detached_counters << [detached_counter_cache_placeholders[column_name.to_s], value]
              updates.delete(column_name)
            end
          end

          puts "--> detached counters: #{detached_counters}"
          detached_counters.each do |placeholder, value|
            puts "executing sql..."
            connection.execute(<<-SQL
              INSERT INTO \`#{placeholder.detached_counter_cache_table_name}\` (#{placeholder.reflection.foreign_key}, count) VALUES (#{record_id}, #{value})
              ON DUPLICATE KEY UPDATE count = count + #{value}
            SQL
            )
          end

          super unless updates.blank?
        end
      end
    end

    module HasManyAssociation
      def count_records
        potential_table_name = [@owner.class.table_name, @reflection.klass.table_name, 'counts'].join('_')

        if (@owner.class.detached_counter_cache_table_names || []).include?(potential_table_name)
          DetachedCounterCache.count_from_connection(
            @owner.class.connection,
            potential_table_name,
            @reflection.foreign_key,
            @owner.id
          )
        else
          super
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

ActiveRecord::Base.send(:prepend, ActiveRecordExtensions::DetachedCounterCache::Base)
ActiveRecord::Associations::HasManyAssociation.send(:prepend, ActiveRecordExtensions::DetachedCounterCache::HasManyAssociation)
