global without sharing class relatedSObject {
	private Map<id, sobject> relatedSobjects {
		get {
			if (relatedSObjects == null) {
				relatedSObjects =  QueryRelatedSObjects();
			}

			return relatedSobjects;
		}
		set;
	}
	private map<id, sobject> sobjectsToUpdate = new map<id, sobject>();
	private list<sobject> givenSobjects;
	private Schema.SObjectField relationshipField;
	private boolean isParent;
	private string parentType;
	private string childType;

	public relatedSObject(List<sobject> sobjects, string childObjectType, Schema.sobjectField relationshipField) {
		System.assert (sobjects != null);
		System.assert (relationshipField != null);

		if (sobjects.size() < 1) {
			relatedSobjects = new Map<id, sobject>();
			givenSobjects = sobjects;
			relationshipField = relationshipField;
			isParent = false;

			return;
		}

		this.givenSobjects = sobjects;
		this.relationshipField = relationshipField;
		childType = childObjectType;
		setSobjectTypes();
		system.debug('given is a parent ' + isParent);
		system.debug('parentType Is: ' + parentType);
		system.debug('childType Is: ' + childType);
	}

	private void setSobjectTypes(){
		parentType = String.valueOf(relationshipField.getDescribe().getReferenceTo()[0]);
		string givenObjectType = string.valueOf(givenSobjects[0].getSObjectType());
		this.isParent = givenObjectType == parentType;
	}
	public void updateObjects(sobject fromObject, Schema.SObjectField fromField, Schema.SObjectField ToField){
		for (sobject obj :  getSpecificSobject(fromObject)) {
			try{
				updateObjectField(obj, ToField, fromObject.get(fromField));
			}catch(Exception e){
				System.debug('related object: ' + obj);
				System.debug('from object: ' + fromObject);
				system.debug(LoggingLevel.ERROR, e.getMessage());
				system.debug(LoggingLevel.ERROR, e.getStackTraceString());
			}
		}
	}
	public void updateObjects(sobject fromObject, object value, Schema.SObjectField ToField){
		for (sobject obj :  getSpecificSobject(fromObject)) {
			updateObjectField(obj, ToField, value);
		}
	}
	private void updateObjectField(sobject inputObject, sobjectField field, object value){
        if(inputObject.get(field) == value){
            return;
        }
		if (sobjectsToUpdate.containsKey((id)inputObject.get('id'))) {
			sobjectsToUpdate.get((id)inputObject.get('id')).put(field, value);

			return;
		}
		inputObject.put(field, value);
		sobjectsToUpdate.put(inputObject.id, inputObject);

	}
	public Map<id, sobject> getAllRelatedSobjects(){
		return relatedSObjects;
	}
	public List<sobject> getSpecificSobject(sobject fromObject){
		return isParent ? getSpecificChildObjects(fromObject) : getSpecificParentObjects(fromObject);
	}
	private List<sobject> getSpecificChildObjects(sobject fromObject){
		List<sobject> specificSobjects = new List<Sobject>();
		for (sobject obj : relatedSobjects.values()) {
			if (obj.get(relationshipField) == fromObject.id) {
				specificSobjects.add(obj);
			}
		}

		return specificSobjects;
	}
	private List<sobject> getSpecificParentObjects(sobject fromObject){
		List<sobject> specificSobjects = new List<Sobject>();
		if (relatedSObjects.keySet().contains((id)fromObject.get(relationshipField))) {
			specificSobjects.add(relatedSobjects.get((id)fromObject.get(relationshipField)));
		}

		return specificSobjects;
	}

	public void saveChangesToDB(){
		if(sobjectsToUpdate != null && sobjectsToUpdate.values() != null && sobjectsToUpdate.values().size()>0){
			update sobjectsToUpdate.values();
		}

	}
	private Map<id, sobject> QueryRelatedSobjects(){
		return isParent ? QueryRelatedChildSobjects() : QueryRelatedParentSobjects();
	}
	private Map<id, sobject> QueryRelatedChildSobjects(){
		String query = 'SELECT ';
		query += getObjectFieldNames(childType) + ' ';
		query += 'FROM ' + childType + ' ';
		query += 'WHERE ' + relationshipField.getDescribe().getName() + ' ';
		query += 'IN ' + formatIdsForQuery(getAllSobjectIds('id'));
		system.debug(query.right(100));

		return new Map<id, sobject>(database.query(query));
	}
	private Map<id, sobject> QueryRelatedParentSobjects(){
		String query = 'SELECT ';
		query += getObjectFieldNames(parentType) + ' ';
		query += 'FROM ' + parentType + ' ';
		query += 'WHERE id ';
		query += 'IN ' + formatIdsForQuery(getAllSobjectIDs(relationshipField));
		system.debug(query.right(100));

		return new Map<id, sobject>(database.query(query));
	}
	private string getObjectFieldNames(string sobjectType){
		Schema.DescribeSobjectResult SobjectDescribe =
			Schema.describeSobjects(new String[] {sobjectType})[0];

		return String.join(new List<string>(SobjectDescribe.fields.getMap().keyset()), ',');
	}
	private List<id>  getAllSobjectIDs(schema.SObjectField field){
		set<id> ids = new set<id>();
		for (sobject obj : givenSobjects) {
			ids.add((id)obj.get(field));
		}

		return new List<id>(ids);
	}
	private List<id>  getAllSobjectIDs(string field){
		set<id> ids = new set<id>();
		for (sobject obj : givenSobjects) {
			ids.add((id)obj.get(field));
		}
		system.debug(' ' + ids);

		return new List<id>(ids);
	}
	private string formatIdsForQuery(List<id> ids){
		string formattedIdString = '(';
		for (id anId : ids) {
			formattedIdString += '\'' + anId + '\',';
		}
		formattedIdString =
			formattedIdString.removeEnd(',') + ')';
		system.debug('formattedString: ' + formattedIdString);

		return formattedIdString;

	}

}