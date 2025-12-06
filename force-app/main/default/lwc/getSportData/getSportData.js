/**
 * @description Headless LWC component for Quick Actions - automatically executes ESPN API call
 * @author Brendan Milton
 * @date 2025-11-27
 * 
 * LWC Best Practices:
 * - Use renderedCallback to ensure @api properties are set before executing
 * - Validate all inputs before making Apex calls
 * - Proper error handling with user-friendly messages
 * - Console logging for debugging
 */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getSportDataApex from '@salesforce/apex/ESPNActionController.getSportData';

export default class GetSportData extends LightningElement {
    @api recordId;
    @api objectApiName;
    
    isLoading = true;
    errorMessage = '';
    hasExecuted = false; // Prevent multiple executions
    
    connectedCallback() {
        console.log('[getSportData] connectedCallback - Component initialized');
        console.log('[getSportData] recordId:', this.recordId);
        console.log('[getSportData] objectApiName:', this.objectApiName);
    }
    
    renderedCallback() {
        // LWC Best Practice: Use renderedCallback to ensure @api properties are set
        // Only execute once when component is fully rendered
        if (!this.hasExecuted && this.recordId) {
            console.log('[getSportData] renderedCallback - Component rendered, executing action');
            console.log('[getSportData] recordId:', this.recordId);
            console.log('[getSportData] objectApiName:', this.objectApiName);
            
            // Derive objectApiName from recordId if not provided
            if (!this.objectApiName && this.recordId) {
                const prefix = this.recordId.substring(0, 3);
                // Standard objects have fixed prefixes, custom objects start with 'a0' followed by variable chars
                const objectMap = {
                    '001': 'Account',
                    '003': 'Contact',
                    '006': 'Opportunity'
                };
                
                // Check standard objects first
                if (objectMap[prefix]) {
                    this.objectApiName = objectMap[prefix];
                } else if (this.recordId.startsWith('a0')) {
                    // Custom object - need to check context or use objectApiName if available
                    // Since we can't determine the exact custom object from ID alone,
                    // we'll rely on objectApiName being provided by the Quick Action
                    this.objectApiName = this.objectApiName || 'Opportunity_Group__c';
                }
                console.log('[getSportData] Derived objectApiName from recordId prefix:', this.objectApiName);
            }
            
            this.hasExecuted = true;
            this.executeAction();
        }
    }
    
    /**
     * @description Main entry point - calls getSportData Apex method with proper error handling
     */
    executeAction() {
        try {
            console.log('[getSportData] executeAction - Starting execution');
            console.log('[getSportData] recordId:', this.recordId);
            console.log('[getSportData] objectApiName:', this.objectApiName);
            
            // Validate required parameters
            if (!this.recordId) {
                console.error('[getSportData] ERROR: Record ID is missing');
                this.handleError(new Error('Record ID is required'));
                return;
            }
            
            if (!this.objectApiName) {
                console.error('[getSportData] ERROR: Object type is missing');
                this.handleError(new Error('Object type is required'));
                return;
            }
            
            console.log('[getSportData] Calling Apex method getSportData with params:', {
                recordId: this.recordId,
                objectType: this.objectApiName
            });
            
            // Call Apex method with proper error handling
            getSportDataApex({ 
                recordId: this.recordId, 
                objectType: this.objectApiName 
            })
            .then(result => {
                console.log('[getSportData] Apex method SUCCESS - Result received:', result);
                console.log('[getSportData] Result success:', result?.success);
                console.log('[getSportData] Result message:', result?.message);
                console.log('[getSportData] Result errorMessage:', result?.errorMessage);
                this.handleResult(result);
            })
            .catch(error => {
                console.error('[getSportData] Apex method ERROR - Promise rejected:', error);
                console.error('[getSportData] Error type:', typeof error);
                console.error('[getSportData] Error keys:', Object.keys(error || {}));
                console.error('[getSportData] Full error:', JSON.stringify(error, null, 2));
                this.handleError(error);
            });
            
        } catch (error) {
            console.error('[getSportData] CRITICAL ERROR in executeAction:', error);
            console.error('[getSportData] Error stack:', error?.stack);
            this.handleError(error);
        }
    }
    
    /**
     * @description Handle successful API response
     */
    handleResult(result) {
        console.log('[getSportData] handleResult - Processing result');
        console.log('[getSportData] Result object:', result);
        
        this.isLoading = false;
        
        if (!result) {
            console.error('[getSportData] ERROR: Result is null or undefined');
            this.handleError(new Error('No result returned from Apex method'));
            return;
        }
        
        if (result.success) {
            console.log('[getSportData] SUCCESS - Operation completed successfully');
            console.log('[getSportData] Success message:', result.message);
            this.showToast('Success', result.message || 'Operation completed successfully', 'success');
            // Close Quick Action after short delay to show toast
            setTimeout(() => {
                console.log('[getSportData] Closing Quick Action and refreshing page');
                this.closeAction();
                this.refreshPage();
            }, 1500);
        } else {
            console.error('[getSportData] ERROR - Operation failed');
            console.error('[getSportData] Error message:', result.errorMessage);
            this.showToast('Error', result.errorMessage || 'An error occurred', 'error');
            // Keep action open on error so user can see the message
            setTimeout(() => {
                console.log('[getSportData] Closing Quick Action after error display');
                this.closeAction();
            }, 3000);
        }
    }
    
    /**
     * @description Handle errors with comprehensive error parsing
     */
    handleError(error) {
        this.isLoading = false;
        
        let errorMessage = 'An unexpected error occurred';
        
        try {
            if (error) {
                // Handle Apex exception
                if (error.body) {
                    if (error.body.message) {
                        errorMessage = error.body.message;
                    } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                        errorMessage = error.body.pageErrors[0].message;
                    } else if (error.body.fieldErrors) {
                        const fieldErrors = Object.values(error.body.fieldErrors);
                        if (fieldErrors.length > 0 && fieldErrors[0].length > 0) {
                            errorMessage = fieldErrors[0][0].message;
                        }
                    }
                } 
                // Handle standard JavaScript error
                else if (error.message) {
                    errorMessage = error.message;
                } 
                // Handle string errors
                else if (typeof error === 'string') {
                    errorMessage = error;
                }
                
                // Log full error for debugging
                console.error('Full error object:', JSON.stringify(error, null, 2));
            }
        } catch (parseError) {
            console.error('Error parsing error object:', parseError);
            errorMessage = 'An error occurred. Please check the browser console for details.';
        }
        
        this.errorMessage = errorMessage;
        this.showToast('Error', errorMessage, 'error');
        
        // Close action after showing error
        setTimeout(() => {
            this.closeAction();
        }, 4000);
    }
    
    /**
     * @description Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
    
    /**
     * @description Close the Quick Action
     */
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    /**
     * @description Refresh the record page
     */
    refreshPage() {
        // Use NavigationMixin or eval to refresh
        eval("$A.get('e.force:refreshView').fire();");
    }
}