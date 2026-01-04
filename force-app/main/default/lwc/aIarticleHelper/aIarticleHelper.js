/**
 * AI Article Helper Component
 * 
 * JAVASCRIPT DEVELOPER I EXAM CONCEPTS DEMONSTRATED:
 * 
 * 1. VARIABLES & SCOPE (23% of exam)
 *    - @track decorator for reactive properties
 *    - const, let declarations with proper scoping
 *    - Property initialization patterns
 * 
 * 2. OBJECTS & FUNCTIONS (25% of exam)
 *    - Class-based component structure
 *    - Arrow functions vs traditional functions
 *    - Object destructuring
 *    - Getters and computed properties
 * 
 * 3. ASYNCHRONOUS PROGRAMMING (13% of exam)
 *    - Promises with .then().catch()
 *    - async/await pattern
 *    - Imperative Apex calls
 * 
 * 4. ERROR HANDLING (7% of exam)
 *    - try-catch-finally blocks
 *    - Error message display
 *    - Graceful degradation
 * 
 * 5. BROWSER & EVENTS (17% of exam)
 *    - Event handlers (onclick, onchange)
 *    - Event.target usage
 *    - preventDefault() concepts
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// EXAM CONCEPT: Importing Apex methods for server-side calls
import generateArticle from '@salesforce/apex/ArticleGeneratorController.generateArticle';
import saveArticle from '@salesforce/apex/ArticleGeneratorController.saveArticle';
import { getRecord } from 'lightning/uiRecordApi';

/**
 * EXAM CONCEPT: const for constants (cannot be reassigned)
 * These objects demonstrate Object.freeze() equivalent behavior
 */
const ARTICLE_TYPES = [
    { label: 'Match Preview', value: 'matchPreview' },
    { label: 'Match Recap', value: 'matchRecap' },
    { label: 'Team Analysis', value: 'teamAnalysis' },
    { label: 'Player Profile', value: 'playerProfile' },
    { label: 'Season Review', value: 'seasonReview' }
];

// EXAM CONCEPT: Array of objects for sport types
const SPORT_TYPES = [
    { label: 'Soccer', value: 'Soccer' },
    { label: 'Basketball', value: 'Basketball' },
    { label: 'Football', value: 'Football' },
    { label: 'Baseball', value: 'Baseball' },
    { label: 'Hockey', value: 'Hockey' }
];

/**
 * EXAM CONCEPT: Class declaration and extends
 * NavigationMixin demonstrates mixins/composition pattern
 */
export default class AiArticleHelper extends NavigationMixin(LightningElement) {
    
    // ============================================================================
    // EXAM CONCEPT: Property Declarations with Decorators
    // @track makes properties reactive (causes re-render on change)
    // ============================================================================
    
    @track articleType = '';
    @track selectedMatchId;
    @track selectedTeamId;
    @track selectedPlayerId;
    @track additionalContext = '';
    @track generatedHeadline = '';
    @track generatedBody = '';
    @track readingTime = 0;
    @track sportType = '';
    @track aiProvider = '';
    @track tokensUsed = 0;
    
    // State management properties
    @track isLoading = false;
    @track isSaving = false;
    @track showConfigStep = true;
    @track showResultStep = false;
    @track error;
    @track success;

    // ============================================================================
    // EXAM CONCEPT: Getters (Computed Properties)
    // These demonstrate the getter pattern for derived values
    // Getters are evaluated each time they're accessed
    // ============================================================================
    
    /**
     * EXAM CONCEPT: Array property returned as-is
     * Arrays are objects in JavaScript (typeof [] === 'object')
     */
    get articleTypeOptions() {
        // EXAM CONCEPT: Returning reference to array
        // Could use [...ARTICLE_TYPES] for shallow copy
        return ARTICLE_TYPES;
    }

    get sportTypeOptions() {
        return SPORT_TYPES;
    }

    /**
     * EXAM CONCEPT: Conditional logic in getter
     * Boolean expressions and comparison operators
     */
    get showMatchSelector() {
        // EXAM CONCEPT: === strict equality (type and value)
        return this.articleType === 'matchPreview' || this.articleType === 'matchRecap';
    }

    get showTeamSelector() {
        return this.articleType === 'teamAnalysis' || this.articleType === 'seasonReview';
    }

    get showPlayerSelector() {
        return this.articleType === 'playerProfile';
    }

    /**
     * EXAM CONCEPT: Multiple condition checking
     * Logical AND (&&) and OR (||) operators
     * Falsy values: null, undefined, false, 0, '', NaN
     */
    get isGenerateDisabled() {
        // EXAM CONCEPT: ! (NOT) operator
        if (!this.articleType) return true;
        
        // EXAM CONCEPT: Switch-case alternative using if-else
        if (this.showMatchSelector && !this.selectedMatchId) return true;
        if (this.showTeamSelector && !this.selectedTeamId) return true;
        if (this.showPlayerSelector && !this.selectedPlayerId) return true;
        
        return false;
    }

