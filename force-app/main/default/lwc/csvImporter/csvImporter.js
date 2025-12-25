import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableObjects from '@salesforce/apex/CSVImportController.getAvailableObjects';
import getObjectFields from '@salesforce/apex/CSVImportController.getObjectFields';
import parseCSVHeaders from '@salesforce/apex/CSVImportController.parseCSVHeaders';
import importCSVData from '@salesforce/apex/CSVImportController.importCSVData';
import importNRLData from '@salesforce/apex/CSVImportController.importNRLData';

export default class CsvImporter extends LightningElement {
    @track csvContent = '';
    @track csvHeaders = [];
    @track selectedObject = '';
    @track fieldMappings = {};
    @track externalIdField = '';
    @track importResult = null;
    @track isImporting = false;
    @track importMode = 'generic';

    objectOptions = [];
    fieldOptions = [];

    importModeOptions = [
        { label: 'Generic Import', value: 'generic' },
        { label: 'NRL Import (Pre-configured)', value: 'nrl' }
    ];

    connectedCallback() {
        this.loadObjectOptions();
    }

    // Load available objects
    loadObjectOptions() {
        getAvailableObjects()
            .then(result => {
                this.objectOptions = result.map(opt => ({
                    label: opt.label,
                    value: opt.value
                }));
            })
            .catch(error => {
                this.showError('Error loading objects', error);
            });
    }

    // Handle import mode change
    handleImportModeChange(event) {
        this.importMode = event.detail.value;
        this.clearResults();
    }

    // Handle file upload
    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            if (!file.name.endsWith('.csv')) {
                this.showError('Invalid File', new Error('Please select a CSV file'));
                return;
            }

            const reader = new FileReader();
            reader.onload = () => {
                this.csvContent = reader.result;
                this.parseHeaders();
            };
            reader.onerror = () => {
                this.showError('File Read Error', new Error('Failed to read file'));
            };
            reader.readAsText(file);
        }
    }

    // Parse CSV headers
    parseHeaders() {
        parseCSVHeaders({ csvContent: this.csvContent })
            .then(result => {
                this.csvHeaders = result;
                this.showSuccess('CSV Loaded', `${this.csvHeaders.length} columns detected`);
            })
            .catch(error => {
                this.showError('CSV Parse Error', error);
            });
    }

    // Handle object selection
    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.loadObjectFields();
        this.fieldMappings = {};
    }

    // Load fields for selected object
    loadObjectFields() {
        getObjectFields({ objectName: this.selectedObject })
            .then(result => {
                this.fieldOptions = result.map(field => ({
                    label: `${field.label} (${field.name})`,
                    value: field.name
                }));
            })
            .catch(error => {
                this.showError('Error loading fields', error);
            });
    }

    // Handle field mapping change
    handleFieldMappingChange(event) {
        const csvColumn = event.target.dataset.csvColumn;
        const salesforceField = event.detail.value;
        
        if (salesforceField) {
            this.fieldMappings[csvColumn] = salesforceField;
        } else {
            delete this.fieldMappings[csvColumn];
        }
    }

    // Handle external ID field change
    handleExternalIdChange(event) {
        this.externalIdField = event.detail.value;
    }

    // Handle import
    handleImport() {
        if (!this.csvContent) {
            this.showError('No CSV', new Error('Please upload a CSV file first'));
            return;
        }

        if (this.importMode === 'nrl') {
            this.importNRL();
        } else {
            this.importGeneric();
        }
    }

    // Import using generic importer
    importGeneric() {
        if (!this.selectedObject) {
            this.showError('No Object Selected', new Error('Please select a target object'));
            return;
        }

        if (Object.keys(this.fieldMappings).length === 0) {
            this.showError('No Mappings', new Error('Please map at least one field'));
            return;
        }

        this.isImporting = true;
        this.importResult = null;

        importCSVData({
            csvContent: this.csvContent,
            objectName: this.selectedObject,
            fieldMappingsJson: JSON.stringify(this.fieldMappings),
            lookupMappingsJson: '',
            externalIdField: this.externalIdField
        })
            .then(result => {
                this.importResult = result;
                if (result.success) {
                    this.showSuccess('Import Complete', result.summary);
                } else {
                    this.showWarning('Import Completed with Errors', result.summary);
                }
            })
            .catch(error => {
                this.showError('Import Failed', error);
            })
            .finally(() => {
                this.isImporting = false;
            });
    }

    // Import using NRL helper
    importNRL() {
        this.isImporting = true;
        this.importResult = null;

        importNRLData({ csvContent: this.csvContent })
            .then(result => {
                this.importResult = result;
                if (result.overallSuccess) {
                    this.showSuccess('NRL Import Complete', result.summary);
                } else {
                    this.showWarning('NRL Import Completed with Errors', result.summary);
                }
            })
            .catch(error => {
                this.showError('NRL Import Failed', error);
            })
            .finally(() => {
                this.isImporting = false;
            });
    }

    // Handle clear
    handleClear() {
        this.csvContent = '';
        this.csvHeaders = [];
        this.selectedObject = '';
        this.fieldMappings = {};
        this.externalIdField = '';
        this.importResult = null;
        this.fieldOptions = [];
    }

    // Clear results only
    clearResults() {
        this.importResult = null;
    }

    // Computed properties
    get isGenericMode() {
        return this.importMode === 'generic';
    }

    get isNRLMode() {
        return this.importMode === 'nrl';
    }

    get importButtonLabel() {
        return this.isNRLMode ? 'Import NRL Data' : 'Import Data';
    }

    get hasErrors() {
        return this.importResult && 
               this.importResult.errors && 
               this.importResult.errors.length > 0;
    }

    get resultCardClass() {
        if (!this.importResult) return '';
        
        const baseClass = 'slds-box';
        if (this.importResult.success || this.importResult.overallSuccess) {
            return `${baseClass} slds-theme_success`;
        } else {
            return `${baseClass} slds-theme_warning`;
        }
    }

    get nrlResultBreakdown() {
        if (!this.isNRLMode || !this.importResult || !this.importResult.resultsByType) {
            return null;
        }

        return Object.keys(this.importResult.resultsByType).map(type => ({
            type: type,
            created: this.importResult.resultsByType[type].recordsCreated
        }));
    }

    // Toast helpers
    showSuccess(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        }));
    }

    showWarning(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning',
            mode: 'sticky'
        }));
    }

    showError(title, error) {
        const message = error.body?.message || error.message || 'Unknown error';
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
    }
}

