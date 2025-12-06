/**
 * @description Interface for Competitions Domain
 * @author Brendan Milton
 * @date 2025-12-05
 */
public interface ICompetitions extends fflib_ISObjectDomain {
    void validateSport();
    void setSeasonDates(Date startDate, Date endDate);
    void markAsActive();
    void markAsCompleted();
}

