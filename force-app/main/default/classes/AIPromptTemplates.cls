/**
 * @description Reusable AI prompt templates for sports content generation
 * Centralizes prompt engineering for consistency and maintainability
 * @author Brendan Milton
 * @date 2025-12-30
 */
public class AIPromptTemplates {
    
    /**
     * @description Generate match preview prompt
     * @param match Match__c record with related data
     * @return Formatted prompt for AI
     */
    public static String getMatchPreviewPrompt(Match__c match) {
        String prompt = 'Write a comprehensive match preview for the following fixture:\n\n';
        
        prompt += '**Match Details:**\n';
        prompt += '- Competition: ' + match.Competition__r.Name + '\n';
        prompt += '- Teams: ' + match.Home_Team__r.Name + ' vs ' + match.Away_Team__r.Name + '\n';
        prompt += '- Date: ' + match.Match_Date_Time__c.format() + '\n';
        prompt += '- Venue: ' + (String.isNotBlank(match.Venue__c) ? match.Venue__c : 'TBD') + '\n\n';
        
        prompt += '**Content Requirements:**\n';
        prompt += '1. Opening paragraph with key match context\n';
        prompt += '2. Team form analysis (search for recent results)\n';
        prompt += '3. Head-to-head history\n';
        prompt += '4. Key players to watch\n';
        prompt += '5. Tactical preview\n';
        prompt += '6. Prediction with reasoning\n\n';
        
        prompt += 'Length: 600-800 words\n';
        prompt += 'Tone: Professional but engaging\n';
        prompt += 'Include relevant statistics and facts\n';
        prompt += 'Use Google Search to find the latest team news and form';
        
        return prompt;
    }
    
    /**
     * @description Generate match recap prompt
     * @param match Match__c record with final scores
     * @return Formatted prompt for AI
     */
    public static String getMatchRecapPrompt(Match__c match) {
        String prompt = 'Write a compelling match recap for:\n\n';
        
        prompt += '**Match Summary:**\n';
        prompt += '- ' + match.Home_Team__r.Name + ' ' + match.Home_Score_Final__c + ' - ';
        prompt += match.Away_Score_Final__c + ' ' + match.Away_Team__r.Name + '\n';
        prompt += '- Competition: ' + match.Competition__r.Name + '\n';
        prompt += '- Venue: ' + (String.isNotBlank(match.Venue__c) ? match.Venue__c : 'Unknown') + '\n\n';
        
        prompt += '**Content Requirements:**\n';
        prompt += '1. Opening with match result and significance\n';
        prompt += '2. First half summary\n';
        prompt += '3. Second half summary\n';
        prompt += '4. Key moments and turning points\n';
        prompt += '5. Player performances (Man of the Match, standout players)\n';
        prompt += '6. Manager reactions\n';
        prompt += '7. What this means for both teams\n\n';
        
        prompt += 'Length: 700-900 words\n';
        prompt += 'Tone: Exciting and descriptive\n';
        prompt += 'Search for actual match events, goals, cards, and key incidents\n';
        prompt += 'Include quotes if available';
        
        return prompt;
    }
    
    /**
     * @description Generate player summary prompt
     * @param player Contact (Player) record
     * @return Formatted prompt for AI
     */
    public static String getPlayerSummaryPrompt(Contact player) {
        String prompt = 'Create a professional player profile summary for:\n\n';
        
        prompt += 'Player: ' + player.Name + '\n';
        if (String.isNotBlank(player.Department)) {
            prompt += 'Position: ' + player.Department + '\n'; // Assuming Department stores position
        }
        prompt += '\n';
        
        prompt += '**Requirements:**\n';
        prompt += '1. Brief career overview (2-3 sentences)\n';
        prompt += '2. Current form and recent performances\n';
        prompt += '3. Key statistics (goals, assists, appearances)\n';
        prompt += '4. Playing style and strengths\n';
        prompt += '5. Notable achievements\n\n';
        
        prompt += 'Length: 250-350 words\n';
        prompt += 'Tone: Professional and factual\n';
        prompt += 'Use latest available statistics';
        
        return prompt;
    }
    
