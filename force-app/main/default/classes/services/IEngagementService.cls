/**
 * @description Interface for Engagement Service
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IEngagementService {
    Map<String, Integer> getEngagementCounts(Id commentaryEventId);
    Boolean isViral(Id commentaryEventId);
    void calculateViralScores(Set<Id> commentaryEventIds, fflib_ISObjectUnitOfWork uow);
}

