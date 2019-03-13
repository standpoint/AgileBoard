import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const showToast = (title, message, variant, thisArg) => {
    thisArg.dispatchEvent(
        new ShowToastEvent({
            'title': title,
            'message': message,
            'variant': variant
        })
    );
}

export {
    showToast
}