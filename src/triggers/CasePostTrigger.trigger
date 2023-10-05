trigger CasePostTrigger on FeedItem (before insert, after insert) {
	// Before Action is to enhance the Post
	if (Trigger.isBefore) {
	  for (FeedItem item : Trigger.new) {
	  	// Only work on posts on Cases, anything else, we ignore
		if (CasePostEnhancer.parentIsCase(item)) {
			CasePostEnhancer.enhancePost(item);
		}
	  }
	}
	
    // After Action is to fix the @ mentions -- must wait for the after trigger because we can't comment
    // on the Post until it's saved to the database
    if (Trigger.isAfter) {
	  for (FeedItem item : Trigger.new) {
	  	// Only work on posts on Cases, anything else, we ignore
		if (CasePostEnhancer.parentIsCase(item)) {
			CasePostEnhancer.fixMentionsByCommenting(item);
		}
	  }
    	
    }
}