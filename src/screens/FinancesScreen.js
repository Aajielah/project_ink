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
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../theme/colors';
import { financeManager } from '../storage/financeManager';
import { MONTH_NAMES } from '../utils/dateUtils';

export default function FinancesScreen() {
  const [level, setLevel] = useState('year'); // 'year' | 'months' | 'days' | 'sheet'
  const [config, setConfig] = useState(null);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [selectedDay, setSelectedDay] = useState(null);

  // Month & Day summaries
  const [unlockedMonths, setUnlockedMonths] = useState([]);
  const [daysSummary, setDaysSummary] = useState([]);

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
      setSelectedYear(cfg.createdYear || new Date().getFullYear());
      const months = financeManager.getUnlockedMonths(
        cfg.createdYear || new Date().getFullYear()
      );
      setUnlockedMonths(months);
    }
  };

  // ---- INITIAL ONE-TIME CREATION ----
  const handleCreateYearFolder = async () => {
    const currentYear = new Date().getFullYear();
    const created = await financeManager.createYearFolder(currentYear);
    setConfig(created);
    setSelectedYear(currentYear);
    const months = financeManager.getUnlockedMonths(currentYear);
    setUnlockedMonths(months);
    setLevel('months');
  };

  // ---- OPEN MONTH ----
  const openMonth = async (m) => {
    setSelectedMonth(m);
    const summary = await financeManager.getMonthDaysSummary(selectedYear, m.index);
    setDaysSummary(summary);
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

    // Auto-generate extra row if editing last row
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

    // Auto-generate extra row if editing last row
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
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.container}
      >
        {/* Header */}
        <View style={[styles.header, totals.isNegative && styles.headerNegative]}>
          <TouchableOpacity
            style={styles.backBtn}
            onPress={async () => {
              const summary = await financeManager.getMonthDaysSummary(
                selectedYear,
                selectedMonth.index
              );
              setDaysSummary(summary);
              setLevel('days');
            }}
          >
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>
              {selectedMonth?.name} {selectedDay}, {selectedYear}
            </Text>
            <Text style={styles.headerSubtitle}>
              Financial Ledger • Day {selectedDay}
            </Text>
          </View>
        </View>

        {/* Negative Balance Alert Banner */}
        {totals.isNegative && (
          <View style={styles.alertBanner}>
            <Ionicons name="alert-circle" size={22} color={colors.white} />
            <Text style={styles.alertBannerText}>
              Expenses exceed Income! You likely forgot an income transaction because you don't buy on credit. Please add the missing income.
            </Text>
          </View>
        )}

        {/* Table Content */}
        <ScrollView style={styles.tableScroll} keyboardShouldPersistTaps="handled">
          {/* Table Headers */}
          <View style={styles.tableHeaderRow}>
            <View style={[styles.columnHeader, { borderRightWidth: 1, borderRightColor: colors.border }]}>
              <Ionicons name="arrow-down-circle" size={16} color={colors.secondary} />
              <Text style={[styles.columnHeaderText, { color: colors.secondary }]}>
                INCOME
              </Text>
            </View>
            <View style={styles.columnHeader}>
              <Ionicons name="arrow-up-circle" size={16} color={colors.warning} />
              <Text style={[styles.columnHeaderText, { color: colors.warning }]}>
                EXPENSE
              </Text>
            </View>
          </View>

          {/* Table Subheaders (Item | Amount) */}
          <View style={styles.subHeaderRow}>
            <View style={styles.halfRow}>
              <Text style={styles.subHeaderText}>Item / Service</Text>
              <Text style={styles.subHeaderAmount}>Amount (₦)</Text>
            </View>
            <View style={styles.halfRow}>
              <Text style={styles.subHeaderText}>Item / Service</Text>
              <Text style={styles.subHeaderAmount}>Amount (₦)</Text>
            </View>
          </View>

          {/* Rows */}
          {Array.from({ length: maxRows }).map((_, index) => {
            const inc = incomes[index] || { description: '', amount: '', isRollover: false };
            const exp = expenses[index] || { description: '', amount: '' };

            return (
              <View key={`row_${index}`} style={[styles.tableRow, index % 2 === 1 && styles.rowAlt]}>
                {/* Income Item */}
                <View style={[styles.halfRowInput, { borderRightWidth: 1, borderRightColor: colors.border }]}>
                  <TextInput
                    style={[styles.descInput, inc.isRollover && styles.rolloverText]}
                    placeholder={index === 0 && !inc.isRollover ? 'e.g. Salary' : 'Item...'}
                    placeholderTextColor={colors.textMuted}
                    value={inc.description}
                    onChangeText={(val) => handleIncomeChange(index, 'description', val)}
                  />
                  <TextInput
                    style={[styles.amountInput, inc.isRollover && styles.rolloverAmount]}
                    placeholder="0.00"
                    placeholderTextColor={colors.textMuted}
                    keyboardType="numeric"
                    value={inc.amount ? String(inc.amount) : ''}
                    onChangeText={(val) => handleIncomeChange(index, 'amount', val)}
                  />
                </View>

                {/* Expense Item */}
                <View style={styles.halfRowInput}>
                  <TextInput
                    style={styles.descInput}
                    placeholder="Item..."
                    placeholderTextColor={colors.textMuted}
                    value={exp.description}
                    onChangeText={(val) => handleExpenseChange(index, 'description', val)}
                  />
                  <TextInput
                    style={styles.amountInput}
                    placeholder="0.00"
                    placeholderTextColor={colors.textMuted}
                    keyboardType="numeric"
                    value={exp.amount ? String(exp.amount) : ''}
                    onChangeText={(val) => handleExpenseChange(index, 'amount', val)}
                  />
                </View>
              </View>
            );
          })}

          {/* Add Row Button */}
          <TouchableOpacity style={styles.addRowBtn} onPress={addManualRow}>
            <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
            <Text style={styles.addRowText}>Add More Rows</Text>
          </TouchableOpacity>
        </ScrollView>

        {/* Bottom Totals Footer */}
        <View style={[styles.footerTotals, totals.isNegative && styles.footerTotalsNegative]}>
          <View style={styles.totalBlock}>
            <Text style={styles.totalLabel}>TOTAL INCOME</Text>
            <Text style={styles.totalIncomeVal}>
              +₦{totals.totalIncome.toFixed(2)}
            </Text>
          </View>

          <View style={styles.totalBlock}>
            <Text style={styles.totalLabel}>TOTAL EXPENSE</Text>
            <Text style={styles.totalExpenseVal}>
              -₦{totals.totalExpense.toFixed(2)}
            </Text>
          </View>

          <View style={[styles.totalBlock, styles.netBlock, totals.isNegative && styles.netBlockNegative]}>
            <Text style={[styles.totalLabel, totals.isNegative && styles.negativeText]}>
              REMAINING
            </Text>
            <Text
              style={[
                styles.totalNetVal,
                totals.isNegative && styles.totalNetValNegative,
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
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backBtn} onPress={() => setLevel('months')}>
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>{selectedMonth?.name} {selectedYear}</Text>
            <Text style={styles.headerSubtitle}>
              Daily Financial Sheets (Numbered 1 to {daysSummary.length})
            </Text>
          </View>
        </View>

        <FlatList
          data={daysSummary}
          keyExtractor={(item) => `day_${item.dayNumber}`}
          contentContainerStyle={styles.daysGrid}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[
                styles.dayCard,
                item.isLocked && styles.dayCardLocked,
                item.isToday && styles.dayCardToday,
                item.isNegative && styles.dayCardNegative,
              ]}
              activeOpacity={item.isLocked ? 1 : 0.7}
              onPress={() => openDaySheet(item)}
            >
              <View style={styles.dayCardHeader}>
                <Text
                  style={[
                    styles.dayNumberText,
                    item.isLocked && styles.dayNumberLocked,
                    item.isNegative && styles.negativeText,
                  ]}
                >
                  Day {item.dayNumber}
                </Text>
                {item.isLocked ? (
                  <Ionicons name="lock-closed" size={16} color={colors.textMuted} />
                ) : item.isNegative ? (
                  <Ionicons name="alert-circle" size={18} color={colors.danger} />
                ) : item.isToday ? (
                  <View style={styles.todayPill}>
                    <Text style={styles.todayPillText}>Today</Text>
                  </View>
                ) : (
                  <Ionicons name="chevron-forward" size={16} color={colors.textMuted} />
                )}
              </View>

              {!item.isLocked && (
                <View style={styles.dayCardBody}>
                  <Text style={styles.daySubInfo}>
                    Remaining: ₦{item.netBalance.toFixed(2)}
                  </Text>
                </View>
              )}
            </TouchableOpacity>
          )}
        />
      </View>
    );
  }

  // -------------------------------------------------------------
  // LEVEL: MONTHS IN YEAR
  // -------------------------------------------------------------
  if (level === 'months') {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backBtn} onPress={() => setLevel('year')}>
            <Ionicons name="arrow-back" size={24} color={colors.text} />
          </TouchableOpacity>
          <View style={styles.headerTitles}>
            <Text style={styles.headerTitle}>Finances • {selectedYear}</Text>
            <Text style={styles.headerSubtitle}>
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
              style={[styles.card, item.isCurrent && styles.activeCard]}
              activeOpacity={0.7}
              onPress={() => openMonth(item)}
            >
              <View style={styles.cardHeader}>
                <View style={styles.iconCircle}>
                  <Ionicons
                    name="calendar"
                    size={24}
                    color={item.isCurrent ? colors.secondary : colors.primary}
                  />
                </View>
                <View style={styles.cardMainInfo}>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  <Text style={styles.cardSubtitle}>
                    {item.isCurrent ? 'Current Active Month' : 'Completed Month'}
                  </Text>
                </View>
                {item.isCurrent && (
                  <View style={styles.activeBadge}>
                    <Text style={styles.activeBadgeText}>Active</Text>
                  </View>
                )}
                <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
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
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerTitles}>
          <Text style={styles.headerTitle}>Finances</Text>
          <Text style={styles.headerSubtitle}>Daily Income & Expense Ledger</Text>
        </View>
      </View>

      {hasYearFolder ? (
        <ScrollView contentContainerStyle={styles.listContainer}>
          <TouchableOpacity
            style={styles.card}
            activeOpacity={0.7}
            onPress={() => setLevel('months')}
          >
            <View style={styles.cardHeader}>
              <View style={styles.iconCircle}>
                <Ionicons name="wallet" size={26} color={colors.primary} />
              </View>
              <View style={styles.cardMainInfo}>
                <Text style={styles.cardTitle}>{selectedYear} Finances</Text>
                <Text style={styles.cardSubtitle}>
                  {unlockedMonths.length} Active Month(s) Available
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
            </View>
          </TouchableOpacity>
        </ScrollView>
      ) : (
        <View style={styles.emptyContainer}>
          <Ionicons name="wallet-outline" size={64} color={colors.primary} />
          <Text style={styles.emptyTitle}>Start Your Finances</Text>
          <Text style={styles.emptySub}>
            Tap the + button below to generate your {new Date().getFullYear()} Finance folder.
            The system will automatically manage months and daily sheets for you.
          </Text>

          {/* One-Time Plus Button */}
          <TouchableOpacity
            style={styles.fab}
            activeOpacity={0.8}
            onPress={handleCreateYearFolder}
          >
            <Ionicons name="add" size={32} color={colors.white} />
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
  },
  headerNegative: {
    backgroundColor: colors.danger,
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
    color: colors.text,
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  alertBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.danger,
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 10,
  },
  alertBannerText: {
    flex: 1,
    color: colors.white,
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 18,
  },
  listContainer: {
    padding: 16,
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  activeCard: {
    borderColor: colors.secondary,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconCircle: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: colors.surface,
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
    color: colors.text,
  },
  cardSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  activeBadge: {
    backgroundColor: colors.secondaryLight,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    marginRight: 8,
  },
  activeBadgeText: {
    color: colors.secondary,
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
    color: colors.text,
    marginTop: 16,
  },
  emptySub: {
    fontSize: 14,
    color: colors.textSecondary,
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
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOpacity: 0.35,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
  },
  // Days Grid
  daysGrid: {
    padding: 16,
    gap: 8,
  },
  dayCard: {
    backgroundColor: colors.card,
    borderRadius: 10,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  dayCardLocked: {
    opacity: 0.45,
    backgroundColor: colors.surface,
  },
  dayCardToday: {
    borderColor: colors.primary,
    borderWidth: 1.5,
  },
  dayCardNegative: {
    borderColor: colors.danger,
    borderWidth: 1.5,
    backgroundColor: colors.dangerLight,
  },
  dayCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dayNumberText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.text,
  },
  dayNumberLocked: {
    color: colors.textMuted,
  },
  todayPill: {
    backgroundColor: colors.primaryLight,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  todayPillText: {
    color: colors.primary,
    fontSize: 10,
    fontWeight: '700',
  },
  dayCardBody: {
    marginTop: 6,
  },
  daySubInfo: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  negativeText: {
    color: colors.danger,
    fontWeight: '700',
  },
  // Table Spreadsheet
  tableScroll: {
    flex: 1,
  },
  tableHeaderRow: {
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
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
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 1,
  },
  subHeaderRow: {
    flexDirection: 'row',
    backgroundColor: colors.surfaceHover,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
    paddingVertical: 6,
    paddingHorizontal: 8,
  },
  subHeaderText: {
    flex: 1,
    fontSize: 10,
    color: colors.textMuted,
    fontWeight: '600',
  },
  subHeaderAmount: {
    width: 65,
    fontSize: 10,
    color: colors.textMuted,
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
    borderBottomColor: colors.border,
    minHeight: 44,
  },
  rowAlt: {
    backgroundColor: 'rgba(255,255,255,0.02)',
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
    color: colors.text,
    fontSize: 13,
    paddingVertical: 6,
  },
  amountInput: {
    width: 65,
    color: colors.text,
    fontSize: 13,
    textAlign: 'right',
    paddingVertical: 6,
  },
  rolloverText: {
    color: colors.secondary,
    fontStyle: 'italic',
    fontWeight: '600',
  },
  rolloverAmount: {
    color: colors.secondary,
    fontWeight: '700',
  },
  addRowBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    gap: 8,
  },
  addRowText: {
    color: colors.primary,
    fontSize: 13,
    fontWeight: '600',
  },
  // Totals Footer
  footerTotals: {
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingHorizontal: 12,
    paddingVertical: 10,
    justifyContent: 'space-between',
  },
  footerTotalsNegative: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
    borderTopColor: colors.danger,
  },
  totalBlock: {
    alignItems: 'center',
    flex: 1,
  },
  netBlock: {
    backgroundColor: colors.card,
    borderRadius: 8,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: colors.border,
  },
  netBlockNegative: {
    borderColor: colors.danger,
    backgroundColor: 'rgba(239, 68, 68, 0.2)',
  },
  totalLabel: {
    fontSize: 9,
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 0.5,
  },
  totalIncomeVal: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.secondary,
    marginTop: 2,
  },
  totalExpenseVal: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.warning,
    marginTop: 2,
  },
  totalNetVal: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
    marginTop: 2,
  },
  totalNetValNegative: {
    color: colors.danger,
    fontWeight: '800',
  },
});
