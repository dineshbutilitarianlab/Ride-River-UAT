/**
 * @author Dinesh Baddawar
 * @email dinesh.butilitarianlab@gmail.com
 * @create date 2024-12-10 13:11:20
 * @modify date 2024-12-13 13:31:36
 * @desc [Add ProductRequestLineItems Comp]
 */

import createProductRequestLineItems from '@salesforce/apex/ProductRequestLineController.createProductRequestLineItems';
import getPORelatedPRLI from '@salesforce/apex/ProductRequestLineController.getPORelatedPRLI';
import userId from '@salesforce/user/Id';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track } from 'lwc';
export default class AddProductRequestLiteItem extends LightningElement  {

    @api recordId;
    @track requestLineItems = [];
    @track selectedItems = [];
    //@track updatedValues = new Map();
    @track filteredRequestLineItems = [];
    @track updatedValues = new Map();  
    @track selectAllChecked = false; 
    showSpinner = false;
    currentUserId;

    connectedCallback() {
        debugger;
        this.currentUserId = userId;
        this.recordId = this.recordId;
        this.callApexMethod(); 
    }
    

    closeModal() {
        // Dispatch a custom event to inform the parent to close the modal
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
    }
    callApexMethod() {
        debugger;
        this.showSpinner = true; // Show spinner at the start
        
        // Track the start time
        const spinnerDelay = 1000; // 3 seconds
        const startTime = new Date().getTime();
    
        getPORelatedPRLI({ recordId: this.recordId, loggedInUserId: this.currentUserId })
            .then((data) => {
                if (data) {
                    this.requestLineItems = data.map((res) => ({
                        Id: res.Id,
                        ProductName: res.Name,
                        HSNCode: res.HSN_Code__c,
                        AllocatedQuantity: 0,
                        selected: false,
                        isChargesDisabled: true,
                    }));
                    this.filteredRequestLineItems = [];
                    this.error = undefined;
                } else {
                    this.filteredRequestLineItems = [];
                    this.requestLineItems = [];
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching product request items:', error);
            })
            .finally(() => {
                // Calculate the time remaining to ensure the spinner shows for at least 3 seconds
                const elapsedTime = new Date().getTime() - startTime;
                const remainingTime = Math.max(0, spinnerDelay - elapsedTime);
    
                setTimeout(() => {
                    this.showSpinner = false; // Hide spinner after ensuring 3 seconds have passed
                }, remainingTime);
            });
    }
    

    handleSearchInput(event) {
        debugger;
        const searchTerm = event.target.value.toLowerCase().trim();
        if (searchTerm) {
            this.filteredRequestLineItems = this.requestLineItems.filter(item =>(
                item.ProductName.toLowerCase().startsWith(searchTerm)||item.HSNCode.toLowerCase().startsWith(searchTerm))
            );
        } else {
            this.filteredRequestLineItems = []; // Reset to blank if no search term
        }
    
        // Recalculate selectAllChecked based on filteredRequestLineItems
        this.selectAllChecked = this.filteredRequestLineItems.every(item => item.selected);
    }
    

    handleDelete(event) {
        const itemId = event.target.dataset.id; // Get the item ID from the data-id attribute

        // Remove the item from filteredRequestLineItems
        this.filteredRequestLineItems = this.filteredRequestLineItems.filter(item => item.Id !== itemId);

        // Also remove from the requestLineItems to keep the state consistent
        this.requestLineItems = this.requestLineItems.filter(item => item.Id !== itemId);

        // Optionally, if the item was in selectedItems, remove it from there as well
        //this.selectedItems = this.selectedItems.filter(item => item.Id !== itemId);
    }

    handleDeleteSelectedItem(event) {
        const itemId = event.target.dataset.id; // Get the item ID from the data-id attribute    
        this.selectedItems = this.selectedItems.filter(item => item.Id !== itemId);
        const itemToAddBack = this.selectedItems.find(item => item.Id === itemId);
        if (itemToAddBack) {
            this.filteredRequestLineItems = [...this.filteredRequestLineItems, itemToAddBack];
        }
        this.selectAllChecked = this.filteredRequestLineItems.every(item => item.selected);
    }
    
    // @wire(getPORelatedPRLI, { recordId: '$recordId',loggedInUserId : this.currentUserId })
    // wiredProductRequestItems({ error, data }) {
    //     if (data) {
    //         this.requestLineItems = data.map((res) => ({
    //             Id: res.Id,
    //             ProductName: res.Name,
    //             HSNCode: res.HSN_Code__c,
    //             AllocatedQuantity : 0,
    //             selected: false,
    //             isChargesDisabled: true,
    //         }));
    //         this.filteredRequestLineItems = [];
    //         this.showSpinner = false;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.filteredRequestLineItems = [];
    //         this.requestLineItems = [];
    //         console.error('Error fetching product request items:', error);
    //     }
    // }

    

    // Handle input changes in quantity
    // handleInputChange(event) {
    //     debugger;
    //     const rowId = event.target.dataset.id;
    //     const updatedValue = event.target.value; 
    //     this.updatedValues.set(rowId, updatedValue); 
    //     console.log('Updated Values Map == >', Array.from(this.updatedValues.entries()));
    // }

    handleQuantityChange(event) {
        const itemId = event.target.dataset.id; // Get the item ID from the data-id attribute
        const updatedQuantity = parseFloat(event.target.value); // Get the updated quantity value

        
            this.selectedItems = this.selectedItems.map(item => {
                if (item.Id === itemId) {
                    item.AllocatedQuantity = updatedQuantity; // Update the quantity of the selected item
                }
                return item;
            });
          
            
            this.updatedValues.set(itemId, updatedQuantity);
            console.log('Updated Values Map == >', Array.from(this.updatedValues.entries()));
        
    
        // Update the selected item with the new quantity
       
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        // window.history.back();
      //  window.location.replace(`/lightning/r/ProductRequest/`+this.recordId+'/view');
    }
       
       handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
    
        
        this.filteredRequestLineItems = this.filteredRequestLineItems.map(item => {
            const updatedItem = { 
                ...item, 
                selected: isChecked, 
                isChargesDisabled: !isChecked // Enable/disable the field
            };
    
            if (isChecked) {
                
                if (!this.selectedItems.find(i => i.Id === item.Id)) {
                    this.selectedItems = [...this.selectedItems, updatedItem];
                }
            } else {
                
                this.selectedItems = this.selectedItems.filter(i => i.Id !== item.Id);
            }
    
            return updatedItem;
        });
    
        
        if (isChecked) {
            this.filteredRequestLineItems = [];
        }
    }
    
    
    
    
    handleCheckboxChange(event) {
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
    
        
        this.filteredRequestLineItems = this.filteredRequestLineItems.map(item => {
            if (item.Id === itemId) {
                const updatedItem = { ...item, selected: isChecked };
    
                if (isChecked) {
                    
                    this.selectedItems = [...this.selectedItems, updatedItem];
                } else {
                    
                    this.selectedItems = this.selectedItems.filter(i => i.Id !== itemId);
                }
    
                return updatedItem;
            }
            return item;
        });
    
        
        if (isChecked) {
            this.filteredRequestLineItems = this.filteredRequestLineItems.filter(item => item.Id !== itemId);
        }
    
        
        this.selectAllChecked = this.filteredRequestLineItems.every(item => item.selected);
    }
    
    
    

