import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyChart extends StatefulWidget {
  const MyChart({super.key});

  @override
  State<MyChart> createState() => _myChartState();
}

class _myChartState extends State<MyChart> {
  @override
  Widget build(BuildContext context) {
    return BarChart(mainBarData());
  }

  BarChartData mainBarData() {
    return BarChartData(
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ), // AxisTitles
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ), // AxisTitles
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: getTiles,
          ),
        ), // AxisTitles
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ), // AxisTitles
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: false),
    );
  }

  Widget getTiles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    Widget text;

    switch (value.toInt()) {
      case 0:
        text = const Text('01', style: style);
        break;
      case 1:
        text = const Text('02', style: style);
        break;
      case 2:
        text = const Text('03', style: style);
        break;
      case 3:
        text = const Text('04', style: style);
        break;
      case 4:
        text = const Text('05', style: style);
        break;
      case 5:
        text = const Text('06', style: style);
        break;
      case 6:
        text = const Text('07', style: style);
        break;
      case 7:
        text = const Text('08', style: style);
        break;

      default:
        text = const Text('00', style: style);
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 16, child: text);
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    String text;

    if (value == 0) {
      text = '1K';
    } else if (value == 2) {
      text = '2K';
    } else if (value == 3) {
      text = '3K';
    } else if (value == 4) {
      text = '4K';
    } else if (value == 5) {
      text = '5K';
    } else {
      return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: Text(text, style: style),
    );
  }
}
