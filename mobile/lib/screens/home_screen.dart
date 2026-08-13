import 'package:flutter/material.dart';
import '../models/ghazi_models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(GasStation) onSelectStation;

  const HomeScreen({Key? key, required this.onSelectStation}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final List<String> _categories = ['الكل', 'المكلا', 'الديس', 'فوه', 'روكب'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStations() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stations = ApiService.instance.stations.where((s) {
      final matchesQuery =
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'الكل' ||
          s.location.contains(_selectedCategory) ||
          s.name.contains(_selectedCategory);
      return matchesQuery && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GhaziTheme.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_gas_station,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('محطات غاز السيارات'),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المحطة أو الموقع...',
                prefixIcon: const Icon(Icons.search, color: GhaziTheme.navy),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // شريط التصفية حسب المنطقة / التصنيف
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: GhaziTheme.navy,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : GhaziTheme.navy,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? GhaziTheme.navy
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // قائمة المحطات
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshStations,
              color: GhaziTheme.orange,
              child: stations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: GhaziTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد محطات مطابقة للبحث',
                            style: TextStyle(
                              color: GhaziTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: stations.length,
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        station.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: GhaziTheme.navy,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: station.isOpen
                                            ? GhaziTheme.greenLight
                                            : GhaziTheme.redLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        station.isOpen
                                            ? 'مفتوح الآن'
                                            : 'مغلق حالياً',
                                        style: TextStyle(
                                          color: station.isOpen
                                              ? GhaziTheme.green
                                              : GhaziTheme.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: GhaziTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        station.location,
                                        style: const TextStyle(
                                          color: GhaziTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions_car_outlined,
                                          size: 18,
                                          color: GhaziTheme.orange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'الطابور: ${station.currentQueueCount} سيارة',
                                          style: const TextStyle(
                                            color: GhaziTheme.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(100, 36),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                      onPressed: station.isOpen
                                          ? () =>
                                              widget.onSelectStation(station)
                                          : null,
                                      child: const Text('حجز دور'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
