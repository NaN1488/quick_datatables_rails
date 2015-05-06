# Quick Datatables Rails

TODO

## General Installation

###Requirements:
1. First you must install jquery-datatables-rails 
https://github.com/rweng/jquery-datatables-rails/releases/tag/v1.12.0
(currently version 1.12 is the only one supported)


### After install jquery-datatables-rails follow these steps

1. Add to your Gemfile:

    ```ruby
      gem 'quick_datatables_rails', git: 'git://github.com/NaN1488/quick_datatables_rails.git'
    ```

1. Install the gem:

        $ bundle install

1. Run the installer:

        $ rails g quick_datatable:install

## Simple Usage:

1. Run the creator:

        $ rails g quick_datatable:create [MODEL]
  example:
        
        $ rails g quick_datatable:create product
        
  It will create the class ProductsDatatable for you:
        
  ```ruby
  # app/datatables/products_datatable.rb
  class ProductsDatatable < QuickDatatablesRails::Base
    
    row_builder do | product |
      # Insert an array where each item represents each column displayed in the view 
      # example:
      # [
      #   product.name,
      #   product.price
      # ]
      # Note: the order of the columns must fit the order in the view
    end
    
  end
  ```

2. **Controller**: Add a json response in your controller and return the instance of `[Model]Datatable`. The constructor requires the `view_context`

  ```ruby
  class ProductsController < ApplicationController
  
    def index
      respond_to do |format|
        format.html
        format.json do  
          render json: ProductsDatatable.new(view_context)
        end
      end
    end
  
  end
  ```
3. **View**: Create a table with the header of the attributes you want to display. You must to add data-s-name attribute and the value should be the name of the desired attribute 

  ```html
    <table id="product_table" class='quick_datatable'>
      <thead>
        <tr>
          <th data-s-name="name">Name</th>
          <th data-s-name="price">Price</th>
          ...
        </tr>
      </thead>
      <tbody></tbody>
    </table>
  ```
4. **Javascript**: Call the wrapper QuickDatatable to initialize the table:
  
  ```javascript
    $('table.quick_datatable').QuickDatatable();
  ```
