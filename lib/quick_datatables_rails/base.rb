require "quick_datatables_rails/version"
require "quick_datatables_rails/association"
require 'kaminari'

module QuickDatatablesRails
  class Base
    include Association
    DEFAULT_RESULTS_PER_PAGE = 25
    ADAPTER_DELIMITER = {'mysql2'=>'`', 'postgresql'=>'"'}

    class << self
      attr_reader :model, :custom_conditions, :row, :selected_columns, :default_results_per_page
      def from(model)
        @model = model
      end

      def row_builder(&block)
        @row = block
      end

      def search(column_name, &block)
        @custom_conditions ||= {}
        @custom_conditions[column_name.to_s] = block
      end

      def columns(*columns_name)
        @selected_columns = columns_name
      end

      def results_per_page(number)
        @default_results_per_page = number
      end
    end

    def initialize(view, from = nil, options = {})
      @view = view
      @from = from
      @options = options
    end

    def as_json(options = {})
      {
        sEcho: params[:sEcho].to_i,
        iTotalDisplayRecords: resources.total_count,
        iTotalRecords: collection_count,
        aaData: data
      }
    end

    #delegate all to view_context
    def method_missing(method, *args, &block)
      if @view.respond_to?(method)
        (class << self; self; end).class_eval do
          delegate method, to: :@view
        end
        self.send method, *args, &block
      else
        super
      end
    end

  protected
    
    #return collection or model class
    def collection
      @collection ||= begin
        collection_tmp = @from.nil? ? model : @from
        @character_delimiter = ADAPTER_DELIMITER[collection_tmp.connection.instance_values["config"][:adapter]]
        collection_tmp
      end
      
    end

    def model
      if self.class.model.nil?
        begin
          #substract Model name from Datatables class name
          model_a = self.class.to_s.split(/(?=[A-Z])/)
          model_a.pop
          model_a.join.singularize.constantize
        rescue
          raise 'Add model_as ModelClass to the class, see documentation'
        end
      else
        self.class.model
      end
    end

    def resources
      @resources ||= fetch_resources
    end

    def fetch_resources
      return paginator.paginate_array([]) unless collection_count > 0
      join_associated_columns
      resources = order
      resources = resources.page(page).per(per_page)
      filters   = params.select { |index, value| index=~/sSearch_/ && !value.blank?}
      resources = add_conditions_for(filters, resources) if filters.present?
      resources
    end

    def collection_count
      @collection_count ||= collection.count
    end

    def order
      collection.order(" #{@character_delimiter}#{current_table_name}#{@character_delimiter}.#{@character_delimiter}#{sort_column}#{@character_delimiter} #{sort_direction}")
    end

    def data
      resources.map {|row| instance_exec row, &self.class.row }
    end

    def add_conditions_for(filters, resources)
      filters.map do |filter_index, search_term|
        index_filter = filter_index.scan(/[0-9]/).first.to_i

        column = columns[index_filter]
        raise IndexError, "No Searchable column for the index: #{index_filter}" if column.nil?

        column_name = real_column_name_for(column)
        
        if custom_conditions.has_key?(column)
          resources = resources.instance_exec column_name.to_s, search_term, &custom_conditions[column]
        else
          resources = resources.where("#{column_name} like ?", "%#{search_term}%")
        end
      end
      resources
    end

    #deal with ambiguations
    def real_column_name_for(column_name)
      if associated_columns.has_key? column_name
        ac = structurize_associated_column(associated_columns[column_name])
        "#{ac.database_name}.#{ac.table_name}.#{ac.column_name}"
      else
        "#{collection.table_name}.#{column_name}"
      end
    end

    def selected_columns
      self.class.selected_columns.nil? ? "#{current_table_name}.*" : self.class.selected_columns.map{ |column| "#{current_table_name}.#{column.to_s}"}.join(', ')
    end

    def current_table_name
      @current_table_name ||= @collection.is_a?(Array) ? @collection.where(nil).first.class.table_name : @collection.table_name
    end

    def paginator
      Kaminari
    end

    def custom_conditions
      self.class.custom_conditions.nil? ? {} : self.class.custom_conditions
    end

    def columns
      @columns ||= params[:sColumns].split(',')
    end

    def page
      params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
      if params[:iDisplayLength].to_i > 0
        params[:iDisplayLength].to_i 
      else
        self.class.default_results_per_page.present? ? self.class.default_results_per_page : DEFAULT_RESULTS_PER_PAGE
      end
    end

    def sort_column
      column_name = columns[params[:iSortCol_0].to_i]
      if self.class.selected_columns.present? && self.class.selected_columns.map(&:to_s).include?(column_name)
        "#{current_table_name}.#{column_name}"
      else
        column_name
      end
    end

    def sort_direction
      params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
    end
  end
end
