/**
 * @description Domain class for Contact (Players) business logic
 * @author Brendan Milton
 * @date 2025-12-05
 */
public inherited sharing class Players extends fflib_SObjectDomain implements IPlayers {
    
    public static final String ROLE_PLAYER = 'Player';
    public static final String ROLE_COACH = 'Coach';
    public static final String ROLE_STAFF = 'Staff';
    
    public Players(List<Contact> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Players((List<Contact>) records);
        }
    }
    
    public static IPlayers newInstance(List<Contact> records) {
        return (IPlayers) Application.Domain.newInstance(records);
    }
    
    public List<Contact> getPlayers() {
        return (List<Contact>) getRecords();
    }
    
    public void updateFromESPNData(Map<String, Object> espnPlayerData) {
        for (Contact player : getPlayers()) {
            if (espnPlayerData.containsKey('id')) {
                player.ESPN_Player_ID__c = String.valueOf(espnPlayerData.get('id'));
            }
            if (espnPlayerData.containsKey('firstName')) {
                player.FirstName = String.valueOf(espnPlayerData.get('firstName'));
            }
            if (espnPlayerData.containsKey('lastName')) {
                player.LastName = String.valueOf(espnPlayerData.get('lastName'));
            }
            if (espnPlayerData.containsKey('position')) {
                player.Position__c = String.valueOf(espnPlayerData.get('position'));
            }
            if (espnPlayerData.containsKey('jersey')) {
                String jersey = String.valueOf(espnPlayerData.get('jersey'));
                if (String.isNotBlank(jersey) && jersey.isNumeric()) {
                    player.Jersey_Number__c = Integer.valueOf(jersey);
                }
            }
            if (espnPlayerData.containsKey('headshotUrl')) {
                player.Profile_Image_URL__c = String.valueOf(espnPlayerData.get('headshotUrl'));
            }
            player.Player_Role__c = ROLE_PLAYER;
        }
    }
    
    public void linkToTeam(Id teamId) {
        for (Contact player : getPlayers()) {
            player.Current_Team__c = teamId;
        }
    }
    
    public void validatePosition() {
        for (Contact player : getPlayers()) {
            if (player.Player_Role__c == ROLE_PLAYER && String.isBlank(player.Position__c)) {
                player.addError('Position is required for players');
            }
        }
    }
}

