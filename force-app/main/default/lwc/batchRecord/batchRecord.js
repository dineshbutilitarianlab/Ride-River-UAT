import { LightningElement, track, wire } from 'lwc';
import fetchClaims from '@salesforce/apex/BatchRecordController.fetchClaims';
import createBatchAndTagClaims from '@salesforce/apex/BatchRecordController.createBatchAndTagClaims';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BatchRecord extends LightningElement {
    @track claims = [];
    @track selectedClaims = [];
    @track preSelectedRowIds = [];
    @track batchAmount = 0;
    @track showModal = false;

    @track batchDispatchDate;
    @track lrNumber = '';
    @track lrAttachment = '';
    @track today = new Date().toISOString().split('T')[0];

    wiredClaimsResult; // Store the result of the wired service to refresh later

    columns = [
        { label: 'Claim Name', fieldName: 'Name', cellAttributes: { alignment: 'left' } },
        { label: 'Total Claimed Amount', fieldName: 'Total_Claimed_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' } }
    ];

    selectedClaimsColumns = [
        { label: 'Claim Name', fieldName: 'Name' },
        { label: 'Total Claimed Amount', fieldName: 'Total_Claimed_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' } },
        {
            type: 'button',
            typeAttributes: {
                label: 'Remove',
                name: 'remove',
                variant: 'destructive'
            }
        }
    ];

    // Fetch Claims via Apex
    @wire(fetchClaims)
    wiredClaims(result) {
        this.wiredClaimsResult = result; // Store wired result for refresh
        if (result.data) {
            this.claims = result.data;
        } else if (result.error) {
            this.showToast('Error', `Error fetching claims: ${result.error.body.message}`, 'error');
        }
    }

    handleAddWarrantyClaim() {
        this.preSelectedRowIds = this.selectedClaims.map(claim => claim.Id);
        this.showModal = true;
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.preSelectedRowIds = selectedRows.map(row => row.Id);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'remove') {
            this.selectedClaims = this.selectedClaims.filter(claim => claim.Id !== row.Id);
            this.calculateBatchAmount();
        }
    }

    handleSelect() {
        this.selectedClaims = this.claims.filter(claim =>
            this.preSelectedRowIds.includes(claim.Id)
        );
        this.calculateBatchAmount();
        this.showModal = false;
    }

    handleModalClose() {
        this.showModal = false;
    }

    handleDispatchDateChange(event) {
        this.batchDispatchDate = event.target.value;
    }

    handleLRNumberChange(event) {
        this.lrNumber = event.target.value;
    }

    handleLRAttachmentChange(event) {
        this.lrAttachment = event.target.value;
    }

    calculateBatchAmount() {
        this.batchAmount = this.selectedClaims.reduce(
            (total, claim) => total + (claim.Total_Claimed_Amount__c || 0), 0
        );
    }

    async handleSubmit() {
        if (!this.selectedClaims.length) {
            this.showToast('Error', 'Please select at least one claim.', 'error');
            return;
        }
        if (!this.batchDispatchDate) {
            this.showToast('Error', 'Batch dispatch date is required.', 'error');
            return;
        }
        if (!this.lrNumber) {
            this.showToast('Error', 'LR Number is required.', 'error');
            return;
        }

        try {
            const claimIds = this.selectedClaims.map(claim => claim.Id);
            const result = await createBatchAndTagClaims({
                claimIds,
                batchDispatchDate: this.batchDispatchDate,
                lrNumber: this.lrNumber,
                lrAttachment: this.lrAttachment
            });

            this.showToast('Success', 'Batch created successfully.', 'success');
            this.resetForm();

            // Refresh the claims list after successful submission
            await refreshApex(this.wiredClaimsResult);
        } catch (error) {
            this.showToast('Error', `Error creating batch: ${error.body.message}`, 'error');
        }
    }

    resetForm() {
        this.batchAmount = 0;
        this.batchDispatchDate = '';
        this.lrNumber = '';
        this.lrAttachment = '';
        this.selectedClaims = [];
        this.preSelectedRowIds = [];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}