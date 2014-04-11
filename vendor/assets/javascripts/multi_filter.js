$.fn.dataTableExt.oApi.fnMultiFilter = function( oSettings, oData ) {
    for ( var key in oData )
    {
        if ( oData.hasOwnProperty(key) )
        {
            for ( var i=0, iLen=oSettings.aoColumns.length ; i<iLen ; i++ )
            {
                if( oSettings.aoColumns[i].sName == key )
                {
                    /* Add single column filter */
                    oSettings.aoPreSearchCols[ i ].sSearch = oData[key];
                    break;
                }
            }
        }
    }
    this.oApi._fnDraw( oSettings );
};