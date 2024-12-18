import { LightningElement, api, track, wire } from 'lwc';
import getShipments from '@salesforce/apex/ShipmentController.getShipments';
import getOrderProducts from '@salesforce/apex/ShipmentController.getOrderProducts';
import createShipmentItems from '@salesforce/apex/ShipmentController.createShipmentItems';
import createShipment from '@salesforce/apex/ShipmentController.createShipment';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateOrderItems from '@salesforce/apex/ShipmentController.updateOrderItems';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import SHIPMENT_OBJECT from '@salesforce/schema/Shipment';
import PROVIDER_FIELD from '@salesforce/schema/Shipment.Provider';

import getDealerInfoOnOrder from '@salesforce/apex/ShipmentController.getDealerInfoOnOrder';

export default class ShipmentCreation extends LightningElement {
    @api recordId; // Passed from the standard action
    @track orderId;

    @track shipments = [];
    @track orderProducts = [];
    @track selectedOrderProductIds = [];
    @track shipmentId;
    @track picklistValues = [];
    @track selectedProvider = '';
    @track error;

    wiredOrderProductsResult; 
    showShipmentForm = true;
    showShipmentList = false;
    showOrderItems = false;
    ShipmentInformation = {};
    newdata;
    value;
    wiredDealerDetails;
    dealerOrderInfo = [];



    @wire(getDealerInfoOnOrder, { orderId: '$recordId' })
          wiredOrderProducts(result) {
    this.wiredDealerDetails = result; // Store the result for refreshApex
    if (result.data && result.data.length > 0) {
        const contact = result.data[0].Contact__r || {}; // Assuming the first record's contact details
        this.dealerName = contact.Name || '';
        this.dealerPhone = contact.Phone || '';
        this.dealerEmail = contact.Email || '';
    } else if (result.error) {
        console.error('Error fetching order products:', result.error);
    }
}


        // Fetch object info to get the default record type ID
        @wire(getObjectInfo, { objectApiName: SHIPMENT_OBJECT })
        objectInfo;
    
        // Fetch picklist values for the Provider field
        @wire(getPicklistValues, {
            recordTypeId: '$objectInfo.data.defaultRecordTypeId',
            fieldApiName: PROVIDER_FIELD
        })
        wiredPicklistValues({ error, data }) {
            if (data) {
                this.picklistValues = data.values;
                this.error = undefined;
                this.value = data.values[3].value; //to set default picklist values
            } else if (error) {
                this.error = error;
                this.picklistValues = [];
            }
        }
    
        handlePicklistChange(event) {
            this.selectedProvider = event.detail.value;
            this.ShipmentInformation.Provider = this.selectedProvider;
            console.log('Selected Provider:', this.selectedProvider);
        }

    
    handleShipmentSuccess(event) {
        debugger;
        this.shipmentId = event.detail.id;
        console.log('Shipment ID: ' + this.shipmentId);
    }

    handleShipmentFieldChange(event) {
        debugger;
        const fieldName = event.target.fieldName;
        const fieldValue = event.target.value;
        this.ShipmentInformation[fieldName] = fieldValue;
        
        var tempObj = this.ShipmentInformation;
    }
  
    // Navigate to the Shipment List
    handleGetShipmentRecord() {
        this.showShipmentForm = false;
        this.showShipmentList = true;
        this.fetchShipments();
    }

    handleNext() {
        let allValid = true;
    
        // Validate "Provider" field explicitly
        // if (!this.selectedProvider) {
        //     allValid = false;
    
        //     // Show a toast message if Provider is not selected
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Error',
        //             message: 'Please fill out all required fields.',
        //             variant: 'error'
        //         })
        //     );
        // }
    
        // Validate all other input fields in the form
        const inputFields = this.template.querySelectorAll('lightning-input-field, lightning-combobox');
        inputFields.forEach(field => {
            if (!field.reportValidity()) {
                allValid = false;
            }
        });
    
        // If all validations pass, proceed to the next screen
        if (allValid) {
            this.showShipmentForm = false;
            this.showOrderItems = true;
            this.fetchOrderProducts(); // Existing functionality
        }
    }
    

    // Navigate back to the Shipment Form
    handleBackToForm() {
        this.showShipmentForm = true;
        this.showShipmentList = false;
        this.showOrderItems = false;
    }

    debugger;
    // Fetch Shipments
    fetchShipments() {
        getShipments()
            .then(data => {
                this.shipments = data;
            })
            .catch(error => {
                console.error('Error fetching shipments:', error);
            });
    }

