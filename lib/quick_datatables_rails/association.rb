module QuickDatatablesRails
  module Association

    ASSOCIATION_METHOD = 'LEFT OUTER JOIN'

    module ClassMethods
      attr_reader :associated_columns
      def associate_column(column_name, db_column_name = nil, &block)
        @associated_columns ||= {}
        @associated_columns[column_name.to_s] = {block:block_given? ? block : nil , db_column_name:(db_column_name.nil? ? column_name : db_column_name)}
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    #Attach virtual columns queries
    def join_associated_columns
      if associated_columns.present?
        associated_columns.each_value do |associated_column|
          if associated_column[:block].nil?
            join_associated_column(associated_column)
          else
            @collection = @collection.select(selected_columns)
            @collection = @collection.where(nil).instance_eval &associated_column[:block]
          end
        end
      end
    end

    #join virtaul column, adding db name in order to handle multiple connections
    def join_associated_column(associated_column)
      vc          = structurize_associated_column(associated_column)
      @collection = @collection.select(selected_columns)
      @collection = @collection.select("#{vc.table_name}.#{vc.column_name} as #{vc.table_name.singularize}_#{vc.column_name}")
      @collection = @collection.joins("#{ASSOCIATION_METHOD} #{vc.table_name} ON #{vc.table_name}.id = #{current_table_name}.#{vc.table_name.singularize}_id")
    end

    def structurize_associated_column(associated_column)
      column_name   = associated_column[:db_column_name][:column_name]
      model         = associated_column[:db_column_name][:class]
      block         = associated_column[:block]
      table_name    = model.table_name

      OpenStruct.new({block:block, column_name:column_name, table_name:table_name})
    end

    def associated_columns
      self.class.associated_columns.nil? ? {} : self.class.associated_columns
    end

  end
end
