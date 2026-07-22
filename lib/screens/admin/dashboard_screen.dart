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
    setState(() => loading = true);
    final result = await DashboardService.getDashboard();
    setState(() {
      data = result;
      loading = false;
    });
  }

  String formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return "₦${number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}";
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
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchDashboard,
          ),
        ],
      ),

      drawer: const SideNav(),

      body: loading
          ? const FullScreenLoader(message: "Loading dashboard...")
          : data == null
              ? const Center(
                  child: Text(
                    "Failed to load dashboard",
                    style: TextStyle(color: Color(0xFF8FAADC)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchDashboard,
                  color: const Color(0xFF2F5DA8),
                  backgroundColor: const Color(0xFF0F2847),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // REVENUE TODAY CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Revenue Today",
                              style: TextStyle(color: Color(0xFF8FAADC)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              formatMoney(data!['totalRevenueToday']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.shopping_cart_rounded,
                                    color: Color(0xFF8FAADC), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Week: ${formatMoney(data!['totalSalesThisWeek'])}",
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

                      // STAT ROW: STOCK
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.inventory_2_rounded,
                              label: "Products in Stock",
                              value: "${data!['productsInStock']}",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // PROFIT SUMMARY
                      _sectionCard(
                        title: "Profit Summary",
                        icon: Icons.show_chart_rounded,
                        child: Column(
                          children: [
                            _row("Daily", formatMoney(data!['dailyProfit']), true),
                            _row("Weekly", formatMoney(data!['weeklyProfit']), true),
                            _row("Monthly", formatMoney(data!['monthlyProfit']), true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // NET PROFIT / LOSS
                      _sectionCard(
                        title: "Net Profit & Loss",
                        icon: Icons.account_balance_rounded,
                        child: Column(
                          children: [
                            _row(
                              "Today",
                              formatMoney(data!['netProfitToday']),
                              (double.tryParse(data!['netProfitToday'].toString()) ?? 0) >= 0,
                            ),
                            _row(
                              "This Week",
                              formatMoney(data!['netProfitWeek']),
                              (double.tryParse(data!['netProfitWeek'].toString()) ?? 0) >= 0,
                            ),
                            _row(
                              "This Month",
                              formatMoney(data!['netProfitMonth']),
                              (double.tryParse(data!['netProfitMonth'].toString()) ?? 0) >= 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // DISCOUNTS
                      _sectionCard(
                        title: "Discounts Summary",
                        icon: Icons.local_offer_rounded,
                        child: Column(
                          children: [
                            _row("Today", formatMoney(data!['totalDiscountToday']), null),
                            _row("This Week", formatMoney(data!['totalDiscountThisWeek']), null),
                            _row("This Month", formatMoney(data!['totalDiscountThisMonth']), null),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SALES TREND CHART
                      _sectionCard(
                        title: "Sales Trend (Last 7 Days)",
                        icon: Icons.bar_chart_rounded,
                        child: SizedBox(
                          height: 200,
                          child: _buildSalesTrendChart(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TOP SELLING PRODUCTS PIE CHART
                      _sectionCard(
                        title: "Top Selling Products",
                        icon: Icons.pie_chart_rounded,
                        child: (data!['topSellingProductNames'] as List).isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "No sales yet today",
                                    style: TextStyle(color: Color(0xFF8FAADC)),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: _buildTopSellingPieChart(),
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
              color: const Color(0xFF2F5DA8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF8FAADC), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8FAADC), size: 18),
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

  Widget _row(String label, String value, bool? positive) {
    Color valueColor = Colors.white;
    if (positive != null) {
      valueColor = positive ? const Color(0xFF4CAF50) : Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8FAADC), fontSize: 13),
          ),
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

  Widget _buildSalesTrendChart() {
    final labels = List<String>.from(data!['salesTrendLabels'] ?? []);
    final values = (data!['salesTrendData'] as List)
        .map((e) => double.tryParse(e.toString()) ?? 0.0)
        .toList();

    if (values.isEmpty || values.every((v) => v == 0)) {
      return const Center(
        child: Text(
          "No sales data yet",
          style: TextStyle(color: Color(0xFF8FAADC)),
        ),
      );
    }

    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      color: Color(0xFF8FAADC),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(values.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: const Color(0xFF2F5DA8),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopSellingPieChart() {
    final names = List<String>.from(data!['topSellingProductNames'] ?? []);
    final values = (data!['topSellingProductSales'] as List)
        .map((e) => double.tryParse(e.toString()) ?? 0.0)
        .toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: List.generate(names.length, (index) {
          return PieChartSectionData(
            value: values[index],
            color: pieColors[index % pieColors.length],
            title: '',
            radius: 60,
          );
        }),
      ),
    );
  }

  List<Widget> _buildPieLegend() {
    final names = List<String>.from(data!['topSellingProductNames'] ?? []);
    final values = (data!['topSellingProductSales'] as List);

    return List.generate(names.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: pieColors[index % pieColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                names[index],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Text(
              "${values[index]} sold",
              style: const TextStyle(color: Color(0xFF8FAADC), fontSize: 12),
            ),
          ],
        ),
      );
    });
  }
}