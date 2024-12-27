CLASS zcl_purchasejob_lines DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PURCHASEJOB_LINES IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.
" Return the supported selection parameters here
    et_parameter_def = VALUE #(
*      ( selname = 'S_ID'    kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 10 param_text = 'My ID'                                      changeable_ind = abap_true )
*      ( selname = 'P_DESCR' kind = if_apj_dt_exec_object=>parameter     datatype = 'C' length = 80 param_text = 'My Description'   lowercase_ind = abap_true changeable_ind = abap_true )
*      ( selname = 'P_COUNT' kind = if_apj_dt_exec_object=>parameter     datatype = 'I' length = 10 param_text = 'My Count'                                   changeable_ind = abap_true )
      ( selname = 'P_SIMUL' kind = if_apj_dt_exec_object=>parameter     datatype = 'C' length =  1 param_text = 'Full Processing' checkbox_ind = abap_true  changeable_ind = abap_true )
    ).

" Return the default parameters values here
    et_parameter_val = VALUE #(
*      ( selname = 'S_ID'    kind = if_apj_dt_exec_object=>select_option sign = 'I' option = 'EQ' low = '4711' )
*      ( selname = 'P_DESCR' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = 'My Default Description' )
*      ( selname = 'P_COUNT' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = '200' )
      ( selname = 'P_SIMUL' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = abap_false )
    ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    TYPES ty_id TYPE c LENGTH 10.

    DATA s_id    TYPE RANGE OF ty_id.
    DATA p_descr TYPE c LENGTH 80.
    DATA p_count TYPE i.
    DATA p_simul TYPE abap_boolean.
    DATA processfrom TYPE d.

    DATA: jobname   type cl_apj_rt_api=>TY_JOBNAME.
    DATA: jobcount  type cl_apj_rt_api=>TY_JOBCOUNT.
    DATA: catalog   type cl_apj_rt_api=>TY_CATALOG_NAME.
    DATA: template  type cl_apj_rt_api=>TY_TEMPLATE_NAME.

    DATA: lt_purchinvlines TYPE STANDARD TABLE OF zpurchinvlines,
          wa_purchinvlines TYPE zpurchinvlines,
          lt_purchinvprocessed TYPE STANDARD TABLE OF zpurchinvproc,
          wa_purchinvprocessed TYPE zpurchinvproc.

    GET TIME STAMP FIELD DATA(lv_timestamp).

    " Getting the actual parameter values
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'S_ID'.
          APPEND VALUE #( sign   = ls_parameter-sign
                          option = ls_parameter-option
                          low    = ls_parameter-low
                          high   = ls_parameter-high ) TO s_id.
        WHEN 'P_DESCR'. p_descr = ls_parameter-low.
        WHEN 'P_COUNT'. p_count = ls_parameter-low.
        WHEN 'P_SIMUL'. p_simul = ls_parameter-low.
      ENDCASE.
    ENDLOOP.

    try.
*      read own runtime info catalog
       cl_apj_rt_api=>GET_JOB_RUNTIME_INFO(
                        importing
                          ev_jobname        = jobname
                          ev_jobcount       = jobcount
                          ev_catalog_name   = catalog
                          ev_template_name  = template ).

       catch cx_apj_rt.

    endtry.

    processfrom = sy-datum - 30.
    IF p_simul = abap_true.
       processfrom = sy-datum - 2000.
    ENDIF.

    SELECT FROM I_SupplierInvoiceAPI01 AS c
        LEFT JOIN i_supplier AS b ON b~supplier = c~InvoicingParty
        FIELDS
            b~Supplier , b~PostalCode , b~BPAddrCityName , b~BPAddrStreetName , b~TaxNumber3,
            b~SupplierFullName, b~region, c~ReverseDocument , c~ReverseDocumentFiscalYear,
            c~CompanyCode , c~PaymentTerms , c~CreatedByUser , c~CreationDate , c~InvoicingParty , c~InvoiceGrossAmount,
            c~DocumentCurrency , c~SupplierInvoiceIDByInvcgParty, c~FiscalYear, c~SupplierInvoice, c~SupplierInvoiceWthnFiscalYear,
            c~DocumentDate, c~PostingDate
        WHERE c~PostingDate >= @processfrom
            AND NOT EXISTS (
               SELECT supplierinvoice FROM zpurchinvproc
               WHERE c~supplierinvoice = zpurchinvproc~supplierinvoice AND
                 c~CompanyCode = zpurchinvproc~companycode AND
                 c~FiscalYear = zpurchinvproc~fiscalyearvalue )
            INTO TABLE @DATA(ltheader).

    LOOP AT ltheader INTO DATA(waheader).
      lv_timestamp = cl_abap_tstmp=>add_to_short( tstmp = lv_timestamp secs = 11111 ).

