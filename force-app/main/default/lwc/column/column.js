import { LightningElement, api } from 'lwc';

export default class Column extends LightningElement {
    @api name;
    @api label;
    @api cards = [];
    @api dropzone = 'slds-box';
    @api dropzoneReorder = 'slds-hide';
    @api columnWidth;
    dragged;

    get columnStyle() {
        return `width: ${this.columnWidth}px`;
    }

    drop(event) {
        const cardIndex = parseInt(event.target.dataset.cardIndex, 10);
        event.preventDefault();
        let sourceData = event.dataTransfer.getData('text').split(':') || ['',''];
        this.dropzoneReorder = 'slds-hide';
        this.dispatchEvent(new CustomEvent('droptile', {
            'detail' : {
                'targetColumnName' : event.target.dataset.columnName,
                'targetColumnCardIndex' : cardIndex,
                'sourceCardId' : sourceData[1],
                'sourceColumnName' : sourceData[0]
            }
        }));
        if (this.dragged) {
            this.dragged.style.opacity = 1;
        } 
    }

    allowDrop(event) {
        event.preventDefault();
    }

    drag(event) {
        this.dragged = event.target;
        event.target.style.opacity = 0.5;
        event.dataTransfer.setData('text/plain', event.target.dataset.columnName + ':' + event.target.dataset.cardId);
    }

    dragEnter(event) {
        event.preventDefault();
    }

    dragOver(event) {
        event.preventDefault();
    }

    dragEnd() {
        this.dragged.style.opacity = 1;
    }
}