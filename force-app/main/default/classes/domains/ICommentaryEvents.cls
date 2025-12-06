/**
 * @description Interface for Commentary_Event__c Domain
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ICommentaryEvents extends fflib_ISObjectDomain {
    void makeShareable();
    void updateViralScore(Decimal score);
    void incrementShareCount();
    void incrementViewCount();
}