* Delete already processed sales line
      delete from zpurchinvlines
        Where zpurchinvlines~companycode = @waheader-CompanyCode AND
        zpurchinvlines~fiscalyearvalue = @waheader-FiscalYear AND
        zpurchinvlines~supplierinvoice = @waheader-SupplierInvoice.



      SELECT FROM I_SuplrInvcItemPurOrdRefAPI01 AS a
        FIELDS
            a~PurchaseOrderItem, a~SupplierInvoiceItem,
            a~PurchaseOrder, a~SupplierInvoiceItemAmount AS tax_amt, a~SupplierInvoiceItemAmount, a~taxcode,
            a~FreightSupplier , a~SupplierInvoice , a~FiscalYear , a~TaxJurisdiction AS SInvwithFYear, a~plant,
            a~PurchaseOrderItemMaterial AS material, a~QuantityInPurchaseOrderUnit, a~QtyInPurchaseOrderPriceUnit,
            a~PurchaseOrderQuantityUnit, PurchaseOrderPriceUnit, a~ReferenceDocument , a~ReferenceDocumentFiscalYear
        WHERE a~SupplierInvoice = @waheader-SupplierInvoice
          AND a~FiscalYear = @waheader-FiscalYear
          INTO TABLE @DATA(ltlines).


*      SELECT FROM I_BillingDocItemPrcgElmntBasic FIELDS BillingDocument , BillingDocumentItem, ConditionRateValue, ConditionAmount, ConditionType
*        WHERE BillingDocument = @waheader-BillingDocument
*        INTO TABLE @DATA(it_price).

        SELECT FROM I_Producttext as a FIELDS
            a~ProductName, a~Product
        FOR ALL ENTRIES IN @ltlines
        WHERE a~Product = @ltlines-material AND a~Language = 'E'
            INTO TABLE @DATA(it_product).

        SELECT FROM I_PurchaseOrderItemAPI01 AS a
            LEFT JOIN I_PurchaseOrderAPI01 AS b ON a~PurchaseOrdeR = b~PurchaseOrder
            FIELDS a~BaseUnit , b~PurchaseOrderType , b~PurchasingGroup , b~PurchasingOrganization ,
            b~PurchaseOrderDate , a~PurchaseOrder , a~PurchaseOrderItem , a~ProfitCenter
        FOR ALL ENTRIES IN @ltlines
        WHERE a~PurchaseOrder = @ltlines-PurchaseOrder AND a~PurchaseOrderItem = @ltlines-PurchaseOrderItem
            INTO TABLE @DATA(it_po).

        SELECT FROM I_MaterialDocumentItem_2
            FIELDS MaterialDocument , PurchaseOrder , PurchaseOrderItem , QuantityInBaseUnit , PostingDate
        FOR ALL ENTRIES IN @ltlines
        WHERE MaterialDocument  = @ltlines-ReferenceDocument
            INTO TABLE @DATA(it_grn).

        SELECT FROM I_ProductPlantIntlTrd FIELDS
            product , plant  , ConsumptionTaxCtrlCode
            FOR ALL ENTRIES IN @ltlines
        WHERE product = @ltlines-Material  AND plant = @ltlines-Plant
            INTO TABLE @DATA(it_hsn).

        SELECT FROM I_taxcodetext
            FIELDS TaxCode , TaxCodeName
        FOR ALL ENTRIES IN @ltlines
        WHERE Language = 'E' AND taxcode = @ltlines-TaxCode
            INTO TABLE @DATA(it_tax).

        LOOP AT ltlines INTO DATA(walines).

            wa_purchinvlines-client = SY-MANDT.
            wa_purchinvlines-companycode = waheader-CompanyCode.
            wa_purchinvlines-fiscalyearvalue = waheader-FiscalYear.
            wa_purchinvlines-supplierinvoice = waheader-SupplierInvoice.
            wa_purchinvlines-supplierinvoiceitem = walines-SupplierInvoiceItem.

            wa_purchinvlines-postingdate = waheader-PostingDate.


            SELECT SINGLE FROM I_IN_BusinessPlaceTaxDetail AS a
                LEFT JOIN  I_Address_2  AS b ON a~AddressID = b~AddressID
                FIELDS
                a~BusinessPlaceDescription,
                a~IN_GSTIdentificationNumber,
                b~Street, b~PostalCode , b~CityName
            WHERE a~CompanyCode = @waheader-CompanyCode AND a~BusinessPlace = @walines-Plant
            INTO ( @wa_purchinvlines-plantname, @wa_purchinvlines-plantgst, @wa_purchinvlines-plantadr, @wa_purchinvlines-plantpin,
                @wa_purchinvlines-plantcity ).

            wa_purchinvlines-product                   = walines-material.
            READ TABLE it_product INTO DATA(wa_product) WITH KEY product = walines-material.
            wa_purchinvlines-productname = wa_product-ProductName.

            wa_purchinvlines-purchaseorder             = walines-PurchaseOrder.
            wa_purchinvlines-purchaseorderitem         = walines-PurchaseOrderItem.

            READ TABLE it_po INTO DATA(wa_po) WITH KEY PurchaseOrder = walines-PurchaseOrder
                                                    PurchaseOrderItem = walines-PurchaseOrderItem.

            wa_purchinvlines-baseunit                  = wa_po-BaseUnit.
            wa_purchinvlines-profitcenter              = wa_po-ProfitCenter.
            wa_purchinvlines-purchaseordertype         = wa_po-PurchaseOrderType.
