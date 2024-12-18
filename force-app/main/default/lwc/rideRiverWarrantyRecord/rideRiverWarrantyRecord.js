import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WARRANTY_OBJECT from '@salesforce/schema/Warranty_Prior__c';
import TYPE_OF_WARRANTY_FIELD from '@salesforce/schema/Warranty_Prior__c.Type_of_Warranty__c';
import getWarrantyPrior from '@salesforce/apex/WarrantyPriorController.getWarrantyPrior';
import getRelatedWorkPlans from '@salesforce/apex/WarrantyPriorController.getRelatedWorkPlans';
import getRelatedWorkOrderLineItems from '@salesforce/apex/WarrantyPriorController.getRelatedWorkOrderLineItems';
import submitApprovalProcess from '@salesforce/apex/WarrantyPriorApprovalController.submitApprovalProcess';
import updateParts from '@salesforce/apex/WarrantyPriorController.updateParts';
import updateLabours from '@salesforce/apex/WarrantyPriorController.updateLabours';
import updateWarrantyPrior from '@salesforce/apex/WarrantyPriorController.updateWarrantyPrior';
import { refreshApex } from '@salesforce/apex';

// Component class
export default class RideRiverWarrantyRecord extends LightningElement {
    // Variables and Constants
    @api recordId; // Job Card ID
    @track warrantyPrior = {};
    @track warrantyId = ''; // Stores the Warranty ID
    @track labourData = []; // Labour records
    @track partsData = []; // Parts records
    @track error; // Error handling
    @track draftValuesParts = []; // Draft values for Parts
    @track draftValuesLabours = []; // Draft values for Labours
    @track warrantyOptions = []; // Warranty picklist values

    refreshLabours; // Store wire result for refresh
    refreshParts; // Store wire result for refresh

