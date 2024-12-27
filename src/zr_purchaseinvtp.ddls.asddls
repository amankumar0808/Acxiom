@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'CDS View forpurchaseinv'
define root view entity ZR_purchaseinvTP
  as select from ZPURCHINVPROC as purchaseinv
  composition [0..*] of ZR_purchaselineTP as _purchaseline
{
  key COMPANYCODE as Companycode,
  key FISCALYEARVALUE as Fiscalyearvalue,
  key SUPPLIERINVOICE as Supplierinvoice,
  SUPPLIERINVOICEWTHNFISCALYEAR as Supplierinvoicewthnfiscalyear,
  @Semantics.systemDateTime.createdAt: true
  CREATIONDATETIME as Creationdatetime,
  _purchaseline
  
}
