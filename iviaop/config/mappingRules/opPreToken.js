importClass(Packages.com.tivoli.am.fim.trustserver.sts.utilities.IDMappingExtUtils);
importClass(Packages.com.tivoli.am.fim.trustserver.sts.utilities.OAuthMappingExtUtils);
importClass(Packages.com.ibm.security.access.user.UserLookupHelper);
IDMappingExtUtils.traceString("Starting Pre Token JS");

var requestType = stsuu.getContextAttributes().getAttributeValueByName("request_type");
var grant_type = stsuu.getContextAttributes().getAttributeValueByName("grant_type");
IDMappingExtUtils.traceString("Claims content: " + claims.getAllClaims().join());
for (const claim of claims.getAllClaims()) {
  IDMappingExtUtils.traceString("Resolving claim: " + claim);
  switch (claim) {
    case "email_verified":
      idtokenData["email_verified"] = true;
      tokenData["email_verified"] = true;
      break;
    case "updated_at":
      tokenData["updated_at"] = Date.now();
      break;
    default:
      var value = stsuu.getAttributeContainer().getAttributeValueByName(claim);
      if (value != null && value != "") {
        idtokenData[claim] = value;
        tokenData[claim] = value;
      }
  }
}
