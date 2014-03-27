require "quick_datatables_rails/version"
require "quick_datatables_rails/dsl"
require "quick_datatables_rails/association"
require 'kaminari'

module QuickDatatablesRails
  class Base
    extend DSL
    include Association
    DEFAULT_RESULTS_PER_PAGE = 25

    def initialize(view, from = nil)
      @view = view
      @from = from
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
    def method_missing(method, *args)
      if @view.respond_to?(method)
        (class << self; self; end).class_eval do
          delegate method, to: :@view
        end
        self.send method, *args
      else
        super
      end
    end

  protected

    #reserved columns can neither sortable nor searchable
    RESERVED_COLUMNS = %w[bulk_actions]
    #return collection or model class
    def collection
      @collection ||= @from.nil? ? model : @from
    end

    def model
      if self.class.model.nil?
        begin
          #susbtract Model name from Datatables class name
          self.class.to_s.split(/(?=[A-Z])/).first.singularize.constantize
        rescue => e
          raise "Add model_as ModelClass to the class, see documentation"
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
       RESERVED_COLUMNS.include?(sort_column.to_s) ? collection : collection.order("#{sort_column} #{sort_direction}")
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
        
        if search_for_columns.has_key?(column)
          resources = resources.instance_exec column_name.to_s, search_term, &search_for_columns[column]
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
      @current_table_name ||= @collection.is_a?(Array) ? @collection.scoped.first.class.table_name : @collection.table_name
    end

    def paginator
      Kaminari
    end

    def search_for_columns
      self.class.search_for_columns.nil? ? {} : self.class.search_for_columns
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
      params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
  end
end
