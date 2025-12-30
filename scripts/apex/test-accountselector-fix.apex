// Test AccountsSelector getOverflowStore fix
// This tests that the methods handle empty results gracefully

System.debug('=== Testing AccountsSelector Fix ===');

try {
    AccountsSelector selector = new AccountsSelector();
    
    // Test getOverflowStore - should return null if store doesn't exist
    System.debug('Testing getOverflowStore()...');
    Account overflowStore = selector.getOverflowStore();
    if (overflowStore == null) {
        System.debug('✅ getOverflowStore() returned null (store not found) - PASS');
    } else {
        System.debug('✅ getOverflowStore() returned store: ' + overflowStore.Name + ' - PASS');
    }
    
    // Test getDefaultAussieStore - should return null if store doesn't exist
    System.debug('Testing getDefaultAussieStore()...');
    Account defaultStore = selector.getDefaultAussieStore();
    if (defaultStore == null) {
        System.debug('✅ getDefaultAussieStore() returned null (store not found) - PASS');
    } else {
        System.debug('✅ getDefaultAussieStore() returned store: ' + defaultStore.Name + ' - PASS');
    }
    
    // Test getAussieHlsStore - should return null if store doesn't exist
    System.debug('Testing getAussieHlsStore()...');
    Account hlsStore = selector.getAussieHlsStore();
    if (hlsStore == null) {
        System.debug('✅ getAussieHlsStore() returned null (store not found) - PASS');
    } else {
        System.debug('✅ getAussieHlsStore() returned store: ' + hlsStore.Name + ' - PASS');
    }
    
    System.debug('=== All AccountsSelector Tests PASSED ===');
    
} catch (Exception e) {
    System.debug('❌ TEST FAILED: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

