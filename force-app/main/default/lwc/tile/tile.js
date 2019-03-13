import { LightningElement, api } from 'lwc';

export default class Tile extends LightningElement {
    @api card;
    @api get cardRef() {
        return `/${this.card.id}`;
    }

    drag(event) {
        event.preventDefault();
        // event.stopPropagation();
        // this.dispatchEvent(event);
    }
}