module QuickDatatable
  module Generators
    class CreateGenerator < Rails::Generators::Base
      
      source_root File.expand_path('../templates', __FILE__)
      argument :model, type: :string

      def generate_quick_datatable
        template 'quick_datatable.rb', File.join('app/datatables', "#{model.tableize}_datatable.rb")
      end

    end
  end
end

