public with sharing class CasePostEnhancer {
	// use to extract the mentions that need to be looked up (e.g. don't supply the id)
    //public static final String MENTIONPATTERN_AUTOLOOKUP = '@\\[[^\\]]{4,}\\]'; // matches @[First Last]
    public static final String MENTIONPATTERN_AUTOLOOKUP = '@\\b[^\\s^@]{1,}\\s\\b[^\\s^@^\\.]{1,}'; // matches @First Last
    public static final String MENTIONPATTERN_ADD1WORD = '\\s\\b[^\\s^@]{1,}';
    
    public enum ExtractDirective { ALL, ONLY_TEXT, ONLY_MENTIONS }
    public class postTooLargeException extends Exception {}
    /** 
    used to store mentions extracted from the post.  
    Offsets to the beginning and end of the mention (where it came from in the original)
    **/
    public class Mention {
       public Integer groupStart { get; set; }  
       public Integer groupEnd   { get; set; }
       public String  text { get; set; }
    }
	
	/**
	  Decorate a FeedPost with extra context from the Parent Object
	**/
    public static void enhancePost(FeedItem feedItem) {
        
      if (parentIsCase(feedItem)) {
          String enhancedContext = generateContext(feedItem.ParentId);
           
          String enhancedText = enhancedContext + '\n' + feedItem.Body;
          
          feedItem.Body = enhancedText; // update the Feed
                  
      } else {
        System.Debug('Parent is not a Case, do nothing');
      }
    }
    
    /**
      Helper method that safely tests to see if this feed item's parent is a Case
    **/
    public static boolean parentIsCase(FeedItem feedItem) {
        return (feedItem != null && feedItem.ParentId != null && Case.sObjectType == feedItem.ParentId.getSObjectType());
    } 
    
    public static String generateContext(Id parent) {
          Case parentCase = [SELECT Subject, Account.Name FROM Case Where Id = :parent];
          String enhancedContext = '';
          enhancedContext += 'Account: ' + ( (parentCase != null && parentCase.Account != null) ? parentCase.Account.Name : '<null>');
          enhancedContext += '\nSubject: ' + ( (parentCase != null && parentCase.Subject != null) ? parentCase.Subject : '<null>');
          return enhancedContext;
    }
    
    /**
      Compensate for @mentions being broken in the original post by making a Comment fix the Connect in Apex API
      and automatically rementioning those people and groups.
    **/
    public static void fixMentionsByCommenting(FeedItem feedItem) {
        // Parse the Body Text, get a list of mentions 
        List<ConnectApi.MessageSegmentInput> mentions = new List<ConnectApi.MessageSegmentInput>();
        List<Mention> failedMentions = new List<Mention>();
         
        for (Mention mentionTag : extractAllMentions(feedItem.Body))  {  
        	// Lookup the Id's of the mentioned users and groups
        	Id mentionedUser = lookupMentionedUserOrGroup(mentionTag.text);
        	
        	if (mentionedUser == null) {
        		failedMentions.add(mentionTag);
        	}
        	
        	if (mentionedUser != null) { // Found a match
               ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
               mentionSegment.id = mentionedUser;
               mentions.add(mentionSegment);
        	}
        }
        
        // Make a pass at resolving based on longer names
        List<Mention> failedMentions3 = new List<Mention>();       
        for (Mention failedMention : failedMentions) {
        	Mention longerMention = extractLongerMention(feedItem.Body,failedMention,1);
        	
        	Id mentionedUser = null;
        	if (longerMention != null) {
               // Lookup the Id's of the mentioned users and groups
               mentionedUser = lookupMentionedUserOrGroup(longerMention.text);
        	}
        	
        	
        	if (mentionedUser == null) {
        		failedMentions3.add(failedMention);
        	}
        	
        	if (mentionedUser != null) { // Found a match
               ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
               mentionSegment.id = mentionedUser;
               mentions.add(mentionSegment);
        	}
        	
        }
        
        // Make a final pass at resolving based on longer (4 word) names
        for (Mention failedMention : failedMentions3) {
        	Mention longerMention = extractLongerMention(feedItem.Body,failedMention,2);
        	
        	Id mentionedUser = null;
        	if (longerMention != null) {
               // Lookup the Id's of the mentioned users and groups
               mentionedUser = lookupMentionedUserOrGroup(longerMention.text);
        	}
        	
        	        	
        	if (mentionedUser != null) { // Found a match
               ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
               mentionSegment.id = mentionedUser;
               mentions.add(mentionSegment);
        	}
        	
        }
        
        
        // Compose a FeedComment containing only the mentioned users we could resolve
        // Execute the Connect in Apex call to create the Comment
        if (mentions.size() > 0) {
           ConnectApi.CommentInput commentInput = new ConnectApi.CommentInput();
           commentInput.body = new ConnectApi.MessageBodyInput();
           commentInput.body.messageSegments = mentions;
           ConnectApi.ChatterFeeds.postComment(null, feedItem.Id, commentInput, null);
        }
        
               
   }   
   
   /** Make a special pass through the text to get more words  
     original pattern find 2 word names:  @John Smith.
     if we have 3 or 4 word names, we need to try harder:  @John Paul Jones
   **/
   public static Mention extractLongerMention(String post, Mention originalMention, integer numWordsToAdd) {
   	   String remainingText = post.subString(originalMention.groupStart);
   	   String newPattern = originalMention.text;
   	   for(integer i=0; i < numWordsToAdd; i++) {
   	   	  newPattern += MENTIONPATTERN_ADD1WORD;
   	   }
   	   
       Pattern pat = Pattern.compile(newPattern);
       Matcher matcher = pat.matcher(remainingText);
       
       if (matcher.find()) {
          Mention longerMention = new Mention();
          longerMention.text    = matcher.group(); // text of matched mention
          longerMention.groupStart  = matcher.start(); // position in string where mention starts
          longerMention.groupEnd = matcher.end() ;  // position after the last char of the mention
          return longerMention;
          }
       
       
 	   return null;
   }
   // parse post text into a list of Mentions
  public static List<Mention> extractAllMentions(String post) {
    Pattern pat = Pattern.compile(MENTIONPATTERN_AUTOLOOKUP);
    Matcher matcher = pat.matcher(post);
    List<Mention> mentions = new List<Mention>(); 
   
    while(matcher.find()) {
      Mention mention = new Mention();
      mention.text    = matcher.group(); // text of matched mention
      mention.groupStart  = matcher.start(); // position in string where mention starts
      mention.groupEnd = matcher.end() ;  // position after the last char of the mention
      mentions.add(mention);
    }
    
    System.debug('Mention Count='+mentions.size());
    return mentions;
  }
   
    /**
    Mention text is in the form @[First Last]
    
    We need to strip away the brackets and attempt to resolve to an Id by name
    
    If there is no match or an exception occurs, return NULL
  **/
  public static Id lookupMentionedUserOrGroup(String mentionText) {
  	Id result=null;
  	try {
  		String name = mentionText.replace('@','').trim();
   		System.debug('Looking up User from Mention='+mentionText + ' name='+name);
  		
  		User[] mentionedUserHits = [SELECT Id FROM User WHERE Name = :name];
  		
  		if (mentionedUserHits.size() == 1) {
  			// exactly 1 hit
  			result = mentionedUserHits[0].Id;
  		} else if (mentionedUserHits.size()==0) {
  			// no hits, let's try to see if there is a matching Group
  			CollaborationGroup[] mentionedGroupHits = [SELECT Id FROM CollaborationGroup WHERE Name = :name];
  			result = (mentionedGroupHits.size() == 1 ? mentionedGroupHits[0].Id : null);
  		} else if (mentionedUserHits.size() > 1) {
  			System.debug('multiple matches found!');
  		}
  		System.debug('found ==>'+result);
  		
  	} catch(Exception e) {
  		System.debug('Error while looking up @mentioned user'+e.getMessage());
  	}
  	return result;
  }
  
   

}