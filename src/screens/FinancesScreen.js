// src/screens/FinancesScreen.js
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  FlatList,
  TextInput,
  StyleSheet,
  Alert,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  BackHandler,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useTheme } from '../theme/ThemeContext';
import { financeManager } from '../storage/financeManager';

export default function FinancesScreen() {
  const { theme } = useTheme();
  const [level, setLevel] = useState('year'); // 'year' | 'months' | 'days' | 'sheet'
  const [config, setConfig] = useState(null);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [selectedDay, setSelectedDay] = useState(null);

  // Month & Day summaries
  const [unlockedMonths, setUnlockedMonths] = useState([]);
  const [daysSummary, setDaysSummary] = useState([]);
  const [monthSummary, setMonthSummary] = useState(null);

  // Active Day Sheet data
  const [sheetData, setSheetData] = useState(null);
  const [incomes, setIncomes] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [totals, setTotals] = useState({
    totalIncome: 0,
    totalExpense: 0,
    netBalance: 0,
    isNegative: false,
  });

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    const cfg = await financeManager.getConfig();
    setConfig(cfg);
    if (cfg && cfg.yearFolderCreated) {
      const yr = cfg.createdYear || new Date().getFullYear();
      setSelectedYear(yr);
      const months = financeManager.getUnlockedMonths(yr, cfg);
      const allSheets = await financeManager.getAllSheets();
      const enriched = months.map((m) => {
        const s = financeManager.getMonthFinancialSummarySync(allSheets, yr, m.index);
        return { ...m, summary: s };
      });
      setUnlockedMonths(enriched);
    }
  };

  const handleBackFromSheet = async () => {
    if (selectedMonth) {
      const summary = await financeManager.getMonthDaysSummary(
        selectedYear,
        selectedMonth.index
      );
      const mSummary = await financeManager.getMonthFinancialSummary(
        selectedYear,
        selectedMonth.index
      );
      setDaysSummary(summary);
      setMonthSummary(mSummary);
    }
    setLevel('days');
    loadConfig(); // Refresh month list summaries
  };

  // ANDROID HARDWARE BACK HANDLER
  useEffect(() => {
    const onBackPress = () => {
      if (level === 'sheet') {
        handleBackFromSheet();
        return true;
      }
      if (level === 'days') {
        setLevel('months');
        return true;
      }
      if (level === 'months') {
        setLevel('year');
        return true;
      }
      return false; // Year root: lets parent tab or Android handle
    };

    const backHandler = BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => backHandler.remove();
  }, [level, selectedYear, selectedMonth]);

  // ---- INITIAL ONE-TIME CREATION ----
  const handleCreateYearFolder = async () => {
    const currentYear = new Date().getFullYear();
    const created = await financeManager.createYearFolder(currentYear);
    setConfig(created);
    setSelectedYear(currentYear);
    const months = financeManager.getUnlockedMonths(currentYear, created);
    const allSheets = await financeManager.getAllSheets();
    const enriched = months.map((m) => {
      const s = financeManager.getMonthFinancialSummarySync(allSheets, currentYear, m.index);
      return { ...m, summary: s };
    });
    setUnlockedMonths(enriched);
    setLevel('months');
  };

  // ---- OPEN MONTH ----
  const openMonth = async (m) => {
    setSelectedMonth(m);
    const summary = await financeManager.getMonthDaysSummary(selectedYear, m.index);
    const mSummary = await financeManager.getMonthFinancialSummary(selectedYear, m.index);
    setDaysSummary(summary);
    setMonthSummary(mSummary);
    setLevel('days');
  };

  // ---- OPEN DAY SHEET ----
  const openDaySheet = async (dayItem) => {
    if (dayItem.isLocked) {
      Alert.alert(
        'Day Locked',
        `Day ${dayItem.dayNumber} is in the future. It will automatically unlock when that day arrives.`
      );
      return;
    }

    setSelectedDay(dayItem.dayNumber);
    const sheet = await financeManager.getDaySheet(
      selectedYear,
      selectedMonth.index,
      dayItem.dayNumber
    );

    setSheetData(sheet);
    setIncomes([...sheet.incomes]);
    setExpenses([...sheet.expenses]);
    recalculateTotals(sheet.incomes, sheet.expenses);
    setLevel('sheet');
  };

  // ---- SHEET EDITING & CALCULATIONS ----
  const recalculateTotals = (incList, expList) => {
    const computed = financeManager.computeSheetTotals({
      incomes: incList,
      expenses: expList,
    });
    setTotals(computed);
  };

  const handleIncomeChange = (index, field, value) => {
    const updated = [...incomes];
    updated[index] = { ...updated[index], [field]: value };

    if (index === updated.length - 1 && value.trim() !== '') {
      updated.push({
        id: `inc_${Date.now()}_${updated.length}`,
        description: '',
        amount: '',
        isRollover: false,
      });
    }

    setIncomes(updated);
    recalculateTotals(updated, expenses);
    persistSheet(updated, expenses);
  };

  const handleExpenseChange = (index, field, value) => {
    const updated = [...expenses];
    updated[index] = { ...updated[index], [field]: value };

    if (index === updated.length - 1 && value.trim() !== '') {
      updated.push({
        id: `exp_${Date.now()}_${updated.length}`,
        description: '',
        amount: '',
      });
    }

    setExpenses(updated);
    recalculateTotals(incomes, updated);
    persistSheet(incomes, updated);
  };

  const addManualRow = () => {
    const newInc = [
      ...incomes,
      {
        id: `inc_${Date.now()}_${incomes.length}`,
        description: '',
        amount: '',
        isRollover: false,
      },
    ];
    const newExp = [
      ...expenses,
      {
        id: `exp_${Date.now()}_${expenses.length}`,
        description: '',
        amount: '',
      },
    ];
    setIncomes(newInc);
    setExpenses(newExp);
    persistSheet(newInc, newExp);
  };

  const persistSheet = async (incList, expList) => {
    await financeManager.saveDaySheet(
      selectedYear,
      selectedMonth.index,
      selectedDay,
      incList,
      expList
    );
  };

  // -------------------------------------------------------------
  // LEVEL: DAY SHEET SPREADSHEET
  // -------------------------------------------------------------
  if (level === 'sheet') {
    const maxRows = Math.max(incomes.length, expenses.length);

    return (
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 25}
        style={[styles.container, { backgroundColor: theme.background }]}
      >
        {/* Header */}
        <View
          style={[
            styles.header,
            { backgroundColor: theme.surface, borderBottomColor: theme.border },
            totals.isNegative && { backgroundColor: theme.danger },
          ]}
        >
          <TouchableOpacity
            style={styles.backBtn}
            onPress={handleBackFromSheet}
          >
            <Ionicons name="arrow-back" size={24} color={totals.isNegative ? '#FFFFFF' : theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: totals.isNegative ? '#FFFFFF' : theme.text }]}>
              {selectedMonth?.name} {selectedDay}, {selectedYear}
            </Text>
            <Text style={[styles.headerSubtitle, { color: totals.isNegative ? 'rgba(255,255,255,0.85)' : theme.textSecondary }]}>
              Financial Ledger • Day {selectedDay}
            </Text>
          </View>
        </View>

        {/* Negative Balance Alert Banner */}
        {totals.isNegative && (
          <View style={[styles.alertBanner, { backgroundColor: theme.danger }]}>
            <Ionicons name="alert-circle" size={22} color="#FFFFFF" />
            <Text style={styles.alertBannerText}>
              Expenses exceed Income! You likely forgot an income transaction because you don't buy on credit. Please add the missing income.
            </Text>
          </View>
        )}

        {/* Table Content */}
        <ScrollView
          style={styles.tableScroll}
          contentContainerStyle={styles.tableScrollContent}
          keyboardShouldPersistTaps="handled"
          automaticallyAdjustKeyboardInsets={true}
        >
          {/* Table Headers */}
          <View style={[styles.tableHeaderRow, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
            <View style={[styles.columnHeader, { borderRightWidth: 1, borderRightColor: theme.border }]}>
              <Ionicons name="arrow-down-circle" size={16} color={theme.secondary} />
              <Text style={[styles.columnHeaderText, { color: theme.secondary }]}>
                INCOME
              </Text>
            </View>
            <View style={styles.columnHeader}>
              <Ionicons name="arrow-up-circle" size={16} color={theme.warning} />
              <Text style={[styles.columnHeaderText, { color: theme.warning }]}>
                EXPENSE
              </Text>
            </View>
          </View>

          {/* Table Subheaders (Item | Amount) - Font increased by 1px */}
          <View style={[styles.subHeaderRow, { backgroundColor: theme.surfaceHover, borderBottomColor: theme.border }]}>
            <View style={styles.halfRow}>
              <Text style={[styles.subHeaderText, { color: theme.textSecondary }]}>Item / Service</Text>
              <Text style={[styles.subHeaderAmount, { color: theme.textSecondary }]}>Amount (₦)</Text>
            </View>
            <View style={styles.halfRow}>
              <Text style={[styles.subHeaderText, { color: theme.textSecondary }]}>Item / Service</Text>
              <Text style={[styles.subHeaderAmount, { color: theme.textSecondary }]}>Amount (₦)</Text>
            </View>
          </View>

          {/* Rows - Font increased by 1px (14px) */}
          {Array.from({ length: maxRows }).map((_, index) => {
            const inc = incomes[index] || { description: '', amount: '', isRollover: false };
            const exp = expenses[index] || { description: '', amount: '' };

            return (
              <View
                key={`row_${index}`}
                style={[
                  styles.tableRow,
                  { borderBottomColor: theme.border },
                  index % 2 === 1 && { backgroundColor: theme.surfaceHover },
                ]}
              >
                {/* Income Item (Locked if Rollover) */}
                <View
                  style={[
                    styles.halfRowInput,
                    { borderRightWidth: 1, borderRightColor: theme.border },
                    inc.isRollover && { backgroundColor: theme.surfaceHover },
                  ]}
                >
                  {inc.isRollover ? (
                    <TouchableOpacity
                      style={styles.lockedRowContainer}
                      activeOpacity={0.7}
                      onPress={() => {
                        Alert.alert(
                          'Rollover Income Locked',
                          "This amount is automatically calculated from yesterday's closing balance. To change this value, please edit yesterday's financial sheet."
                        );
                      }}
                    >
                      <View style={styles.lockedDescRow}>
                        <Ionicons name="lock-closed" size={12} color={theme.secondary} style={{ marginRight: 4 }} />
                        <Text
                          numberOfLines={1}
                          style={[styles.descInput, { color: theme.secondary, fontWeight: '700', paddingVertical: 10 }]}
                        >
                          {inc.description}
                        </Text>
                      </View>
                      <Text
                        style={[styles.amountInput, { color: theme.secondary, fontWeight: '700', paddingVertical: 10 }]}
                      >
                        {inc.amount ? String(inc.amount) : '0.00'}
                      </Text>
                    </TouchableOpacity>
                  ) : (
                    <>
                      <TextInput
                        style={[styles.descInput, { color: theme.text }]}
                        placeholder={index === 0 ? 'e.g. Salary' : 'Item...'}
                        placeholderTextColor={theme.textMuted}
                        value={inc.description}
                        onChangeText={(val) => handleIncomeChange(index, 'description', val)}
                      />
                      <TextInput
                        style={[styles.amountInput, { color: theme.text }]}
                        placeholder="0.00"
                        placeholderTextColor={theme.textMuted}
                        keyboardType="numeric"
                        value={inc.amount ? String(inc.amount) : ''}
                        onChangeText={(val) => handleIncomeChange(index, 'amount', val)}
                      />
                    </>
                  )}
                </View>

                {/* Expense Item */}
                <View style={styles.halfRowInput}>
                  <TextInput
                    style={[styles.descInput, { color: theme.text }]}
                    placeholder="Item..."
                    placeholderTextColor={theme.textMuted}
                    value={exp.description}
                    onChangeText={(val) => handleExpenseChange(index, 'description', val)}
                  />
                  <TextInput
                    style={[styles.amountInput, { color: theme.text }]}
                    placeholder="0.00"
                    placeholderTextColor={theme.textMuted}
                    keyboardType="numeric"
                    value={exp.amount ? String(exp.amount) : ''}
                    onChangeText={(val) => handleExpenseChange(index, 'amount', val)}
                  />
                </View>
              </View>
            );
          })}

          <TouchableOpacity style={styles.addRowBtn} onPress={addManualRow}>
            <Ionicons name="add-circle-outline" size={18} color={theme.primary} />
            <Text style={[styles.addRowText, { color: theme.primary }]}>Add More Rows</Text>
          </TouchableOpacity>
        </ScrollView>

        {/* Bottom Totals Footer */}
        <View
          style={[
            styles.footerTotals,
            { backgroundColor: theme.surface, borderTopColor: theme.border },
            totals.isNegative && { backgroundColor: theme.dangerLight, borderTopColor: theme.danger },
          ]}
        >
          <View style={styles.totalBlock}>
            <Text style={[styles.totalLabel, { color: theme.textMuted }]}>TOTAL INCOME</Text>
            <Text style={[styles.totalIncomeVal, { color: theme.secondary }]}>
              +₦{totals.totalIncome.toFixed(2)}
            </Text>
          </View>

          <View style={styles.totalBlock}>
            <Text style={[styles.totalLabel, { color: theme.textMuted }]}>TOTAL EXPENSE</Text>
            <Text style={[styles.totalExpenseVal, { color: theme.warning }]}>
              -₦{totals.totalExpense.toFixed(2)}
            </Text>
          </View>

          <View
            style={[
              styles.totalBlock,
              styles.netBlock,
              { backgroundColor: theme.card, borderColor: theme.border },
              totals.isNegative && { borderColor: theme.danger, backgroundColor: theme.dangerLight },
            ]}
          >
            <Text style={[styles.totalLabel, { color: totals.isNegative ? theme.danger : theme.textMuted }]}>
              REMAINING
            </Text>
            <Text
              style={[
                styles.totalNetVal,
                { color: totals.isNegative ? theme.danger : theme.text },
              ]}
            >
              ₦{totals.netBalance.toFixed(2)}
            </Text>
          </View>
        </View>
      </KeyboardAvoidingView>
    );
  }

  // -------------------------------------------------------------
  // LEVEL: DAYS IN MONTH
  // -------------------------------------------------------------
  if (level === 'days') {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
          <TouchableOpacity style={styles.backBtn} onPress={() => setLevel('months')}>
            <Ionicons name="arrow-back" size={24} color={theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: theme.text }]}>{selectedMonth?.name} {selectedYear}</Text>
            <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
              Daily Financial Sheets (Numbered 1 to {daysSummary.length})
            </Text>
          </View>
        </View>

        {/* Quick Month Overview Strip */}
        {monthSummary && (
          <View style={[styles.quickSummaryBar, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
            <View style={styles.quickSummaryItem}>
              <Text style={[styles.quickSummaryLabel, { color: theme.textMuted }]}>EARNED</Text>
              <Text style={[styles.quickSummaryVal, { color: theme.secondary }]}>
                +₦{monthSummary.totalEarned.toFixed(2)}
              </Text>
            </View>
            <View style={[styles.quickSummaryDivider, { backgroundColor: theme.border }]} />
            <View style={styles.quickSummaryItem}>
              <Text style={[styles.quickSummaryLabel, { color: theme.textMuted }]}>SPENT</Text>
              <Text style={[styles.quickSummaryVal, { color: theme.warning }]}>
                -₦{monthSummary.totalSpent.toFixed(2)}
              </Text>
            </View>
            <View style={[styles.quickSummaryDivider, { backgroundColor: theme.border }]} />
            <View style={styles.quickSummaryItem}>
              <Text style={[styles.quickSummaryLabel, { color: monthSummary.isNegative ? theme.danger : theme.textMuted }]}>
                BALANCE
              </Text>
              <Text style={[styles.quickSummaryVal, { color: monthSummary.isNegative ? theme.danger : theme.primary }]}>
                ₦{monthSummary.finalBalance.toFixed(2)}
              </Text>
            </View>
          </View>
        )}

        <FlatList
          data={daysSummary}
          keyExtractor={(item) => `day_${item.dayNumber}`}
          contentContainerStyle={styles.daysGrid}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[
                styles.dayCard,
                { backgroundColor: theme.card, borderColor: theme.border },
                item.isLocked && { opacity: 0.45, backgroundColor: theme.surfaceHover },
                item.isToday && { borderColor: theme.primary, borderWidth: 1.5 },
                item.isNegative && { borderColor: theme.danger, borderWidth: 1.5, backgroundColor: theme.dangerLight },
              ]}
              activeOpacity={item.isLocked ? 1 : 0.7}
              onPress={() => openDaySheet(item)}
            >
              <View style={styles.dayCardHeader}>
                <Text
                  style={[
                    styles.dayNumberText,
                    { color: item.isNegative ? theme.danger : item.isLocked ? theme.textMuted : theme.text },
                  ]}
                >
                  Day {item.dayNumber}
                </Text>
                {item.isLocked ? (
                  <Ionicons name="lock-closed" size={16} color={theme.textMuted} />
                ) : item.isNegative ? (
                  <Ionicons name="alert-circle" size={18} color={theme.danger} />
                ) : item.isToday ? (
                  <View style={[styles.todayPill, { backgroundColor: theme.primaryLight }]}>
                    <Text style={[styles.todayPillText, { color: theme.primary }]}>Today</Text>
                  </View>
                ) : (
                  <Ionicons name="chevron-forward" size={16} color={theme.textMuted} />
                )}
              </View>

              {!item.isLocked && (
                <View style={styles.dayCardBody}>
                  <Text style={[styles.daySubInfo, { color: item.isNegative ? theme.danger : theme.textSecondary }]}>
                    Remaining: ₦{item.netBalance.toFixed(2)}
                  </Text>
                </View>
              )}
            </TouchableOpacity>
          )}
          ListFooterComponent={
            monthSummary ? (
              <View
                style={[
                  styles.monthSummaryCard,
                  { backgroundColor: theme.card, borderColor: monthSummary.isNegative ? theme.danger : theme.border },
                ]}
              >
                <View style={styles.monthSummaryHeader}>
                  <View style={[styles.iconCircleSmall, { backgroundColor: theme.surfaceHover }]}>
                    <Ionicons name="pie-chart" size={22} color={theme.primary} />
                  </View>
                  <View style={{ flex: 1, marginLeft: 10 }}>
                    <Text style={[styles.monthSummaryTitle, { color: theme.text }]}>
                      End of {selectedMonth?.name} Summary
                    </Text>
                    <Text style={[styles.monthSummarySub, { color: theme.textSecondary }]}>
                      Monthly Overview (Days 1 to {daysSummary.length})
                    </Text>
                  </View>
                </View>

                <View style={[styles.monthSummaryGrid, { borderTopColor: theme.border }]}>
                  <View style={styles.summaryItem}>
                    <Text style={[styles.summaryItemLabel, { color: theme.textMuted }]}>PREV MONTH CARRIED</Text>
                    <Text style={[styles.summaryItemVal, { color: theme.text }]}>
                      ₦{monthSummary.initialRollover.toFixed(2)}
                    </Text>
                  </View>
                  <View style={styles.summaryItem}>
                    <Text style={[styles.summaryItemLabel, { color: theme.secondary }]}>TOTAL MONEY EARNED</Text>
                    <Text style={[styles.summaryItemVal, { color: theme.secondary }]}>
                      +₦{monthSummary.totalEarned.toFixed(2)}
                    </Text>
                  </View>
                </View>

                <View style={[styles.monthSummaryGrid, { borderTopColor: theme.border }]}>
                  <View style={styles.summaryItem}>
                    <Text style={[styles.summaryItemLabel, { color: theme.warning }]}>TOTAL MONEY SPENT</Text>
                    <Text style={[styles.summaryItemVal, { color: theme.warning }]}>
                      -₦{monthSummary.totalSpent.toFixed(2)}
                    </Text>
                  </View>
                  <View style={styles.summaryItem}>
                    <Text style={[styles.summaryItemLabel, { color: monthSummary.isNegative ? theme.danger : theme.primary }]}>
                      FINAL MONTH BALANCE
                    </Text>
                    <Text style={[styles.summaryItemVal, { color: monthSummary.isNegative ? theme.danger : theme.primary, fontWeight: '800' }]}>
                      ₦{monthSummary.finalBalance.toFixed(2)}
                    </Text>
                  </View>
                </View>

                <View style={[styles.summaryFooterNote, { backgroundColor: theme.surfaceHover }]}>
                  <Ionicons name="information-circle-outline" size={16} color={theme.textMuted} />
                  <Text style={[styles.summaryNoteText, { color: theme.textSecondary }]}>
                    {monthSummary.finalBalance >= 0
                      ? 'This remaining balance automatically carries over as starting income for next month.'
                      : 'Alert: Your expenses exceeded your income for this month.'}
                  </Text>
                </View>
              </View>
            ) : null
          }
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // LEVEL: MONTHS IN YEAR (Strictly starting from creation month)
  // -------------------------------------------------------------
  if (level === 'months') {
    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
          <TouchableOpacity style={styles.backBtn} onPress={() => setLevel('year')}>
            <Ionicons name="arrow-back" size={24} color={theme.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={[styles.headerTitle, { color: theme.text }]}>Finances • {selectedYear}</Text>
            <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>
              Active & passed months (reveals 1 month at a time)
            </Text>
          </View>
        </View>

        <FlatList
          data={unlockedMonths}
          keyExtractor={(item) => `month_${item.index}`}
          contentContainerStyle={styles.listContainer}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[
                styles.card,
                { backgroundColor: theme.card, borderColor: theme.border },
                item.isCurrent && { borderColor: theme.secondary, borderWidth: 1.5 },
              ]}
              activeOpacity={0.7}
              onPress={() => openMonth(item)}
            >
              <View style={styles.cardHeader}>
                <View style={[styles.iconCircle, { backgroundColor: theme.surfaceHover }]}>
                  <Ionicons
                    name="calendar"
                    size={24}
                    color={item.isCurrent ? theme.secondary : theme.primary}
                  />
                </View>
                <View style={styles.cardMainInfo}>
                  <Text style={[styles.cardTitle, { color: theme.text }]}>{item.name}</Text>
                  <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>
                    {item.isCurrent ? 'Current Active Month' : 'Completed Month'}
                  </Text>
                  {item.summary && item.summary.hasData && (
                    <View style={styles.monthCardMetrics}>
                      <Text style={[styles.monthMetricText, { color: theme.secondary }]}>
                        Earned: ₦{item.summary.totalEarned.toFixed(2)}
                      </Text>
                      <Text style={[styles.monthMetricText, { color: theme.textMuted }]}>•</Text>
                      <Text style={[styles.monthMetricText, { color: theme.warning }]}>
                        Spent: ₦{item.summary.totalSpent.toFixed(2)}
                      </Text>
                      <Text style={[styles.monthMetricText, { color: theme.textMuted }]}>•</Text>
                      <Text style={[styles.monthMetricText, { color: item.summary.isNegative ? theme.danger : theme.primary, fontWeight: '700' }]}>
                        Net: ₦{item.summary.finalBalance.toFixed(2)}
                      </Text>
                    </View>
                  )}
                </View>
                {item.isCurrent && (
                  <View style={[styles.activeBadge, { backgroundColor: theme.secondaryLight }]}>
                    <Text style={[styles.activeBadgeText, { color: theme.secondary }]}>Active</Text>
                  </View>
                )}
                <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
              </View>
            </TouchableOpacity>
          )}
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // LEVEL: YEAR FOLDER ROOT (ONE-TIME CREATION)
  // -------------------------------------------------------------
  const hasYearFolder = config && config.yearFolderCreated;

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        <View style={styles.headerTitles}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>Finances</Text>
          <Text style={[styles.headerSubtitle, { color: theme.textSecondary }]}>Daily Income & Expense Ledger</Text>
        </View>
      </View>

      {hasYearFolder ? (
        <ScrollView contentContainerStyle={styles.listContainer}>
          <TouchableOpacity
            style={[styles.card, { backgroundColor: theme.card, borderColor: theme.border }]}
            activeOpacity={0.7}
            onPress={() => setLevel('months')}
          >
            <View style={styles.cardHeader}>
              <View style={[styles.iconCircle, { backgroundColor: theme.surfaceHover }]}>
                <Ionicons name="wallet" size={26} color={theme.primary} />
              </View>
              <View style={styles.cardMainInfo}>
                <Text style={[styles.cardTitle, { color: theme.text }]}>{selectedYear} Finances</Text>
                <Text style={[styles.cardSubtitle, { color: theme.textSecondary }]}>
                  {unlockedMonths.length} Active Month(s) Available
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={theme.textMuted} />
            </View>
          </TouchableOpacity>
        </ScrollView>
      ) : (
        <View style={styles.emptyContainer}>
          <Ionicons name="wallet-outline" size={64} color={theme.primary} />
          <Text style={[styles.emptyTitle, { color: theme.text }]}>Start Your Finances</Text>
          <Text style={[styles.emptySub, { color: theme.textSecondary }]}>
            Tap the + button below to generate your {new Date().getFullYear()} Finance folder.
            It will start from {new Date().toLocaleString('default', { month: 'long' })} and manage months and daily sheets for you.
          </Text>

          {/* One-Time Plus Button */}
          <TouchableOpacity
            style={[styles.fab, { backgroundColor: theme.primary }]}
            activeOpacity={0.8}
            onPress={handleCreateYearFolder}
          >
            <Ionicons name="add" size={32} color="#FFFFFF" />
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  backBtn: {
    padding: 6,
    marginRight: 10,
  },
  headerTitles: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
  },
  headerSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  alertBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 10,
  },
  alertBannerText: {
    flex: 1,
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 18,
  },
  listContainer: {
    padding: 16,
  },
  card: {
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  cardMainInfo: {
    flex: 1,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  cardSubtitle: {
    fontSize: 12,
    marginTop: 2,
  },
  activeBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  activeBadgeText: {
    fontSize: 11,
    fontWeight: '600',
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 30,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    marginTop: 16,
  },
  emptySub: {
    fontSize: 14,
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 22,
  },
  fab: {
    position: 'absolute',
    bottom: 30,
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOpacity: 0.25,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
  },
  // Days Grid
  daysGrid: {
    padding: 16,
    gap: 8,
  },
  dayCard: {
    borderRadius: 10,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
  },
  dayCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dayNumberText: {
    fontSize: 15,
    fontWeight: '700',
  },
  todayPill: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  todayPillText: {
    fontSize: 10,
    fontWeight: '700',
  },
  dayCardBody: {
    marginTop: 6,
  },
  daySubInfo: {
    fontSize: 12,
  },
  // Table Spreadsheet - Font sizes increased by 1px
  tableScroll: {
    flex: 1,
  },
  tableScrollContent: {
    paddingBottom: 220,
  },
  lockedRowContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 4,
  },
  lockedDescRow: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  tableHeaderRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
  },
  columnHeader: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    gap: 6,
  },
  columnHeaderText: {
    fontSize: 14, // increased
    fontWeight: '700',
    letterSpacing: 1,
  },
  subHeaderRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    paddingVertical: 6,
    paddingHorizontal: 8,
  },
  subHeaderText: {
    flex: 1,
    fontSize: 11, // increased by 1px
    fontWeight: '600',
  },
  subHeaderAmount: {
    width: 75,
    fontSize: 11, // increased by 1px
    fontWeight: '600',
    textAlign: 'right',
  },
  halfRow: {
    flex: 1,
    flexDirection: 'row',
    paddingHorizontal: 6,
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    minHeight: 46,
  },
  halfRowInput: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  descInput: {
    flex: 1,
    fontSize: 14, // increased by 1px
    paddingVertical: 6,
  },
  amountInput: {
    width: 75,
    fontSize: 14, // increased by 1px
    textAlign: 'right',
    paddingVertical: 6,
  },
  addRowBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    gap: 8,
  },
  addRowText: {
    fontSize: 13,
    fontWeight: '600',
  },
  // Totals Footer
  footerTotals: {
    flexDirection: 'row',
    borderTopWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
    justifyContent: 'space-between',
  },
  totalBlock: {
    alignItems: 'center',
    flex: 1,
  },
  netBlock: {
    borderRadius: 8,
    paddingVertical: 4,
    borderWidth: 1,
  },
  totalLabel: {
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  totalIncomeVal: {
    fontSize: 14,
    fontWeight: '700',
    marginTop: 2,
  },
  totalExpenseVal: {
    fontSize: 14,
    fontWeight: '700',
    marginTop: 2,
  },
  totalNetVal: {
    fontSize: 14,
    fontWeight: '700',
    marginTop: 2,
  },
  // End of Month Summary Card & Quick Bar
  quickSummaryBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomWidth: 1,
  },
  quickSummaryItem: {
    flex: 1,
    alignItems: 'center',
  },
  quickSummaryDivider: {
    width: 1,
    height: 24,
  },
  quickSummaryLabel: {
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  quickSummaryVal: {
    fontSize: 13,
    fontWeight: '700',
    marginTop: 2,
  },
  monthSummaryCard: {
    borderRadius: 14,
    borderWidth: 1.5,
    padding: 16,
    marginTop: 16,
    marginBottom: 30,
  },
  monthSummaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  iconCircleSmall: {
    width: 38,
    height: 38,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  monthSummaryTitle: {
    fontSize: 16,
    fontWeight: '700',
  },
  monthSummarySub: {
    fontSize: 11,
    marginTop: 2,
  },
  monthSummaryGrid: {
    flexDirection: 'row',
    borderTopWidth: 1,
    paddingVertical: 10,
  },
  summaryItem: {
    flex: 1,
  },
  summaryItemLabel: {
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  summaryItemVal: {
    fontSize: 14,
    fontWeight: '700',
    marginTop: 3,
  },
  summaryFooterNote: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 8,
    marginTop: 10,
    gap: 8,
  },
  summaryNoteText: {
    flex: 1,
    fontSize: 11,
    lineHeight: 16,
  },
  monthCardMetrics: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
    gap: 6,
    flexWrap: 'wrap',
  },
  monthMetricText: {
    fontSize: 11,
  },
});
