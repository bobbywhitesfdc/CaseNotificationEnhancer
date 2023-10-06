/**
  Unit and Functional Tests for the Case Post Enhancer Class
 **/

@IsTest(SeeAllData=true)
private class CasePostEnhancerTest {
	static final String USERID1='bobby.white@demo.salesforce.com';
	static final String USERNAME1='Bobby White';
	static final String USERID2='jpj@demo.salesforce.com';
	static final String USERNAME2='John Paul Jones';
	static final String USERID3='kiki@demo.salesforce.com';
	static final String USERNAME3='Kiki Van Der Wey';
	
	
	static final String CASE_SUBJECT = '$$$$Test Case Subject$$$$';
	static final String CASE_POST_PLAIN = 'This is a plain post';
	static final String CASE_POST_WITH_MENTIONS = 'Hey @'+USERNAME1+' this is a test';
    static final String CASE_POST_WITH_LONG_MENTIONS = 'Hey @'+USERNAME1+' this is a test @'+USERNAME2;
    static final String CASE_POST_WITH_LONGEST_MENTIONS = 'Hey @'+USERNAME1+' this is a test @'+USERNAME3;
    static final String CASE_POST_WITH_BAD_MENTIONS = 'Hey @Mickey Mouse this is a test';
    
	
	static final String ACCT_POST_PLAIN = 'This is a plain post on an Account';
	static final String MY_TEST_URL = 'http://www.nascar.com';
	static final String TEST_ACCOUNT_NAME='The Shire';
	
	/**
	  Establish the common test data and users that these tests will rely on
	**/
	public User user1=null;
	public Account account1=null;
	
    void setupTestData() {
    	
    	User[] existing = [SELECT Id,Name, UserName FROM User WHERE UserName IN(:USERID1,:USERID2,:USERID3)];
    	
    	if (existing.isEmpty()) {
    		Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
 
		    user1 = new User(UserName=USERID1
		           , FirstName='Bobby'
		           , LastName='White'
		           , Email='bobby.white@salesforce.com'
		           , Alias='Bobby'
		           , TimeZoneSidKey='America/New_York'
		           , LocaleSidKey='en_US'
		           , EmailEncodingKey='ISO-8859-1'
	               , ProfileId=profile.Id
		           , LanguageLocaleKey='en_US');
		
		   INSERT user1;
		   		   
    	}
    	
    	Account[] testAccounts = [SELECT Id, Name FROM Account WHERE Name=:TEST_ACCOUNT_NAME];
    	if (testAccounts.isEmpty()) {
    	   account1 = new Account(Name=TEST_ACCOUNT_NAME);
		   INSERT account1;
    		
    	}
		
	}
	static testMethod void testParentIsCaseMethodPositive() {
		CasePostEnhancerTest test = new CasePostEnhancerTest();
		test.setupTestData();
		
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject='Test Case');
		testCase.AccountId = test.account1.Id;
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_PLAIN;
		
		System.Assert(CasePostEnhancer.parentIsCase(testFeedItem));
		
	}
	
    static testMethod void testParentIsCaseMethodNegative1() {
    	CasePostEnhancerTest test = new CasePostEnhancerTest();
		test.setupTestData();
    	
		List<Account> accounts = new List<Account>();
		Account testAcct =  new Account(Name='Test Account');
		accounts.add(testAcct);
		INSERT accounts;
		
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testAcct.Id;
		testFeedItem.Body = CASE_POST_PLAIN;
		
		System.Assert(!CasePostEnhancer.parentIsCase(testFeedItem));
		
		
	}
	
	static testMethod void testParentIsCaseMethodNegative2() {
		
		System.Assert(!CasePostEnhancer.parentIsCase(null));
		
		
	}
	

/**
 In this test, we're persisting the FeedPost on a Case and testing that the trigger works with Plain Test post
**/
    static testMethod void testPlainText() {
    	CasePostEnhancerTest test = new CasePostEnhancerTest();
		test.setupTestData();
    	
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		testCase.AccountId = test.account1.Id;
		
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_PLAIN;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId FROM FeedItem WHERE Id = :testFeedITem.Id];
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_PLAIN));
		
   }
    static testMethod void testPlainTextWithUserMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_WITH_MENTIONS;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_WITH_MENTIONS));
		
    }
    
    static testMethod void testPlainTextWithLongMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_WITH_LONG_MENTIONS;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_WITH_LONG_MENTIONS));
		
    }
    
    static testMethod void testPlainTextWithLongestMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_WITH_LONGEST_MENTIONS;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_WITH_LONGEST_MENTIONS));
		
    }
    
    static testMethod void testPlainTextWithBadMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_WITH_BAD_MENTIONS;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_WITH_BAD_MENTIONS));
		
    }
    
    
    static testMethod void testURLPostNoMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_PLAIN;
		testFeedItem.LinkUrl = MY_TEST_URL;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId, LinkUrl FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_PLAIN));
		System.Assert(afterTriggerState.LinkUrl==MY_TEST_URL);
    }
    
    static testMethod void testUrlPostWithMentions() {
		List<Case> cases = new List<Case>();
		Case testCase =  new Case(Subject=CASE_SUBJECT);
		cases.add(testCase);
		INSERT cases;
		FeedItem testFeedItem = new FeedItem();
		testFeedItem.ParentId=testCase.Id;
		testFeedItem.Body = CASE_POST_WITH_MENTIONS;
		testFeedItem.LinkUrl = MY_TEST_URL;
		INSERT testFeedItem;
		
		// It's been Saved, now lets retrieve it and ensure that the trigger did what we expected
		FeedItem afterTriggerState = [SELECT Id, Body, ParentId, LinkUrl FROM FeedItem WHERE Id = :testFeedITem.Id];

		System.Debug(afterTriggerState.Body);
		
		System.Assert(afterTriggerState.Body.contains(CASE_SUBJECT));
		System.Assert(afterTriggerState.Body.contains(CASE_POST_WITH_MENTIONS));
		System.Assert(afterTriggerState.LinkUrl==MY_TEST_URL);
    }
    
    
}