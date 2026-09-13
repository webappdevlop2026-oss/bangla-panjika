import 'package:flutter/material.dart';

class BengaliCalendarUI extends StatelessWidget {
  final String bengaliMonth;
  final String bengaliYear;
  final String englishMonth;
  final List<Map<String, String>> days;

  const BengaliCalendarUI({
    super.key,
    required this.bengaliMonth,
    required this.bengaliYear,
    required this.englishMonth,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3E1D6D);
    const secondary = Color(0xFF7C3FC8);
    const gold = Color(0xFFFFD45A);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF5), Color(0xFFFFF5DE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withOpacity(.60), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.20),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF29104C),
                  Color(0xFF5A258D),
                  Color(0xFF7C3FC8),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  bengaliMonth,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black38,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: gold.withOpacity(.55)),
                  ),
                  child: Text(
                    'বঙ্গাব্দ $bengaliYear',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  englishMonth,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(7, 9, 7, 5),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            decoration: BoxDecoration(
              color: primary.withOpacity(.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                _WeekDay('রবি', 'SUN', isSunday: true),
                _WeekDay('সোম', 'MON'),
                _WeekDay('মঙ্গল', 'TUE'),
                _WeekDay('বুধ', 'WED'),
                _WeekDay('বৃহস্পতি', 'THU'),
                _WeekDay('শুক্র', 'FRI'),
                _WeekDay('শনি', 'SAT'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: .62,
              ),
              itemBuilder: (context, index) {
                final day = days[index];

                if (day['blank'] == 'true') {
                  return const SizedBox();
                }

                final isToday = day['today'] == 'true';
                final festival = day['festival'] ?? '';
                final tithi = day['tithi'] ?? '';
                final bengaliDate = day['bengali'] ?? '';
                final englishDate = day['english'] ?? '';

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF2B5), Color(0xFFFFD76A)],
                          )
                        : festival.isNotEmpty
                        ? const LinearGradient(
                            colors: [Color(0xFFFFF5F5), Color(0xFFFFE9E9)],
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFFCF4)],
                          ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFFE09A00)
                          : festival.isNotEmpty
                          ? const Color(0xFFFFA8A8)
                          : const Color(0xFFE8DFCF),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isToday)
                        BoxShadow(
                          color: const Color(0xFFFFB000).withOpacity(.38),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(.035),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        bengaliDate,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: isToday
                              ? const Color(0xFFA82117)
                              : const Color(0xFF20152C),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.045),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          englishDate,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),

                      if (tithi.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tithi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            height: 1.15,
                            color: Color(0xFF5B3A87),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      if (festival.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          festival,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            height: 1.15,
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withOpacity(.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 15, color: Color(0xFFD69B00)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'আজকের দিন সোনালি রঙে চিহ্নিত',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5B3A87),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String bengali;
  final String english;
  final bool isSunday;

  const _WeekDay(this.bengali, this.english, {this.isSunday = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            bengali,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isSunday
                  ? const Color(0xFFC62828)
                  : const Color(0xFF3E1D6D),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            english,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: isSunday ? const Color(0xFFD75C5C) : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
