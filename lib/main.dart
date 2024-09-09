library event_calendar;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Supabase Calendar',
      debugShowCheckedModeBanner: false,
      home: EventCalendar(),
    );
  }
}

class EventCalendar extends StatefulWidget {
  const EventCalendar({super.key});

  @override
  EventCalendarState createState() => EventCalendarState();
}

class EventCalendarState extends State<EventCalendar> {
  List<ChartData> chartData = <ChartData>[];
  final _future = supabase.from('gold_rate').stream(primaryKey: ['id']);
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
                  chartData =
                      countries.map((e) => ChartData.fromSnapShot(e)).toList();
                  return Padding(
                    padding:
                        const EdgeInsets.only(top: 18.0, left: 30, right: 30),
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      primaryXAxis: DateTimeCategoryAxis(
                        interval: 1,
                        axisLabelFormatter: (args) {
                          return ChartAxisLabel(
                              args.text.replaceAll(' ', '\n'), args.textStyle);
                        },
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: const NumericAxis(
                        interval: 6,
                        rangePadding: ChartRangePadding.additional,
                      ),
                      series: <CartesianSeries>[
                        CandleSeries<ChartData, DateTime>(
                          animationDuration: 0,
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.timestamp,
                          lowValueMapper: (ChartData data, _) => data.low,
                          highValueMapper: (ChartData data, _) => data.high,
                          openValueMapper: (ChartData data, _) => data.open,
                          closeValueMapper: (ChartData data, _) => data.close,
                          // dataLabelSettings:
                          //     const DataLabelSettings(isVisible: true),
                        )
                      ],
                    ),
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
                      await _client.from('gold_rate').insert({
                        'id': chartData.isEmpty ? 1 : chartData.length + 1,
                        'date': chartData.last.timestamp
                            .add(const Duration(days: 1))
                            .toIso8601String(),
                        'low': 106.4,
                        'high': 112.5,
                        'open': 107.2,
                        'close': 110.9,
                      });
                    },
                    child: const Text('Add data point at last'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _client
                          .from('gold_rate')
                          .delete()
                          .eq('id', chartData.last.id);
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

class ChartData {
  ChartData({
    required this.id,
    required this.timestamp,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
  });

  num id;
  DateTime timestamp;
  num open;
  num close;
  num high;
  num low;

  static ChartData fromSnapShot(Map<String, dynamic> dataSnapshot) {
    return ChartData(
        id: dataSnapshot['id'],
        timestamp: DateTime.parse(dataSnapshot['date']),
        open: dataSnapshot['open'],
        close: dataSnapshot['close'],
        high: dataSnapshot['high'],
        low: dataSnapshot['low']);
  }
}
