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
          .where('stock', isEqualTo: 0)
          .get();
      final pendingOrdersSnapshot = await _firestore
          .collection('purchase')
          .doc(franchiseID)
          .collection('list')
          .where('state', isEqualTo: 'Pending')
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

      // Dummy data for charts
      _monthlyOrderData = List.generate(12, (index) => FlSpot(index.toDouble(), (index + 1) * 10.0));
      _ordersByRegion = {
        'Region A': 30,
        'Region B': 40,
        'Region C': 20,
        'Region D': 10,
      };

      setState(() {
        _outOfStock = outOfStockSnapshot.docs.length;
        _pendingOrders = pendingOrdersSnapshot.docs.length;
        _numberOfStores = storesSnapshot.docs.length;
        _numberOfFranchisees = franchiseesSnapshot.docs.length;
      });
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDashboardCard('Out Of Stock', _outOfStock.toString(), theme, Colors.orange),
                  _buildDashboardCard('Pending Orders', _pendingOrders.toString(), theme, Colors.blue),
                  _buildDashboardCard('Number Of Stores', _numberOfStores.toString(), theme, Colors.teal),
                  _buildDashboardCard('Number Of Franchisees', _numberOfFranchisees.toString(), theme, Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              _buildQuickLinks(theme),
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

  Widget _buildDashboardCard(String title, String count, FlutterFlowTheme theme, Color color) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(count, style: theme.headlineMedium.copyWith(color: Colors.white)),
              Text(title, style: theme.bodyMedium.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinks(FlutterFlowTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Links', style: theme.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildQuickLink('Add New Store', theme),
                _buildQuickLink('Add Product', theme),
                _buildQuickLink('Add Franchisee', theme),
                _buildQuickLink('Pending Orders', theme),
                _buildQuickLink('New Purchase Orders', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink(String label, FlutterFlowTheme theme) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.link),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.primaryBackground,
      ),
    );
  }

  Widget _buildChartsSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monthly Orders', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildLineChart(theme),
        const SizedBox(height: 16),
        Text('Orders By Region', style: theme.headlineSmall),
        const SizedBox(height: 8),
        _buildPieChart(theme),
      ],
    );
  }

  Widget _buildLineChart(FlutterFlowTheme theme) {
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
              spots: _monthlyOrderData,
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
                  final month = DateTime.now().subtract(Duration(days: (11 - value.toInt()) * 30)).month;
                  return Text(month.toString(), style: TextStyle(color: theme.primary));
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
        _buildBarChart(theme),
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
          barGroups: _monthlyOrderData.map((e) => BarChartGroupData(
            x: e.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: e.y,
                color: theme.tertiary,
              ),
            ],
          )).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = DateTime.now().subtract(Duration(days: 6 - value.toInt())).day;
                  return Text(day.toString(), style: TextStyle(color: theme.primary));
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
