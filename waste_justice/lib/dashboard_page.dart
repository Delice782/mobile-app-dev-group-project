import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import 'home_page.dart';
import 'notification.dart';
import 'offline_storage.dart';
import 'pages.dart';
import 'pending_submission_sync.dart';

/// Waste collector home after login — mirrors web `collector/dashboard.php`.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.uploadSuccessMessage});

  /// Same idea as web `?success=uploaded` banner.
  final String? uploadSuccessMessage;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  bool _loading = true;
  String? _loadError;
  String? _bannerMessage;
  List<Map<String, dynamic>> _collections = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _earningsSummary = {};
  String _currency = 'GHS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bannerMessage = widget.uploadSuccessMessage;
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  /// When earnings include a new [paymentID], show a local notification and
  /// vibration (no API/database changes — uses existing get_earnings data).
  Future<void> _maybeNotifyNewPayments(
    List<Map<String, dynamic>> payments,
    String currency,
  ) async {
    if (kIsWeb) return;

    final currentIds = <int>{};
    for (final p in payments) {
      final id = p['paymentID'];
      if (id is int) {
        currentIds.add(id);
      } else if (id is num) {
        currentIds.add(id.toInt());
      }
    }

    final known = OfflineStorageService.getKnownPaidPaymentIds().toSet();
    if (known.isEmpty) {
      await OfflineStorageService.setKnownPaidPaymentIds(currentIds);
      return;
    }

    for (final p in payments) {
      final rawId = p['paymentID'];
      final id = rawId is int
          ? rawId
          : rawId is num
              ? rawId.toInt()
              : null;
      if (id == null || known.contains(id)) continue;

      final amt = p['amount'];
      final amountLabel =
          '$currency ${amt is num ? amt.toStringAsFixed(2) : amt}';
      String? plastic;
      final col = p['collection'];
      if (col is Map && col['plasticType'] is Map) {
        plastic = col['plasticType']['typeName']?.toString();
      }

      await NotificationService.instance.notifyNewCompletedPayment(
        paymentId: id,
        amountLabel: amountLabel,
        plasticType: plastic,
      );
    }

    await OfflineStorageService.setKnownPaidPaymentIds(currentIds);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final synced = await PendingSubmissionSync.flushAll();
      final collectionsData = await ApiService.getCollections();
      final earningsData = await ApiService.getEarnings();
      final payments = List<Map<String, dynamic>>.from(
        earningsData['earnings'] ?? [],
      );
      final currency = earningsData['currency']?.toString() ?? 'GHS';
      await _maybeNotifyNewPayments(payments, currency);
      if (!mounted) return;
      setState(() {
        _collections = List<Map<String, dynamic>>.from(
          collectionsData['collections'] ?? [],
        );
        _stats = Map<String, dynamic>.from(
          collectionsData['statistics'] ?? {},
        );
        _payments = payments;
        _earningsSummary = Map<String, dynamic>.from(
          earningsData['summary'] ?? {},
        );
        _currency = currency;
        _loading = false;
      });
      if (synced > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced == 1
                  ? '1 offline submission was sent.'
                  : '$synced offline submissions were sent.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String get _userName {
    final m = OfflineStorageService.getUserCredentials();
    final n = m?['userName']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Collector';
  }

  double get _totalEarnings {
    final v = _earningsSummary['totalEarnings'];
    if (v is num) return v.toDouble();
    return 0;
  }

  void _logout() {
    OfflineStorageService.clearUserCredentials();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (d == null) return raw;
      return '${_months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _plasticName(Map<String, dynamic> c) {
    final pt = c['plasticType'];
    if (pt is Map) return pt['typeName']?.toString() ?? '';
    return '';
  }

  String _statusName(Map<String, dynamic> c) {
    final s = c['status'];
    if (s is Map) return s['statusName']?.toString() ?? '';
    return '';
  }

  String _aggregatorLabel(Map<String, dynamic> c) {
    final a = c['aggregator'];
    if (a is Map && a['name'] != null) {
      return a['name'].toString();
    }
    return 'Select Aggregator';
  }

  /// Collection IDs that already appear in completed earnings (aggregator paid).
  Set<int> get _paidCollectionIds {
    final s = <int>{};
    for (final p in _payments) {
      final col = p['collection'];
      if (col is Map) {
        final id = col['collectionID'];
        if (id is int) {
          s.add(id);
        } else if (id is num) {
          s.add(id.toInt());
        }
      }
    }
    return s;
  }

  Future<void> _savePaymentReceipt(Map<String, dynamic> p) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final name =
          'WasteJustice_receipt_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${dir.path}/$name');
      final amt = p['amount'];
      final paid = p['paidAt']?.toString();
      final col = p['collection'];
      final buf = StringBuffer()
        ..writeln('WasteJustice — Payment receipt')
        ..writeln('Generated: ${DateTime.now().toIso8601String()}')
        ..writeln(
          'Amount: $_currency ${amt is num ? amt.toStringAsFixed(2) : amt}',
        )
        ..writeln('Paid at: ${paid ?? '—'}');
      if (col is Map) {
        buf.writeln('Collection ID: ${col['collectionID'] ?? '—'}');
        final pt = col['plasticType'];
        if (pt is Map) {
          buf.writeln('Plastic type: ${pt['typeName'] ?? '—'}');
        }
      }
      await file.writeAsString(buf.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Receipt saved (${file.path})',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save receipt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCol = (_stats['totalCollections'] as num?)?.toInt() ?? 0;
    final pending = (_stats['pendingCollections'] as num?)?.toInt() ?? 0;
    final delivered = (_stats['deliveredCollections'] as num?)?.toInt() ?? 0;
    final offlinePending = OfflineStorageService.pendingCollectionCount;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🌍 WasteJustice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'Waste Collector Dashboard',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'dashboard':
                  break;
                case 'aggregators':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AggregatorsPage()),
                  );
                  break;
                case 'submit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPage()),
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
              PopupMenuItem(value: 'aggregators', child: Text('View Aggregators')),
              PopupMenuItem(value: 'submit', child: Text('Submit Waste')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _loading && _collections.isEmpty && _loadError == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_bannerMessage != null) ...[
                    Material(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green.shade700),
                        title: Text(
                          _bannerMessage!,
                          style: TextStyle(color: Colors.green.shade900, fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _bannerMessage = null),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _loadError!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  if (offlinePending > 0) ...[
                    Material(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: Icon(Icons.cloud_upload_outlined,
                            color: Colors.orange.shade800),
                        title: Text(
                          '$offlinePending submission(s) saved offline — will send when you are online.',
                          style: TextStyle(
                              color: Colors.orange.shade900, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Pull down to refresh after you reconnect.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Welcome back, $_userName! 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your waste collection transactions and monitor your impact.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🆓 FREE VERSION\n'
                      'Full access to all collector features at no cost!',
                      style: TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _miniStat('📦 Total Collections', '$totalCol', 'All time collections'),
                  const SizedBox(height: 10),
                  _miniStat(
                    '💰 Total Earnings',
                    '$_currency ${_totalEarnings.toStringAsFixed(2)}',
                    'Net amount received',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat('⏳ Pending', '$pending', 'Awaiting acceptance'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _miniStat('✅ Delivered', '$delivered', 'Successfully delivered'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AggregatorsPage()),
                        );
                      },
                      icon: const Icon(Icons.factory_outlined),
                      label: const Text('🏭 View Aggregators & Prices'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LocationPage()),
                        );
                      },
                      icon: const Icon(Icons.recycling),
                      label: const Text('♻️ Upload Plastic Waste'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '♻️ My Waste Collections',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_collections.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No collections yet. Upload plastic waste to get started.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.green.shade50),
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Weight')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Aggregator')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Date')),
                        ],
                        rows: _collections.map((c) {
                          final id = c['collectionID'];
                          final cid = id is int
                              ? id
                              : id is num
                                  ? id.toInt()
                                  : null;
                          final w = c['weight'];
                          final loc = c['location']?.toString() ?? '';
                          final paidRow =
                              cid != null && _paidCollectionIds.contains(cid);
                          return DataRow(
                            cells: [
                              DataCell(Text('#$id')),
                              DataCell(Text(_plasticName(c))),
                              DataCell(Text('${w is num ? w.toStringAsFixed(2) : w} kg')),
                              DataCell(SizedBox(
                                width: 120,
                                child: Text(loc, overflow: TextOverflow.ellipsis, maxLines: 2),
                              )),
                              DataCell(Text(
                                _aggregatorLabel(c),
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(Text(_statusName(c))),
                              DataCell(Text(
                                paidRow ? 'Paid' : '—',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: paidRow
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              )),
                              DataCell(Text(_fmtDate(c['collectionDate']?.toString()))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    '💵 Payment History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_payments.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No payment history yet. Payments will appear here once your deliveries are accepted.',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ..._payments.take(20).map((p) {
                      final amt = p['amount'];
                      final paid = p['paidAt']?.toString();
                      final col = p['collection'];
                      String type = '';
                      if (col is Map && col['plasticType'] is Map) {
                        type = col['plasticType']['typeName']?.toString() ?? '';
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '$_currency ${amt is num ? amt.toStringAsFixed(2) : amt}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            [type, _fmtDate(paid)]
                                .where((e) => e.isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_outlined),
                            tooltip: 'Save receipt to device',
                            onPressed: () => _savePaymentReceipt(p),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _miniStat(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}
