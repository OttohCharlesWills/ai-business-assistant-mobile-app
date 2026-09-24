
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

import '../../../services/production_report_service.dart';
import '../../../services/plan_access_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';
import '../../subscription_screen.dart';

class ProductionReportScreen extends StatefulWidget {
  const ProductionReportScreen({super.key});

  @override
  State<ProductionReportScreen> createState() =>
      _ProductionReportScreenState();
}

class _ProductionReportScreenState
    extends State<ProductionReportScreen> {
  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  bool loading = true;
  bool checkingAccess = true;
  bool downloading = false;
  bool locked = false;

  String? lockMessage;

  Map<String, dynamic>? reportData;

  List shops = [];
  List productions = [];

  dynamic selectedShop;

  DateTime? startDate;
  DateTime? endDate;

  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CHECK PRODUCTION ACCESS
  // ------------------------------------------------------------

  Future<void> _checkAccess() async {
    setState(() {
      checkingAccess = true;
      loading = true;
    });

    final allowed =
        await PlanAccessService.hasFeature('production');

    if (!mounted) return;

    if (!allowed) {
      final message =
          await PlanAccessService.getFeatureMessage(
        'production',
        featureName: 'Production & Manufacturing',
      );

      if (!mounted) return;

      setState(() {
        locked = true;
        lockMessage = message.isNotEmpty
            ? message
            : 'Production & Manufacturing is available on the Business plan.';
        checkingAccess = false;
        loading = false;
      });

      return;
    }

    setState(() {
      locked = false;
      checkingAccess = false;
    });

    await fetchShops();
    await fetchReport();
  }

  // ------------------------------------------------------------
  // FETCH SHOPS
  // ------------------------------------------------------------

  Future<void> fetchShops() async {
    if (locked || checkingAccess) return;

    final data =
        await ShopService.getShops(refresh: true);

    if (!mounted) return;

    setState(() {
      shops = data;
    });
  }

  // ------------------------------------------------------------
  // FETCH REPORT
  // ------------------------------------------------------------

  Future<void> fetchReport() async {
    if (locked || checkingAccess) return;

    setState(() => loading = true);

    final res =
        await ProductionReportService.getProductionReport(
      startDate:
          startDate != null ? _fmtDate(startDate!) : null,
      endDate:
          endDate != null ? _fmtDate(endDate!) : null,
      shopId: selectedShop,
      search: searchCtrl.text.trim().isEmpty
          ? null
          : searchCtrl.text.trim(),
    );

    if (!mounted) return;

    if (res['status'] == true) {
      final data = res['data'];

      setState(() {
        reportData = data;
        productions = data?['productions'] ?? [];
      });
    }

    setState(() => loading = false);
  }

  // ------------------------------------------------------------
  // DOWNLOAD PDF
  // ------------------------------------------------------------

  Future<void> downloadPdf() async {
    if (locked) return;

    setState(() => downloading = true);

    final bytes =
        await ProductionReportService
            .downloadProductionReportPdf(
      startDate:
          startDate != null ? _fmtDate(startDate!) : null,
      endDate:
          endDate != null ? _fmtDate(endDate!) : null,
      shopId: selectedShop,
    );

    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to download PDF"),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => downloading = false);
      return;
    }

    try {
      final dir =
          await getApplicationDocumentsDirectory();

      final file =
          File('${dir.path}/production_report.pdf');

      await file.writeAsBytes(bytes);

      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Could not open PDF: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => downloading = false);
    }
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------

  Future<void> pickDate({
    required bool isStart,
  }) async {
    if (locked) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: accentBlue,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtMoney(dynamic v) {
    final d =
        double.tryParse(v?.toString() ?? '0') ?? 0;

    return "₦${d.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}";
  }

  // ------------------------------------------------------------
  // OPEN SUBSCRIPTION
  // ------------------------------------------------------------

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final data = reportData;

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Production Report",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
            onPressed:
                locked ? null : fetchReport,
          ),
        ],
      ),

      body: checkingAccess || loading
          ? const FullScreenLoader(
              message: "Loading production report...",
            )
          : Stack(
              children: [
                // ==================================================
                // ORIGINAL REPORT CONTENT
                // ==================================================

                AbsorbPointer(
                  absorbing: locked,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        // FILTERS
                        _sectionTitle("Filters"),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: _datePicker(
                                "Start Date",
                                startDate,
                                () => pickDate(
                                  isStart: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _datePicker(
                                "End Date",
                                endDate,
                                () => pickDate(
                                  isStart: false,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        _shopDropdown(),

                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: searchCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration:
                                const InputDecoration(
                              hintText:
                                  "Search batch no (e.g. BATCH-001)...",
                              hintStyle: TextStyle(
                                color: softBlue,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: softBlue,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) =>
                                fetchReport(),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  ElevatedButton.icon(
                                onPressed: fetchReport,
                                icon: const Icon(
                                  Icons.filter_alt_rounded,
                                  size: 16,
                                ),
                                label:
                                    const Text("Apply Filter"),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      accentBlue,
                                  foregroundColor:
                                      Colors.white,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child:
                                  ElevatedButton.icon(
                                onPressed: downloading
                                    ? null
                                    : downloadPdf,
                                icon: downloading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child:
                                            CircularProgressIndicator(
                                          color:
                                              Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 16,
                                      ),
                                label: const Text(
                                  "Download PDF",
                                ),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.black,
                                  foregroundColor:
                                      Colors.white,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        if (data == null)
                          const Center(
                            child: Text(
                              "No data",
                              style: TextStyle(
                                color: softBlue,
                              ),
                            ),
                          )
                        else ...[
                          // SUMMARY CARDS
                          _sectionTitle("Summary"),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _statCard(
                                "Total Batches",
                                "${data['total_productions'] ?? 0}",
                                accentBlue,
                                Icons.factory_rounded,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                "Completed",
                                "${data['completed_count'] ?? 0}",
                                Colors.green,
                                Icons.check_circle_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _statCard(
                                "In Progress",
                                "${data['in_progress_count'] ?? 0}",
                                Colors.orange,
                                Icons.pending_rounded,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                "Pending",
                                "${data['pending_count'] ?? 0}",
                                Colors.grey,
                                Icons.hourglass_empty_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _statCard(
                                "Input Cost",
                                _fmtMoney(
                                  data['total_input_cost'],
                                ),
                                const Color(0xFFF57C00),
                                Icons.input_rounded,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                "Output Value",
                                _fmtMoney(
                                  data['total_output_value'],
                                ),
                                Colors.green,
                                Icons.output_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _statCard(
                                "Loss Value",
                                _fmtMoney(
                                  data['total_loss_value'],
                                ),
                                Colors.red,
                                Icons.trending_down_rounded,
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                "Net Value",
                                _fmtMoney(
                                  data['net_value'],
                                ),
                                (double.tryParse(
                                            data['net_value']
                                                    ?.toString() ??
                                                '0') ??
                                        0) >=
                                    0
                                    ? Colors.teal
                                    : Colors.red,
                                Icons.equalizer_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // PRODUCTION BATCHES
                          _sectionTitle(
                            "Production Batches",
                          ),

                          const SizedBox(height: 8),

                          if (productions.isEmpty)
                            Container(
                              padding:
                                  const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  "No productions found",
                                  style: TextStyle(
                                    color: softBlue,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...productions.map(
                              (p) => _batchCard(p),
                            ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // LOCK OVERLAY
                // ==================================================

                if (locked) _buildLockedOverlay(),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // LOCKED OVERLAY
  // ------------------------------------------------------------

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: Container(
            color: bgColor.withOpacity(0.72),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: 390,
                ),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        accentBlue.withOpacity(0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // LOCK ICON
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color:
                            accentBlue.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              accentBlue.withOpacity(0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: accentBlue,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LABEL
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            accentBlue.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'BUSINESS PLAN FEATURE',
                        style: TextStyle(
                          color: accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Production Report Locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      lockMessage ??
                          'Production & Manufacturing is available '
                              'on the Business plan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: softBlue,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Upgrade your plan to view production reports, '
                      'analyze production data, and download PDF reports.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: softBlue,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // UPGRADE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _openSubscription,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .workspace_premium_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upgrade to Business Plan',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BATCH CARD
  // ------------------------------------------------------------

  double _sumPrice(List items) =>
      items.fold(
        0.0,
        (sum, i) =>
            sum +
            (double.tryParse(
                  i['price']?.toString() ?? '0',
                ) ??
                0),
      );

  Widget _batchCard(Map p) {
    final inputs =
        p['parsed_inputs'] as List? ?? [];

    final outputs =
        p['parsed_outputs'] as List? ?? [];

    final losses =
        p['parsed_losses'] as List? ?? [];

    final inCost = _sumPrice(inputs);
    final outVal = _sumPrice(outputs);
    final lossVal = _sumPrice(losses);
    final net = outVal - inCost - lossVal;

    final status =
        p['status']?.toString() ?? '';

    Color statusColor = Colors.grey;

    if (status == 'completed') {
      statusColor = Colors.green;
    }

    if (status == 'in_progress') {
      statusColor = Colors.orange;
    }

    if (status == 'pending') {
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          childrenPadding:
              const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            14,
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['batch_no'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      p['title'] ?? '',
                      style: const TextStyle(
                        color: softBlue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor
                      .withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Text(
                  status
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding:
                const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _miniChip(
                  "In: ${_fmtMoney(inCost)}",
                  Colors.orange,
                ),
                const SizedBox(width: 6),
                _miniChip(
                  "Out: ${_fmtMoney(outVal)}",
                  Colors.green,
                ),
                const SizedBox(width: 6),
                _miniChip(
                  "Net: ${_fmtMoney(net)}",
                  net >= 0
                      ? Colors.teal
                      : Colors.red,
                ),
              ],
            ),
          ),
          children: [
            if (inputs.isNotEmpty) ...[
              _itemsSection(
                "Inputs",
                inputs,
                Colors.orange,
              ),
              const SizedBox(height: 8),
            ],
            if (outputs.isNotEmpty) ...[
              _itemsSection(
                "Outputs",
                outputs,
                Colors.green,
              ),
              const SizedBox(height: 8),
            ],
            if (losses.isNotEmpty)
              _itemsSection(
                "Losses",
                losses,
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemsSection(
    String label,
    List items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 2,
            ),
            child: Text(
              "• ${item['name'] ?? item['item_name'] ?? '?'} — "
              "${item['quantity'] ?? 0} ${item['unit'] ?? ''} "
              "@ ${_fmtMoney(item['price'])}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniChip(
    String label,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) =>
      Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );

  Widget _statCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(
    String label,
    DateTime? value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: softBlue,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? _fmtDate(value)
                  : label,
              style: TextStyle(
                color: value != null
                    ? Colors.white
                    : softBlue,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopDropdown() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedShop,
          isExpanded: true,
          dropdownColor: cardColor,
          hint: const Text(
            "All Shops",
            style: TextStyle(
              color: softBlue,
              fontSize: 13,
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text(
                "All Shops",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ...shops.map(
              (s) => DropdownMenuItem(
                value: s['id'],
                child: Text(
                  s['name'] ?? '',
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(
            () => selectedShop = v,
          ),
        ),
      ),
    );
  }
}