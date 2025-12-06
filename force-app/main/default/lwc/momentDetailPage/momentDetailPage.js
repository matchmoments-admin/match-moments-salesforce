/**
 * @description Public-facing moment detail page component
 * Displays match context, event details, video, and share options
 * @author Brendan Milton
 * @date 2025-12
 */
import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEventDetails from '@salesforce/apex/MomentPageController.getEventDetails';
import trackEngagement from '@salesforce/apex/MomentPageController.trackEngagement';

export default class MomentDetailPage extends NavigationMixin(LightningElement) {
    @api recordId;
    
    @track event = {};
    @track fixture = {};
    @track period = {};
    @track relatedMoments = [];
    @track allEvents = [];
    
    isLoading = true;
    hasError = false;
    errorMessage = '';
    hasVideo = false;
    hasPlayer = false;
    hasRelatedMoments = false;
    showEmbedCode = false;
    
    connectedCallback() {
        this.trackView();
    }
    
    @wire(getEventDetails, { eventId: '$recordId' })
    wiredEvent({ error, data }) {
        this.isLoading = false;
        
        if (data) {
            this.event = data.event || {};
            this.fixture = data.fixture || {};
            this.period = data.period || {};
            this.relatedMoments = data.relatedMoments || [];
            this.allEvents = data.allEvents || [];
            
            this.hasVideo = !!this.event.videoUrl;
            this.hasPlayer = !!this.event.playerName;
            this.hasRelatedMoments = this.relatedMoments.length > 0;
            this.hasPeriod = !!this.period.periodNumber;
            
            this.setMetaTags();
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || 'Error loading moment details';
            console.error('Error loading event:', error);
        }
    }
    
    // Getters
    get eventIcon() {
        const iconMap = {
            'Goal': '⚽',
            'Penalty Goal': '🎯',
            'Yellow Card': '🟨',
            'Red Card': '🟥',
            'Try': '🏉',
            'Wicket': '🏏',
            'Substitution': '🔄',
            'Conversion': '🏉'
        };
        return iconMap[this.event.eventType] || '📌';
    }
    
    get formattedViralScore() {
        const score = this.event.viralScore || 0;
        if (score >= 1000) {
            return (score / 1000).toFixed(1) + 'k';
        }
        return score.toString();
    }
    
    get scoreDisplay() {
        return `${this.fixture.homeScore || 0} - ${this.fixture.awayScore || 0}`;
    }
    
    get periodLabel() {
        if (!this.period.periodType) return '';
        return `${this.period.periodType} ${this.period.periodNumber}`;
    }
    
    get periodScoreDisplay() {
        if (!this.period.homeScore && !this.period.awayScore) return '';
        return `${this.period.homeScore || 0} - ${this.period.awayScore || 0}`;
    }
    
    get cumulativeScoreDisplay() {
        if (!this.period.cumulativeHomeScore && !this.period.cumulativeAwayScore) return '';
        return `Score at this point: ${this.period.cumulativeHomeScore || 0} - ${this.period.cumulativeAwayScore || 0}`;
    }
    
    // Meta tags for social sharing
    setMetaTags() {
        if (!this.event.socialShareTitle) return;
        
        this.updateMetaTag('og:title', this.event.socialShareTitle);
        this.updateMetaTag('og:description', this.event.socialShareDescription);
        this.updateMetaTag('og:image', this.event.socialMediaImageUrl);
        this.updateMetaTag('og:url', this.event.publicUrl);
        this.updateMetaTag('og:type', 'video.other');
        
        this.updateMetaTag('twitter:card', this.event.twitterCardType || 'summary_large_image');
        this.updateMetaTag('twitter:title', this.event.socialShareTitle);
        this.updateMetaTag('twitter:description', this.event.socialShareDescription);
        this.updateMetaTag('twitter:image', this.event.socialMediaImageUrl);
        
        // Update page title
        document.title = this.event.socialShareTitle;
    }
    
    updateMetaTag(property, content) {
        if (!content) return;
        
        let meta = document.querySelector(`meta[property="${property}"]`) || 
                   document.querySelector(`meta[name="${property}"]`);
        
        if (!meta) {
            meta = document.createElement('meta');
            if (property.startsWith('og:')) {
                meta.setAttribute('property', property);
            } else {
                meta.setAttribute('name', property);
            }
            document.head.appendChild(meta);
        }
        meta.setAttribute('content', content);
    }
    
    // Event handlers
    trackView() {
        if (!this.recordId) return;
        
        trackEngagement({
            eventId: this.recordId,
            engagementType: 'View',
            platform: 'Website',
            referrerUrl: document.referrer
        }).catch(error => {
            console.log('View tracking failed:', error);
        });
    }
    
    handleShareEvent(event) {
        // Handle share event from child component
        console.log('Share event:', event.detail);
    }
    
    handleMomentClick(event) {
        const momentId = event.currentTarget.dataset.id;
        if (momentId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: momentId,
                    objectApiName: 'Commentary_Event__c',
                    actionName: 'view'
                }
            });
        }
    }
    
    toggleEmbedCode() {
        this.showEmbedCode = !this.showEmbedCode;
    }
    
    async copyEmbedCode() {
        try {
            await navigator.clipboard.writeText(this.event.embedCode);
            // Could add toast notification here
        } catch (err) {
            console.error('Failed to copy embed code:', err);
        }
    }
}