    /**
     * @description Generate article from topic and context
     * @param topic Article topic
     * @param context Additional context data
     * @return Formatted prompt for AI
     */
    public static String getArticleGenerationPrompt(String topic, Map<String, Object> context) {
        String prompt = 'Write a professional sports article on: ' + topic + '\n\n';
        
        if (context != null && !context.isEmpty()) {
            prompt += '**Context Information:**\n';
            for (String key : context.keySet()) {
                Object value = context.get(key);
                if (value != null) {
                    prompt += '- ' + key + ': ' + String.valueOf(value) + '\n';
                }
            }
            prompt += '\n';
        }
        
        prompt += '**Content Requirements:**\n';
        prompt += '1. Compelling headline (60-80 characters)\n';
        prompt += '2. Strong opening paragraph (hook readers)\n';
        prompt += '3. Well-structured body with subheadings\n';
        prompt += '4. Include relevant statistics and data\n';
        prompt += '5. Quotes from key figures (if context provided)\n';
        prompt += '6. Analysis and insights\n';
        prompt += '7. Conclusion with forward-looking perspective\n\n';
        
        prompt += 'Length: 800-1000 words\n';
        prompt += 'Tone: Professional, engaging, authoritative\n';
        prompt += 'Target audience: Sports enthusiasts and general readers\n';
        prompt += 'SEO-friendly with natural keyword integration';
        
        return prompt;
    }
    
    /**
     * @description Generate competition news summary prompt
     * @param competitionName Name of the competition
     * @param dateRange Date range for news
     * @return Formatted prompt for AI
     */
    public static String getCompetitionNewsPrompt(String competitionName, String dateRange) {
        String prompt = 'Search and summarize the latest news for: ' + competitionName + '\n\n';
        
        if (String.isNotBlank(dateRange)) {
            prompt += 'Date range: ' + dateRange + '\n\n';
        }
        
        prompt += '**Information to gather:**\n';
        prompt += '1. Latest match results (last 3 days)\n';
        prompt += '2. Upcoming fixtures (next 7 days)\n';
        prompt += '3. Current league standings/table\n';
        prompt += '4. Major news stories (transfers, injuries, controversies)\n';
        prompt += '5. Statistical leaders (top scorers, assists, etc.)\n\n';
        
        prompt += 'Format:\n';
        prompt += '- Use clear sections with headings\n';
        prompt += '- Include specific dates and scores\n';
        prompt += '- Cite sources where possible\n';
        prompt += '- Keep it factual and up-to-date\n';
        prompt += '- Length: 500-600 words';
        
        return prompt;
    }
    
    /**
     * @description Generate team form analysis prompt
     * @param teamName Team name
     * @param matchCount Number of recent matches to analyze
     * @return Formatted prompt for AI
     */
    public static String getTeamFormPrompt(String teamName, Integer matchCount) {
        String prompt = 'Analyze the recent form of: ' + teamName + '\n\n';
        
        prompt += 'Look at the last ' + matchCount + ' matches and provide:\n';
        prompt += '1. Results summary (W-D-L record)\n';
        prompt += '2. Goals scored and conceded\n';
        prompt += '3. Key patterns or trends\n';
        prompt += '4. Standout performers\n';
        prompt += '5. Areas of strength and weakness\n';
        prompt += '6. Comparison to earlier in the season\n\n';
        
        prompt += 'Format: Structured analysis, 300-400 words\n';
        prompt += 'Include specific match results with dates and opponents';
        
        return prompt;
    }
    
    /**
     * @description Generate social media post prompt
     * @param content Brief content description
     * @param platform Social platform (Twitter, Instagram, etc.)
     * @param maxLength Character limit
     * @return Formatted prompt for AI
     */
    public static String getSocialMediaPrompt(String content, String platform, Integer maxLength) {
        String prompt = 'Create a ' + platform + ' post about: ' + content + '\n\n';
        
        prompt += '**Requirements:**\n';
        prompt += '- Maximum ' + maxLength + ' characters\n';
        prompt += '- Engaging and shareable\n';
        prompt += '- Include relevant hashtags (2-4)\n';
        prompt += '- Use emojis appropriately\n';
        prompt += '- Call to action if appropriate\n';
        prompt += '- Match ' + platform + ' tone and style\n\n';
        
        prompt += 'Return only the post text, ready to publish';
        
        return prompt;
    }
    
    /**
     * @description Generate field summary prompt for any Salesforce record
     * @param recordData JSON representation of record
     * @param objectLabel Object label (e.g., "Match", "Team")
     * @return Formatted prompt for AI
     */
    public static String getFieldSummaryPrompt(String recordData, String objectLabel) {
        String prompt = 'Summarize this ' + objectLabel + ' record in 2-3 concise sentences:\n\n';
        prompt += recordData + '\n\n';
        prompt += 'Focus on the most important and relevant information.\n';
        prompt += 'Write in natural, professional language suitable for a CRM user.';
        
        return prompt;
    }
}