    /**
     * EXAM CONCEPT: String methods and type coercion
     * .length property on strings
     */
    get characterCount() {
        // EXAM CONCEPT: Ternary operator (condition ? true : false)
        // Type coercion: this.additionalContext || '' ensures string
        return (this.additionalContext || '').length;
    }

    // ============================================================================
    // EXAM CONCEPT: Event Handlers
    // These methods handle user interactions from the template
    // Arrow functions vs traditional function declarations
    // ============================================================================

    /**
     * EXAM CONCEPT: Event handler with event parameter
     * Event.target.value to get input value
     * event.detail.value for Lightning components
     */
    handleArticleTypeChange(event) {
        // EXAM CONCEPT: Accessing object properties
        // event.detail is specific to Lightning Web Components
        this.articleType = event.detail.value;
        
        // EXAM CONCEPT: Side effects - resetting related fields
        this.selectedMatchId = null;
        this.selectedTeamId = null;
        this.selectedPlayerId = null;
    }

    /**
     * EXAM CONCEPT: Arrow function syntax (ES6)
     * Automatically binds 'this' to component context
     */
    handleMatchSelection = (event) => {
        // EXAM CONCEPT: Object destructuring from event
        const { recordId } = event.detail;
        this.selectedMatchId = recordId;
    }

    handleTeamSelection = (event) => {
        this.selectedTeamId = event.detail.recordId;
    }

    handlePlayerSelection = (event) => {
        this.selectedPlayerId = event.detail.recordId;
    }

    /**
     * EXAM CONCEPT: Traditional function declaration
     * Must use .bind(this) or arrow function to preserve context
     */
    handleContextChange(event) {
        // EXAM CONCEPT: String assignment from input
        this.additionalContext = event.target.value;
    }

    handleHeadlineChange(event) {
        this.generatedHeadline = event.target.value;
    }

    handleBodyChange(event) {
        this.generatedBody = event.target.value;
    }

    handleReadingTimeChange(event) {
        // EXAM CONCEPT: Type coercion - converting string to number
        // Number() function vs parseInt() vs parseFloat()
        this.readingTime = Number(event.target.value);
    }

    handleSportTypeChange(event) {
        this.sportType = event.detail.value;
    }

    // ============================================================================
    // EXAM CONCEPT: Asynchronous Operations
    // Promises, async/await, try-catch error handling
    // ============================================================================

    /**
     * EXAM CONCEPT: async function declaration
     * Allows use of await keyword inside
     */
    async handleGenerate() {
        // EXAM CONCEPT: Early return pattern for validation
        if (this.isGenerateDisabled) {
            return;
        }

        // EXAM CONCEPT: State management
        this.isLoading = true;
        this.error = null;
        this.success = null;

        // EXAM CONCEPT: try-catch-finally block
        try {
            // EXAM CONCEPT: Object literal creation
            // Property shorthand: { articleType } same as { articleType: articleType }
            const params = {
                articleType: this.articleType,
                matchId: this.selectedMatchId,
                teamId: this.selectedTeamId,
                playerId: this.selectedPlayerId,
                additionalContext: this.additionalContext
            };

            // EXAM CONCEPT: await keyword pauses execution until Promise resolves
            // generateArticle returns a Promise
            const result = await generateArticle({ params });

            // EXAM CONCEPT: Object destructuring assignment
            // Extracts properties from result object
            const {
                headline,
                body,
                readingTime,
                sport,
                provider,
                tokensUsed
            } = result;

            // EXAM CONCEPT: Property assignment
            this.generatedHeadline = headline;
            this.generatedBody = body;
            this.readingTime = readingTime;
            this.sportType = sport;
            this.aiProvider = provider;
            this.tokensUsed = tokensUsed;

            // EXAM CONCEPT: Updating state to show different view
            this.showConfigStep = false;
            this.showResultStep = true;

            // EXAM CONCEPT: Calling helper method
            this.showSuccessToast('Article generated successfully!');

        } catch (error) {
            // EXAM CONCEPT: Error handling
            // Accessing error.body.message (nested property access)
            this.error = this.getErrorMessage(error);
            this.showErrorToast(this.error);
            
        } finally {
            // EXAM CONCEPT: finally block executes regardless of try/catch outcome
            // Used for cleanup operations
            this.isLoading = false;
        }
    }

