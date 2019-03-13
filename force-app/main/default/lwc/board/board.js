import { LightningElement, track, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getInitData from '@salesforce/apex/BoardController.getInitData';
import upsertSortOrder from '@salesforce/apex/BoardController.upsertSortOrder';
import updateBoard from '@salesforce/apex/BoardController.updateBoard';
import ID_FIELD from '@salesforce/schema/Issue__c.Id';
import STATUS_FIELD from '@salesforce/schema/Issue__c.Status__c';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { showToast } from 'c/notifications';
import { CurrentPageReference } from 'lightning/navigation';

export default class Board extends LightningElement {

    @api recordId;

    @wire(CurrentPageReference) pageRef;

    @wire(getInitData, { 'boardId' : '$recordId' }) 
    board({ error, data }) {
        if (data) {
            let _data =  JSON.parse(data);
            this.columns = _data.columns;
            this.cards = _data.cards;
            this.record = _data.record;
            this.resize();
        } else if (error) {
            window.console.error(error);
        }
    }

    @track columns = [];
    @track columnWidth;
    cards = [];

    renderedCallback() {
        if (!this.hasRendered) {
            let board = this;
            window.addEventListener('resize', () => {
                board.resize();
            })
        }
        this.hasRendered = true;
    }
    
    connectedCallback() {
        let board = this;
        document.addEventListener('dragover', (event) => {
            event.preventDefault();
        });
        document.addEventListener('dragend', (event) => {
            event.preventDefault();
            for (let col of board.columns) {
                col.dropzone = 'slds-box';
                col.dropzoneReorder = 'slds-hide';
            }
        });
        registerListener('boardUpdated', this.handleBoardUpdated, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleBoardUpdated(boardId) {
        if (boardId === this.recordId) {
            updateBoard({ 'boardId' : this.recordId })
            .then(result => {
                let _data =  JSON.parse(result);
                this.columns = _data.columns;
                this.cards = _data.cards;
                this.record = _data.record;
                this.resize();
                showToast('Board updated!', 'Somebody changed the board', 'warning', this);
            }).catch(error => {
                window.console.error('error during init data on board update', error);
            })
        } 
    }
    
    resize() {
        let width = Math.floor((this.template.querySelector('div').clientWidth - 120) / this.columns.length);
        this.columnWidth = width < 175 ? 175 : width;
    }

    drop(event) {
        const targetColCardIndex = event.detail.targetColumnCardIndex;
        let card = this.cards.find(item => item.id === event.detail.sourceCardId);
        let isUpdated = false;
        
        function changeCardColumn(col, _this) {
            if (col.name === event.detail.targetColumnName) {
                col.cards.splice(targetColCardIndex, 0, card);
                _this.updateIssue(card.id, col.name);
                isUpdated = true;
            } else if (col.name === event.detail.sourceColumnName) {
                col.cards.splice(col.cards.findIndex(item => item.id === card.id), 1);
            }
        }

        function reorderCards(col) {
            if (col.name === event.detail.targetColumnName) {
                let srcIndex = col.cards.findIndex(item => item.id === card.id);
                let targetIndex = srcIndex === 0 && targetColCardIndex > 0 
                    ? (targetColCardIndex - 1) 
                    : (srcIndex === (col.cards.length - 1) && targetColCardIndex > srcIndex) 
                        ? srcIndex : targetColCardIndex;
                if (targetIndex !== srcIndex) {
                    col.cards.splice(col.cards.findIndex(item => item.id === card.id), 1);
                    col.cards.splice(targetIndex, 0, card);
                    isUpdated = true;
                }
            }
        }

        for (let col of this.columns) {
            col.dropzone = 'slds-box';
            col.dropzoneReorder = 'slds-hide';
            if (event.detail.targetColumnName && event.detail.sourceColumnName) {
                if (event.detail.targetColumnName !== event.detail.sourceColumnName) {
                    changeCardColumn(col, this);
                } else {
                    reorderCards(col);
                }
            }
        }
        if (isUpdated) {
            this.upsertSortOrder();
        }
    }

    drag(event) {
        for (let col of this.columns) {
            if (col.name !== event.target.name) {
                col.dropzone = 'slds-box dropzone';
            }
            col.dropzoneReorder = 'slds-show';
        }
    }

    updateIssue(recordId, status) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[STATUS_FIELD.fieldApiName] = status;
        const recordInput = { fields };
        window.console.log(recordInput);
        updateRecord(recordInput)
            .then(() => {
                showToast('Success', 'Status of the issue is updated', 'success', this);
            })
            .catch(error => {
                window.console.error(error);
                showToast('Error updating record', error.body.message, 'error', this);
            });
    }

    upsertSortOrder() {
        let issuesByColumns = {};
        for (let col of this.columns) {
            issuesByColumns[col.name] = col.cards.map(issue => issue.id)
        }
        upsertSortOrder({
            'boardId': this.recordId, 
            'boardName': this.record.Name, 
            'issuesByColumns' : JSON.stringify(issuesByColumns)
        }).then(() => {
            // enqueued deploy of custom metadata record which holds info about sort order of the board
            // platform event will be fired on complete of the deploy process and handled with pubsub model
        })
        .catch(error => {
            window.console.error(error);
            showToast('Error updating board', error.body.message, 'error', this);
        });
    }
}