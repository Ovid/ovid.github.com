// https://github.com/ireade/accessible-modal-dialog

function Dialog(dialogEl, overlayEl) {

    this.dialogEl = dialogEl;
    this.overlayEl = overlayEl;
    this.focusedElBeforeOpen;

    var focusableEls = this.dialogEl.querySelectorAll('a[href], area[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), [tabindex="0"]');
    this.focusableEls = Array.prototype.slice.call(focusableEls);

    this.firstFocusableEl = this.focusableEls[0];
    this.lastFocusableEl = this.focusableEls[ this.focusableEls.length - 1 ];

    // Registered once here; open() used to add a fresh pair on every open.
    var Dialog = this;
    this.dialogEl.addEventListener('keydown', function(e) {
        Dialog._handleKeyDown(e);
    });
    this.overlayEl.addEventListener('click', function() {
        if (Dialog.isOpen) Dialog.close();
    });

    this.inertEls = [];
    this.close(); // Reset
}


Dialog.prototype.open = function() {

    this.dialogEl.removeAttribute('aria-hidden');
    this.overlayEl.removeAttribute('aria-hidden');
    this.isOpen = true;

    this.focusedElBeforeOpen = document.activeElement;
    this._setInert(true);

    this.firstFocusableEl.focus();
};

// aria-modal tells screen readers the rest of the page is off limits;
// inert makes that true for everyone. Walk from the dialog up to <body>
// and mark every sibling along the way, remembering what we marked.
Dialog.prototype._setInert = function(on) {
    if (!on) {
        this.inertEls.forEach(function(el) { el.inert = false; });
        this.inertEls = [];
        return;
    }
    var keep = [this.dialogEl, this.overlayEl];
    for (var el = this.dialogEl; el && el !== document.body; el = el.parentElement) {
        var siblings = el.parentElement ? el.parentElement.children : [];
        for (var i = 0; i < siblings.length; i++) {
            var sib = siblings[i];
            if (sib !== el && keep.indexOf(sib) === -1 && !sib.inert && sib.tagName !== 'SCRIPT') {
                sib.inert = true;
                this.inertEls.push(sib);
            }
        }
    }
};

Dialog.prototype.close = function() {

    this.dialogEl.setAttribute('aria-hidden', true);
    this.overlayEl.setAttribute('aria-hidden', true);
    this.isOpen = false;
    this._setInert(false);

    if ( this.focusedElBeforeOpen ) {
        this.focusedElBeforeOpen.focus();
    }
};


Dialog.prototype._handleKeyDown = function(e) {

    var Dialog = this;
    var KEY_TAB = 9;
    var KEY_ESC = 27;

    function handleBackwardTab() {
        if ( document.activeElement === Dialog.firstFocusableEl ) {
            e.preventDefault();
            Dialog.lastFocusableEl.focus();
        }
    }
    function handleForwardTab() {
        if ( document.activeElement === Dialog.lastFocusableEl ) {
            e.preventDefault();
            Dialog.firstFocusableEl.focus();
        }
    }

    switch(e.keyCode) {
    case KEY_TAB:
        if ( Dialog.focusableEls.length === 1 ) {
            e.preventDefault();
            break;
        } 
        if ( e.shiftKey ) {
            handleBackwardTab();
        } else {
            handleForwardTab();
        }
        break;
    case KEY_ESC:
        Dialog.close();
        break;
    default:
        break;
    }


};


Dialog.prototype.addEventListeners = function(openDialogSel, closeDialogSel) {

    var Dialog = this;

    var openDialogEls = document.querySelectorAll(openDialogSel);
    for ( var i = 0; i < openDialogEls.length; i++ ) {
        openDialogEls[i].addEventListener('click', function() { 
            Dialog.open();
        });
    }

    var closeDialogEls = document.querySelectorAll(closeDialogSel);
    for ( var i = 0; i < closeDialogEls.length; i++ ) {
        closeDialogEls[i].addEventListener('click', function() {
            Dialog.close();
        });
    }

};




