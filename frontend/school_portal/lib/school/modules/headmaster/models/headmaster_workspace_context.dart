class HeadmasterWorkspaceContext {
  final String schoolName;
  final String? activeSession;
  final Set<String> enabledModules;

  const HeadmasterWorkspaceContext({
    required this.schoolName,
    required this.activeSession,
    required this.enabledModules,
  });
}
