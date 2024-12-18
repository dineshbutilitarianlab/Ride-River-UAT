import { LightningElement, track, api, wire } from 'lwc';
import {   NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedWorkPlans from '@salesforce/apex/WorkPlanController.getRelatedWorkPlans';
import getLabourCode from '@salesforce/apex/AdditionalJobsRecommendedController.getLabourCode';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from "lightning/uiRecordApi";
import Status from "@salesforce/schema/WorkOrder.Status";



export default class BulkInsertWorkPlans extends NavigationMixin(LightningElement) {
    @api recordId;
    keyIndex = 0;
    showProducts = true;
    showSubmitButton = true;
    showAddMoreButton = false;
    @track existingWorkPlans = [];
    @track submittedWorkPlans = [];
    @track name='';
    @track itemList = [
        {
            id: 0,
            code:''
        }
    ];

    @track showAll;
    @track showRow = false;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [Status],
    })
    wiredWorkOrder({ error, data }) {
        if (data && data.fields.Status.value == 'Completed') {
            this.showAll = false;
        }
        else if(data){
            this.showAll = true;
        } 
    }

    toggleTemplates() {
    this.showAll = !this.showAll;
    this.showRow = !this.showRow;
    }
       // Columns definition for Lightning Datatable
       columns = [
        {
            label: 'Name',
            fieldName: 'jobUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Name' }, 
            target: '_blank'},
            sortable: true
        },
        {
            label: 'Labour Code',
            fieldName: 'codeUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'RR_Labour_Code__c' }, 
            target: '_blank'},
            sortable: true
        },
        //{ label: 'Name', fieldName: 'Name', type: 'text' },
        //{ label: 'Labour Code', fieldName: 'RR_Labour_Code__c', type: 'text' },
        { label: 'Duration (Hours)', fieldName: 'Duration_Hour__c', type: 'text' },
        { label: 'Duration (Minutes)', fieldName: 'Duration_Min__c', type: 'Number' },
        { label: 'Labour charge', fieldName: 'Labour_Charge__c', type: 'currency' }

    ];

    refreshResultData;
   
    @wire(getRelatedWorkPlans, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        this.refreshResultData = result;
        if (result.data) {
            console.log('data received>>',result.data);
            this.existingWorkPlans = result.data.map(workPlan => {

                const jobUrl = `/${workPlan.Id}`; 
                const codeUrl = workPlan.RR_Labour_Code__c? `/${workPlan.RR_Labour_Code__c}`:'';

                return{
                    Id: workPlan.Id,
                    Name: workPlan.Name,
                    RR_Labour_Code__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Code:'',
                    Status__c: workPlan.Status__c,
                    Duration_Min__c:workPlan.Duration_Min__c?workPlan.Duration_Min__c:0,
                    Duration_Hour__c: workPlan.Duration_Hour__c?workPlan.Duration_Hour__c:0,
                    Labour_Charge__c: workPlan.Labour_Charge__c,
                    jobUrl: jobUrl,
                    codeUrl: codeUrl
                }
                

            });
        } else if (result.error) {
            console.error('Error fetching Work Plans:', result.error);
        }
    }
  
    // connectedCallback() {
    //     // Refresh data every second
    //     this.refreshInterval = setInterval(() => {
    //         refreshApex(this.refreshResultData);
    //     }, 1000);
    // }

    // disconnectedCallback() {
    //     // Clear the interval when the component is disconnected
    //     clearInterval(this.refreshInterval);
    // }


    addRow(event, index) {
        index = parseInt(event.target.dataset.id,10);
        console.log('indes os>>s',JSON.stringify(event.target));

        ++this.keyIndex;
        let newItem = { id: this.keyIndex, code: '' };
        this.itemList.splice(index + 1, 0, newItem);
        console.log('Row added at index:', index + 1);
    }

    removeRow(event) {
        let index = parseInt(event.target.id,10);
        if (this.itemList.length > 1) { // Ensure there is always at least one row
            this.itemList.splice(index, 1);
            console.log('Row deleted at index:', index);
        } else {
            console.log('Cannot delete the last row.');
        }
    }

    handleSubmit() {
        let isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {

            console.log('element>>'+element);
            isVal = isVal && element.reportValidity();
            console.log('isVal>>'+isVal);
        });
    
        if (isVal) {
            const forms = Array.from(this.template.querySelectorAll('lightning-record-edit-form'));
            forms.forEach(form => form.submit());
            // Refresh data after successful submission
            refreshApex(this.refreshResultData)
                .then(() => {
                    //this.showToast(true, 'Work Plans added successfully!');
                     this.showAll = true;
                    this.showRow = false;
                    this.clearRows(); 

                })
                .catch(error => {
                    
                    this.showToast(false, 'Error in fetching fresh data!');
                });
        } else {

            console.error('Error while adding Work Plans:');

            this.showToast(false, 'Please check the validations!');
        }
    }


    handleSuccess(event) {
        console.log('The success happed');
        this.showToast(true, 'Labour codes added successfully.');
        return refreshApex(this.refreshResultData);
    }
    
    handleError(event) {
        let errorMsg = '';
    
        console.log('Error:1', JSON.stringify(event.detail));
    
        if (event.detail && event.detail.output && event.detail.output.fieldErrors &&event.detail.output.fieldErrors.length > 0) {
            console.log('inside 1');
            // Check for field-specific errors
            let fieldErrors = event.detail.output.fieldErrors;
            for (let fieldName in fieldErrors) {
                if (fieldErrors.hasOwnProperty(fieldName)) {
                    const fieldError = fieldErrors[fieldName];
                    if (fieldError && fieldError.length > 0) {
                        errorMsg = 'Error: ' + fieldError[0].message;
                        break; // Exit loop after finding the first field error
                    }
                }
            }
        }else if (event.detail && event.detail.output && event.detail.output.errors && event.detail.output.errors.length > 0) {
            console.log('inside 2');
            // Check for field-specific errors
            let fieldErrors = event.detail.output.errors;
            for (let fieldName in fieldErrors) {
                console.log(' error loccured1>>'+ JSON.stringify(fieldErrors[fieldName]));
                if (fieldErrors.hasOwnProperty(fieldName)) {
                    console.log(' error loccured2>>'+ JSON.stringify(fieldErrors[fieldName]));
                    const fieldError = fieldErrors[fieldName];
                    if (fieldError && fieldError.length > 0) {
                        console.log(' error loccured3>>'+ JSON.stringify(fieldErrors[fieldName]));
                        errorMsg = 'Error: ' + fieldError[0].message;
                        break; // Exit loop after finding the first field error
                    }else if(fieldError.message){
                        errorMsg = 'Error: ' + fieldError.message;
                        break; 
                    }
                }
            }
        }
         else if (event.detail && event.detail.detail) {
            console.log('inside 3');
            errorMsg = 'Error: ' + event.detail.detail;
        }else if (event.detail && event.detail.message) {
            console.log('inside 4');
            errorMsg = 'Error: ' + event.detail.message;
        }
         else if (event.detail && event.detail.output && event.detail.output.errors) {
            // Check for Apex errors
            const apexErrors = event.detail.output.errors;
            if (apexErrors && apexErrors.length > 0) {
                errorMsg = 'Apex Error: ' + apexErrors[0].message;
            }
        } else {
            // Default generic error message
            errorMsg = 'An unknown error occurred. Please try again.';
        }
    
        // Display the error message in a single toast
        this.showToast(false, errorMsg);
    }

    handleAddMore() {
        // Clear the itemList
        this.itemList = [];
        this.clearRows(); // Clear rows when Add More is clicked

    
        // Add a new record with an incremented id
        let newId = this.keyIndex + 1;
        let newItem = { id: newId, code:'' };
        this.itemList.push(newItem);
    
        // Update keyIndex and button visibility
        this.keyIndex = newId;
        this.showSubmitButton = true;
        this.showAddMoreButton = false;
    }
 handleCodeselection(event) {
    console.log('event.target.dataset.id', event.target.dataset.id);
    console.log('event.target.name', event.target.name);
    console.log('event.target.value', event.target.value);
    const index = event.target.dataset.id; // Assuming this dataset.id corresponds to the index of the itemList

    const codeId = event.target.value;

    if (!codeId) {
        // If the input field is cleared, reset the corresponding values
        this.itemList[index].labourCode = '';
        this.itemList[index].CodeDescription = '';
    } else {
        getLabourCode({ codeId: codeId })
            .then(result => {
                console.log('code:', result);
                // Update the item with dynamic values
                if (result) {

                    this.name = result.Name;
                    
                    // Update each field independently if they exist
                    if (result.labourCode !== undefined) {
                        this.itemList[index].labourCode = result.labourCode;
                    }
                    if (result.labourCodeDescription !== undefined) {
                        this.itemList[index].CodeDescription = result.labourCodeDescription;
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching code values:', error);
            });
    }
}


 clearRows() {
        this.itemList = [];
        this.keyIndex = 0;
        let newItem = { id: this.keyIndex, labourCode: '', labourCodeDescription: '' };
        this.itemList = [...this.itemList, newItem];
    }

    

    showToast(isSuccess, message) {
        let event;
        if(isSuccess) {
            event = new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success',
            });
        } else {
            event = new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
            });
        }
        this.dispatchEvent(event);
    }
   

}