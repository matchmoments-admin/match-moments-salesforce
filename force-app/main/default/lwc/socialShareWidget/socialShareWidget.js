/**
 * @description Reusable social share widget component
 * Provides share buttons for Twitter, Facebook, WhatsApp, and link copy
 * @author Brendan Milton
 * @date 2025-12
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import trackEngagement from '@salesforce/apex/MomentPageController.trackEngagement';

// Import fields - these will be dynamically generated in the controller
const FIELDS = [
    'Commentary_Event__c.Id',
    'Commentary_Event__c.Public_URL__c',
    'Commentary_Event__c.Social_Share_Title__c',
    'Commentary_Event__c.Social_Share_Description__c',
    'Commentary_Event__c.QR_Code_URL__c',
    'Commentary_Event__c.Video_URL__c'
];

export default class SocialShareWidget extends LightningElement {
    @api recordId;
    @api variant = 'full'; // 'full', 'compact', 'icons-only'
    @api showQrCode = false;
    @api showStats = false;
    
    publicUrl = '';
    socialTitle = '';
    socialDescription = '';
    qrCodeUrl = '';
    linkButtonText = 'Copy Link';
    linkButtonIcon = 'utility:copy';
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            // Build public URL from record Id if not available from field
            const baseUrl = window.location.origin;
            this.publicUrl = `${baseUrl}/fans/moment/${this.recordId}`;
            
            // Get social share title
            const titleField = getFieldValue(data, 'Commentary_Event__c.Social_Share_Title__c');
            this.socialTitle = titleField || 'Check out this moment!';
            
            // Get description
            const descField = getFieldValue(data, 'Commentary_Event__c.Social_Share_Description__c');
            this.socialDescription = descField || '';
            
            // Build QR code URL
            this.qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(this.publicUrl)}`;
        } else if (error) {
            console.error('Error loading record:', error);
            // Fallback - construct URL anyway
            this.publicUrl = `${window.location.origin}/fans/moment/${this.recordId}`;
            this.qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(this.publicUrl)}`;
        }
    }
    
    // Variant checks
    get isFullVariant() {
        return this.variant === 'full';
    }
    
    get isCompactVariant() {
        return this.variant === 'compact';
    }
    
    get isIconsOnlyVariant() {
        return this.variant === 'icons-only';
    }
    
    get containerClass() {
        return `share-widget ${this.variant}`;
    }
    
    // Share handlers
    handleTwitterShare() {
        if (!this.publicUrl) return;
        
        const text = encodeURIComponent(this.socialTitle);
        const url = encodeURIComponent(this.publicUrl);
        const hashtags = this.getHashtags();
        
        const twitterUrl = `https://twitter.com/intent/tweet?text=${text}&url=${url}${hashtags ? '&hashtags=' + hashtags : ''}`;
        
        window.open(twitterUrl, '_blank', 'width=550,height=420');
        this.trackShare('Twitter');
    }
    
    handleFacebookShare() {
        if (!this.publicUrl) return;
        
        const url = encodeURIComponent(this.publicUrl);
        const facebookUrl = `https://www.facebook.com/sharer/sharer.php?u=${url}`;
        
        window.open(facebookUrl, '_blank', 'width=550,height=420');
        this.trackShare('Facebook');
    }
    
    handleWhatsAppShare() {
        if (!this.publicUrl) return;
        
        const text = encodeURIComponent(`${this.socialTitle}\n\n${this.publicUrl}`);
        const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        const whatsappUrl = isMobile 
            ? `whatsapp://send?text=${text}`
            : `https://web.whatsapp.com/send?text=${text}`;
        
        window.open(whatsappUrl, '_blank');
        this.trackShare('WhatsApp');
    }
    
    handleLinkedInShare() {
        if (!this.publicUrl) return;
        
        const url = encodeURIComponent(this.publicUrl);
        const title = encodeURIComponent(this.socialTitle);
        const linkedInUrl = `https://www.linkedin.com/sharing/share-offsite/?url=${url}`;
        
        window.open(linkedInUrl, '_blank', 'width=550,height=420');
        this.trackShare('LinkedIn');
    }
    
    handleEmailShare() {
        if (!this.publicUrl) return;
        
        const subject = encodeURIComponent(this.socialTitle);
        const body = encodeURIComponent(`${this.socialDescription}\n\nWatch here: ${this.publicUrl}`);
        
        window.location.href = `mailto:?subject=${subject}&body=${body}`;
        this.trackShare('Email');
    }
    
    async handleCopyLink() {
        if (!this.publicUrl) return;
        
        try {
            await navigator.clipboard.writeText(this.publicUrl);
            
            // Update button text temporarily
            this.linkButtonText = 'Copied!';
            this.linkButtonIcon = 'utility:check';
            
            // Reset after 2 seconds
            setTimeout(() => {
                this.linkButtonText = 'Copy Link';
                this.linkButtonIcon = 'utility:copy';
            }, 2000);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Link Copied',
                    message: 'Moment link copied to clipboard',
                    variant: 'success'
                })
            );
            
            this.trackShare('Link_Copy');
        } catch (err) {
            console.error('Failed to copy:', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to copy link',
                    variant: 'error'
                })
            );
        }
    }
    
    // Helper methods
    getHashtags() {
        // Could be made configurable via @api property
        return 'Sports,Moment';
    }
    
    trackShare(platform) {
        if (!this.recordId) return;
        
        trackEngagement({
            eventId: this.recordId,
            engagementType: 'Share',
            platform: platform,
            referrerUrl: window.location.href
        }).catch(error => {
            console.error('Error tracking share:', error);
        });
        
        // Dispatch custom event for parent components
        this.dispatchEvent(new CustomEvent('share', {
            detail: {
                platform: platform,
                url: this.publicUrl
            }
        }));
    }
}

