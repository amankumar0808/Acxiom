CLASS zcl_zgateentry_in_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_zgateentry_in_http IMPLEMENTATION.
  METHOD if_http_service_extension~handle_request.
    CASE request->get_method( ).
      WHEN CONV string( if_web_http_client=>get ).
         TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr = 'BN'
            object      = 'ZRGATENUM'
          IMPORTING
            number      = DATA(nextnumber)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
      ENDTRY.
      SHIFT nextnumber LEFT DELETING LEADING '0'.
      data: finaldata type string.
            finaldata = nextnumber.
      response->set_text( finaldata ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
