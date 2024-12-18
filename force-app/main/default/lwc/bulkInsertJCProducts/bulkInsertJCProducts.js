import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import getRelatedWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.getRelatedWorkOrderLineItems';
import getDynamicValues from '@salesforce/apex/AdditionalJobsRecommendedController.getDynamicValues';
import { getRecord } from "lightning/uiRecordApi";
import Status from "@salesforce/schema/WorkOrder.Status";
import getWarrantyForJobCard from '@salesforce/apex/WorkOrderLineItemController.getWarrantyForJobCard';





export default class BulkInsert_JCProducts extends NavigationMixin(LightningElement) {

    @api recordId;
    keyIndex = 0;
    showProducts = true;
    showSubmitButton = true;
    showAddMoreButton = false;
    existingWorkOrderLineItems = [];
    @track itemList = [
        {
            id: 0,
            price: 0,
            hasError: false
        }
    ];

    @track warrantyId;
    @track showAll;
    @track showRow = false;
    @track partCategory = '';
    @track replacementType = '';
    @track picklistOptions = {};
    @track showAdditionalFields = false;
    @track showVideofield = false;

    connectedCallback() {
        debugger;
        this.fetchWarranty();
    }
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [Status],
    })
    wiredWorkOrder({ error, data }) {
        if (data && data.fields.Status.value == 'Completed') {
            this.showAll = false;
        }
        else if (data) {
            this.showAll = true;
        }
    }

    fetchWarranty() {
        getWarrantyForJobCard({ workOrderId: this.recordId })
            .then(result => {
                this.warrantyId = result;
                console.log('Fetched Warranty ID: ', this.warrantyId);
            })
            .catch(error => {
                console.error('Error fetching Warranty ID:', error);
            });
    }

    toggleTemplates() {
        this.clearRows();
        this.showAll = !this.showAll;
        this.showRow = !this.showRow;
        this.showAdditionalFields = false;
        this.showVideofield = false;
        this.template.querySelectorAll('lightning-record-edit-form').forEach(form => {
            form.reset();
        });
    }
    // Columns definition for Lightning Datatable
    columns = [
        {
            label: 'Part No',
            fieldName: 'partUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Labour Code',
            fieldName: 'labourUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Labour_Name__c' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Product',
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'RR_Product__c' },
                target: '_blank'
            },
            sortable: true
        },

        { label: 'Quantity', fieldName: 'Quantity', type: 'Number' },
        { label: 'Parts Category', fieldName: 'RR_Parts_Category__c', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' }
        /* { label: 'FFIR Number', fieldName: 'FFIR_Number__c', type: 'text' },
         { label: 'Photos', fieldName: 'Photos__c', type: 'text' },
         { label: 'Replacement Type', fieldName: 'Replacement_Type__c', type: 'text' },
         { label: 'Videos', fieldName: 'Videos__c', type: 'text' }*/

    ];
    refreshResultData;

    @wire(getRelatedWorkOrderLineItems, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        this.refreshResultData = result
        if (result.data) {
            console.log('data received1>>', result.data);

            this.existingWorkOrderLineItems = result.data.map(Lineitem => {
                const nameUrl = Lineitem.Id ? `/${Lineitem.Id}` : '';
                const labourUrl = Lineitem.Labour_Code__c ? `/${Lineitem.Labour_Code__c}` : '';
                const productUrl = Lineitem.PricebookEntry && Lineitem.PricebookEntry.Product2Id ? `/${Lineitem.PricebookEntry.Product2Id}` : '';
                return {
                    WorkOrderId: Lineitem.WorkOrder ? Lineitem.WorkOrder.WorkOrderNumber : '',
                    RR_Product__c: Lineitem.PricebookEntryId ? Lineitem.PricebookEntry.Product2.Name : '',
                    Quantity: Lineitem.Quantity,
                    RR_Parts_Category__c: Lineitem.RR_Parts_Category__c,
                    Status: Lineitem.Status,
                    Name: Lineitem.LineItemNumber,
                    partUrl: nameUrl,
                    productUrl: productUrl,
                    labourUrl:labourUrl,
                    Labour_Name__c: Lineitem.Labour_Code__r ? Lineitem.Labour_Code__r.Name : '',
                    FFIR_Number__c: Lineitem.FFIR_Number__c,
                    Photos__c: Lineitem.Photos__c,
                    Replacement_Type__c: Lineitem.Replacement_Type__c,
                    Videos__c: Lineitem.Videos__c,
                };
            });

        } else if (result.error) {
            console.error('Error fetching Work Plans:', result.error);
        }
    }

    handlepicklistchange(event) {
        const selectedValue = event.target.value;
        const fieldName = event.target.dataset.fieldname;
        const index = parseInt(event.target.dataset.id, 10);
        if (fieldName === 'RR_Parts_Category__c') {

            if (selectedValue === 'River Warranty') {
                this.itemList[index].showAdditionalFields = true;

            } else {
                this.itemList[index].showAdditionalFields = false;
            }
        } else if (fieldName === 'Replacement_Type__c') {

            if (selectedValue === 'Causal') {
                this.itemList[index].showVideofield = true;
            } else {
                this.itemList[index].showVideofield = false;
            }

        }
    }



    addRow(event, index) {
        index = parseInt(event.target.dataset.id, 10);
        ++this.keyIndex;
        let newItem = { id: this.keyIndex, code: '', showAdditionalFields: false, showVideofield: false };
        this.itemList.splice(index + 1, 0, newItem);

        console.log('add rows>>' + JSON.stringify(newItem));
    }

    handleAddMore() {
        // Clear the itemList
        this.itemList = [];
        this.clearRows();
        // Add a new record with an incremented id
        let newId = this.keyIndex + 1;
        let newItem = { id: newId, price: 0, hasError: false, showAdditionalFields: false, showVideofield: false };
        this.itemList.push(newItem);

        // Update keyIndex and button visibility
        this.keyIndex = newId;
        this.showSubmitButton = true;
        this.showAddMoreButton = false;
        this.showAdditionalFields = false;
        this.showVideofield = false;

    }

    handleProductSelection(event) {
        const index = event.target.dataset.id;
        const productId = event.target.value;
    }

    handleLabourSelection(event) {
        const index = event.target.dataset.id;
        const productId = event.target.value;
    }

    removeRow(event) {
        let index = parseInt(event.target.id, 10);
        if (this.itemList.length > 1) {
            this.itemList.splice(index, 1);
        } else {
        }
    }


    handleSubmit() {
        debugger;
        console.log('submit');
        let isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {

            isVal = isVal && element.reportValidity();
        });

        this.itemList.map((item, idx) => {
            if (item.hasError) {
                isVal = false;
            }
        });

        if (isVal) {
            // Add event listeners for success and error
            this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
                const warrantyField = element.querySelector("lightning-input-field[data-fieldname='Warranty_Prior__c']");
                if (warrantyField) {
                    warrantyField.value = this.warrantyId;
                }
                element.submit();
            });


        } else {
            this.showToast(false, 'Validation failed. Please check the fields and try again.');
        }
    }

    handleSuccess(event) {
        this.showAll = true;
        this.showRow = false;
        this.clearRows();
        this.showToast(true, 'Record saved successfully.');
        this.showAdditionalFields = false;
        this.showVideofield = false;
        return refreshApex(this.refreshResultData);
    }

    handleError(event) {
        let fieldErrors = {};

        // Check for field errors
        if (event.detail && event.detail.output && event.detail.output.fieldErrors) {
            fieldErrors = event.detail.output.fieldErrors;

            for (let fieldName in fieldErrors) {
                if (fieldErrors.hasOwnProperty(fieldName)) {
                    const fieldError = fieldErrors[fieldName];
                    if (fieldError && fieldError.length > 0) {
                        const errorMsg = fieldError[0].message;
                        // Display the field-specific error
                        this.showToast(false, 'Error while saving record: ' + errorMsg);
                    }
                }
            }
        } else if (event.detail && event.detail.message) {
            const generalErrorMsg = event.detail.message;

            if (!fieldErrors || Object.keys(fieldErrors).length === 0) {
                this.showToast(false, 'Error: ' + generalErrorMsg);
            }
        } else if (event.detail && event.detail.output && event.detail.output.errors) {
            const apexErrors = event.detail.output.errors;

            if (apexErrors && apexErrors.length > 0) {
                apexErrors.forEach(error => {
                    const errorMsg = error.message;
                    this.showToast(false, 'Apex Error: ' + errorMsg);
                });
            }
        } else if (!event.detail || (!fieldErrors && !event.detail.message && (!event.detail.output || !event.detail.output.errors))) {
            this.showToast(false, 'An unknown error occurred. Please try again.');
        }
    }


    showToast(success, message) {
        const event = new ShowToastEvent({
            title: success ? 'Success' : 'Error',
            message: message,
            variant: success ? 'success' : 'error',
        });
        this.dispatchEvent(event);
    }



    handleProductselection(event) {

        const index = event.target.dataset.id;
        const productId = event.target.value;

        if (!productId) {
            // If the input field is cleared, reset the corresponding values
            this.itemList = this.itemList.map((item, idx) => {
                if (idx == index) {
                    return { ...item, price: '', productCode: '', errorMessage: '', hasError: false };
                }
                return item;
            });
        } else {
            getDynamicValues({ productId: productId })
                .then(result => {
                    if (result && result.price && result.productCode) {

                        this.itemList = this.itemList.map((item, idx) => {
                            if (idx == index) {
                                return { ...item, price: result.price, productCode: result.productCode, errorMessage: '', hasError: false };
                            }
                            return item;
                        });
                    }
                })
                .catch(error => {
                    // Set the error message in the product field
                    this.itemList = this.itemList.map((item, idx) => {
                        if (idx == index) {
                            return { ...item, errorMessage: error.body.message, hasError: true };
                        }
                        return item;
                    });

                });
        }
    }

    clearRows() {
        // Reset itemList and keyIndex
        this.itemList = [];
        this.keyIndex = 0;
        let newItem = { id: this.keyIndex, price: '', productCode: '', errorMessage: '', hasError: false };
        this.itemList = [...this.itemList, newItem];
        this.showAdditionalFields = false;
        this.showVideofield = false;
    }

    navigateToRecord(recordid) {
        this.dispatchEvent(new RefreshEvent());
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordid,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            },
        });
    }

}