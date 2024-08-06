import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../Common/flutter_flow_theme.dart';
import '../Common/user_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _outOfStock = 0;
  int _pendingOrders = 0;
  int _numberOfStores = 0;
  int _numberOfFranchisees = 0;
  List<FlSpot> _monthlyOrderData = [];
  Map<String, double> _ordersByRegion = {};
  List<FlSpot> _weeklyOrderData = [];
  List<FlSpot> _revenueByStore = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final user = _auth.currentUser;
    final userState = Provider.of<UserState>(context, listen: false);
    final franchiseID = userState.franchiseID;

    if (user != null && franchiseID.isNotEmpty) {
      final outOfStockSnapshot = await _firestore
          .collection('product')
          .doc(franchiseID)
          .collection('list')
          .where('quantity', isEqualTo: 0)
          .get();
      final pendingOrdersSnapshot = await _firestore
          .collection('purchase')
          .doc(franchiseID)
          .collection('list')
          .where('State', isEqualTo: 'Pending')
          .get();
      final storesSnapshot = await _firestore
          .collection('store')
          .doc(franchiseID)
          .collection('list')
          .get();
      final franchiseesSnapshot = await _firestore
          .collection('franchise')
          .doc(franchiseID)
          .collection('list')
          .get();

      final salesSnapshot = await _firestore
          .collection('sales')
          .doc(franchiseID)
          .collection('list')
          .get();

      _monthlyOrderData = _calculateMonthlyOrders(salesSnapshot.docs);
      _ordersByRegion = _calculateOrdersByRegion(salesSnapshot.docs);
      _weeklyOrderData = _calculateWeeklyOrders(salesSnapshot.docs);
      _revenueByStore = _calculateRevenueByStore(salesSnapshot.docs);

      setState(() {
        _outOfStock = outOfStockSnapshot.docs.length;
        _pendingOrders = pendingOrdersSnapshot.docs.length;
        _numberOfStores = storesSnapshot.docs.length;
        _numberOfFranchisees = franchiseesSnapshot.docs.length;
      });
    }
  }

  List<FlSpot> _calculateMonthlyOrders(List<QueryDocumentSnapshot> salesDocs) {
    final monthlyOrders = List.generate(12, (index) => 0);
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['Date'] as Timestamp).toDate();
      final month = date.month - 1;
      monthlyOrders[month] += 1;
    }
    return monthlyOrders
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();
  }

  Map<String, double> _calculateOrdersByRegion(
      List<QueryDocumentSnapshot> salesDocs) {
    final ordersByRegion = <String, double>{};
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final region = data['Region'] ?? 'Unknown';
      ordersByRegion[region] = (ordersByRegion[region] ?? 0) + 1;
    }
    return ordersByRegion;
  }

  List<FlSpot> _calculateWeeklyOrders(List<QueryDocumentSnapshot> salesDocs) {
    final weeklyOrders = List.generate(7, (index) => 0);
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['Date'] as Timestamp).toDate();
      final weekday = date.weekday - 1;
      weeklyOrders[weekday] += 1;
    }
    return weeklyOrders
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();
  }

  List<FlSpot> _calculateRevenueByStore(List<QueryDocumentSnapshot> salesDocs) {
    final revenueByStore = <String, double>{};
    for (var doc in salesDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final store = data['StoreID'] ?? 'Unknown';
      final netTotal = data['NetTotal']?.toDouble() ?? 0;
      revenueByStore[store] = (revenueByStore[store] ?? 0) + netTotal;
    }
    return revenueByStore.entries
        .map((entry) => FlSpot(
            double.parse(entry.key.replaceAll(RegExp(r'[^0-9]'), '')),
            entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: theme.headlineMedium),
        backgroundColor: theme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildDashboardCard('Out Of Stock', _outOfStock.toString(),
                      theme, Colors.orange),
                  _buildDashboardCard('Pending Orders',
                      _pendingOrders.toString(), theme, Colors.blue),
                  _buildDashboardCard('Number Of Stores',
                      _numberOfStores.toString(), theme, Colors.teal),
                  _buildDashboardCard('Number Of Franchisees',
                      _numberOfFranchisees.toString(), theme, Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              _buildChartsSection(theme),
              const SizedBox(height: 16),
              _buildAdditionalReportsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, String count, FlutterFlowTheme theme, Color color) {
    return SizedBox(
      width: 150,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(count,
                  style: theme.headlineMedium.copyWith(color: Colors.white)),
              Text(title,
                  style: theme.bodyMedium.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monthly Orders', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildLineChart(theme, _monthlyOrderData),
        const SizedBox(height: 16),
        Text('Orders By Region', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildPieChart(theme),
      ],
    );
  }

  Widget _buildLineChart(FlutterFlowTheme theme, List<FlSpot> data) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.alternate,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              barWidth: 2,
              color: theme.tertiary,
              belowBarData: BarAreaData(show: false),
              dotData: const FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final month = DateTime.now()
                      .subtract(Duration(days: (11 - value.toInt()) * 30))
                      .month;
                  return Text(month.toString(),
                      style: TextStyle(color: theme.primary));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.primary, width: 1),
          ),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildPieChart(FlutterFlowTheme theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.alternate,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PieChart(
        PieChartData(
          sections: _ordersByRegion.entries
              .map((entry) => PieChartSectionData(
                    value: entry.value,
                    title: '${entry.value}%',
                    color: theme.tertiary,
                  ))
              .toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 4,
        ),
      ),
    );
  }

  Widget _buildAdditionalReportsSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Orders', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildLineChart(theme, _weeklyOrderData),
        const SizedBox(height: 16),
        Text('Revenue by Store', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildBarChart(theme),
      ],
    );
  }

  Widget _buildBarChart(FlutterFlowTheme theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.alternate,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: BarChart(
        BarChartData(
          barGroups: _revenueByStore
              .map((e) => BarChartGroupData(
                    x: e.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: e.y,
                        color: theme.tertiary,
                      ),
                    ],
                  ))
              .toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final store = _revenueByStore[value.toInt()].x.toString();
                  return Text(store, style: TextStyle(color: theme.primary));
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.primary, width: 1),
          ),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}
