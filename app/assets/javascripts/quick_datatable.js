//= require multi_filter


// Usage:
// 
//  $('table.data_table').quickDatatable()
//  
//   //pass options to jquery.dataTables with data_table_options key
// 
//  $('table.data_table').quickDatatable({
//    data_table_options: {
//      fnDrawCallback: function( oSettings ) {
//        //do something for each draw, like attach events
//      }
//    }
//  });


(function ( $ ) {

  var private_vars = null;
  $.fn.quickDatatable = function(options) {
      
     var settings = $.extend({
          // These are the defaults.
          columns:[],
          search_button: null,
          results_per_page: null,
          fields_for_search: null,
          data_table: null,
          default_datatable_options:{
            bProcessing: true,
            bServerSide: true,
            sStripeOdd: '',
            sStripeEven: '',
            bLengthChange: true,
            sDom: 'rtip'
          }
      }, options );

    return this.each(function() {
         var $this = $( this );
        _build_columns_attrs($this);
        _build_datatable($this);

        _bind_search($this);
        _bind_results_per_page();
        _bind_enter_key();
    });

    function _build_columns_attrs($obj){
      settings.columns = []
      $.each($obj.find("th"), function(i, col){
        var column_options = {};
        $.each($(col).data(), function (key, value){
          column_options[key] = value;
        });
        settings.columns.push(column_options);
      });
    }
    function _build_datatable($obj) {
      var data_table_options = {
        sAjaxSource: $obj.data('source'),
        aoColumns: settings.columns,
        iDisplayLength: parseInt($(settings.results_per_page).val())
      }

      var data_table_options_merged = $.extend(data_table_options,$obj.find("thead tr").data(), settings.default_datatable_options, settings.data_table_options);
      settings.data_table = $obj.dataTable(data_table_options_merged);
    }

    function _bind_search($obj){
      
      $(settings.button_search).on('click', function (){
        var filters = {};
        $.each($(settings.fields_for_search), function (i, elem){
          name = $(elem).attr('name');
          value = $(elem).val();
          filters[name] = value;
        });
        var oSettings = settings.data_table.fnSettings();
        result_per_page = parseInt($(settings.results_per_page).val())
        if (!isNaN(result_per_page)) {
          oSettings._iDisplayLength = parseInt($(settings.results_per_page).val());
        }
        settings.data_table.fnMultiFilter(filters);
      });
    }

    function _bind_results_per_page() {
      $(settings.results_per_page).on('keypress', function (e){
        if(e.which == 13) {
          var oSettings = settings.data_table.fnSettings();
          oSettings._iDisplayLength = parseInt($(this).val());
          $(settings.button_search).trigger("click");
        }
      });
    }

    function _bind_enter_key() {
      $(settings.fields_for_search).keypress(function (e){
        if(e.which == 13) {
          $(settings.button_search).trigger("click");
        }
      });
    }
   
  };

}(jQuery));

