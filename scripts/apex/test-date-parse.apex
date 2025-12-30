// Test date parsing logic
String testDate = '2025-12-21T16:30Z';

System.debug('Original: ' + testDate);

// Remove Z
String dateStr = testDate.replace('Z', '');
System.debug('After removing Z: ' + dateStr);

// Count colons
Integer colonCount = dateStr.length() - dateStr.replace(':', '').length();
System.debug('Colon count: ' + colonCount);

if (colonCount == 2) {
    dateStr = dateStr + ':00';
    System.debug('Added seconds: ' + dateStr);
}

// Replace T with space
dateStr = dateStr.replace('T', ' ');
System.debug('Final string: ' + dateStr);

try {
    DateTime result = DateTime.valueOf(dateStr);
    System.debug('SUCCESS: Parsed to ' + result);
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}

