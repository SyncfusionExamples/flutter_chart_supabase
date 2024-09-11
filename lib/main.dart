import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'Your Supabase URL',
    anonKey: 'Your Supabase Anon Key',
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Supabase Chart',
      debugShowCheckedModeBanner: false,
      home: LiveChart(),
    );
  }
}

class LiveChart extends StatefulWidget {
  const LiveChart({super.key});

  @override
  LiveChartState createState() => LiveChartState();
}

class LiveChartState extends State<LiveChart> {
  List<ChartData> _chartData = <ChartData>[];
  final Stream<List<Map<String, dynamic>>> _future =
      supabase.from('table_name').stream(primaryKey: ['id']);
  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Syncfusion Flutter Chart with Supabase',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.black87,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 8,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _future,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final countries = snapshot.data!;
                  _chartData =
                      countries.map((e) => ChartData.fromSnapShot(e)).toList();
                  return SfCartesianChart(
                    primaryXAxis: const DateTimeCategoryAxis(),
                    primaryYAxis: const NumericAxis(
                      interval: 4,
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<ChartData, DateTime>(
                        animationDuration: 0,
                        dataSource: _chartData,
                        xValueMapper: (ChartData data, int index) =>
                            data.timestamp,
                        yValueMapper: (ChartData data, int index) =>
                            data.yValue,
                      )
                    ],
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () async {
                      await _client.from('table_name').insert({
                        'id': _chartData.isEmpty ? 1 : _chartData.length + 1,
                        'date': _chartData.last.timestamp
                            .add(const Duration(days: 1))
                            .toIso8601String(),
                        'yValue': _getRandomInt(105, 120),
                      });
                    },
                    child: const Text('Add data point at last'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _client.from('table_name').update({
                        'yValue': _getRandomInt(105, 120),
                      }).eq('id', 5);
                    },
                    child: const Text('Update y value of 5th segment'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _client
                          .from('table_name')
                          .delete()
                          .eq('id', _chartData.last.id);
                    },
                    child: const Text('Remove data point at last'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getRandomInt(int min, int max) {
    final Random random = Random();
    return min + random.nextInt(max - min);
  }
}

// Custom data model class with constructor to convert the data from snapshot
class ChartData {
  ChartData({
    required this.id,
    required this.timestamp,
    required this.yValue,
  });

  num id;
  DateTime timestamp;
  num yValue;

  static ChartData fromSnapShot(Map<String, dynamic> dataSnapshot) {
    return ChartData(
        id: dataSnapshot['id'],
        timestamp: DateTime.parse(dataSnapshot['date']),
        yValue: dataSnapshot['yValue']);
  }
}
