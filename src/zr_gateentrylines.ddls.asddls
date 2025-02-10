@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Entry Lines CDS'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_GateEntryLines as select from zgateentrylines as GateEntryLines
association to parent ZR_GateEntryHeader as _GateEntryHeader on $projection.Gateentryno = _GateEntryHeader.Gateentryno
{
    key gateentryno as Gateentryno,
    key gateitemno as Gateitemno,
    plant as Plant,
    sloc as Sloc,
    vendorcode as Vendorcode,
    vendorname as Vendorname,
    vendorcity as Vendorcity,
    customercode as Customercode,
    customername as Customername,
    productcode as Productcode,
    productdesc as Productdesc,
    entrytype as Entrytype,
    documentno as Documentno,
    documentitem as Documentitem,
    documentqty as Documentqty,
    uom as Uom,
    gateqty as Gateqty,
    gatevalue as Gatevalue,
    billedparcelqy as Billedparcelqy,
    itemwt as Itemwt,
    insplot as Insplot,
    qualityok as Qualityok,
    matsno as Matsno,
    remarks as Remarks,
    _GateEntryHeader

}