*            wa_purchinvlines-purchaseorderdate         : wa_po-PurchaseOrderDate.
            wa_purchinvlines-purchasingorganization    = wa_po-PurchasingOrganization.
            wa_purchinvlines-purchasinggroup           = wa_po-PurchasingGroup.

            READ TABLE it_grn INTO DATA(wa_grn) WITH KEY MaterialDocument = walines-ReferenceDocument.
            wa_purchinvlines-mrnquantityinbaseunit     = wa_grn-QuantityInBaseUnit.
*            wa_purchinvlines-mrnpostingdate            = wa_grn-PostingDate;
*            ls_response-grn = wa_it-ReferenceDocument.
*        ls_response-grnyear = wa_it-ReferenceDocumentFiscalYear.

            READ TABLE it_hsn INTO DATA(wa_hsn) WITH KEY plant = walines-Plant Product = walines-Material.
            wa_purchinvlines-hsncode                    = wa_hsn-ConsumptionTaxCtrlCode.
            CLEAR wa_hsn.

            READ TABLE it_tax INTO DATA(wa_tax) WITH KEY TaxCode = walines-TaxCode.
            wa_purchinvlines-taxcodename                = wa_tax-TaxCodeName.

*        wa_purchinvlines-originalreferencedocument : abap.char(20);

            SELECT SINGLE TaxItemAcctgDocItemRef FROM i_operationalacctgdocitem
                WHERE OriginalReferenceDocument = @walines-sinvwithfyear AND TaxItemAcctgDocItemRef IS NOT INITIAL
                AND AccountingDocumentItemType <> 'T'
                AND FiscalYear = @walines-FiscalYear
                AND CompanyCode = @waheader-CompanyCode
                AND AccountingDocumentType = 'RE'
            INTO  @DATA(lv_TaxItemAcctgDocItemRef).

            SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                WHERE OriginalReferenceDocument = @walines-sinvwithfyear
                    AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                    AND AccountingDocumentItemType = 'T'
                    AND FiscalYear = @walines-FiscalYear
                    AND CompanyCode = @waheader-CompanyCode
                    AND TransactionTypeDetermination = 'JII'
            INTO  @wa_purchinvlines-igst.

            IF wa_purchinvlines-igst IS INITIAL.
                SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                    WHERE OriginalReferenceDocument = @walines-sinvwithfyear
                        AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                        AND AccountingDocumentItemType = 'T'
                        AND FiscalYear = @walines-FiscalYear
                        AND CompanyCode = @waheader-CompanyCode
                        AND TransactionTypeDetermination = 'JIC'
                INTO  @wa_purchinvlines-cgst.

                SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                    WHERE OriginalReferenceDocument = @walines-sinvwithfyear
                        AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                        AND AccountingDocumentItemType = 'T'
                        AND FiscalYear = @walines-FiscalYear
                        AND CompanyCode = @waheader-CompanyCode
                        AND TransactionTypeDetermination = 'JIS'
                INTO  @wa_purchinvlines-sgst.
            ENDIF.

*            wa_purchinvlines-igst = ABS( wa_purchinvlines-igst ).
*            wa_purchinvlines-cgst = ABS( wa_purchinvlines-cgst ).
*            wa_purchinvlines-sgst = ABS( wa_purchinvlines-sgst ).

