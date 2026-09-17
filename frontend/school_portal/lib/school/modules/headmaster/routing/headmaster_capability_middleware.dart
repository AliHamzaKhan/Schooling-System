import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../config/headmaster_routes.dart';
import '../data/headmaster_repository.dart';
import '../models/headmaster_workspace_context.dart';

typedef HeadmasterCapabilityLoader =
    Future<ApiResponse<HeadmasterWorkspaceContext>> Function();

/// Defers construction of a headmaster feature page until fresh effective
/// permissions confirm that at least one of [requiredAny] is available.
/// Backend authorization remains the final boundary for every API operation.
class HeadmasterCapabilityMiddleware extends GetMiddleware {
  final Set<String> requiredAny;

  HeadmasterCapabilityMiddleware(this.requiredAny, {super.priority = -5});

  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    if (page == null || requiredAny.isEmpty) return page;
    return () => HeadmasterCapabilityGate(
      requiredAny: requiredAny,
      childBuilder: (_) => page(),
    );
  }
}

class HeadmasterCapabilityGate extends StatefulWidget {
  final Set<String> requiredAny;
  final WidgetBuilder childBuilder;
  final HeadmasterCapabilityLoader? loader;

  const HeadmasterCapabilityGate({
    super.key,
    required this.requiredAny,
    required this.childBuilder,
    this.loader,
  });

  @override
  State<HeadmasterCapabilityGate> createState() =>
      _HeadmasterCapabilityGateState();
}

class _HeadmasterCapabilityGateState extends State<HeadmasterCapabilityGate> {
  bool _loading = true;
  String? _error;
  HeadmasterWorkspaceContext? _context;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _context = null;
    });
    ApiResponse<HeadmasterWorkspaceContext> result;
    try {
      result =
          await (widget.loader ??
              Get.find<HeadmasterRepository>().loadWorkspaceContext)();
    } catch (_) {
      result = ApiResponse.fail('Could not verify module access.');
    }
    if (!mounted) return;
    setState(() {
      if (result.success && result.data != null) {
        _context = result.data;
      } else {
        _error = result.error ?? 'Could not verify module access.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        body: AppStateView.loading(
          title: 'Checking module access',
          message: 'Confirming your current school permissions.',
        ),
      );
    }
    if (_error != null) {
      return AppScaffold(
        body: AppStateView.error(
          title: 'Could not verify module access',
          message: _error!,
          actionLabel: 'Try again',
          onAction: _load,
        ),
      );
    }

    final enabled = _context!.enabledModules;
    if (!widget.requiredAny.any(enabled.contains)) {
      return AppScaffold(
        body: AppStateView.error(
          title: 'Module unavailable',
          message:
              'This module is not enabled for your current school workspace.',
          actionLabel: 'Back to workspace',
          onAction: () => Get.offAllNamed(HeadmasterRoutes.shell),
        ),
      );
    }
    return widget.childBuilder(context);
  }
}