    labourColumns = [
        { label: 'Labour Name', fieldName: 'jobUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, sortable: true },
        { label: 'Labour Code', fieldName: 'codeUrl', type: 'url', typeAttributes: { label: { fieldName: 'RR_Labour_Code__c' }, target: '_blank' }, sortable: true },
        { label: 'Amount/hr', fieldName: 'Amount_per_Hour__c', type: 'currency', editable: true, cellAttributes: { alignment: 'left' } },
        { label: 'Tax %', fieldName: 'Tax__c', type: 'number', editable: true, cellAttributes: { alignment: 'left' } },
        { label: 'Total Amount', fieldName: 'TotalAmount__c', type: 'currency' }
    ];

    partsColumns = [
        { label: 'Product Code', fieldName: 'partUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, sortable: true },
        { label: 'Product Name', fieldName: 'productUrl', type: 'url', typeAttributes: { label: { fieldName: 'ProductName' }, target: '_blank' }, sortable: true },
        { label: 'Labour Code', fieldName: 'LabourUrl', type: 'url', typeAttributes: { label: { fieldName: 'Labour_Name__c' }, target: '_blank' }, sortable: true },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number' },
        { label: 'Part Description', fieldName: 'Part_Description__c', type: 'text' },
        { label: 'Consequential Part', fieldName: 'Consequential_Part__c', type: 'text' },
        { label: 'Hours', fieldName: 'Hours__c', type: 'number' },
        { label: 'Electrical Value', fieldName: 'Electrical_Value__c', type: 'text' },
        { label: 'Amount @ NDP', fieldName: 'Amount_per_Hour__c', type: 'currency', editable: true, cellAttributes: { alignment: 'left' } },
        { label: 'Tax %', fieldName: 'Tax__c', type: 'number', editable: true, cellAttributes: { alignment: 'left' } },
        { label: 'Total Amount', fieldName: 'TotalAmount__c', type: 'currency' }
    ];
    
    // Lifecycle Hooks
    connectedCallback() {
        if (this.recordId) {
            this.fetchWarrantyPrior();
        }
    }

    // Wired Methods
    @wire(getObjectInfo, { objectApiName: WARRANTY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_OF_WARRANTY_FIELD })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.warrantyOptions = data.values.map((value) => ({
                label: value.label,
                value: value.value
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.warrantyOptions = [];
        }
    }

    @wire(getRelatedWorkPlans, { warrantyId: '$warrantyId' })
    wiredLabourPlans(result) {
        this.refreshLabours = result;
        if (result.data) {
            this.labourData = result.data.map((item) => ({
                Id: item.Id,
                jobUrl: `/${item.Id}`,
                codeUrl: item.RR_Labour_Code__r ? `/${item.RR_Labour_Code__r.Id}` : '',
                Name: item.Name,
                RR_Labour_Code__c: item.RR_Labour_Code__r ? item.RR_Labour_Code__r.Code : 'N/A',
                Amount_per_Hour__c: item.Amount_per_Hour__c || 0,
                Tax__c: item.Tax__c || 0,
                TotalAmount__c: item.TotalAmount__c || 0
            }));
        } else if (result.error) {
            this.error = result.error;
            this.labourData = [];
        }
    }

    @wire(getRelatedWorkOrderLineItems, { warrantyId: '$warrantyId' })
    wiredWorkOrderLineItems(result) {
        debugger;
        this.refreshParts = result;
        if (result.data) {
            this.partsData = result.data.map((item) => ({
                Id: item.Id,
                partUrl: `/${item.Id}`,
                productUrl: item.PricebookEntry?.Product2Id ? `/${item.PricebookEntry.Product2Id}` : '',
                Labour_Name__c: item.Labour_Code__c ? item.Labour_Code__r.Name : '',
                LabourUrl: item.Labour_Code__c? `/${item.Labour_Code__c}` : '',
                Name: item.LineItemNumber || 'N/A',
                ProductName: item.PricebookEntry && item.PricebookEntry.Product2 ? item.PricebookEntry.Product2.Name : 'N/A',
                Quantity: item.Quantity || 0,
                Part_Description__c: item.Part_Description__c || 'N/A',
                Hours__c: item.Hours__c || 0,
                Electrical_Value__c: item.Electrical_Value__c || 'N/A',
                Consequential_Part__c: item.Consequential_Part__c || 'N/A',
                //Amount_per_Hour__c: (item.Quantity || 0) * (item.Hours__c || 0) * (item.Labour_Code__r?.RR_Labour_Charge__c || 0),
                Amount_per_Hour__c : (item.Hours__c || 1) *(item.Quantity || 1) * (item.Labour_Code__r?.RR_Labour_Charge__c || 1),
                Tax__c: item.Tax__c || 0,
                TotalAmount__c: ((item.Hours__c || 1) *(item.Quantity || 1) * (item.Labour_Code__r?.RR_Labour_Charge__c || 1)) + (((item.Hours__c || 1) *(item.Quantity || 1) * (item.Labour_Code__r?.RR_Labour_Charge__c || 1) * item.Tax__c) /100 )
            }));
        } else if (result.error) {
            this.error = result.error;
            this.partsData = [];
        }
    }

    // Event Handlers
    handleCellChange(event) {
        if (event.target === this.template.querySelector('lightning-datatable[data-id="parts"]')) {
            this.draftValuesParts = event.detail.draftValues;
        } else if (event.target === this.template.querySelector('lightning-datatable[data-id="labours"]')) {
            this.draftValuesLabours = event.detail.draftValues;
        }
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.warrantyPrior[field] = event.target.value;
    }

    handlePartsSave(event) {
       // const updatedParts = event.detail.draftValues;
       const updatedParts = event.detail.draftValues.map((draft) => {
        const originalRow = this.partsData.find((row) => row.Id === draft.Id);
        return { ...originalRow, ...draft ,Amount_per_Hour__c: draft.Amount_per_Hour__c || originalRow.Amount_per_Hour__c,}; // Merge original data with the draft values
        });
        updateParts({ partsDraftValues: updatedParts })
            .then(() => {
                this.showToast('Success', 'Parts updated successfully', 'success');
                this.draftValuesParts = [];
                return refreshApex(this.refreshParts);
            })
            .catch((error) => {
                this.showToast('Error', `Error updating Parts: ${error.body.message}`, 'error');
            });
    }

    handleLaboursSave(event) {
       // const updatedLabours = event.detail.draftValues;
       const updatedLabours = event.detail.draftValues.map((draft) => {
        const originalRow = this.labourData.find((row) => row.Id === draft.Id);
        return { ...originalRow, ...draft }; // Merge original data with the draft values
        });
        updateLabours({ labourDraftValues: updatedLabours })
            .then(() => {
                this.showToast('Success', 'Labours updated successfully', 'success');
                this.draftValuesLabours = [];
                return refreshApex(this.refreshLabours);
            })
            .catch((error) => {
                this.showToast('Error', `Error updating Labours: ${error.body.message}`, 'error');
            });
    }

    // Apex Call Helpers
    fetchWarrantyPrior() {
        getWarrantyPrior({ workOrderId: this.recordId })
            .then((data) => {
                this.warrantyPrior = data || {};
                this.warrantyId = data?.Id || '';
            })
            .catch((error) => {
                this.error = error;
                this.warrantyPrior = {};
                this.warrantyId = '';
            });
    }

    // handleUpdateWarranty() {
    //     debugger;
    //     return 
    // }

    // handleSubmitApproval() {
    //     debugger;
    //     return 
    // }

    handleSubmit() {
        debugger;
        console.log('Submit button clicked');
        console.log('Parts Data:', this.partsData);
    
        
        const invalidParts = this.partsData.filter(
            (part) => part.TotalAmount__c <= 0 || part.Tax__c === 0
        );
        console.log('Invalid Parts:', invalidParts);
    
        if (invalidParts.length > 0) {
            const errorMessage = invalidParts.map((part) =>
                `Part ${part.Name}: Total Amount must be greater than 0 and Tax cannot be 0.`
            ).join('\n');
            console.error('Validation Error:', errorMessage);
    
            this.showToast('Validation Error', errorMessage, 'error');
            return; 
        }
    
        console.log('Validation passed. Proceeding with submission...');
        submitApprovalProcess({
            warrantyId: this.warrantyId,
            typeOfWarranty: this.warrantyPrior.Type_of_Warranty__c,
            asmFeedback: this.warrantyPrior.ASM_Feedback__c,
            ffirNumber: this.warrantyPrior.FFIR_Number__c,
            dealerObservation: this.warrantyPrior.Dealer_Observation__c,
            media: this.warrantyPrior.Media__c,
            standardValue: this.warrantyPrior.Standard_Values__c,
        })

        .then(result => {
            if(result == 'Success'){
                this.showToast('Success', 'Approval process initiated and Warranty updated successfully', 'success');
                // submitApprovalProcess({ warrantyId: this.warrantyId });
                //window.location.reload();
            }else{
                this.showToast('error', 'Approval process Already initiated for this Record', 'error');
            }
        })
        .catch(error => {
            this.error = error;
            
        });
        // // .then(() => {
        // //     console.log('Warranty updated successfully');
        // //     submitApprovalProcess({ warrantyId: this.warrantyId });
        // //     if(){

        // //     }
        // // })
        // // .then(() => {
        // //     console.log('Approval process initiated successfully');
        // //     this.showToast('Success', 'Approval process initiated successfully', 'success');
        // //     return Promise.all([refreshApex(this.refreshLabours), refreshApex(this.refreshParts)]);
        // // })
        // .catch((error) => {
        //     console.error('Error during submission:', error);
        //     this.showToast('Error', `Error during submission: ${error.message}`, 'error');
        // });
    }
    
    
    // handleUpdateWarranty() {
    //     debugger;
    //     updateWarrantyPrior({
    //         warrantyId: this.warrantyId,
    //         typeOfWarranty: this.warrantyPrior.Type_of_Warranty__c,
    //         asmFeedback: this.warrantyPrior.ASM_Feedback__c,
    //         ffirNumber: this.warrantyPrior.FFIR_Number__c,
    //         dealerObservation: this.warrantyPrior.Dealer_Observation__c,
    //         media: this.warrantyPrior.Media__c,
    //         standardValue: this.warrantyPrior.Standard_Value__c,
    //     })
    //         .then(() => {
    //             console.log('Warranty updated successfully');
    //             this.showToast('Success', 'Warranty updated successfully', 'success');
    //         })
    //         .catch((error) => {
    //             console.error('Error during warranty update:', error);
    //             this.showToast('Error', `Error during warranty update: ${error.message}`, 'error');
    //         });
    // }
    
    // handleSubmit() {
    //     debugger;
    //     console.log('Submit button clicked');
    //     this.handleUpdateWarranty();
    // }e
    

    // Utility Methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}