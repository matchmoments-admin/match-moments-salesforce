/**
 * CORRECTED: Using Match__c instead of Fixture__c
 * Your data is in Match__c, not Fixture__c!
 */

import { getSalesforceClient } from '../client';
import type { Match, MatchPeriod, CommentaryEvent } from '../types';
import { getCached } from '../../cache/redis';
import { CacheKeys, CacheStrategy } from '../../cache/strategies';

/**
 * Get today's matches with caching
 */
export async function getTodayMatches() {
  return getCached(
    CacheKeys.FIXTURES_TODAY, // Keep same cache key or rename
    async () => {
      const client = getSalesforceClient();
      const today = new Date().toISOString().split('T')[0];
      const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      const matches = await client.query<Match>(`
        SELECT 
          Id, Name, Match_Date_Time__c, Status__c, Venue__c,
          Home_Score_Final__c, Away_Score_Final__c,
          Home_Team__r.Name, Home_Team__r.Team_Logo_URL__c,
          Away_Team__r.Name, Away_Team__r.Team_Logo_URL__c,
          Competition__r.Name, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
          Season__r.Season_Name__c
        FROM Match__c
        WHERE Match_Date_Time__c >= ${today}T00:00:00Z
          AND Match_Date_Time__c < ${tomorrow}T00:00:00Z
        ORDER BY Match_Date_Time__c ASC
      `);

      return matches;
    },
    CacheStrategy.fixturesToday
  );
}

/**
 * Get live matches with caching
 */
export async function getLiveMatches() {
  return getCached(
    CacheKeys.FIXTURES_LIVE,
    async () => {
      const client = getSalesforceClient();

      const matches = await client.query<Match>(`
        SELECT 
          Id, Name, Match_Date_Time__c, Status__c, Venue__c,
          Home_Score_Final__c, Away_Score_Final__c,
          Home_Team__r.Name, Home_Team__r.Team_Logo_URL__c,
          Away_Team__r.Name, Away_Team__r.Team_Logo_URL__c,
          Competition__r.Name, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c
        FROM Match__c
        WHERE Status__c = 'Live'
        ORDER BY Match_Date_Time__c DESC
      `);

      return matches;
    },
    CacheStrategy.fixturesLive
  );
}

/**
 * Get upcoming matches with caching
 */
export async function getUpcomingMatches(days: number = 7) {
  return getCached(
    CacheKeys.FIXTURES_UPCOMING,
    async () => {
      const client = getSalesforceClient();
      const today = new Date().toISOString().split('T')[0];
      const futureDate = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      const matches = await client.query<Match>(`
        SELECT 
          Id, Name, Match_Date_Time__c, Status__c, Venue__c,
          Home_Score_Final__c, Away_Score_Final__c,
          Home_Team__r.Name, Home_Team__r.Team_Logo_URL__c,
          Away_Team__r.Name, Away_Team__r.Team_Logo_URL__c,
          Competition__r.Name, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c
        FROM Match__c
        WHERE Match_Date_Time__c >= ${today}T00:00:00Z
          AND Match_Date_Time__c < ${futureDate}T23:59:59Z
          AND Status__c = 'Scheduled'
        ORDER BY Match_Date_Time__c ASC
      `);

      return matches;
    },
    CacheStrategy.fixturesUpcoming
  );
}

/**
 * Get detailed match data with periods and commentary
 */
export async function getMatchData(matchId: string): Promise<any | null> {
  return getCached(
    CacheKeys.FIXTURE_DETAIL(matchId),
    async () => {
      const client = getSalesforceClient();

      // Fetch match details
      const matches = await client.query<Match>(`
        SELECT 
          Id, Name, Match_Date_Time__c, Status__c, Venue__c, Attendance__c,
          Home_Score_Final__c, Away_Score_Final__c,
          Home_Team__r.Name, Home_Team__r.Team_Logo_URL__c, Home_Team__r.Team_Primary_Color__c,
          Away_Team__r.Name, Away_Team__r.Team_Logo_URL__c, Away_Team__r.Team_Primary_Color__c,
          Competition__r.Name, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
          Season__r.Season_Name__c,
          ESPN_Event_ID__c
        FROM Match__c
        WHERE Id = '${matchId}'
        LIMIT 1
      `);

      if (!matches || matches.length === 0) {
        return null;
      }

      const match = matches[0];

      // Fetch periods
      const periods = await client.query<MatchPeriod>(`
        SELECT 
          Period_Number__c, Period_Type__c,
          Home_Score_Period__c, Away_Score_Period__c,
          Home_Score_Cumulative__c, Away_Score_Cumulative__c,
          Status__c
        FROM Match_Period__c
        WHERE Match__c = '${matchId}'
        ORDER BY Period_Number__c ASC
      `);

      // Fetch commentary events (if they exist)
      const commentary = await client.query<CommentaryEvent>(`
        SELECT 
          Id, Event_Minute__c, Event_Type__c, Description__c,
          Primary_Player__r.Name, Event_Importance__c
        FROM Commentary_Event__c
        WHERE Match__c = '${matchId}'
        ORDER BY Event_Minute__c ASC
      `);

      return {
        ...match,
        periods,
        commentary,
      };
    },
    CacheStrategy.fixtureDetail
  );
}

/**
 * Get matches by competition with caching
 */
export async function getMatchesByCompetition(competitionId: string, limit: number = 20) {
  return getCached(
    CacheKeys.FIXTURES_BY_COMPETITION(competitionId),
    async () => {
      const client = getSalesforceClient();

      const matches = await client.query<Match>(`
        SELECT 
          Id, Name, Match_Date_Time__c, Status__c, Venue__c,
          Home_Score_Final__c, Away_Score_Final__c,
          Home_Team__r.Name, Home_Team__r.Team_Logo_URL__c,
          Away_Team__r.Name, Away_Team__r.Team_Logo_URL__c,
          Competition__r.ESPN_League_ID__c
        FROM Match__c
        WHERE Competition__c = '${competitionId}'
        ORDER BY Match_Date_Time__c DESC
        LIMIT ${limit}
      `);

      return matches;
    },
    CacheStrategy.fixturesByCompetition
  );
}

/**
 * Get all matches from last month (for testing)
 */
export async function getRecentMatches() {
  const client = getSalesforceClient();

  const matches = await client.query<Match>(`
    SELECT 
      Id, Name, Match_Date_Time__c, Status__c, Venue__c, Attendance__c,
      Home_Score_Final__c, Away_Score_Final__c,
      Home_Team__r.Name, Home_Team__r.Abbreviation__c,
      Away_Team__r.Name, Away_Team__r.Abbreviation__c,
      Competition__r.Name, Competition__r.ESPN_League_ID__c, Competition__r.Sport__c,
      Season__r.Season_Name__c
    FROM Match__c
    WHERE Match_Date_Time__c >= 2024-11-30T00:00:00Z
      AND Match_Date_Time__c <= 2024-12-31T23:59:59Z
    ORDER BY Match_Date_Time__c DESC
  `);

  return matches;
}

