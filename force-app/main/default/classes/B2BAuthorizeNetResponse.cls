public class B2BAuthorizeNetResponse {
    
    public class Errors {
		public String errorCode;
		public String errorText;
	}

	public class Messages {
		public String code;
		public String description;
	}

	public class TransactionResponse {
		public String responseCode;
		public String authCode;
		public String avsResultCode;
		public String cvvResultCode;
		public String cavvResultCode;
		public String transId;
		public String refTransID;
		public String transHash;
		public String testRequest;
		public String accountNumber;
		public String accountType;
		public List<Messages> messages;
        public List<Errors> errors; 
		public String transHashSha2;
		public Integer SupplementalDataQualificationIndicator;
		public String networkTransId;
	}

	public class Message {
		public String code;
		public String text;
	}

	public class Messages_Z {
		public String resultCode;
		public List<Message> message;
	}

	public TransactionResponse transactionResponse;
	public Messages_Z messages;

	
	public static B2BAuthorizeNetResponse parse(String json) {
		return (B2BAuthorizeNetResponse) System.JSON.deserialize(json, B2BAuthorizeNetResponse.class);
	}
}