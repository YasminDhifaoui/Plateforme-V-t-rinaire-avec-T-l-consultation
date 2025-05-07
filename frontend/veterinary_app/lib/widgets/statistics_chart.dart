import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsChart extends StatelessWidget {
  final Map<String, int> data;

  const StatisticsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY =
        (data.values.isNotEmpty)
            ? (data.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
            : 10.0;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: _buildBarGroups(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= data.length) return Container();
                  return Text(
                    data.keys.elementAt(index),
                    style: TextStyle(fontSize: 12),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> groups = [];
    int x = 0;
    data.forEach((label, value) {
      groups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.blueAccent,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      x++;
    });
    return groups;
  }
}