*        wa_purchinvlines-rateigst                  : abap.dec(13,2);
*        wa_purchinvlines-ratecgst                  : abap.dec(13,2);
*        wa_purchinvlines-ratesgst                  : abap.dec(13,2);

            SELECT SINGLE FROM I_JournalEntry
                FIELDS DocumentDate ,
                    DocumentReferenceID ,
                    IsReversed
            WHERE OriginalReferenceDocument = @walines-SupplierInvoice
            INTO (  @wa_purchinvlines-journaldocumentdate , @wa_purchinvlines-journaldocumentrefid, @wa_purchinvlines-isreversed ).

            wa_purchinvlines-pouom                      = walines-PurchaseOrderPriceUnit.
            wa_purchinvlines-poqty                      = walines-QuantityInPurchaseOrderUnit.
            wa_purchinvlines-netamount                  = walines-SupplierInvoiceItemAmount.
            wa_purchinvlines-basicrate                  = ROUND( val = wa_purchinvlines-netamount / wa_purchinvlines-poqty dec = 2 ).

            wa_purchinvlines-taxamount                  = wa_purchinvlines-igst + wa_purchinvlines-sgst +
                                                          wa_purchinvlines-cgst.
            wa_purchinvlines-totalamount                = wa_purchinvlines-taxamount + wa_purchinvlines-netamount.

*        wa_purchinvlines-roundoff                  : abap.dec(13,2);
*        wa_purchinvlines-manditax                  : abap.dec(13,2);
*        wa_purchinvlines-mandicess                 : abap.dec(13,2);
*        wa_purchinvlines-discount                  : abap.dec(13,2);



*       CLEAR wa_price.


            APPEND wa_purchinvlines TO lt_purchinvlines.
            CLEAR : wa_purchinvlines.
            CLEAR : wa_po, wa_grn, wa_hsn, wa_tax, lv_taxitemacctgdocitemref.
        ENDLOOP.
        INSERT zpurchinvlines FROM TABLE @lt_purchinvlines.

        wa_purchinvprocessed-client = SY-MANDT.
        wa_purchinvprocessed-supplierinvoice = waheader-SupplierInvoice.
        wa_purchinvprocessed-companycode = waheader-CompanyCode.
        wa_purchinvprocessed-fiscalyearvalue = waheader-FiscalYear.
        wa_purchinvprocessed-supplierinvoicewthnfiscalyear = waheader-SupplierInvoiceWthnFiscalYear.
        wa_purchinvprocessed-creationdatetime = lv_timestamp.

        APPEND wa_purchinvprocessed TO lt_purchinvprocessed.
        INSERT zpurchinvproc FROM TABLE @lt_purchinvprocessed.
        COMMIT WORK.

        CLEAR :  wa_purchinvprocessed, lt_purchinvprocessed, lt_purchinvlines.
        CLEAR : ltlines, it_product, it_po, it_grn, it_hsn, it_tax.

    ENDLOOP.


  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
      DATA processfrom TYPE d.
      DATA p_simul TYPE abap_boolean.
      DATA assignmentreference TYPE string.


      DATA: lt_purchinvlines TYPE STANDARD TABLE OF zpurchinvlines,
          wa_purchinvlines TYPE zpurchinvlines,
          lt_purchinvprocessed TYPE STANDARD TABLE OF zpurchinvproc,
          wa_purchinvprocessed TYPE zpurchinvproc.

    GET TIME STAMP FIELD DATA(lv_timestamp).

*delete from zpurchinvproc.
*delete from zpurchinvlines.
*COMMIT WORK.

    p_simul = abap_true.
    processfrom = sy-datum - 30.
    IF p_simul = abap_true.
       processfrom = sy-datum - 2000.
    ENDIF.


    SELECT FROM I_SupplierInvoiceAPI01 AS c
        LEFT JOIN i_supplier AS b ON b~supplier = c~InvoicingParty
        FIELDS
            b~Supplier , b~PostalCode , b~BPAddrCityName , b~BPAddrStreetName , b~TaxNumber3,
            b~SupplierFullName, b~region, c~ReverseDocument , c~ReverseDocumentFiscalYear,
            c~CompanyCode , c~PaymentTerms , c~CreatedByUser , c~CreationDate , c~InvoicingParty , c~InvoiceGrossAmount,
            c~DocumentCurrency , c~SupplierInvoiceIDByInvcgParty, c~FiscalYear, c~SupplierInvoice, c~SupplierInvoiceWthnFiscalYear,
            c~DocumentDate, c~PostingDate
        WHERE c~PostingDate >= @processfrom
            AND NOT EXISTS (
               SELECT supplierinvoice FROM zpurchinvproc
               WHERE c~supplierinvoice = zpurchinvproc~supplierinvoice AND
                 c~CompanyCode = zpurchinvproc~companycode AND
                 c~FiscalYear = zpurchinvproc~fiscalyearvalue )
            AND c~supplierinvoice = '5105600237'
            INTO TABLE @DATA(ltheader).

    LOOP AT ltheader INTO DATA(waheader).
