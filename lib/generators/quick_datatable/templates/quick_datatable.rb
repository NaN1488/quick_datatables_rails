class <%= model.classify.pluralize %>Datatable < QuickDatatablesRails::Base
  
  row_builder do | <%= model.underscore %> |
    # Insert an array where each item represents each column displayed in the view 
    # example:
    # [
    #   prodcut.name,
    #   product.price
    # ]
    # Note: the order of the columns must fit the order in the view
  end
  
end