import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ServiceRecordScreen extends StatefulWidget {
  final String employeeNumber;
  const ServiceRecordScreen({super.key, required this.employeeNumber});

  @override
  State<ServiceRecordScreen> createState() => _ServiceRecordScreenState();
}

class _ServiceRecordScreenState extends State<ServiceRecordScreen> {
  List<Map<String, dynamic>> serviceRecords = [];
  bool isLoading = true;
  String fullName = '';
  String firstDayOfService = '';
  String yearsOfService = '';
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    fetchServiceRecords(widget.employeeNumber);
  }

  Future<void> fetchServiceRecords(String empNo) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_records_data')
          .doc(empNo)
          .get();

      if (doc.exists) {
        final data = doc.data();
        fullName = data?['full_name'] ?? '';
        final rawRecords = data?['records'] as List<dynamic>? ?? [];
        serviceRecords = rawRecords
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (serviceRecords.isNotEmpty) {
          serviceRecords.sort((a, b) {
            DateTime? dateA = _parseDate(a['from_date']);
            DateTime? dateB = _parseDate(b['from_date']);
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          });

          final validDates = serviceRecords
              .map((r) => _parseDate(r['from_date']))
              .where((d) => d != null)
              .cast<DateTime>()
              .toList();

          if (validDates.isNotEmpty) {
            final earliestDate = validDates.reduce(
                (a, b) => a.isBefore(b) ? a : b);
            firstDayOfService =
                DateFormat('MM/dd/yyyy').format(earliestDate);

            final now = DateTime.now();
            int diffYears = now.year - earliestDate.year;
            int diffMonths = now.month - earliestDate.month;
            if (diffMonths < 0) {
              diffYears -= 1;
              diffMonths += 12;
            }
            yearsOfService = '$diffYears years $diffMonths months';
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching service records: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'PRESENT') {
      return null;
    }
    try {
      return DateFormat('MM/dd/yyyy').parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Record')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: $fullName',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Employee Number: ${widget.employeeNumber}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          'Years of Service: ${yearsOfService.isNotEmpty ? yearsOfService : 'N/A'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          'First Day of Service: ${firstDayOfService.isNotEmpty ? firstDayOfService : 'N/A'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1, color: Colors.black54),
                      const SizedBox(height: 12),
                      serviceRecords.isNotEmpty
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                columns: const [
                                  DataColumn(label: Text('Designation')),
                                  DataColumn(label: Text('From Date')),
                                  DataColumn(label: Text('To Date')),
                                  DataColumn(label: Text('Entity')),
                                  DataColumn(label: Text('Branch')),
                                  DataColumn(label: Text('Salary')),
                                  DataColumn(label: Text('Monthly Salary')),
                                  DataColumn(
                                      label: Text('Leave Without Pay')),
                                ],
                                rows: serviceRecords.map((record) {
                                  final salary = record['salary'];
                                  final yearlySalary =
                                      double.tryParse(salary.toString()) ?? 0;
                                  final monthlySalary = yearlySalary / 12;
                                  final formattedSalary =
                                      currencyFormat.format(yearlySalary);
                                  final formattedMonthly =
                                      currencyFormat.format(monthlySalary);
                                  return DataRow(cells: [
                                    DataCell(Text(record['designation'] ?? '')),
                                    DataCell(Text(record['from_date'] ?? '')),
                                    DataCell(Text(
                                        record['to_date'] ?? 'PRESENT')),
                                    DataCell(Text(record['entity'] ?? '')),
                                    DataCell(Text(record['branch'] ?? '')),
                                    DataCell(Text(formattedSalary)),
                                    DataCell(Text(formattedMonthly)),
                                    DataCell(Text(record['leave_without_pay'] ??
                                        'None')),
                                  ]);
                                }).toList(),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No existing service record yet.',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
