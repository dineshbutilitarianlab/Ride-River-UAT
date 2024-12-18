import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPayments from '@salesforce/apex/POPaymentsController.getPayments';
import deletePaymentRecord from '@salesforce/apex/POPaymentsController.deletePaymentRecord';
import getOrder from '@salesforce/apex/POPaymentsController.getOrder';
import checkDuplicateUTR from '@salesforce/apex/POPaymentsController.checkDuplicateUTR';

export default class BulkInsertPoPayments extends LightningElement {
    keyIndex = 0; // Index for dynamic rows
    showPayments = true; // Controls visibility of payments table
    showRow = false; // Controls visibility of "Add More" section
    existingPayments = []; // Stores fetched payments
    purchaseOrderId; 
    @track itemList = [{ id: 0 }]; // Tracks dynamic rows
    @api recordId; // Record ID from context
    @track wireRecordId; // Record ID fetched using CurrentPageReference

    // Columns for the lightning-datatable
    columns = [
        {
            label: 'Payment Order',
            fieldName: 'paymentOrderUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'paymentOrderName' }, target: '_blank' }
        },
        {
            label: 'Purchase Order',
            fieldName: 'purchaseOrderUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'purchaseOrderName' }, target: '_blank' }
        },
        {
            label: 'Payment Reference',
            fieldName: 'Payment_reference__c',
            type: 'text'
        },
        { label: 'Amount Paid', fieldName: 'Amount_Paid__c', type: 'currency' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Delete',
                name: 'delete',
                variant: 'destructive',
                iconName: 'utility:delete',
                iconPosition: 'left'
            }
        }
    ];

    // Fetch the related Order record
    @wire(getOrder, { orderId: '$recordId' })
    wiredOrder({ error, data }) {
        if (data) {
            this.purchaseOrderId = data.Purchase_Order__c; // Get related Purchase Order
        } else if (error) {
            console.error('Error fetching Order:', error);
        }
    }

    // Fetch the CurrentPageReference to extract the recordId
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('CurrentPageReference:', currentPageReference);
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

    // Wire method to fetch payments based on the current recordId
    @wire(getPayments, { orderId: '$recordId' })
    wiredPayments(result) {
        this.refreshResult = result; // Store result for refreshing later
        if (result.data) {
            // Transform data to include URLs
            this.existingPayments = result.data.map(payment => ({
                ...payment,
                paymentOrderUrl: `/${payment.Id}`,
                paymentOrderName: payment.Name, 
                purchaseOrderUrl: `/${payment.Purchase_Order__c}`,
                purchaseOrderName: payment.Purchase_Order__r ? payment.Purchase_Order__r.ProductRequestNumber : ''
            }));
        } else if (result.error) {
            this.showToast('Error', 'Error fetching PO Payments.', 'error');
        }
    }

    // Toggles the "Add More" section
    toggleTemplates() {
      //  this.showPayments = !this.showPayments;
        this.showRow = !this.showRow;
    }

    // Adds a new row to the itemList
    addRow() {  
        this.keyIndex++;
        this.itemList.push({ id: this.keyIndex });
    }

    // Removes a row from the itemList
    removeRow(event) {
        const index = parseInt(event.target.id, 10);
        if (this.itemList.length > 1) {
            this.itemList.splice(index, 1);
        }
    }

    deletePayment(paymentId) {
        // Call Apex to delete the payment
        deletePaymentRecord({ paymentId })
            .then(() => {
                this.showToast('Success', 'Payment deleted successfully.', 'success');
                return refreshApex(this.refreshResult); // Refresh the table data
            })
            .catch(error => {
                this.showToast('Error', `Error deleting payment: ${error.body.message}`, 'error');
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
    
        if (actionName === 'delete') {
            this.deletePayment(row.Id);
        }
    }
    

    handleSubmit() {
        let isValid = true;
        let hasNegativeAmount = false;
        let utrValue = '';
    
        // Validate all fields in the form
        this.template.querySelectorAll('lightning-input-field').forEach((field) => {
            isValid = isValid && field.reportValidity();
    
            // Check if the field is Amount_Paid__c and validate its value
            if (field.fieldName === 'Amount_Paid__c') {
                const fieldValue = parseFloat(field.value || 0);
                if (fieldValue < 0) {
                    hasNegativeAmount = true;
                    isValid = false; // Mark the form as invalid
                }
            }
    
            // Capture the UTR field value
            if (field.fieldName === 'Payment_reference__c') {
                utrValue = field.value;
            }
        });
    
        if (hasNegativeAmount) {
            this.showToast('Error', 'Amount Paid cannot be negative. Please enter a valid amount.', 'error');
            return;
        }
    
        if (isValid) {
            // Call Apex to check for duplicate UTR
            checkDuplicateUTR({ utr: utrValue })
                .then((isDuplicate) => {
                    if (isDuplicate) {
                        this.showToast('Error', `Oops! Duplicate UTR Found: ${utrValue}`, 'error');
                        return;
                    } else {
                        // Submit all forms if no duplicate UTR
                        try {
                            this.template.querySelectorAll('lightning-record-edit-form').forEach((form) => {
                                form.submit();
                            });
                        } catch (error) {
                            this.showToast('Error', 'Error submitting forms. Please try again.', 'error');
                        }
                    }
                })
                .catch((error) => {
                    this.showToast('Error', `Error checking UTR: ${error.body ? error.body.message : error.message}`, 'error');
                });
        } else {
            this.showToast('Error', 'Validation failed. Please check the fields and try again.', 'error');
        }
    }
    
    

    // Handles successful form submission
    handleSuccess() {
        this.showToast('Success', 'Payment saved successfully.', 'success');
        this.clearRows();
      //  this.toggleTemplates(); // Go back to the payments table view
        return refreshApex(this.refreshResult);
    }

    // Handles errors during form submission
    handleError(event) {
        this.showToast('Error', 'Oops! Duplicate UTR Found:', 'error');
       // this.showToast('Error', `Error saving Payment: ${event.detail.message}`, 'error');
    }

    // Displays toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Resets the itemList to a single row
    // clearRows() {
    //     this.itemList = [{ id: 0 }];
    // }

    clearRows() {
        this.itemList = [{ id: ++this.keyIndex }]; // Maintain unique IDs for each row
    }
}