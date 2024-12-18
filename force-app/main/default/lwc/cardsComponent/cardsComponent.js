import { LightningElement, wire, track } from 'lwc';
import No_Lead_img from "@salesforce/resourceUrl/No_Lead_img";
import No_Job_Card_img from "@salesforce/resourceUrl/No_Job_Card_img";
import No_Purchase_Order_img from "@salesforce/resourceUrl/No_Purchase_Order_img";
import No_cases_img from "@salesforce/resourceUrl/No_cases_img";
import Id from '@salesforce/user/Id';
import fetchOnLoadData from '@salesforce/apex/cardsComponentController.fetchOnLoadData';
import MyPopup from 'c/createPurchaseOrderForm';
import AddPoPaymments from 'c/bulkInsertPoPayments1';

export default class CardsComponent extends LightningElement {
    NoLeadimg = No_Lead_img;
    NoJobCardimg = No_Job_Card_img;
    NoPurchaseOrderimg = No_Purchase_Order_img;
    Nocasesimg = No_cases_img;
    userId = Id;
    @track role;
    error;
    @track isDisabled = true;

    connectedCallback(){
        debugger;
        fetchOnLoadData({userId: this.userId}).then(result=>{
            this.role=result
            if(role = 'Service'){
                this.isDisabled = true;
            }
        }).catch((error)=>{
            console.log('error occurs')
        });
    }

    async navigateToPurchaseOrder() {
        debugger;
        console.log('userId ---> '+this.userId);
        const result = await MyPopup.open({
            size: 'large', // 'small', 'medium', 'large'
            description: 'This is a modal popup', // Description for accessibility
        });

        if (result === 'close') {
            console.log('Popup closed');
        }
       
    }

    async navigateToAddPoPayments() {
        debugger;
        console.log('Navigating to Add PO Payments');
        const result = await AddPoPaymments.open({
            size: 'large',
            description: 'This is a modal popup for Add PO Payments', 
        });

        if (result === 'close') {
            console.log('Add PO Payments popup closed');
        }
    }
    navigateToJobCards() {
        window.open(
            'https://rivermobilityprivatelimited2--rruat.sandbox.my.site.com/autocloudSite/s/job-card',
            '_blank'
        );
    }

    navigateToCases() {
        window.open(
            'https://rivermobilityprivatelimited2--rruat.sandbox.my.site.com/autocloudSite/s/case/Case/Default',
            '_blank'
        );
    }
}