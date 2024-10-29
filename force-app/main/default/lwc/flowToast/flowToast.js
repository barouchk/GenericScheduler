import { LightningElement, api } from 'lwc';
import {showToast} from 'c/toastService';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
export default class FlowToast extends LightningElement {

    @api message;
    @api title;
    @api mode;
    @api variant;

    connectedCallback() {
      if(this.message) this.showToast();
    }

    showToast() {
        showToast.call(this,this.title, this.message, this.variant, this.mode);
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'message',
            ''
        );
        this.dispatchEvent(attributeChangeEvent);
    }
}