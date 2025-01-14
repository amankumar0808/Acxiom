@EndUserText.label: 'I_OperationalAcctgDocItem CDS'
@Search.searchable: false
@ObjectModel.query.implementedBy: 'ABAP:ZCL_ACCT_PRINT'
@UI.headerInfo: {typeName: 'VOUCHER PRINT'}
define view entity ZCDS_ACCO as select from I_OperationalAcctgDocItem
{
     @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:1 }] 
     @UI.lineItem   : [{ position:1, label:'Accounting Document' }] 
    key AccountingDocument,
     @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:2 }] 
     @UI.lineItem   : [{ position:2, label:'Company Code' }] 
    key CompanyCode,

     @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:3 }] 
     @UI.lineItem   : [{ position:3, label:'Fiscal Year' }] 
    key FiscalYear,
     @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:4 }] 
     @UI.lineItem   : [{ position:4, label:'Accounting Document Item' }] 
    key AccountingDocumentItem,
    
     @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:5}] 
     @UI.lineItem   : [{ position:5, label:'Accounting DocumentType' }] 
    AccountingDocumentType,  
     
     @UI.lineItem   : [{ position:5.2, label:'Document Item Text' }] 
    DocumentItemText,
    
      @Search.defaultSearchElement: true     
     @UI.selectionField   : [{ position:5.5}] 
     @UI.lineItem   : [{ position:5.5, label:' Document Date' }] 
    DocumentDate,   
     @UI.lineItem   : [{ position:6, label:'Clearing Date' }] 
    ClearingDate,
     @UI.selectionField   : [{ position:8}] 
     @UI.lineItem   : [{ position:8, label:'GL Account' }] 
    GLAccount,  
    Customer,   
    Supplier, 
     
      @UI.lineItem   : [{ position:10, label:'Transactional Type Determination' }]  
    TransactionTypeDetermination,
    @Semantics.amount.currencyCode: 'curr'  
     @UI.lineItem   : [{ position:9, label:'Amount In CompanyCode Currency' }]  
    AmountInCompanyCodeCurrency,
    CompanyCodeCurrency as curr,
    /* Associations */
    _CompanyCode,
    _CompanyCodeCurrency,  
    _Customer,
    _CustomerCompany,
    _CustomerText,
    _FiscalYear, 
    _GLAccountInCompanyCode,  
    _JournalEntry,
    _JournalEntryItemOneTimeData, 
    /*_OneTimeAccountBP,*/
     _Supplier,
    _SupplierCompany,
    _SupplierText
   
}