*      lv_timestamp = cl_abap_tstmp=>add_to_short( tstmp = lv_timestamp secs = 11111 ).
      get TIME STAMP FIELD lv_timestamp.


* Delete already processed sales line
      delete from zpurchinvlines
        Where zpurchinvlines~companycode = @waheader-CompanyCode AND
        zpurchinvlines~fiscalyearvalue = @waheader-FiscalYear AND
        zpurchinvlines~supplierinvoice = @waheader-SupplierInvoice.



      SELECT FROM I_SuplrInvcItemPurOrdRefAPI01 AS a
        FIELDS
            a~PurchaseOrderItem, a~SupplierInvoiceItem,
            a~PurchaseOrder, a~SupplierInvoiceItemAmount AS tax_amt, a~SupplierInvoiceItemAmount, a~taxcode,
            a~FreightSupplier , a~SupplierInvoice , a~FiscalYear , a~TaxJurisdiction, a~plant,
            a~PurchaseOrderItemMaterial AS material, a~QuantityInPurchaseOrderUnit, a~QtyInPurchaseOrderPriceUnit,
            a~PurchaseOrderQuantityUnit, PurchaseOrderPriceUnit, a~ReferenceDocument , a~ReferenceDocumentFiscalYear
        WHERE a~SupplierInvoice = @waheader-SupplierInvoice
          AND a~FiscalYear = @waheader-FiscalYear
          AND a~SuplrInvcDeliveryCostCndnType = ''
        ORDER BY a~PurchaseOrderItem, a~SupplierInvoiceItem
          INTO TABLE @DATA(ltlines).


*      SELECT FROM I_BillingDocItemPrcgElmntBasic FIELDS BillingDocument , BillingDocumentItem, ConditionRateValue, ConditionAmount, ConditionType
*        WHERE BillingDocument = @waheader-BillingDocument
*        INTO TABLE @DATA(it_price).

        SELECT FROM I_Producttext as a FIELDS
            a~ProductName, a~Product
        FOR ALL ENTRIES IN @ltlines
        WHERE a~Product = @ltlines-material AND a~Language = 'E'
            INTO TABLE @DATA(it_product).

        SELECT FROM I_PurchaseOrderItemAPI01 AS a
            LEFT JOIN I_PurchaseOrderAPI01 AS b ON a~PurchaseOrdeR = b~PurchaseOrder
            FIELDS a~BaseUnit , b~PurchaseOrderType , b~PurchasingGroup , b~PurchasingOrganization ,
            b~PurchaseOrderDate , a~PurchaseOrder , a~PurchaseOrderItem , a~ProfitCenter
        FOR ALL ENTRIES IN @ltlines
        WHERE a~PurchaseOrder = @ltlines-PurchaseOrder AND a~PurchaseOrderItem = @ltlines-PurchaseOrderItem
            INTO TABLE @DATA(it_po).

        SELECT FROM I_MaterialDocumentItem_2
            FIELDS MaterialDocument , PurchaseOrder , PurchaseOrderItem , QuantityInBaseUnit , PostingDate
        FOR ALL ENTRIES IN @ltlines
        WHERE MaterialDocument  = @ltlines-ReferenceDocument
            INTO TABLE @DATA(it_grn).

        SELECT FROM I_taxcodetext
            FIELDS TaxCode , TaxCodeName
        FOR ALL ENTRIES IN @ltlines
        WHERE Language = 'E' AND taxcode = @ltlines-TaxCode
            INTO TABLE @DATA(it_tax).

        LOOP AT ltlines INTO DATA(walines).
            wa_purchinvlines-client = SY-MANDT.
            wa_purchinvlines-companycode = waheader-CompanyCode.
            wa_purchinvlines-fiscalyearvalue = waheader-FiscalYear.
            wa_purchinvlines-supplierinvoice = waheader-SupplierInvoice.
            wa_purchinvlines-supplierinvoiceitem = walines-SupplierInvoiceItem.

            wa_purchinvlines-postingdate = waheader-PostingDate.


            SELECT SINGLE FROM I_IN_BusinessPlaceTaxDetail AS a
                LEFT JOIN  I_Address_2  AS b ON a~AddressID = b~AddressID
                FIELDS
                a~BusinessPlaceDescription,
                a~IN_GSTIdentificationNumber,
                b~Street, b~PostalCode , b~CityName
            WHERE a~CompanyCode = @waheader-CompanyCode AND a~BusinessPlace = @walines-Plant
            INTO ( @wa_purchinvlines-plantname, @wa_purchinvlines-plantgst, @wa_purchinvlines-plantadr, @wa_purchinvlines-plantpin,
                @wa_purchinvlines-plantcity ).

            wa_purchinvlines-product                   = walines-material.
            READ TABLE it_product INTO DATA(wa_product) WITH KEY product = walines-material.
            wa_purchinvlines-productname = wa_product-ProductName.

            wa_purchinvlines-purchaseorder             = walines-PurchaseOrder.
            wa_purchinvlines-purchaseorderitem         = walines-PurchaseOrderItem.
            CONCATENATE walines-SupplierInvoice walines-FiscalYear INTO wa_purchinvlines-originalreferencedocument.

            READ TABLE it_po INTO DATA(wa_po) WITH KEY PurchaseOrder = walines-PurchaseOrder
                                                    PurchaseOrderItem = walines-PurchaseOrderItem.

            wa_purchinvlines-baseunit                  = wa_po-BaseUnit.
            wa_purchinvlines-profitcenter              = wa_po-ProfitCenter.
            wa_purchinvlines-purchaseordertype         = wa_po-PurchaseOrderType.
            wa_purchinvlines-purchaseorderdate         = wa_po-PurchaseOrderDate.
            wa_purchinvlines-purchasingorganization    = wa_po-PurchasingOrganization.
            wa_purchinvlines-purchasinggroup           = wa_po-PurchasingGroup.

            READ TABLE it_grn INTO DATA(wa_grn) WITH KEY MaterialDocument = walines-ReferenceDocument.
            wa_purchinvlines-mrnquantityinbaseunit     = wa_grn-QuantityInBaseUnit.
