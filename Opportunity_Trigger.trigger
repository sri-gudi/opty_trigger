trigger Opportunity_Trigger on Opportunity (after insert, after update, before delete) {
    Set<Id> OpptyIds = new Set<Id>();
    Set<Id> OpptyIdsToSubtractAmount = new Set<Id>();
    Set<Id> commissionIds = new Set<Id>();
    List<Opportunity> pendingOpptyIds = new List<Opportunity>();
    if(trigger.isInsert){
        for(Opportunity oppty : trigger.New){
            if(oppty.StageName == 'Pending'){
                OpptyIds.add(oppty.Id);
            }
        }    
    }
    if(trigger.isUpdate){
        for(Opportunity oppty : trigger.New){
            if(oppty.StageName == 'Pending'){
                OpptyIds.add(oppty.Id);
            }
            Opportunity oldOppty = Trigger.oldMap.get(oppty.Id);
            if(oldOppty.StageName == 'Pending' & oldOppty.StageName != oppty.StageName) {
                OpptyIdsToSubtractAmount.add(oppty.Id);
            }
        }    
    }
    if(trigger.isDelete){
        for(Opportunity oppty : trigger.old){
            if(oppty.StageName == 'Pending'){
                OpptyIdsToSubtractAmount.add(oppty.Id);
            }
        }    
    }
    List<Sale_Agent__c> saleAgentsToUpdate = new List<Sale_Agent__c>();
    Map<Id, Decimal> saleAgentAmountMap = new Map<Id, Decimal>();
    List<Commission__c> Commissions = [Select Id, Sale_Agent__c,Sale_Agent__r.Amount_Pending__c, Opportunity__r.Amount  from Commission__c where Opportunity__c in :OpptyIds];
    for(Commission__c Commission: Commissions) {
        if(saleAgentAmountMap.containsKey(Commission.Sale_Agent__c)) {
            saleAgentAmountMap.put(Commission.Sale_Agent__c, saleAgentAmountMap.get(Commission.Sale_Agent__c) + Commission.Opportunity__r.Amount);
        } else {
            system.debug(Commission.Sale_Agent__c);
            system.debug(Commission.Sale_Agent__r.Amount_Pending__c);
            system.debug(Commission.Opportunity__r.Amount);
            saleAgentAmountMap.put(Commission.Sale_Agent__c, Commission.Sale_Agent__r.Amount_Pending__c + Commission.Opportunity__r.Amount);
        }
    }
    List<Commission__c> CommissionsToDelete = [Select Id, Sale_Agent__c,Sale_Agent__r.Amount_Pending__c, Opportunity__r.Amount  from Commission__c where Opportunity__c in :OpptyIdsToSubtractAmount];
    for(Commission__c Commission: CommissionsToDelete) {
        if(saleAgentAmountMap.containsKey(Commission.Sale_Agent__c)) {
            saleAgentAmountMap.put(Commission.Sale_Agent__c, saleAgentAmountMap.get(Commission.Sale_Agent__c) - Commission.Opportunity__r.Amount);
        } else {
            saleAgentAmountMap.put(Commission.Sale_Agent__c, Commission.Sale_Agent__r.Amount_Pending__c - Commission.Opportunity__r.Amount);
        }
    }
    for(Id saleAgentId: saleAgentAmountMap.keySet()) {
        Sale_Agent__c agent = new Sale_Agent__c();
        agent.Id = saleAgentId;
        agent.Amount_Pending__c =  saleAgentAmountMap.get(saleAgentId);
        saleAgentsToUpdate.add(agent);
    }
    update saleAgentsToUpdate;
}