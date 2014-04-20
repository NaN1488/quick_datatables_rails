module QuickDatatable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      def generate_install
        include_file_in_application_js('quick_datatable')
      end
    
    private
    
      def include_file_in_application_js(name)
        @original_js ||= File.binread("app/assets/javascripts/application.js")
        if @original_js.include?("require #{name}")
           say_status("skipped", "insert into app/assets/javascripts/application.js", :yellow)
        else
           insert_into_file "app/assets/javascripts/application.js", "//= require #{name}\n", :after => "jquery_ujs\n"
        end
      end
      
    end
  end
end