    handleUpdateProcess() {
        
        const invalidItems = this.selectedItems.filter(item => {
            return isNaN(item.AllocatedQuantity) || item.AllocatedQuantity <= 0 || item.AllocatedQuantity === '' || item.AllocatedQuantity === null;
        });
    
        if (invalidItems.length > 0) {
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please ensure all quantities are entered and greater than 0.',
                    variant: 'error'
                })
            );
            return; 
        }
    
        
        const updatedItems = this.selectedItems.map(item => ({
            Id: item.Id,
            QuantityRequested: parseFloat(item.AllocatedQuantity),
            Product2Id: item.Id,
            ParentId: this.recordId
        }));
    
        console.log('updatedItems === >' + updatedItems);
        var jsondatatopass = JSON.stringify(updatedItems);
        createProductRequestLineItems({ jsonData: jsondatatopass })
            .then(result => {
                if (result != null && result === 'SUCCESS') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'SUCCESS',
                            message: 'Records Created Successfully!',
                            variant: 'success'
                        })
                    );
                    this.updatedValues.clear();
                    //this.dispatchEvent(new CloseActionScreenEvent());
                    this.closeModal();
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error Creating records: ' + result,
                            variant: 'error'
                        })
                    );
                   // this.dispatchEvent(new CloseActionScreenEvent());
                   this.closeModal();
                }
            })
            .catch(error => {
                console.log('Error : ' + error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error Creating records: ' + error.body.message,
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
    
    

}