/**
 * @author Dinesh Baddawar
 * @email dinesh.butilitarianlab@gmail.com
 * @create date 2024-12-10 11:00:42
 * @modify date 2024-12-17 14:31:32
 * @desc [Component to update Receive GRN]
 */

import getPOrelatedPLI from '@salesforce/apex/ProductRequestLineController.getPOrelatedPLI';
import TransferReceiveGRNToProductTransfer from '@salesforce/apex/ProductRequestLineController.TransferReceiveGRNToProductTransfer';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track, wire } from 'lwc';
export default class BulkrecieveGRN extends LightningElement {
    @api recordId;
    @track requestLineItems = [];
    @track updatedValues = new Map(); 
    @track selectAllChecked = false; 
    showSpinner = false;
    connectedCallback(){
        this.recordId = this.recordId;
    }

    @wire(getPOrelatedPLI, { recordId: '$recordId' })
    wiredProductRequestItems({ error, data }) {
        if (data) {
            debugger;
            this.requestLineItems = data.map((res) => ({
                Id: res.Id,
                Name: res.Product2?.Name,
                ProductName: res.Product2?.Name || 'N/A',
                Product2Id: res.Product2?.Id || null,
                QuantityRequested: res.Quantity,
                ShipmentId: res.ShipmentId,
                DestinationLocationId : res.Shipment.DestinationLocationId,
                SourceLocationId : res.Shipment.SourceLocationId,
                RecievedQuantity : res.Received_Quantity__c,
                selected: false,
                isChargesDisabled: true,
            }));
            this.showSpinner = false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.requestLineItems = [];
            console.error('Error fetching product request items == >', error);
        }
    }

      handleInputChange(event) {
        debugger;
        const rowId = event.target.dataset.id;
        const updatedValue = event.target.value; 
        this.updatedValues.set(rowId, updatedValue); 
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
        this.requestLineItems = this.requestLineItems.map(item => ({
            ...item,
            selected: isChecked,
            isChargesDisabled: !isChecked 
        }));
    }

    handleCheckboxChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.requestLineItems = this.requestLineItems.map(item => {
            if (item.Id === itemId) {
                return {
                    ...item,
                    selected: isChecked,
                    isChargesDisabled: !isChecked 
                };
            }
            return item;
        });
        this.selectAllChecked = this.requestLineItems.every(item => item.selected);
    }

    handleUpdateProcess() {
        debugger;
        this.showSpinner = true;
        const invalidItems = [];
        const updatedItems = Array.from(this.updatedValues.entries()).map(([id, value]) => {
            const item = this.requestLineItems.find(item => item.Id === id);
            if (parseFloat(value) > item.QuantityRequested) {
                invalidItems.push(item.Name); 
            }
            return {
                Id: id,
                Received_Quantity__c: parseFloat(value),
                Product2Id: item?.Product2Id,
                ShipmentId : item?.ShipmentId,
                DestinationLocationId : item?.DestinationLocationId,
                SourceLocationId : item?.SourceLocationId
            };
        });
    
        if (invalidItems.length > 0) {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: `Shipped Quantity cannot be higher than Allocated Quantity for: ${invalidItems.join(', ')}`,
                    variant: 'error'
                })
            );
            return; 
        }
    
        TransferReceiveGRNToProductTransfer({ updatedItems })
            .then((result) => {
                if (result === 'SUCCESS') {
                    debugger;
                    this.showSpinner = false;
                    // setTimeout(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'SUCCESS',
                                message: 'Records updated successfully',
                                variant: 'success'
                            })
                        );
                        this.updatedValues.clear();
                        this.dispatchEvent(new CloseActionScreenEvent());
                       // window.location.replace(`/lightning/r/ProductRequest/`+this.recordId+'/view');
                    // }, 2000);
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error updating records: ' + result,
                            variant: 'error'
                        })
                    );
                }
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating records: ' + error.body.message,
                        variant: 'error'
                    })
                );
                console.error('Error updating records:', error);
            });
    }
}