*            wa_purchinvlines-mrnpostingdate            = wa_grn-PostingDate;
*            ls_response-grn = wa_it-ReferenceDocument.
*        ls_response-grnyear = wa_it-ReferenceDocumentFiscalYear.

            READ TABLE it_tax INTO DATA(wa_tax) WITH KEY TaxCode = walines-TaxCode.
            wa_purchinvlines-taxcodename                = wa_tax-TaxCodeName.


            CONCATENATE walines-PurchaseOrder walines-PurchaseOrderItem INTO assignmentreference.

            SELECT SINGLE TaxItemAcctgDocItemRef, IN_HSNOrSACCode FROM i_operationalacctgdocitem
                WHERE OriginalReferenceDocument = @waheader-SupplierInvoiceWthnFiscalYear AND TaxItemAcctgDocItemRef is not INITIAL
                AND AccountingDocumentItemType <> 'T'
                AND FiscalYear = @walines-FiscalYear
                AND CompanyCode = @waheader-CompanyCode
                AND AccountingDocumentType = 'RE'
                AND AssignmentReference = @assignmentreference
                AND Material = @walines-material
            INTO  (  @DATA(lv_TaxItemAcctgDocItemRef), @DATA(lv_HSNCode) ).
            wa_purchinvlines-hsncode = lv_HSNCode.

            SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                WHERE OriginalReferenceDocument = @waheader-SupplierInvoiceWthnFiscalYear
                    AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                    AND AccountingDocumentItemType = 'T'
                    AND FiscalYear = @walines-FiscalYear
                    AND CompanyCode = @waheader-CompanyCode
                    AND TransactionTypeDetermination = 'JII'
            INTO  @wa_purchinvlines-igst.

            IF wa_purchinvlines-igst IS INITIAL.
                SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                    WHERE OriginalReferenceDocument = @waheader-SupplierInvoiceWthnFiscalYear
                        AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                        AND AccountingDocumentItemType = 'T'
                        AND FiscalYear = @walines-FiscalYear
                        AND CompanyCode = @waheader-CompanyCode
                        AND TransactionTypeDetermination = 'JIC'
                INTO  @wa_purchinvlines-cgst.

                SELECT  SINGLE AmountInCompanyCodeCurrency FROM i_operationalacctgdocitem
                    WHERE OriginalReferenceDocument = @waheader-SupplierInvoiceWthnFiscalYear
                        AND TaxItemAcctgDocItemRef = @lv_TaxItemAcctgDocItemRef
                        AND AccountingDocumentItemType = 'T'
                        AND FiscalYear = @walines-FiscalYear
                        AND CompanyCode = @waheader-CompanyCode
                        AND TransactionTypeDetermination = 'JIS'
                INTO  @wa_purchinvlines-sgst.
            ENDIF.

