/**
 * @description Interface for Match_Moment__c Domain
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface IMatchMoments extends fflib_ISObjectDomain {
    void makeShareable();
    void updateViralScore(Decimal score);
    void incrementShareCount();
    void incrementViewCount();
}

