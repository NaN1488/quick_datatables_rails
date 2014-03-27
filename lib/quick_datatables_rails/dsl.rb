module QuickDatatablesRails
  module DSL
    attr_reader :model, :collection, :row, :selected_columns, :search_for_columns, :default_results_per_page

      def from(model)
        @model = model
      end

      def row_builder(&block)
        @row = block
      end

      def search(column_name, &block)
        @search_for_columns ||= {}
        @search_for_columns[column_name.to_s] = block
      end

      def columns(*columns_name)
        @selected_columns = columns_name
      end

      def results_per_page(number)
        @default_results_per_page = number
      end
  end
end