""""""""""""""""""""""""""""""""""""""""""""""""for rate percent.
            wa_purchinvlines-rateigst   = 0.
            wa_purchinvlines-ratecgst   = 0.
            wa_purchinvlines-ratesgst   = 0.

            IF walines-TaxCode = 'L0'.
                wa_purchinvlines-ratecgst   = 3.
                wa_purchinvlines-ratesgst   = 3.
            ELSEIF walines-TaxCode = 'I0'.
                wa_purchinvlines-rateigst   = 3.
            ELSEIF walines-TaxCode = 'L5'.
                wa_purchinvlines-ratecgst   = 5.
                wa_purchinvlines-ratesgst   = 5.
            ELSEIF walines-TaxCode = 'I1'.
                wa_purchinvlines-rateigst   = 5.
            ELSEIF walines-TaxCode = 'L2'.
                wa_purchinvlines-ratecgst   = 6.
                wa_purchinvlines-ratesgst   = 6.
            ELSEIF walines-TaxCode = 'I2'.
                wa_purchinvlines-rateigst   = 12.
            ELSEIF walines-TaxCode = 'L3'.
                wa_purchinvlines-ratecgst   = 9.
                wa_purchinvlines-ratesgst   = 9.
            ELSEIF walines-TaxCode = 'I3'.
                wa_purchinvlines-rateigst   = 18.
            ELSEIF walines-TaxCode = 'L4'.
                wa_purchinvlines-ratecgst   = 14.
                wa_purchinvlines-ratesgst   = 14.
            ELSEIF walines-TaxCode = 'I4'.
                wa_purchinvlines-rateigst   = 28.
            ELSEIF walines-TaxCode = 'F5'.
                wa_purchinvlines-ratecgst   = 9.
                wa_purchinvlines-ratesgst   = 9.
            ELSEIF walines-TaxCode = 'H5'.
                wa_purchinvlines-ratecgst   = 9.
                wa_purchinvlines-ratesgst   = 9.
                wa_purchinvlines-rateigst   = 18.
            ELSEIF walines-TaxCode = 'H6'.
                wa_purchinvlines-ratecgst   = 9.
*               ls_response-Ugstrate = '9'.
*               wa_purchinvlines-CESSRate = '18'.
            ELSEIF walines-TaxCode = 'H4'.
                wa_purchinvlines-rateigst   = 18.
*               ls_response-Ugstrate = '9'.
*               ls_response-CESSRate = '18'.
            ELSEIF walines-TaxCode = 'H3'.
                wa_purchinvlines-ratecgst   = 9.
*               ls_response-Ugstrate = '9'.
*               LS_RESPONSE-CESSRate = '18'.
            ELSEIF walines-TaxCode = 'J3'.
                wa_purchinvlines-ratecgst   = 9.
*               ls_response-Ugstrate = '9'.
*               LS_RESPONSE-CESSRate = '18'.
            ELSEIF walines-TaxCode = 'G6'.
                wa_purchinvlines-rateigst   = 18.
*               ls_response-Ugstrate = '9'.
*               ls_response-CESSRate = '18'.
            ELSEIF walines-TaxCode = 'G7'.
                wa_purchinvlines-ratecgst   = 9.
                wa_purchinvlines-ratesgst   = 9.
