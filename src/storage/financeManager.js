// src/storage/financeManager.js
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getDaysInMonth, MONTH_NAMES } from '../utils/dateUtils';

const STORAGE_KEYS = {
  FINANCE_CONFIG: '@daily_notes_finance_config',
  FINANCE_SHEETS: '@daily_notes_finance_sheets',
};

class FinanceManager {
  // ---- CONFIG / CREATION ----
  async getConfig() {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.FINANCE_CONFIG);
      return data ? JSON.parse(data) : null;
    } catch (e) {
      console.error('Error reading finance config', e);
      return null;
    }
  }

  /**
   * One-time creation of the Year folder (e.g. 2026).
   * Once created, user cannot create another year via + button.
   */
  async createYearFolder(year = new Date().getFullYear()) {
    const existing = await this.getConfig();
    if (existing && existing.yearFolderCreated) {
      return existing;
    }

    const currentMonthIndex = new Date().getMonth();
    const config = {
      yearFolderCreated: true,
      createdYear: year,
      createdMonthIndex: currentMonthIndex, // strictly starts from creation month (e.g. October)
      createdAt: new Date().toISOString(),
    };

    await AsyncStorage.setItem(STORAGE_KEYS.FINANCE_CONFIG, JSON.stringify(config));
    return config;
  }

  // ---- MONTHS UNLOCK RULE ----
  /**
   * Returns unlocked months for the year:
   * Rule: Strictly starts from the month the user created the folder (e.g. October).
   * Past months before creation month (e.g. January - September) are never shown.
   * Future months unlock one at a time when their calendar month arrives.
   */
  getUnlockedMonths(year, config = null, now = new Date()) {
    const currentYear = now.getFullYear();
    const currentMonthIndex = now.getMonth();

    if (year < currentYear) {
      // Past year
      const start = (config && typeof config.createdMonthIndex === 'number') ? config.createdMonthIndex : 0;
      return MONTH_NAMES.slice(start).map((name, idx) => ({
        index: start + idx,
        name,
        year,
        isCurrent: false,
      }));
    }

    if (year > currentYear) {
      return [];
    }

    // Same year: strictly start from createdMonthIndex up to currentMonthIndex
    const startMonth = (config && typeof config.createdMonthIndex === 'number')
      ? config.createdMonthIndex
      : currentMonthIndex; // Fallback to current month

    const months = [];
    for (let i = startMonth; i <= currentMonthIndex; i++) {
      months.push({
        index: i,
        name: MONTH_NAMES[i],
        year,
        isCurrent: i === currentMonthIndex,
      });
    }
    return months;
  }

  // ---- SHEETS DATA ----
  async getAllSheets() {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.FINANCE_SHEETS);
      return data ? JSON.parse(data) : {};
    } catch (e) {
      console.error('Error reading finance sheets', e);
      return {};
    }
  }

  getSheetKey(year, monthIndex, dayNumber) {
    return `sheet_${year}_${monthIndex}_${dayNumber}`;
  }

  /**
   * Calculate previous day's net remaining balance for Rollover:
   * Looks backward to the most recent day in the current month with data.
   * If day === 1 (or no days in current month have data), looks at the closing balance of the previous month.
   */
  async getPreviousDayNetBalance(year, monthIndex, dayNumber, sheetsCache = null) {
    const allSheets = sheetsCache || (await this.getAllSheets());

    if (dayNumber > 1) {
      for (let p = dayNumber - 1; p >= 1; p--) {
        const prevKey = this.getSheetKey(year, monthIndex, p);
        const prevSheet = allSheets[prevKey];
        if (prevSheet) {
          return this.computeSheetTotals(prevSheet).netBalance;
        }
      }
    }

    // Day 1 of month (or no preceding days in current month): Check previous month closing
    if (monthIndex > 0) {
      const prevMonth = monthIndex - 1;
      const daysInPrevMonth = getDaysInMonth(year, prevMonth);
      for (let p = daysInPrevMonth; p >= 1; p--) {
        const prevKey = this.getSheetKey(year, prevMonth, p);
        const prevSheet = allSheets[prevKey];
        if (prevSheet) {
          return this.computeSheetTotals(prevSheet).netBalance;
        }
      }
    }

    return 0;
  }

  /**
   * Automatically cascade rollover balances forward starting from startDay.
   * If Day 1 changes -> Day 2's rollover row updates -> Day 3 updates -> ... -> Next Month Day 1 updates.
   */
  async cascadeRollovers(year, monthIndex, startDay = 1) {
    const allSheets = await this.getAllSheets();
    const totalDays = getDaysInMonth(year, monthIndex);

    for (let d = startDay; d < totalDays; d++) {
      const curKey = this.getSheetKey(year, monthIndex, d);
      const curSheet = allSheets[curKey];
      if (!curSheet) continue;

      const curTotals = this.computeSheetTotals(curSheet);
      const nextKey = this.getSheetKey(year, monthIndex, d + 1);
      const nextSheet = allSheets[nextKey];

      if (nextSheet && nextSheet.incomes && nextSheet.incomes.length > 0) {
        const firstInc = nextSheet.incomes[0];
        if (firstInc.isRollover) {
          firstInc.amount = curTotals.netBalance.toFixed(2);
          firstInc.description = 'Yesterday Remaining Income';
        }
      }
    }

    // Check if Day 1 of the NEXT month exists and update its 'Last Month Income' rollover
    if (monthIndex < 11) {
      const nextMonthDay1Key = this.getSheetKey(year, monthIndex + 1, 1);
      const nextMonthDay1 = allSheets[nextMonthDay1Key];
      if (nextMonthDay1 && nextMonthDay1.incomes && nextMonthDay1.incomes.length > 0) {
        if (nextMonthDay1.incomes[0].isRollover) {
          const monthSummary = this.getMonthFinancialSummarySync(allSheets, year, monthIndex);
          nextMonthDay1.incomes[0].amount = monthSummary.finalBalance.toFixed(2);
          nextMonthDay1.incomes[0].description = 'Last Month Income';
        }
      }
    }

    await AsyncStorage.setItem(STORAGE_KEYS.FINANCE_SHEETS, JSON.stringify(allSheets));
  }

  /**
   * Synchronous helper to calculate Month Financial Summary from loaded sheets.
   */
  getMonthFinancialSummarySync(allSheets, year, monthIndex) {
    const totalDays = getDaysInMonth(year, monthIndex);
    let initialRollover = 0;
    let totalEarned = 0;
    let totalSpent = 0;
    let hasData = false;
    let lastActiveDayBalance = 0;

    // Check Day 1 rollover (initial starting money from previous month)
    const day1Key = this.getSheetKey(year, monthIndex, 1);
    const day1Sheet = allSheets[day1Key];
    if (day1Sheet && day1Sheet.incomes && day1Sheet.incomes.length > 0 && day1Sheet.incomes[0].isRollover) {
      const val = parseFloat(day1Sheet.incomes[0].amount);
      if (!isNaN(val)) initialRollover = val;
    }

    for (let d = 1; d <= totalDays; d++) {
      const key = this.getSheetKey(year, monthIndex, d);
      const sheet = allSheets[key];
      if (!sheet) continue;

      hasData = true;

      // Sum only fresh income (do not count daily rollovers to avoid double counting!)
      (sheet.incomes || []).forEach((item) => {
        if (!item.isRollover) {
          const amt = parseFloat(item.amount);
          if (!isNaN(amt) && amt > 0) {
            totalEarned += amt;
          }
        }
      });

      // Sum all expenses
      (sheet.expenses || []).forEach((item) => {
        const amt = parseFloat(item.amount);
        if (!isNaN(amt) && amt > 0) {
          totalSpent += amt;
        }
      });

      // Keep track of the latest day's net closing balance
      const dayTotals = this.computeSheetTotals(sheet);
      lastActiveDayBalance = dayTotals.netBalance;
    }

    // Final closing balance: Starting + Total Earned - Total Spent
    const finalBalance = initialRollover + totalEarned - totalSpent;
    const isNegative = finalBalance < 0;

    return {
      year,
      monthIndex,
      monthName: MONTH_NAMES[monthIndex],
      totalDays,
      initialRollover,
      totalEarned,
      totalSpent,
      finalBalance,
      isNegative,
      hasData,
    };
  }

  /**
   * Async method to get full monthly financial summary
   */
  async getMonthFinancialSummary(year, monthIndex) {
    const allSheets = await this.getAllSheets();
    return this.getMonthFinancialSummarySync(allSheets, year, monthIndex);
  }

  /**
   * Get or initialize a daily sheet with 10 default rows
   * and auto-inject rollover income (Yesterday Remaining Income or Last Month Income).
   * ALWAYS keeps the rollover amount synchronized with the preceding day's closing balance.
   */
  async getDaySheet(year, monthIndex, dayNumber) {
    const allSheets = await this.getAllSheets();
    const key = this.getSheetKey(year, monthIndex, dayNumber);
    let sheet = allSheets[key];

    const prevBalance = await this.getPreviousDayNetBalance(year, monthIndex, dayNumber, allSheets);
    const rolloverLabel = dayNumber === 1 ? 'Last Month Income' : 'Yesterday Remaining Income';

    if (!sheet) {
      // Create new fresh sheet with 10 default rows
      const defaultIncomes = [];
      const defaultExpenses = [];

      // Row 1 of Income: Rollover
      defaultIncomes.push({
        id: 'rollover_auto',
        description: rolloverLabel,
        amount: prevBalance.toFixed(2),
        isRollover: true,
      });

      // Fill up to 10 rows
      for (let i = 1; i < 10; i++) {
        defaultIncomes.push({
          id: `inc_${Date.now()}_${i}`,
          description: '',
          amount: '',
          isRollover: false,
        });
      }

      for (let i = 0; i < 10; i++) {
        defaultExpenses.push({
          id: `exp_${Date.now()}_${i}`,
          description: '',
          amount: '',
        });
      }

      sheet = {
        key,
        year,
        monthIndex,
        dayNumber,
        incomes: defaultIncomes,
        expenses: defaultExpenses,
        updatedAt: new Date().toISOString(),
      };

      allSheets[key] = sheet;
      await AsyncStorage.setItem(STORAGE_KEYS.FINANCE_SHEETS, JSON.stringify(allSheets));
    } else {
      // If sheet exists, keep rollover row amount and label strictly updated
      if (sheet.incomes && sheet.incomes.length > 0) {
        const first = sheet.incomes[0];
        if (first.isRollover) {
          first.description = rolloverLabel;
          first.amount = prevBalance.toFixed(2);
        }
      }
      allSheets[key] = sheet;
      await AsyncStorage.setItem(STORAGE_KEYS.FINANCE_SHEETS, JSON.stringify(allSheets));
    }

    return sheet;
  }

  /**
   * Save changes to a day sheet and trigger forward cascade across subsequent days.
   */
  async saveDaySheet(year, monthIndex, dayNumber, incomes, expenses) {
    const allSheets = await this.getAllSheets();
    const key = this.getSheetKey(year, monthIndex, dayNumber);

    allSheets[key] = {
      key,
      year,
      monthIndex,
      dayNumber,
      incomes,
      expenses,
      updatedAt: new Date().toISOString(),
    };

    await AsyncStorage.setItem(STORAGE_KEYS.FINANCE_SHEETS, JSON.stringify(allSheets));

    // Cascade changes forward so tomorrow and future days immediately reflect updated balance
    await this.cascadeRollovers(year, monthIndex, dayNumber);

    return allSheets[key];
  }

  /**
   * Compute total income, total expense, and net balance.
   */
  computeSheetTotals(sheet) {
    if (!sheet) {
      return { totalIncome: 0, totalExpense: 0, netBalance: 0, isNegative: false };
    }

    let totalIncome = 0;
    (sheet.incomes || []).forEach((item) => {
      const val = parseFloat(item.amount);
      if (!isNaN(val) && val > 0) {
        totalIncome += val;
      }
    });

    let totalExpense = 0;
    (sheet.expenses || []).forEach((item) => {
      const val = parseFloat(item.amount);
      if (!isNaN(val) && val > 0) {
        totalExpense += val;
      }
    });

    const netBalance = totalIncome - totalExpense;
    const isNegative = netBalance < 0;

    return {
      totalIncome,
      totalExpense,
      netBalance,
      isNegative,
    };
  }

  /**
   * Checks status of all days in a month for coloring and badges:
   * - isLocked (day > current day in current month)
   * - isNegative (expenses exceed income)
   * - hasData (user has entered anything)
   */
  async getMonthDaysSummary(year, monthIndex, now = new Date()) {
    const totalDays = getDaysInMonth(year, monthIndex);
    const allSheets = await this.getAllSheets();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();
    const currentDay = now.getDate();

    const isCurrentMonth = year === currentYear && monthIndex === currentMonth;
    const isPastMonth =
      year < currentYear || (year === currentYear && monthIndex < currentMonth);

    const daysSummary = [];

    for (let d = 1; d <= totalDays; d++) {
      let isLocked = false;
      if (isCurrentMonth) {
        isLocked = d > currentDay; // Future days locked
      } else if (!isPastMonth) {
        isLocked = true; // Entire future month locked
      }

      const key = this.getSheetKey(year, monthIndex, d);
      const sheet = allSheets[key];
      const totals = this.computeSheetTotals(sheet);

      daysSummary.push({
        dayNumber: d,
        isLocked,
        isToday: isCurrentMonth && d === currentDay,
        isNegative: totals.isNegative,
        netBalance: totals.netBalance,
        totalIncome: totals.totalIncome,
        totalExpense: totals.totalExpense,
        hasData: !!sheet,
      });
    }

    return daysSummary;
  }
}

export const financeManager = new FinanceManager();