            @wire(getOrderProducts, { orderId: '$recordId' })
            wiredOrderProducts(result) {
                this.wiredOrderProductsResult = result; // Store the result for refreshApex
                if (result.data) {
                    this.orderProducts = result.data.map(item => ({
                        ...item,
                        productName: item.Product2 ? item.Product2.Name : '',
                        shippedQuantity: item.Shipped_Quantity__c,
                        outstandingQuantity: item.Outstanding_Quantity__c,
                        enteredQuantity: 0, // Default to existing quantity
                        selected: false, // Default to not selected
                        disabled: true
                    }));
                    console.log('Order Products fetched:', JSON.stringify(this.orderProducts));
                } else if (result.error) {
                    console.error('Error fetching order products:', result.error);
                }
            }
        
            // Refresh Apex when needed
            handleRefresh() {
                refreshApex(this.wiredOrderProductsResult)
                    .then(() => {
                        console.log('Order products refreshed successfully.');
                    })
                    .catch(error => {
                        console.error('Error refreshing order products:', error);
                    });
            }

    // Capture selected Order Items
    handleRowSelection(event) {
       
        this.selectedOrderProductIds = event.detail.selectedRows.map(row => row.Id);
    }


handleSelectAll(event) {
    const isChecked = event.target.checked;
    this.orderProducts = this.orderProducts.map((product, i) => {
        if (i === parseInt(index, 10)) {
            return {
                ...product,
                selected: event.target.checked,
                disabled: !event.target.checked // Update the disabled state
            };
        }
        return product;
    });
}

handleProductSelection(event) {
    const index = event.target.dataset.index;
    
    this.orderProducts = this.orderProducts.map((product, i) => {
        if (i === parseInt(index, 10)) {
            return {
                ...product,
                selected: event.target.checked,
                disabled: !event.target.checked // Update the disabled state
            };
        }
        return product;
    });
    
}

handleQuantityChange(event) {
    // Get the index and the new value from the event
    const index = event.target.dataset.index;
    const value = parseFloat(event.target.value) || 0;
    
    const product = this.orderProducts[index];
    // Ensure the value is at least 1
    const newQuantity = value < 1 ? 0 : value;

    if (value > product.outstandingQuantity) {
        this.showToast('Error', `Entered quantity cannot exceed Outstanding Quantity (${product.outstandingQuantity}).`, 'error');
        event.target.value = product.outstandingQuantity; // Reset to max allowed value
        return;
    }

    // Create a new array with updated quantities
    this.orderProducts = this.orderProducts.map((product, i) => {
        if (i === parseInt(index, 10)) {
            return {
                ...product,
                enteredQuantity: newQuantity
            };
        }
        return product;
    });

   // If the value was invalid, reset the input field to the minimum value
    if (value < 1) {
        event.target.value = 0;
    }
}


 handleSave() {
        const selectedProducts = this.orderProducts.filter(product => product.selected);

        if (!selectedProducts.length) {
            this.showToast('Error', 'Please select at least one product.', 'error');
            return;
        }

            // Validation for enteredQuantity
    const invalidProduct = selectedProducts.find(product => 
        product.enteredQuantity > product.Outstanding_Quantity__c
    );

    if (invalidProduct) {
        this.showToast('Error', `Entered quantity for product ${invalidProduct.Name} exceeds the outstanding quantity.`, 'error');
        return;
    }
        const updates = selectedProducts.map(product => {
        return {
            Id: product.Id,
        
            Shipped_Quantity__c: (product.shippedQuantity || 0) + product.enteredQuantity
        };
        });

        const selectedOrderProductIds = selectedProducts.map(product => product.Id);
        const quantities = selectedProducts.map(product => product.enteredQuantity);

        createShipment({ orderId: this.recordId, shipment: this.ShipmentInformation })
            .then((shipmentId) => {
                console.log('Shipment created successfully:', shipmentId);
                this.shipmentId = shipmentId;

                return createShipmentItems({
                    shipmentId: shipmentId,
                    orderProductIds: selectedOrderProductIds,
                    quantities: quantities
                });
            })
            .then(() => {
            return updateOrderItems({ updates });
        })
            .then(() => {
                this.showToast('Success', 'Shipment Items created successfully.', 'success');

                 this.showOrderItems = false;
                this.showShipmentForm = true;

                return refreshApex(this.wiredOrderProductsResult);
            })
            .catch((error) => {
                this.showToast('Error', `Error: ${error.body ? error.body.message : error.message}`, 'error');
            });
    }

    // Helper method to show toast messages
     showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }

}