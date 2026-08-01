importClass(Packages.com.tivoli.am.fim.trustserver.sts.utilities.IDMappingExtUtils);
importMappingRule("config");

IDMappingExtUtils.traceString(hostname);

context.setDecision(Decision.allow());
