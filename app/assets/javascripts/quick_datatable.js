// 
// Requirements:
//   jquery.Datatables
//   fnMultiFilter
// Usage:
// 
//  $('table.data_table').quick_datatable()
//  
//   //pass options to jquery.dataTables with data_table_options key
// 
//  $('table.data_table').quick_datatable({
//    data_table_options: {
//      fnDrawCallback: function( oSettings ) {
//        //do something for each draw, like attach events
//      }
//    }
//  });

( function( $ ) {
    $.widget( 'fn.quick_datatable', {
      options:{
        data_table_options:{}
      },
      vars:{
        columns:[],
        //current datatable
        data_table: null, 
        default_datatable_options:{
          bProcessing: true,
          bServerSide: true,
          sStripeOdd: '',
          sStripeEven: '',
          bLengthChange: true,
          sDom: 'rtip'
        }
      },
      _create: function (){
        this.vars = {
          columns:[],
          //current datatable
          data_table: null, 
          default_datatable_options:{
            bProcessing: true,
            bServerSide: true,
            sStripeOdd: '',
            sStripeEven: '',
            bLengthChange: true,
            sDom: 'rtip'
          }
        }

        this._build_columns_attrs();
        this._build_datatable();

        this._bind_search();
        this._bind_results_per_page();
        this._bind_enter_key();
      },
      //get data attr from <th> tag
      _build_columns_attrs: function (){
        var self = this;
        self.vars.columns = []
        $.each($(this.element).find("th"), function(i, col){
          var column_options = {};
          $.each($(col).data(), function (key, value){
            column_options[key] = value;
          });
          self.vars.columns.push(column_options);
        });
      },
      _build_datatable: function () {
        var data_table_options = {
          sAjaxSource: $(this.element).data('source'),
          aoColumns: this.vars.columns,
          iDisplayLength: parseInt($(this.options.results_per_page).val())
        }

        var data_table_options_merged = $.extend(data_table_options,$(this.element).find("thead tr").data(), this.vars.default_datatable_options, this.options.data_table_options);
        this.vars.data_table = $(this.element).dataTable(data_table_options_merged);
      },
      _bind_search: function() {
        var self = this;
        $(this.options.button_search).on('click', function (){
          var filters = {};
          $.each($(self.options.fields_for_search), function (i, elem){
            name = $(elem).attr('name');
            value = $(elem).val();
            filters[name] = value;
          });
          var oSettings = self.vars.data_table.fnSettings();
          oSettings._iDisplayLength = parseInt($(self.options.results_per_page).val());
          self.vars.data_table.fnMultiFilter(filters);
        });
      },
      _bind_results_per_page: function () {
        var self = this;
        $(this.options.results_per_page).on('keypress', function (e){
          if(e.which == 13) {
            var oSettings = self.vars.data_table.fnSettings();
            oSettings._iDisplayLength = parseInt($(this).val());
            $(self.options.button_search).trigger("click");
          }
        });
      },
      _bind_enter_key: function () {
        var self = this;
        $(this.options.fields_for_search).keypress(function (e){
          if(e.which == 13) {
            $(self.options.button_search).trigger("click");
          }
        });
      },

    })
})( jQuery );
