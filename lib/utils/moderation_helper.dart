import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'ui_utils.dart';

/// ModerationHelper: Implements in-app User-Generated Content (UGC) reporting
/// and local listing hiding after successful report delivery.
class ModerationHelper {
  static const String _prefBlockedProviders = 'ugc_blocked_providers';
  static const String _prefReportedItems = 'ugc_reported_items';

  static Set<String> _cachedBlockedProviders = {};
  static Set<String> _cachedReportedItems = {};
  static String? _loadedUserId;

  /// Loads cached blocked and reported IDs from SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (_loadedUserId == userId && userId != null) return;
      _cachedBlockedProviders =
          (prefs.getStringList(_prefBlockedProviders) ?? []).toSet();
      _cachedReportedItems =
          (prefs.getStringList(_prefReportedItems) ?? []).toSet();
      _loadedUserId = userId;
    } catch (_) {}
  }

  /// Synchronously checks whether a listing or provider is blocked/reported.
  static bool isBlockedOrReported(String? providerId, String? itemId) {
    if (providerId != null && _cachedBlockedProviders.contains(providerId)) {
      return true;
    }
    if (itemId != null && _cachedReportedItems.contains(itemId)) {
      return true;
    }
    return false;
  }

  /// Reports a listing and optionally blocks the provider.
  static Future<void> submitReport({
    required String itemId,
    required String itemName,
    required String providerId,
    required String reason,
    String? additionalNotes,
    bool blockProvider = true,
    ApiService? apiService,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final currentUserId = prefs.getString('user_id');
    if (currentUserId == null || currentUserId.isEmpty) {
      throw StateError('Sign in to report a listing.');
    }
    // Only acknowledge a report after the server has accepted it.
    await (apiService ?? ApiService())
        .post('/api/reports', {
          'reporterUserId': currentUserId,
          'reportedItemId': itemId,
          'reportedItemName': itemName,
          'reportedProviderId': providerId,
          'reason': reason,
          'details': additionalNotes ?? '',
          'blocked': blockProvider,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 20));
    await init();
    _cachedReportedItems.add(itemId);
    await prefs.setStringList(
      _prefReportedItems,
      _cachedReportedItems.toList(),
    );
    if (blockProvider && providerId.isNotEmpty) {
      _cachedBlockedProviders.add(providerId);
      await prefs.setStringList(
        _prefBlockedProviders,
        _cachedBlockedProviders.toList(),
      );
    }
  }

  /// Displays the in-app UGC Report & Block Dialog.
  static void showReportDialog(
    BuildContext context, {
    required String itemId,
    required String itemName,
    required String providerId,
    required String providerName,
    VoidCallback? onReported,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return _ReportDialogContent(
          itemId: itemId,
          itemName: itemName,
          providerId: providerId,
          providerName: providerName,
          onReported: onReported,
        );
      },
    );
  }
}

class _ReportDialogContent extends StatefulWidget {
  final String itemId;
  final String itemName;
  final String providerId;
  final String providerName;
  final VoidCallback? onReported;

  const _ReportDialogContent({
    required this.itemId,
    required this.itemName,
    required this.providerId,
    required this.providerName,
    this.onReported,
  });

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  final List<String> _reasons = [
    'Inappropriate or offensive photos / content',
    'Fraud, scam, or misleading information',
    'Incorrect phone number or price rate',
    'Abusive or harassment behavior',
    'Other objectionable behavior',
  ];

  String? _selectedReason;
  bool _blockProvider = true;
  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    try {
      await ModerationHelper.submitReport(
        itemId: widget.itemId,
        itemName: widget.itemName,
        providerId: widget.providerId,
        reason: _selectedReason!,
        additionalNotes: _notesController.text.trim(),
        blockProvider: _blockProvider,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      UiUtils.showCenteredToast(
        context,
        'Report could not be sent. Please try again.',
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);

    UiUtils.showCenteredToast(
      context,
      'Report received. This listing has been hidden from your results.',
    );

    widget.onReported?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flag_rounded, color: Colors.red[700], size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Report Listing',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us understand what is wrong with "${widget.itemName}" by ${widget.providerName}:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: reason,
                        groupValue: _selectedReason,
                        activeColor: const Color(0xFF00AA55),
                        onChanged:
                            (val) => setState(() => _selectedReason = val),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSelected
                                    ? const Color(0xFF1B5E20)
                                    : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF7F9F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            // Block Provider Checkbox
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _blockProvider,
                    activeColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged:
                        (val) => setState(() => _blockProvider = val ?? true),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Block this provider (hide all their listings from you)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Submit Report',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
        ),
      ],
    );
  }
}
