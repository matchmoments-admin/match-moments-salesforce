/**
 * @description Interface for Social Sharing Service
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ISocialSharingService {
    void recordShare(Id commentaryEventId, String platform, fflib_ISObjectUnitOfWork uow);
    void recordView(Id commentaryEventId, fflib_ISObjectUnitOfWork uow);
    void updateShareCounts(Set<Id> commentaryEventIds, fflib_ISObjectUnitOfWork uow);
}

