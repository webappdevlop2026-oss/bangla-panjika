class _CalendarDayCellState extends State<_CalendarDayCell> {
  int _infoIndex = 0;
  Timer? _infoTimer;

  @override
  void initState() {
    super.initState();

    // প্রতিটি date box-এর তথ্য পালা করে দেখাবে।
    _infoTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() {
        _infoIndex++;
      });
    });
  }

  @override
  void dispose() {
    _infoTimer?.cancel();
    super.dispose();
  }

  String _timeText(DateTime time) {
    var hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $amPm';
  }

  // সূর্যোদয়-সূর্যাস্তের দৈর্ঘ্যকে ৮ ভাগ করে
  // প্রচলিত weekday Rahu segment বের করা হচ্ছে।
  List<DateTime> _rahuKaal(DateTime sunrise, DateTime sunset) {
    final daylightMinutes = sunset.difference(sunrise).inMinutes;

    if (daylightMinutes <= 0) {
      return [sunrise, sunrise.add(const Duration(minutes: 90))];
    }

    final part = daylightMinutes / 8;

    const rahuPart = <int, int>{
      DateTime.sunday: 7,
      DateTime.monday: 1,
      DateTime.tuesday: 6,
      DateTime.wednesday: 4,
      DateTime.thursday: 5,
      DateTime.friday: 3,
      DateTime.saturday: 2,
    };

    final index = rahuPart[widget.greg.weekday] ?? 0;

    final start = sunrise.add(Duration(minutes: (part * index).round()));

    final end = sunrise.add(Duration(minutes: (part * (index + 1)).round()));

    return [start, end];
  }

  // আপাতত দিনের মধ্যভাগের একটি compact শুভ সময় দেখানো হচ্ছে।
  // পরে app-এর full Muhurta rules-এর সঙ্গে এটাকে connect করা যাবে।
  List<DateTime> _dayMiddleWindow(DateTime sunrise, DateTime sunset) {
    final daylight = sunset.difference(sunrise);

    if (daylight.inMinutes <= 0) {
      return [sunrise, sunrise.add(const Duration(minutes: 48))];
    }

    final middle = sunrise.add(
      Duration(milliseconds: daylight.inMilliseconds ~/ 2),
    );

    return [
      middle.subtract(const Duration(minutes: 24)),
      middle.add(const Duration(minutes: 24)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    final currentEvent = events.isNotEmpty ? events.first : null;

    Color? pip;

    Color cellBg = Colors.white;
    Color cellBorder = _BengaliCalendarScreenState._lavenderBorder;

    final cat = currentEvent?.category;

    if (cat == 'purnima') {
      pip = _BengaliCalendarScreenState._gold;
      cellBg = _BengaliCalendarScreenState._goldSoft;
      cellBorder = _BengaliCalendarScreenState._goldLine;
    } else if (cat == 'amabasya') {
      pip = _BengaliCalendarScreenState._night;
      cellBg = const Color(0xFFF2EEFA);
    } else if (cat == 'ekadashi') {
      pip = _BengaliCalendarScreenState._leaf;
      cellBg = _BengaliCalendarScreenState._leafSoft;
      cellBorder = _BengaliCalendarScreenState._leafLine;
    } else if (currentEvent != null || widget.isSankranti) {
      pip = _BengaliCalendarScreenState._sundayRed;
      cellBg = _BengaliCalendarScreenState._vermSoft;
      cellBorder = _BengaliCalendarScreenState._vermLine;
    }

    if (widget.highlightTint) {
      cellBg = _BengaliCalendarScreenState._vermSoft;
      cellBorder = _BengaliCalendarScreenState._vermLine;
    }

    final numberColor = widget.isSunday
        ? _BengaliCalendarScreenState._sundayRed
        : _BengaliCalendarScreenState._purpleDeep;

    final marked = widget.isSelected || widget.isToday;

    // -------------------------------------------------------------
    // Existing Panchang engine থেকেই daily information নেওয়া হচ্ছে।
    // -------------------------------------------------------------
    final sun = PanchangCalculator.sunTimes(
      widget.greg,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );

    final nakIndex = PanchangCalculator.nakshatraIndexFor(sun.sunrise);

    final nakshatra = PanchangCalculator.nakshatraNames[nakIndex];

    final rahu = _rahuKaal(sun.sunrise, sun.sunset);

    final shubho = _dayMiddleWindow(sun.sunrise, sun.sunset);

    final movingInfo = <String>[
      widget.tithiName,
      '✦ $nakshatra',
      'রাহুকাল ${_timeText(rahu[0])}-${_timeText(rahu[1])}',
      'শুভ সময় ${_timeText(shubho[0])}-${_timeText(shubho[1])}',
      if (currentEvent != null) currentEvent.label,
    ];

    final currentInfo = movingInfo[_infoIndex % movingInfo.length];

    return GestureDetector(
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.dim ? 0.35 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: widget.isToday
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF8D8), Color(0xFFFFDC75)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cellBg, Colors.white],
                  ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: widget.isToday
                  ? const Color(0xFFD89B12)
                  : marked
                  ? _BengaliCalendarScreenState._purpleAccent
                  : cellBorder,
              width: widget.isToday
                  ? 2.2
                  : marked
                  ? 2
                  : 1,
            ),
            boxShadow: [
              if (widget.isToday)
                BoxShadow(
                  color: const Color(0xFFFFB300).withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
            ],
          ),

          // =========================================================
          // DATE BOX
          // =========================================================
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 5, 2, 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // -----------------------------
                    // বড় বাংলা তারিখ
                    // -----------------------------
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.bnDay,
                          style: TextStyle(
                            fontSize: 29,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            color: numberColor,
                            shadows: widget.isToday
                                ? const [
                                    Shadow(blurRadius: 2, color: Colors.white),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    // -----------------------------
                    // English date
                    // -----------------------------
                    Text(
                      _BengaliCalendarScreenState.engDayLabel(widget.greg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        height: 1,
                        color: _BengaliCalendarScreenState._muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // -----------------------------
                    // Moving daily Panchang details
                    // -----------------------------
                    SizedBox(
                      height: 22,
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0.8, 0),
                                end: Offset.zero,
                              ).animate(animation);

                              return ClipRect(
                                child: SlideTransition(
                                  position: slide,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                        child: Center(
                          key: ValueKey<String>(currentInfo),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Text(
                              currentInfo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 7.6,
                                height: 1.08,
                                color: _BengaliCalendarScreenState._inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------------
              // পূর্ণিমা / অমাবস্যা / একাদশী / উৎসব marker
              // -------------------------------------------------------
              if (pip != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pip,
                      boxShadow: [
                        BoxShadow(color: pip.withOpacity(0.40), blurRadius: 3),
                      ],
                    ),
                  ),
                ),

              // -------------------------------------------------------
              // TODAY BADGE
              // -------------------------------------------------------
              if (widget.isToday)
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC82127),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'আজ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.3,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
