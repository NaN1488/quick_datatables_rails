module QuickDatatablesRails
  module DSL
    attr_reader :model, :collection, :row, :virtual_columns, :search_for_columns, :sort_column, :sort_direction

      def collection_method(collection)
        @collection = collection
      end

      def model_as(model)
        @model = model
      end

      def row_builder(&block)
        @row = block
      end

      def add_virtual_column(column_name, db_column_name = nil, &block)
        @virtual_columns ||= {}
        @virtual_columns[column_name.to_s] = {block:block_given? ? block : nil , db_column_name:(db_column_name.nil? ? column_name : db_column_name)}
      end

      def add_search_for(column_name, &block)
        @search_for_columns ||= {}
        @search_for_columns[column_name.to_s] = block
      end
  end
end