    /**
     * EXAM CONCEPT: Async/await with Apex callout
     * Error handling and state management
     */
    async handleSave() {
        this.isSaving = true;
        this.error = null;
        this.success = null;

        try {
            // EXAM CONCEPT: Creating object with computed property values
            const articleData = {
                heading: this.generatedHeadline,
                body: this.generatedBody,
                articleType: this.articleType,
                matchId: this.selectedMatchId,
                teamId: this.selectedTeamId,
                playerId: this.selectedPlayerId,
                readingTime: this.readingTime,
                sportType: this.sportType,
                source: `AI: ${this.aiProvider}`
            };

            // EXAM CONCEPT: await for async Apex call
            const savedArticleId = await saveArticle({ articleData });

            this.success = 'Article saved successfully!';
            this.showSuccessToast(this.success);

            // EXAM CONCEPT: setTimeout for delayed execution
            // setTimeout is asynchronous (callback-based)
            setTimeout(() => {
                this.navigateToArticle(savedArticleId);
            }, 1500);

        } catch (error) {
            this.error = this.getErrorMessage(error);
            this.showErrorToast(this.error);
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * EXAM CONCEPT: Method for regenerating (calls existing method)
     * Method reuse and composition
     */
    handleRegenerate() {
        this.showResultStep = false;
        this.showConfigStep = true;
        // EXAM CONCEPT: Calling async method without await
        // Returns a Promise that we're not waiting for
        this.handleGenerate();
    }

    /**
     * EXAM CONCEPT: Resetting component state
     * Setting multiple properties to initial values
     */
    handleReset() {
        // EXAM CONCEPT: Setting properties to falsy values
        // Empty string '', null, 0 are all falsy
        this.articleType = '';
        this.selectedMatchId = null;
        this.selectedTeamId = null;
        this.selectedPlayerId = null;
        this.additionalContext = '';
        this.generatedHeadline = '';
        this.generatedBody = '';
        this.readingTime = 0;
        this.sportType = '';
        this.aiProvider = '';
        this.tokensUsed = 0;
        this.showConfigStep = true;
        this.showResultStep = false;
        this.error = null;
        this.success = null;
    }

    // ============================================================================
    // EXAM CONCEPT: Helper Methods (Private Methods)
    // These would be private in a real class but LWC doesn't support private yet
    // ============================================================================

    /**
     * EXAM CONCEPT: Error parsing from Salesforce error format
     * Nested property access with optional chaining
     */
    getErrorMessage(error) {
        // EXAM CONCEPT: Conditional (ternary) operator chaining
        // Checks multiple properties for error message
        return error.body?.message 
            || error.body?.pageErrors?.[0]?.message
            || error.message 
            || 'An unknown error occurred';
    }

    /**
     * EXAM CONCEPT: Creating and dispatching custom events
     * ShowToastEvent is a standard Lightning event
     */
    showSuccessToast(message) {
        // EXAM CONCEPT: new keyword to create object instance
        // Object literal passed as constructor parameter
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        // EXAM CONCEPT: dispatchEvent() method
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

    /**
     * EXAM CONCEPT: Navigation using NavigationMixin
     * Imperative navigation to record page
     */
    navigateToArticle(recordId) {
        // EXAM CONCEPT: this[NavigationMixin.Navigate] - bracket notation
        // Using mixin method
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Article__c',
                actionName: 'view'
            }
        });
    }
}

/**
 * ============================================================================
 * KEY EXAM CONCEPTS SUMMARY:
 * ============================================================================
 * 
 * 1. VARIABLE DECLARATIONS:
 *    - const for constants (ARTICLE_TYPES, SPORT_TYPES)
 *    - @track decorator for reactive properties
 *    - let would be used in helper methods (scoped to block)
 * 
 * 2. DATA TYPES:
 *    - String: articleType, generatedHeadline
 *    - Number: readingTime, tokensUsed
 *    - Boolean: isLoading, isSaving, showConfigStep
 *    - Object: event.detail, params object
 *    - Array: ARTICLE_TYPES, SPORT_TYPES
 *    - null/undefined: selectedMatchId = null
 * 
 * 3. OPERATORS:
 *    - Comparison: ===, !==, ||, &&
 *    - Logical: !, ||, &&
 *    - Ternary: condition ? true : false
 *    - Optional chaining: error.body?.message
 *    - Nullish coalescing: ?? (not used here but important)
 * 
 * 4. FUNCTIONS:
 *    - Arrow functions: handleMatchSelection = (event) => {}
 *    - Traditional functions: handleGenerate() {}
 *    - Async functions: async handleGenerate() {}
 *    - Getters: get articleTypeOptions() {}
 * 
 * 5. OBJECTS & CLASSES:
 *    - Class declaration: export default class
 *    - Object literals: { key: value }
 *    - Object destructuring: const { headline, body } = result
 *    - Property access: this.articleType, event.detail.value
 *    - Nested access: error.body?.message
 * 
 * 6. ARRAYS:
 *    - Array literals: [{ label, value }]
 *    - Array methods: (shown in other components)
 * 
 * 7. ASYNC PROGRAMMING:
 *    - Promises: generateArticle returns Promise
 *    - async/await: async handleGenerate(), await generateArticle()
 *    - try-catch-finally: error handling
 *    - setTimeout: delayed execution
 * 
 * 8. ERROR HANDLING:
 *    - try-catch blocks
 *    - Error object properties
 *    - Graceful error messages
 * 
 * 9. EVENTS:
 *    - Event handlers: onclick, onchange
 *    - Event object: event.detail, event.target
 *    - Custom events: ShowToastEvent
 *    - dispatchEvent(): event propagation
 * 
 * 10. THIS CONTEXT:
 *     - Arrow functions maintain 'this' context
 *     - Traditional functions need .bind(this) or arrow wrapper
 *     - this refers to component instance
 */