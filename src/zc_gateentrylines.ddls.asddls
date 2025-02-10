@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Gate Entry Lines Projection View'
@ObjectModel.semanticKey: [ 'Gateitemno' ]
@Search.searchable: true
define view entity ZC_GateEntryLines 
  as projection on ZR_GateEntryLines as GateEntryLines
{
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.90 
    key Gateentryno,
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.90 
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
    @Semantics.unitOfMeasure: true
    @Consumption.valueHelpDefinition: [ {
      entity: {
        name: 'I_UnitOfMeasure', 
        element: 'UnitOfMeasure'
      }, 
      useForValidation: true
    } ]
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
    _GateEntryHeader : redirected to parent ZC_GateEntryHeader
}
