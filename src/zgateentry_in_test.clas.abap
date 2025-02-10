CLASS zgateentry_in_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zgateentry_in_test IMPLEMENTATION.
METHOD if_oo_adt_classrun~main.
    DELETE from zgateentryheader.
    DELETE from zgateentrylines.
ENDMETHOD.
ENDCLASS.
