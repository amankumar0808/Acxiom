@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Gate Entry Header Projection View'
@ObjectModel.semanticKey: [ 'Gateentryno' ]
@Search.searchable: true
define root view entity ZC_GateEntryHeader 
  provider contract transactional_query
  as projection on ZR_GateEntryHeader as GateEntryHeader
{
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.90 
    @UI.connectedFields: [{label: 'Token Number'}]
    key Gateentryno,
    @UI.connectedFields: [{label: 'Entry Date'}]
    Entrydate,
    Plant,
    Gateoutward,
    Entrytype,
    Gateentrytypedesc,
    Operatorname,
    Transportmode,
    Grdate,
    Grno,
    Vehicleno,
    Vehrepdate,
    Vehreptime,
    Gateindate,
    Gateintime,
    Transportername,
    Drivername,
    Driverlicenseno,
    Driverno,
    Gateoutdate,
    Gateouttime,
    Remarks,
    Grosswt,
    Tarewt,
    Netwt,
    Slipno,
    Totallines,
    Cancelled,
    Invoiceno,
    Invoicedate,
    Lrno,
    Lrdate,
    Gateno,
    Billamount,   
    Purpose,
    Weighbridgereq,
    Preweight,
    Presamplereq,
    Vehiclergnno,
    Insurancevalidity,
    Insuranceno,
    Pucvalidity,
    Pucno,
    Carryingcapacity,
    Transporterbulitylr,
    Looseiteminbody,
    Looseitemincabn,
    Fcno,
    Fcvalidity,
    Alcoholconditiondriver,
    Stocktransferinv,
    Refdocno,
    Wbrgslipno,
    Supewaybillno,
    Supdlchallan, 
    Stocktransferchallan,
    Vehicleinsurance,
    Vehiclerc,
    Vehiclepuc,
    Drvierlicense,
    Transporterlr,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_GATETIMEDIFF'
    @EndUserText.label: 'Time Difference'
    virtual Timedifference : abap.int2,
    /* Associations */
    _GateEntryLines : redirected to composition child ZC_GateEntryLines
  
}
