/**
 * Lineup Builder Component - JavaScript Controller
 * 
 * JAVASCRIPT DEVELOPER I EXAM CONCEPTS:
 * 
 * 1. BROWSER & EVENTS (17% of exam)
 *    - Drag and Drop API (dragstart, dragover, drop, dragend)
 *    - Event.preventDefault() and Event.stopPropagation()
 *    - Event.dataTransfer for drag data
 *    - Event.target vs Event.currentTarget
 * 
 * 2. ARRAYS & COLLECTIONS (Part of 23%)
 *    - Array.map() - transform arrays
 *    - Array.filter() - filter arrays
 *    - Array.find() - find single element
 *    - Array.findIndex() - find element index
 *    - Array.splice() - modify array in place
 *    - Array spread operator [...]
 * 
 * 3. OBJECTS & FUNCTIONS (25% of exam)
 *    - Object destructuring
 *    - Computed property names
 *    - Object.assign() for cloning
 *    - Arrow functions vs traditional
 *    - Getters for computed properties
 * 
 * 4. ASYNCHRONOUS PROGRAMMING (13% of exam)
 *    - async/await with Apex calls
 *    - Promise handling
 *    - Wire adapters
 */

import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

// EXAM CONCEPT: Importing Apex methods (Server Side JavaScript 8%)
import getTeamPlayers from '@salesforce/apex/LineupController.getTeamPlayers';
import getMatchTeams from '@salesforce/apex/LineupController.getMatchTeams';
import saveLineup from '@salesforce/apex/LineupController.saveLineup';

// EXAM CONCEPT: const for immutable object references
// Object.freeze() equivalent - these arrays won't be reassigned
const FORMATIONS = [
    { label: '4-3-3', value: '4-3-3', defenders: 4, midfielders: 3, forwards: 3 },
    { label: '4-4-2', value: '4-4-2', defenders: 4, midfielders: 4, forwards: 2 },
    { label: '4-2-3-1', value: '4-2-3-1', defenders: 4, midfielders: 5, forwards: 1 },
    { label: '3-5-2', value: '3-5-2', defenders: 3, midfielders: 5, forwards: 2 },
    { label: '3-4-3', value: '3-4-3', defenders: 3, midfielders: 4, forwards: 3 },
    { label: '5-3-2', value: '5-3-2', defenders: 5, midfielders: 3, forwards: 2 }
];

// EXAM CONCEPT: Object with nested structure
const POSITION_STYLES = {
    goalkeeper: { top: '90%', left: '50%' },
    defense: { top: '70%', flexDirection: 'row', justifyContent: 'space-around' },
    midfield: { top: '45%', flexDirection: 'row', justifyContent: 'space-around' },
    attack: { top: '20%', flexDirection: 'row', justifyContent: 'space-around' }
};

export default class LineupBuilder extends LightningElement {
    
    // ============================================================================
    // EXAM CONCEPT: Property Declarations with Different Access Modifiers
    // @api - public property (can be set by parent component)
    // @track - reactive property (causes re-render on change)
    // No decorator - private property
    // ============================================================================
    
    @api recordId; // Match record ID when used on record page
    
    @track selectedMatchId;
    @track homeTeamId;
    @track awayTeamId;
    @track selectedFormation = '4-3-3';
    @track teamOptions = [];
    @track availablePlayers = [];
    @track benchPlayers = [];
    @track formationLines = [];
    @track goalkeeperPosition = { player: null };
    @track captainId;
    @track playerSearchTerm = '';
    @track isLoading = false;
    @track isSaving = false;
    
    // EXAM CONCEPT: Private properties (no decorator)
    // Used internally, not reactive
    draggedPlayerId = null;
    draggedFromPosition = null;
    draggedFromArea = null;

    // ============================================================================
    // EXAM CONCEPT: Lifecycle Hooks
    // connectedCallback() runs when component is inserted into DOM
    // ============================================================================
    
