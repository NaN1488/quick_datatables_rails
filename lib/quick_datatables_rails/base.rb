require "quick_datatables_rails/version"
require "quick_datatables_rails/dsl"
require 'kaminari'

module QuickDatatablesRails
  class Base

    include DSL
    DEFAULT_RESULT_PER_PAGE = 25

    class << self
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

    def initialize(view, collection_through = nil)
      @view = view
      @collection_through = collection_through
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
      @collection ||= build_collection
    end

    def build_collection
      if @collection_through.present?
        raise ArgumentError, '"collection_through" given, but "collection" not defined' if self.class.collection.nil?
        @collection_through.public_send(self.class.collection)
      else
        raise ArgumentError, '"model" not defined' if self.class.model.nil?
        self.class.model
      end
    end

    def resources
      @resources ||= fetch_resources
    end

    def fetch_resources
      return paginator.paginate_array([]) unless collection_count > 0
      join_virtual_columns
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

    #Attach virtual columns queries
    def join_virtual_columns
      if virtual_columns.present?
        virtual_columns.each_value do |virtual_column| 
          if virtual_column[:block].nil?
            join_virtual_column(virtual_column)
          else
            @collection = @collection.select("#{current_table_name}.*")
            @collection = @collection.scoped.instance_eval &virtual_column[:block]
          end
        end
      end
    end

    #join virtaul column, adding db name in order to handle multiple connections
    def join_virtual_column(virtual_column)
      vc          = structurize_virtual_column(virtual_column)
      @collection = @collection.select("#{current_table_name}.*")
      @collection = @collection.select("#{vc.database_name}.#{vc.table_name}.#{vc.column_name} as #{vc.table_name.singularize}_#{vc.column_name}")
      @collection = @collection.joins("LEFT OUTER JOIN #{vc.database_name}.#{vc.table_name} ON #{vc.database_name}.#{vc.table_name}.id = #{current_table_name}.#{vc.table_name.singularize}_id")
    end

    def data
      resources.map {|row| instance_exec row, &self.class.row }
    end

    def add_conditions_for(filters, resources)

      filters.map do |filter_index, search_term|
        index_filter = filter_index.scan(/[0-9]/).first.to_i

        column = columns[index_filter]
        raise IndexError, "No Searchable column for the index: #{index_filter}" if column.nil?

        column_name = real_column_name_for column
        
        if search_for_columns.has_key? column
          resources = resources.instance_exec column_name.to_s, search_term, &search_for_columns[column]
        else
          resources = resources.where("#{column_name} like ?", "%#{search_term}%")
        end
      end
      resources
    end

    #deal with ambiguations
    def real_column_name_for(column_name)
      if virtual_columns.has_key? column_name
        vc = structurize_virtual_column(virtual_columns[column_name])
        "#{vc.database_name}.#{vc.table_name}.#{vc.column_name}"
      else
        "#{collection.table_name}.#{column_name}"
      end
    end

    def current_table_name
      @current_table_name ||= @collection.is_a?(Array) ? @collection.scoped.first.class.table_name : @collection.table_name
    end

    def structurize_virtual_column(virtual_column)
      column_name   = virtual_column[:db_column_name][:column_name]
      model         = virtual_column[:db_column_name][:class]
      block         = virtual_column[:block]
      table_name    = model.table_name
      database_name = model.connection.current_database

      OpenStruct.new({block:block, column_name:column_name, table_name:table_name, database_name:database_name})
    end

    def paginator
      Kaminari
    end

    def virtual_columns
      self.class.virtual_columns.nil? ? {} : self.class.virtual_columns
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
      params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : DEFAULT_RESULT_PER_PAGE
    end

    def sort_column
        @sort_column ||= columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        @sort_direction ||= params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
  end
end
