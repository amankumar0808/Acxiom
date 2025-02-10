CLASS lhc_gateentrylines DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS updateLines FOR DETERMINE ON SAVE
      IMPORTING keys FOR GateEntryLines~updateLines.
    METHODS calculateTotals FOR DETERMINE ON MODIFY
      IMPORTING keys FOR GateEntryLines~calculateTotals.

ENDCLASS.

CLASS lhc_gateentrylines IMPLEMENTATION.

  METHOD updateLines.
    READ ENTITIES OF ZR_GateEntryHeader IN LOCAL MODE
      ENTITY GateEntryLines
      FIELDS ( Vendorcode Remarks )
      WITH CORRESPONDING #( keys )
      RESULT DATA(entrylines).

    LOOP AT entrylines INTO DATA(entryline).
      IF entryline-Vendorcode NE '' AND entryline-Remarks = ''.
        MODIFY ENTITIES OF ZR_GateEntryHeader IN LOCAL MODE
          ENTITY GateEntryLines
          UPDATE
          FIELDS ( Remarks ) WITH VALUE #( ( %tky = entryline-%tky Remarks = entryline-Vendorcode ) ).
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD calculateTotals.
    READ ENTITIES OF ZR_GateEntryHeader IN LOCAL MODE
        ENTITY GateEntryLines
        BY \_GateEntryHeader
        FIELDS ( Gateentryno )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_gateentry).

    "update involved instances
    MODIFY ENTITIES OF ZR_GateEntryHeader IN LOCAL MODE
      ENTITY GateEntryHeader
        EXECUTE ReCalcTotals
        FROM VALUE #( FOR <fs_key> IN lt_gateentry ( %tky = <fs_key>-%tky ) ).

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