    connectedCallback() {
        // EXAM CONCEPT: Conditional execution based on property value
        if (this.recordId) {
            this.selectedMatchId = this.recordId;
            this.loadMatchData();
        }
        
        // EXAM CONCEPT: Calling method to initialize state
        this.initializeFormation();
    }

    // ============================================================================
    // EXAM CONCEPT: Getters (Computed Properties)
    // Evaluated each time accessed, not stored
    // ============================================================================
    
    /**
     * EXAM CONCEPT: Array property returned directly
     * const ensures FORMATIONS reference won't change
     */
    get formationOptions() {
        return FORMATIONS;
    }

    /**
     * EXAM CONCEPT: Array.filter() method
     * Creates new array with elements that pass test
     * filter() does NOT mutate original array
     */
    get filteredAvailablePlayers() {
        // EXAM CONCEPT: Early return pattern
        if (!this.playerSearchTerm) {
            return this.availablePlayers;
        }
        
        // EXAM CONCEPT: String methods - toLowerCase(), includes()
        // Arrow function in filter callback
        const searchLower = this.playerSearchTerm.toLowerCase();
        return this.availablePlayers.filter(player => 
            player.Name.toLowerCase().includes(searchLower) ||
            player.Position__c.toLowerCase().includes(searchLower)
        );
    }

    /**
     * EXAM CONCEPT: Boolean getter with logical operators
     * .length property on arrays
     */
    get hasAvailablePlayers() {
        // EXAM CONCEPT: Logical AND (&&) for null check and length
        return this.availablePlayers && this.availablePlayers.length > 0;
    }

    get hasBenchPlayers() {
        return this.benchPlayers && this.benchPlayers.length > 0;
    }

    /**
     * EXAM CONCEPT: Array.map() to transform data
     * map() creates new array, doesn't mutate original
     * Object destructuring in arrow function parameter
     */
    get startingXIOptions() {
        // EXAM CONCEPT: Nested map - iterating formationLines and positions
        const startingPlayers = [];
        
        this.formationLines.forEach(line => {
            line.positions.forEach(position => {
                if (position.player) {
                    startingPlayers.push(position.player);
                }
            });
        });
        
        // Add goalkeeper
        if (this.goalkeeperPosition.player) {
            startingPlayers.push(this.goalkeeperPosition.player);
        }
        
        // EXAM CONCEPT: map() with object literal return
        // Property shorthand: { value, label } same as { value: value, label: label }
        return startingPlayers.map(player => ({
            value: player.Id,
            label: `${player.Jersey_Number__c} - ${player.Name}`
        }));
    }

    // ============================================================================
    // EXAM CONCEPT: Event Handlers
    // These handle user interactions from template
    // ============================================================================

    /**
     * EXAM CONCEPT: Event handler accessing event.detail
     * LWC components use event.detail for custom event data
     */
    handleMatchSelection(event) {
        this.selectedMatchId = event.detail.recordId;
        this.loadMatchData();
    }

    /**
     * EXAM CONCEPT: Async event handler
     * async keyword allows await inside function
     */
    async handleHomeTeamChange(event) {
        this.homeTeamId = event.detail.value;
        
        // EXAM CONCEPT: Conditional execution
        if (this.homeTeamId) {
            await this.loadTeamPlayers();
        }
    }

    handleFormationChange(event) {
        this.selectedFormation = event.detail.value;
        // EXAM CONCEPT: Method call to reinitialize based on new selection
        this.initializeFormation();
    }

    handlePlayerSearch(event) {
        // EXAM CONCEPT: event.target.value vs event.detail.value
        // Lightning components use event.detail
        this.playerSearchTerm = event.target.value;
    }

    handleCaptainChange(event) {
        this.captainId = event.detail.value;
    }

    // ============================================================================
    // EXAM CONCEPT: Drag and Drop Event Handlers
    // Core Browser & Events exam topic (17%)
    // ============================================================================

    /**
     * EXAM CONCEPT: dragstart event
     * Sets data to be transferred during drag
     * event.dataTransfer API
     */
    handleDragStart(event) {
        // EXAM CONCEPT: data-* attributes accessed via dataset
        // event.target is the dragged element
        this.draggedPlayerId = event.target.dataset.playerId;
        this.draggedFromArea = 'available';
        
        // EXAM CONCEPT: DataTransfer API for drag-drop
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedPlayerId);
        
