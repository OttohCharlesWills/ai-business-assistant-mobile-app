import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/side_nav.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;

  final List<Color> pieColors = [
    const Color(0xFF2F5DA8),
    const Color(0xFF8FAADC),
    const Color(0xFF4CAF50),
    const Color(0xFFE91E63),
    const Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final result = await DashboardService.getDashboard();

    if (!mounted) return;

    setState(() {
      data = result;
      loading = false;
    });
  }

  String formatMoney(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;

    return "₦${number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        )}";
  }

  double numericValue(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool isPositive(dynamic value) {
    return numericValue(value) >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1F3F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
            onPressed: fetchDashboard,
          ),
        ],
      ),

      drawer: const SideNav(),

      body: loading
          ? const FullScreenLoader(
              message: "Loading dashboard...",
            )
          : data == null
              ? const Center(
                  child: Text(
                    "Failed to load dashboard",
                    style: TextStyle(
                      color: Color(0xFF8FAADC),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchDashboard,
                  color: const Color(0xFF2F5DA8),
                  backgroundColor: const Color(0xFF0F2847),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // =====================================================
                      // REVENUE TODAY
                      // =====================================================

                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Revenue Today",
                              style: TextStyle(
                                color: Color(0xFF8FAADC),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              formatMoney(
                                data!['totalRevenueToday'],
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Color(0xFF8FAADC),
                                  size: 16,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  "Week: ${formatMoney(data!['totalRevenueThisWeek'] ?? data!['totalSalesThisWeek'])}",
                                  style: const TextStyle(
                                    color: Color(0xFF8FAADC),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // PRODUCTS IN STOCK
                      // =====================================================

                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.inventory_2_rounded,
                              label: "Products in Stock",
                              value:
                                  "${data!['productsInStock'] ?? 0}",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // PROFIT SUMMARY
                      // =====================================================

                      _sectionCard(
                        title: "Profit Summary",
                        icon: Icons.show_chart_rounded,
                        child: Column(
                          children: [
                            // TODAY
                            _subSectionLabel("Today"),

                            _row(
                              "Revenue",
                              formatMoney(
                                data!['totalRevenueToday'],
                              ),
                              null,
                            ),

                            _row(
                              "Cost of Goods",
                              formatMoney(
                                data!['costToday'],
                              ),
                              null,
                            ),

                            _row(
                              "Gross Profit",
                              formatMoney(
                                data!['grossProfitToday'] ??
                                    data!['dailyProfit'],
                              ),
                              isPositive(
                                data!['grossProfitToday'] ??
                                    data!['dailyProfit'],
                              ),
                            ),

                            const Divider(
                              color: Color(0xFF203A5C),
                            ),

                            // WEEK
                            _subSectionLabel("This Week"),

                            _row(
                              "Revenue",
                              formatMoney(
                                data!['totalRevenueThisWeek'] ??
                                    data!['totalSalesThisWeek'],
                              ),
                              null,
                            ),

                            _row(
                              "Cost of Goods",
                              formatMoney(
                                data!['costThisWeek'],
                              ),
                              null,
                            ),

                            _row(
                              "Gross Profit",
                              formatMoney(
                                data!['grossProfitWeek'] ??
                                    data!['weeklyProfit'],
                              ),
                              isPositive(
                                data!['grossProfitWeek'] ??
                                    data!['weeklyProfit'],
                              ),
                            ),

                            const Divider(
                              color: Color(0xFF203A5C),
                            ),

                            // MONTH
                            _subSectionLabel("This Month"),

                            _row(
                              "Revenue",
                              formatMoney(
                                data!['totalRevenueThisMonth'],
                              ),
                              null,
                            ),

                            _row(
                              "Cost of Goods",
                              formatMoney(
                                data!['costThisMonth'],
                              ),
                              null,
                            ),

                            _row(
                              "Gross Profit",
                              formatMoney(
                                data!['grossProfitMonth'] ??
                                    data!['monthlyProfit'],
                              ),
                              isPositive(
                                data!['grossProfitMonth'] ??
                                    data!['monthlyProfit'],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // BUSINESS EXPENSES
                      // =====================================================

                      _sectionCard(
                        title: "Business Expenses",
                        icon: Icons.receipt_long_rounded,
                        child: Column(
                          children: [
                            _row(
                              "Today",
                              formatMoney(
                                data!['dailyExpenses'],
                              ),
                              null,
                            ),

                            _row(
                              "This Week",
                              formatMoney(
                                data!['weeklyExpenses'],
                              ),
                              null,
                            ),

                            _row(
                              "This Month",
                              formatMoney(
                                data!['monthlyExpenses'],
                              ),
                              null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // NET PROFIT
                      // =====================================================

                      _sectionCard(
                        title: "Net Profit",
                        icon: Icons.account_balance_rounded,
                        child: Column(
                          children: [
                            _row(
                              "Today",
                              formatMoney(
                                data!['netProfitToday'],
                              ),
                              isPositive(
                                data!['netProfitToday'],
                              ),
                            ),

                            _row(
                              "This Week",
                              formatMoney(
                                data!['netProfitWeek'],
                              ),
                              isPositive(
                                data!['netProfitWeek'],
                              ),
                            ),

                            _row(
                              "This Month",
                              formatMoney(
                                data!['netProfitMonth'],
                              ),
                              isPositive(
                                data!['netProfitMonth'],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // LOSS
                      // =====================================================

                      _sectionCard(
                        title: "Loss",
                        icon: Icons.trending_down_rounded,
                        child: Column(
                          children: [
                            _row(
                              "Today",
                              formatMoney(
                                data!['dailyLoss'],
                              ),
                              null,
                            ),

                            _row(
                              "This Week",
                              formatMoney(
                                data!['weeklyLoss'],
                              ),
                              null,
                            ),

                            _row(
                              "This Month",
                              formatMoney(
                                data!['monthlyLoss'],
                              ),
                              null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // DISCOUNTS
                      // =====================================================

                      _sectionCard(
                        title: "Discounts Summary",
                        icon: Icons.local_offer_rounded,
                        child: Column(
                          children: [
                            _row(
                              "Today",
                              formatMoney(
                                data!['totalDiscountToday'],
                              ),
                              null,
                            ),

                            _row(
                              "This Week",
                              formatMoney(
                                data!['totalDiscountThisWeek'],
                              ),
                              null,
                            ),

                            _row(
                              "This Month",
                              formatMoney(
                                data!['totalDiscountThisMonth'],
                              ),
                              null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // SALES TREND
                      // =====================================================

                      _sectionCard(
                        title: "Sales Trend (Last 7 Days)",
                        icon: Icons.bar_chart_rounded,
                        child: SizedBox(
                          height: 200,
                          child: _buildSalesTrendChart(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =====================================================
                      // TOP SELLING PRODUCTS
                      // =====================================================

                      _sectionCard(
                        title: "Top Selling Products",
                        icon: Icons.pie_chart_rounded,
                        child:
                            (data!['topSellingProductNames'] as List?)
                                        ?.isEmpty ??
                                    true
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "No sales yet today",
                                        style: TextStyle(
                                          color:
                                              Color(0xFF8FAADC),
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      SizedBox(
                                        height: 180,
                                        child:
                                            _buildTopSellingPieChart(),
                                      ),

                                      const SizedBox(height: 12),

                                      ..._buildPieLegend(),
                                    ],
                                  ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ===============================================================
  // SUB SECTION LABEL
  // ===============================================================

  Widget _subSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // STAT CARD
  // ===============================================================

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2847),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF2F5DA8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8FAADC),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8FAADC),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SECTION CARD
  // ===============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2847),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8FAADC),
                size: 18,
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ===============================================================
  // ROW
  // ===============================================================

  Widget _row(
    String label,
    String value,
    bool? positive,
  ) {
    Color valueColor = Colors.white;

    if (positive != null) {
      valueColor = positive
          ? const Color(0xFF4CAF50)
          : Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8FAADC),
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SALES TREND CHART
  // ===============================================================

  Widget _buildSalesTrendChart() {
    final labels =
        List<String>.from(
      data!['salesTrendLabels'] ?? [],
    );

    final values =
        (data!['salesTrendData'] as List? ?? [])
            .map(
              (e) =>
                  double.tryParse(e.toString()) ??
                  0.0,
            )
            .toList();

    if (values.isEmpty ||
        values.every((v) => v == 0)) {
      return const Center(
        child: Text(
          "No sales data yet",
          style: TextStyle(
            color: Color(0xFF8FAADC),
          ),
        ),
      );
    }

    final highestValue =
        values.reduce(
          (a, b) => a > b ? a : b,
        );

      final double maxY =
          highestValue == 0
              ? 10.0
              : highestValue * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,

        barTouchData: BarTouchData(
          enabled: true,
        ),

        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles:
              const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          topTitles:
              const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          bottomTitles:
              AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (value, meta) {
                final index =
                    value.toInt();

                if (index < 0 ||
                    index >=
                        labels.length) {
                  return const SizedBox();
                }

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 6,
                  ),
                  child: Text(
                    labels[index],
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF8FAADC),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        borderData:
            FlBorderData(
          show: false,
        ),

        gridData:
            const FlGridData(
          show: false,
        ),

        barGroups:
            List.generate(
          values.length,
          (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  color:
                      const Color(0xFF2F5DA8),
                  width: 18,
                  borderRadius:
                      BorderRadius.circular(
                    4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===============================================================
  // TOP SELLING PIE CHART
  // ===============================================================

  Widget _buildTopSellingPieChart() {
    final names =
        List<String>.from(
      data!['topSellingProductNames'] ??
          [],
    );

    final values =
        (data!['topSellingProductSales']
                    as List? ??
                [])
            .map(
              (e) =>
                  double.tryParse(
                    e.toString(),
                  ) ??
                  0.0,
            )
            .toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,

        sections:
            List.generate(
          names.length,
          (index) {
            return PieChartSectionData(
              value: values[index],
              color: pieColors[
                  index % pieColors.length],
              title: '',
              radius: 60,
            );
          },
        ),
      ),
    );
  }

  // ===============================================================
  // PIE LEGEND
  // ===============================================================

  List<Widget> _buildPieLegend() {
    final names =
        List<String>.from(
      data!['topSellingProductNames'] ??
          [],
    );

    final values =
        (data!['topSellingProductSales']
                    as List? ??
                []);

    return List.generate(
      names.length,
      (index) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(
                  color: pieColors[
                      index %
                          pieColors.length],
                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  names[index],
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),

              Text(
                "${values[index]} sold",
                style:
                    const TextStyle(
                  color:
                      Color(0xFF8FAADC),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}