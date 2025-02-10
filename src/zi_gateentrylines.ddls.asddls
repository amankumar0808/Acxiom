@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Entry Lines Interface View'
define view entity ZI_GateEntryLines 
  as projection on ZR_GateEntryLines as GateEntryLines
{    
    key Gateentryno,
    key Gateitemno,
    Plant,
    Sloc,
    Vendorcode,
    Vendorname,
    Vendorcity,
    Customercode,
    Customername,
    Productcode,
    Productdesc,
    Entrytype,
    Documentno,
    Documentitem,
    Documentqty,
    Uom,
    Gateqty,
    Gatevalue,
    Billedparcelqy,
    Itemwt,
    Insplot,
    Qualityok,
    Matsno,
    Remarks,
    /* Associations */
    _GateEntryHeader : redirected to parent ZI_GateEntryHeader

}
