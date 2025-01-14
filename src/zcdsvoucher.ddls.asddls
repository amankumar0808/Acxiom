@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'zcdsVoucher'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zcdsVoucher as select from I_OperationalAcctgDocItem as a
left outer join I_GLAccountTextRawData as b on a.GLAccount = b.GLAccount
left outer join I_CostCenterText as c on a.CostCenter =  c.CostCenter and c.Language = 'E'
left outer join I_ProfitCenterText as d on a.ProfitCenter = d.ProfitCenter and d.Language = 'E'
{
    key a.CompanyCode,
    key a.AccountingDocument,
    key a.FiscalYear,
    key a.AccountingDocumentItem,
    a.GLAccount,
    @Semantics.amount.currencyCode: 'curr'   
   a.AmountInCompanyCodeCurrency ,
   a.CompanyCodeCurrency as curr,
   a.DocumentItemText,
   a.TransactionTypeDetermination,
   b.GLAccountName,
   c.CostCenter,
   c.CostCenterName,
   d.ProfitCenter,
   d.ProfitCenterName,
    /* Associations */
    
    a._CompanyCode,
    a._FiscalYear,
    a._GLAccountInCompanyCode,
    a._JournalEntry,
    a._JournalEntryItemOneTimeData,
    a._OneTimeAccountBP
}
