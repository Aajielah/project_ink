// src/utils/dateUtils.js

export const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

export const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/**
 * Returns total days in a given year and month (monthIndex is 0-11).
 */
export function getDaysInMonth(year, monthIndex) {
  return new Date(year, monthIndex + 1, 0).getDate();
}

/**
 * Defines the 4 week chunks for any month:
 * Week 1: 1 - 7
 * Week 2: 8 - 14
 * Week 3: 15 - 21
 * Week 4: 22 - End of Month (28, 29, 30, or 31)
 */
export function getMonthWeekDefinitions(year, monthIndex) {
  const totalDays = getDaysInMonth(year, monthIndex);

  return [
    {
      weekNumber: 1,
      startDay: 1,
      endDay: 7,
      label: 'Week 1',
      dateRange: `Day 1 - 7`,
    },
    {
      weekNumber: 2,
      startDay: 8,
      endDay: 14,
      label: 'Week 2',
      dateRange: `Day 8 - 14`,
    },
    {
      weekNumber: 3,
      startDay: 15,
      endDay: 21,
      label: 'Week 3',
      dateRange: `Day 15 - 21`,
    },
    {
      weekNumber: 4,
      startDay: 22,
      endDay: totalDays,
      label: 'Week 4',
      dateRange: `Day 22 - ${totalDays}`,
    },
  ];
}

/**
 * When creating a month folder, calculates which weeks are remaining.
 * If created on day 22 or later, only Week 4 is created.
 * If created on day 16, Week 3 and Week 4 are created.
 * If created for a future month, all 4 weeks are created.
 */
export function calculateRemainingWeeks(year, monthIndex, creationDate = new Date()) {
  const allWeeks = getMonthWeekDefinitions(year, monthIndex);
  const currentYear = creationDate.getFullYear();
  const currentMonth = creationDate.getMonth();
  const currentDay = creationDate.getDate();

  // If month is in the future, return all 4 weeks
  if (year > currentYear || (year === currentYear && monthIndex > currentMonth)) {
    return allWeeks;
  }

  // If month is in the past, return empty or all 4
  if (year < currentYear || (year === currentYear && monthIndex < currentMonth)) {
    return allWeeks;
  }

  // Same month: only weeks whose endDay >= currentDay
  return allWeeks.filter((week) => week.endDay >= currentDay);
}

/**
 * Check if a week has expired (past its end day at 23:59:59).
 */
export function isWeekExpired(year, monthIndex, weekDef, now = new Date()) {
  const weekEnd = new Date(year, monthIndex, weekDef.endDay, 23, 59, 59, 999);
  return now.getTime() > weekEnd.getTime();
}

/**
 * Check if a week is the current active week.
 */
export function isWeekActive(year, monthIndex, weekDef, now = new Date()) {
  if (now.getFullYear() !== year || now.getMonth() !== monthIndex) {
    return false;
  }
  const day = now.getDate();
  return day >= weekDef.startDay && day <= weekDef.endDay;
}

/**
 * Format a Date object into readable Day name, Date, and Time.
 */
export function formatNoteDate(dateObj = new Date()) {
  const dayName = DAY_NAMES[dateObj.getDay()];
  const monthName = MONTH_NAMES[dateObj.getMonth()].slice(0, 3);
  const dayNum = dateObj.getDate();
  const year = dateObj.getFullYear();

  let hours = dateObj.getHours();
  const minutes = dateObj.getMinutes().toString().padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12; // 0 becomes 12

  return {
    dayName, // e.g. "Wednesday"
    fullDate: `${monthName} ${dayNum}, ${year}`,
    timeStr: `${hours}:${minutes} ${ampm}`,
    isoDate: dateObj.toISOString(),
  };
}

/**
 * Get date string YYYY-MM-DD
 */
export function getDayKey(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Calculate days remaining for 30-day trash retention.
 */
export function getTrashDaysRemaining(deletedAtStr, now = new Date()) {
  const deletedAt = new Date(deletedAtStr).getTime();
  const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
  const elapsed = now.getTime() - deletedAt;
  const remainingMs = thirtyDaysMs - elapsed;

  if (remainingMs <= 0) return 0;
  return Math.ceil(remainingMs / (24 * 60 * 60 * 1000));
}