        // EXAM CONCEPT: Adding CSS class during drag
        event.target.classList.add('dragging');
    }

    /**
     * EXAM CONCEPT: Dragging player from formation position
     * Stores position information for later use
     */
    handlePlayerDragStart(event) {
        this.draggedPlayerId = event.target.dataset.playerId;
        this.draggedFromPosition = event.target.dataset.positionId;
        this.draggedFromArea = 'formation';
        
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedPlayerId);
        event.target.classList.add('dragging');
    }

    /**
     * EXAM CONCEPT: Dragging from bench
     */
    handleBenchDragStart(event) {
        this.draggedPlayerId = event.target.dataset.playerId;
        this.draggedFromArea = 'bench';
        
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedPlayerId);
        event.target.classList.add('dragging');
    }

    /**
     * EXAM CONCEPT: dragover event
     * CRITICAL: Must call preventDefault() to allow drop
     * Without preventDefault(), drop event won't fire
     */
    handleDragOver(event) {
        // EXAM CONCEPT: preventDefault() prevents default behavior
        // Default behavior is to not allow dropping
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    /**
     * EXAM CONCEPT: drop event - main drop handler
     * This is where the actual position assignment happens
     */
    handleDrop(event) {
        // EXAM CONCEPT: preventDefault() prevents default action (like opening link)
        event.preventDefault();
        
        // EXAM CONCEPT: event.currentTarget vs event.target
        // currentTarget = element with event listener
        // target = element that triggered event
        const positionId = event.currentTarget.dataset.positionId;
        const lineId = event.currentTarget.dataset.lineId;
        
        // EXAM CONCEPT: Early return if no player being dragged
        if (!this.draggedPlayerId) return;
        
        // EXAM CONCEPT: Method call with parameters
        this.assignPlayerToPosition(this.draggedPlayerId, positionId, lineId);
        
        // EXAM CONCEPT: Reset tracking variables
        this.draggedPlayerId = null;
        this.draggedFromPosition = null;
        this.draggedFromArea = null;
    }

    /**
     * EXAM CONCEPT: Drop to bench handler
     */
    handleDropToBench(event) {
        event.preventDefault();
        
        if (!this.draggedPlayerId) return;
        
        this.movePlayerToBench(this.draggedPlayerId);
        
        this.draggedPlayerId = null;
        this.draggedFromPosition = null;
        this.draggedFromArea = null;
    }

    /**
     * EXAM CONCEPT: dragend event - cleanup after drag
     * Fires regardless of whether drop succeeded
     */
    handleDragEnd(event) {
        // EXAM CONCEPT: Removing CSS class
        event.target.classList.remove('dragging');
    }

    // ============================================================================
    // EXAM CONCEPT: Data Loading Methods (Async Programming 13%)
    // ============================================================================

    /**
     * EXAM CONCEPT: async method with try-catch
     * Error handling (7% of exam)
     */
    async loadMatchData() {
        this.isLoading = true;
        
        try {
            // EXAM CONCEPT: await pauses execution until Promise resolves
            // Apex method returns a Promise
            const teams = await getMatchTeams({ matchId: this.selectedMatchId });
            
            // EXAM CONCEPT: Array.map() to transform Apex result
            // Creates array of objects with label/value structure
            this.teamOptions = teams.map(team => ({
                label: team.Name,
                value: team.Id
            }));
            
        } catch (error) {
            // EXAM CONCEPT: Error handling
            this.showToast('Error', 'Failed to load match teams', 'error');
            console.error('Error loading teams:', error);
        } finally {
            // EXAM CONCEPT: finally block executes regardless of try/catch outcome
            this.isLoading = false;
        }
    }

    /**
     * EXAM CONCEPT: Loading players with async/await
     */
    async loadTeamPlayers() {
        this.isLoading = true;
        
        try {
            const players = await getTeamPlayers({ teamId: this.homeTeamId });
            
            // EXAM CONCEPT: Spread operator to create new array
            // This ensures reactivity in LWC
            this.availablePlayers = [...players];
            this.benchPlayers = [];
            
            // EXAM CONCEPT: Method call to reset formation
            this.initializeFormation();
            
        } catch (error) {
            this.showToast('Error', 'Failed to load players', 'error');
            console.error('Error loading players:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // ============================================================================
    // EXAM CONCEPT: Formation Management (Complex Object Manipulation)
    // ============================================================================

    /**
     * EXAM CONCEPT: Initializing complex nested structure
     * Arrays of objects containing arrays
     */
    initializeFormation() {
        // EXAM CONCEPT: Array.find() to locate single element
        // Returns first element that satisfies condition, or undefined
        const formation = FORMATIONS.find(f => f.value === this.selectedFormation);
        
        if (!formation) return;
        
        // EXAM CONCEPT: Array construction with specific size
        // Array(n).fill().map() pattern to create array of objects
        const defenderPositions = Array(formation.defenders).fill(null).map((_, index) => ({
            id: `DEF-${index}`,
            player: null
        }));
        
        const midfielderPositions = Array(formation.midfielders).fill(null).map((_, index) => ({
            id: `MID-${index}`,
            player: null
        }));
        
        const forwardPositions = Array(formation.forwards).fill(null).map((_, index) => ({
            id: `FWD-${index}`,
            player: null
        }));
        
        // EXAM CONCEPT: Creating array of objects
        // Each line has id, positions array, and style object
        this.formationLines = [
            {
                id: 'attack',
                positions: forwardPositions,
                style: this.getLineStyle('attack')
            },
            {
                id: 'midfield',
                positions: midfielderPositions,
                style: this.getLineStyle('midfield')
            },
            {
                id: 'defense',
                positions: defenderPositions,
                style: this.getLineStyle('defense')
            }
        ];
        
        // Reset goalkeeper
        this.goalkeeperPosition = { player: null };
    }

    /**
     * EXAM CONCEPT: Template literal strings
     * Object property access with bracket notation
     */
    getLineStyle(lineType) {
        // EXAM CONCEPT: Object destructuring
        const { top, flexDirection, justifyContent } = POSITION_STYLES[lineType];
        
        // EXAM CONCEPT: Template literals with ${} for interpolation
        return `position: absolute; top: ${top}; left: 0; right: 0; display: flex; flex-direction: ${flexDirection}; justify-content: ${justifyContent}; padding: 10px;`;
    }

    // ============================================================================
    // EXAM CONCEPT: Player Assignment Logic (Array Manipulation)
    // ============================================================================

    /**
     * EXAM CONCEPT: Complex state manipulation
     * Demonstrates array methods: find(), findIndex(), splice()
     */
    assignPlayerToPosition(playerId, positionId, lineId) {
        // EXAM CONCEPT: Array.find() to locate player object
        let player = this.availablePlayers.find(p => p.Id === playerId);
        
        // EXAM CONCEPT: Logical OR (||) for fallback
        if (!player) {
            player = this.benchPlayers.find(p => p.Id === playerId);
        }
        
        // Check if dragging from existing position
        if (!player && this.draggedFromArea === 'formation') {
            player = this.findPlayerInFormation(playerId);
        }
        
        if (!player) return;
        
        // Remove player from previous location
        this.removePlayerFromPreviousLocation(playerId);
        
        // EXAM CONCEPT: Special handling for goalkeeper
        if (positionId === 'GK') {
            this.goalkeeperPosition = { player: player };
            return;
        }
        
        // EXAM CONCEPT: Array.find() on nested structure
        // Finding line, then finding position within that line
        const line = this.formationLines.find(l => l.id === lineId);
        if (!line) return;
        
        const position = line.positions.find(p => p.id === positionId);
        if (!position) return;
        
        // If position occupied, move existing player to bench
        if (position.player) {
            this.movePlayerToBench(position.player.Id);
        }
        
        // EXAM CONCEPT: Object property assignment
        position.player = player;
        
        // EXAM CONCEPT: Spread operator to trigger reactivity
        // LWC requires new array reference to detect changes
        this.formationLines = [...this.formationLines];
    }

    /**
     * EXAM CONCEPT: Finding nested object in complex structure
     */
    findPlayerInFormation(playerId) {
        // Check goalkeeper
        if (this.goalkeeperPosition.player?.Id === playerId) {
            return this.goalkeeperPosition.player;
        }
        
        // EXAM CONCEPT: Nested iteration with for...of
        // for...of iterates over values (not indexes)
        for (let line of this.formationLines) {
            for (let position of line.positions) {
                // EXAM CONCEPT: Optional chaining (?.)
                // Safely access nested property, returns undefined if null
                if (position.player?.Id === playerId) {
                    return position.player;
                }
            }
        }
        
        return null;
    }

    /**
     * EXAM CONCEPT: Array.findIndex() and splice()
     * splice() MUTATES the original array
     */
    removePlayerFromPreviousLocation(playerId) {
        // EXAM CONCEPT: findIndex() returns -1 if not found
        let index = this.availablePlayers.findIndex(p => p.Id === playerId);
        if (index !== -1) {
            // EXAM CONCEPT: splice(index, deleteCount)
            // Removes elements from array IN PLACE (mutates)
            this.availablePlayers.splice(index, 1);
            this.availablePlayers = [...this.availablePlayers]; // Trigger reactivity
        }
        
        index = this.benchPlayers.findIndex(p => p.Id === playerId);
        if (index !== -1) {
            this.benchPlayers.splice(index, 1);
            this.benchPlayers = [...this.benchPlayers];
        }
        
        // Remove from goalkeeper
        if (this.goalkeeperPosition.player?.Id === playerId) {
            this.goalkeeperPosition = { player: null };
        }
        
        // EXAM CONCEPT: Nested iteration to remove from formation
        this.formationLines.forEach(line => {
            line.positions.forEach(position => {
                if (position.player?.Id === playerId) {
                    position.player = null;
                }
            });
        });
        
        this.formationLines = [...this.formationLines];
    }

    /**
     * EXAM CONCEPT: Moving player to bench array
     */
    movePlayerToBench(playerId) {
        const player = this.findPlayerInFormation(playerId);
        if (!player) return;
        
        this.removePlayerFromPreviousLocation(playerId);
        
        // EXAM CONCEPT: Array.push() adds to end
        // push() MUTATES array
        this.benchPlayers.push(player);
        this.benchPlayers = [...this.benchPlayers];
    }

    // ============================================================================
    // EXAM CONCEPT: Save Operations (Async with Error Handling)
    // ============================================================================

    /**
     * EXAM CONCEPT: async method with complex object creation
     */
    async handleSaveLineup() {
        this.isSaving = true;
        
        try {
            // EXAM CONCEPT: Building complex object structure
            const lineupData = this.buildLineupData();
            
            // EXAM CONCEPT: JSON.stringify() to convert object to string
            const lineupJSON = JSON.stringify(lineupData);
            
            // EXAM CONCEPT: Object literal with computed properties
            const saveData = {
                matchId: this.selectedMatchId,
                teamId: this.homeTeamId,
                formation: this.selectedFormation,
                captainId: this.captainId,
                lineupJSON: lineupJSON
            };
            
            // EXAM CONCEPT: await for async Apex call
            await saveLineup({ lineupData: saveData });
            
            this.showToast('Success', 'Lineup saved successfully', 'success');
            
        } catch (error) {
            this.showToast('Error', 'Failed to save lineup', 'error');
            console.error('Save error:', error);
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * EXAM CONCEPT: Building complex nested object structure
     * Array.map(), object spread, property access
     */
    buildLineupData() {
        // EXAM CONCEPT: Object literal creation
        const lineup = {
            goalkeeper: this.goalkeeperPosition.player ? {
                playerId: this.goalkeeperPosition.player.Id,
                name: this.goalkeeperPosition.player.Name,
                jerseyNumber: this.goalkeeperPosition.player.Jersey_Number__c,
                position: 'GK'
            } : null,
            
            // EXAM CONCEPT: Array.map() to transform nested structure
            lines: this.formationLines.map(line => ({
                lineId: line.id,
                players: line.positions
                    .filter(pos => pos.player !== null)  // EXAM: filter() removes nulls
                    .map(pos => ({  // EXAM: map() transforms to desired structure
                        playerId: pos.player.Id,
                        positionId: pos.id,
                        name: pos.player.Name,
                        jerseyNumber: pos.player.Jersey_Number__c,
                        position: pos.player.Position__c
                    }))
            })),
            
            // EXAM CONCEPT: Array.map() on bench players
            bench: this.benchPlayers.map(player => ({
                playerId: player.Id,
                name: player.Name,
                jerseyNumber: player.Jersey_Number__c,
                position: player.Position__c
            }))
        };
        
        return lineup;
    }

    /**
     * EXAM CONCEPT: Resetting all state
     */
    handleClearLineup() {
        // EXAM CONCEPT: Calling initialization method
        this.initializeFormation();
        
        // EXAM CONCEPT: Spreading array to create new reference
        // Moves all players back to available
        this.availablePlayers = [
            ...this.availablePlayers,
            ...this.benchPlayers
        ];
        
        this.benchPlayers = [];
        this.captainId = null;
    }

    // ============================================================================
    // EXAM CONCEPT: Helper Methods
    // ============================================================================

    /**
     * EXAM CONCEPT: Creating and dispatching events
     * ShowToastEvent is standard Lightning platform event
     */
    showToast(title, message, variant) {
        // EXAM CONCEPT: new keyword to create object instance
        // Object literal passed to constructor
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        
        // EXAM CONCEPT: dispatchEvent() method
        this.dispatchEvent(event);
    }
}

/**
 * ============================================================================
 * EXAM CONCEPTS SUMMARY FOR LINEUP BUILDER:
 * ============================================================================
 * 
 * BROWSER & EVENTS (17%):
 * - Drag and Drop API: dragstart, dragover, drop, dragend events
 * - event.preventDefault() - prevent default behavior to enable drop
 * - event.stopPropagation() - stop event bubbling
 * - event.dataTransfer - transfer data during drag
 * - event.target vs event.currentTarget
 * - data-* attributes and dataset API
 * - classList.add/remove for dynamic styling
 * 
 * ARRAYS & COLLECTIONS (23%):
 * - Array.map() - transform arrays (non-mutating)
 * - Array.filter() - filter elements (non-mutating)
 * - Array.find() - find single element
 * - Array.findIndex() - get element index
 * - Array.forEach() - iterate with side effects
 * - Array.push() - add to end (mutating)
 * - Array.splice() - add/remove elements (mutating)
 * - Array spread [...arr] - create shallow copy
 * - for...of - iterate over values
 * - Array(n).fill().map() - create array of specific size
 * 
 * OBJECTS & FUNCTIONS (25%):
 * - Object literals and nested objects
 * - Object destructuring: const { prop } = obj
 * - Property shorthand: { value, label }
 * - Computed property names: obj[variable]
 * - Arrow functions: (param) => expression
 * - Traditional functions with 'this' binding
 * - Getters: get propertyName() {}
 * - Optional chaining: obj?.prop?.subprop
 * 
 * ASYNCHRONOUS (13%):
 * - async/await pattern
 * - Promise handling
 * - try-catch-finally
 * - Imperative Apex calls
 * 
 * ERROR HANDLING (7%):
 * - try-catch-finally blocks
 * - Error logging with console.error()
 * - User-friendly error messages
 * 
 * DATA TYPES (Part of 23%):
 * - String, Number, Boolean, Object, Array
 * - null and undefined
 * - typeof operator
 * - Template literals with ${}
 * 
 * OPERATORS:
 * - Comparison: ===, !==
 * - Logical: &&, ||, !
 * - Ternary: condition ? true : false
 * - Nullish coalescing: ??
 * - Optional chaining: ?.
 * - Spread: ...
 */