@isTest
public class TestDataFactory {

	public TestDataFactory() {}

	public List<SObject> createRecords(Integer recordsNumber, SObjectType type, Map<String, Object> valueByFieldName, Id recordTypeId, Boolean loadDefaults, Boolean doInsert) {
		List<SObject> records = new List<SObject>();
		for (Integer i = 0; i < recordsNumber; i++) {
			SObject record = this.newSObject(type, recordTypeId, loadDefaults);
			records.add(record);
			for (String f : valueByFieldName.keySet()) {
				record.put(f, valueByFieldName.get(f));
			}
		}
		if (doInsert) {
			insert records;
		}
		return records;
	}

	public List<SObject> createRecords(Integer recordsNumber, SObjectType type, Map<String, Object> valueByFieldName, Boolean doInsert) {
		return this.createRecords(recordsNumber, type, valueByFieldName, null, null, doInsert);
	}

	public List<SObject> createRecords(Integer recordsNumber, SObjectType type, Map<String, Object> valueByFieldName) {
		return this.createRecords(recordsNumber, type, valueByFieldName, true);
	}

	public List<SObject> createRecords(Integer recordsNumber, SObjectType type) {
		return this.createRecords(recordsNumber, type, new Map<String, Object>(), true);
	}

	/**
	 * Simulates Id in proper format for the SObject Type
	 *
	 *  @param sot  - SObject Type
	 *  @param s_num - number to generate at the end of the Id string
	 */
	public static String getFakeId(String sobjectType, Integer s_num) {
		Type t = Type.forName(sobjectType);
		if (t == null) return null;
		SObject so = (SObject) t.newInstance();
		String result = String.valueOf(s_num++);
		return so.getSObjectType().getDescribe().getKeyPrefix() +
				'0'.repeat(12 - result.length()) + result;
	}

	private SObject newSObject(SObjectType type, Id recordTypeId, Boolean loadDefaults) {
		return recordTypeId == null 
			? type.newSObject() 
			: type.newSObject(recordTypeId, loadDefaults);
	}

}