*               ls_response-CESSRate = '18'.
            ENDIF.

            SELECT SINGLE FROM I_JournalEntry
                FIELDS DocumentDate ,
                    DocumentReferenceID ,
                    IsReversed
            WHERE OriginalReferenceDocument = @walines-SupplierInvoice
            INTO (  @wa_purchinvlines-journaldocumentdate , @wa_purchinvlines-journaldocumentrefid, @wa_purchinvlines-isreversed ).

            wa_purchinvlines-pouom                      = walines-PurchaseOrderPriceUnit.
            wa_purchinvlines-poqty                      = walines-QuantityInPurchaseOrderUnit.
            wa_purchinvlines-netamount                  = walines-SupplierInvoiceItemAmount.
            wa_purchinvlines-basicrate                  = ROUND( val = wa_purchinvlines-netamount / wa_purchinvlines-poqty dec = 2 ).

            wa_purchinvlines-taxamount                  = wa_purchinvlines-igst + wa_purchinvlines-sgst +
                                                          wa_purchinvlines-cgst.
            wa_purchinvlines-totalamount                = wa_purchinvlines-taxamount + wa_purchinvlines-netamount.

            SELECT FROM I_SuplrInvcItemPurOrdRefAPI01 AS a
            FIELDS
                a~PurchaseOrderItem, a~SupplierInvoiceItem,a~SuplrInvcDeliveryCostCndnType,
                a~PurchaseOrder, a~SupplierInvoiceItemAmount, a~taxcode,
                a~FreightSupplier
            WHERE a~SupplierInvoice = @waheader-SupplierInvoice
              AND a~FiscalYear = @waheader-FiscalYear
              AND a~PurchaseOrderItem = @walines-PurchaseOrderItem
              AND a~SuplrInvcDeliveryCostCndnType <> ''
              INTO TABLE @DATA(ltsublines).

            wa_purchinvlines-discount       = 0.
            wa_purchinvlines-freight        = 0.
            wa_purchinvlines-insurance      = 0.
            wa_purchinvlines-ecs            = 0.
            wa_purchinvlines-epf            = 0.
            wa_purchinvlines-othercharges   = 0.
            wa_purchinvlines-packaging      = 0.
            LOOP AT ltsublines INTO DATA(wasublines).
                if wasublines-SuplrInvcDeliveryCostCndnType = 'FGW1'.
*                   Freight
                    wa_purchinvlines-freight += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'FQU1'.
*                   Freight
                    wa_purchinvlines-freight += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'FVA1'.
*                   Freight
                    wa_purchinvlines-freight += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZDIN'.
*                   Insurance Value
                    wa_purchinvlines-insurance += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZINS'.
*                   Insurance Value
                    wa_purchinvlines-insurance += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZECS'.
*                   ECS
                    wa_purchinvlines-ecs += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZEPF'.
*                   EPF
                    wa_purchinvlines-epf += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZOTH'.
*                   Other Charges
                    wa_purchinvlines-othercharges += wasublines-SupplierInvoiceItemAmount.
                ELSEIF wasublines-SuplrInvcDeliveryCostCndnType = 'ZPKG'.
*                   Packaging & Forwarding Charges
                    wa_purchinvlines-packaging += wasublines-SupplierInvoiceItemAmount.
                ELSE.
                    wa_purchinvlines-othercharges += wasublines-SupplierInvoiceItemAmount.
                ENDIF.
            ENDLOOP.

            wa_purchinvlines-totalamount    = wa_purchinvlines-taxamount + wa_purchinvlines-netamount + wa_purchinvlines-freight +
                                              wa_purchinvlines-insurance + wa_purchinvlines-ecs +
                                              wa_purchinvlines-epf + wa_purchinvlines-othercharges +
                                              wa_purchinvlines-packaging.

*       CLEAR wa_price.


            APPEND wa_purchinvlines TO lt_purchinvlines.
            CLEAR : wa_purchinvlines.
            CLEAR : wa_po, wa_grn, wa_tax, lv_taxitemacctgdocitemref.
        ENDLOOP.

        INSERT zpurchinvlines FROM TABLE @lt_purchinvlines.

        wa_purchinvprocessed-client = SY-MANDT.
        wa_purchinvprocessed-supplierinvoice = waheader-SupplierInvoice.
        wa_purchinvprocessed-companycode = waheader-CompanyCode.
        wa_purchinvprocessed-fiscalyearvalue = waheader-FiscalYear.
        wa_purchinvprocessed-supplierinvoicewthnfiscalyear = waheader-SupplierInvoiceWthnFiscalYear.
        wa_purchinvprocessed-creationdatetime = lv_timestamp.

        APPEND wa_purchinvprocessed TO lt_purchinvprocessed.
        INSERT zpurchinvproc FROM TABLE @lt_purchinvprocessed.
        COMMIT WORK.

        CLEAR :  wa_purchinvprocessed, lt_purchinvprocessed, lt_purchinvlines.
        CLEAR : ltlines, it_product, it_po, it_grn, it_tax.

    ENDLOOP.

*    SELECT * FROM zbillinglines
*               INTO TABLE @DATA(it).
*    LOOP AT it INTO DATA(wa1).
*      out->write( data = 'Data : client -' ) .
*      out->write( data = wa1-client ) .
*      out->write( data = '- bukrs-' ) .
*      out->write( data = wa1-materialdescription ) .
*      out->write( data = '- doc-' ) .
*      out->write( data = wa1-billingdocument ) .
*      out->write( data = '- item -' ) .
*      out->write( data = wa1-billingdocumentitem ) .
*    endloop.


  ENDMETHOD.
ENDCLASS.
